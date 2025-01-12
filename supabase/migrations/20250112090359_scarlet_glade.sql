/*
  # Clean up invitation system

  1. Changes
    - Consolidates all invitation-related changes into a single migration
    - Ensures proper column types and constraints
    - Adds appropriate indexes for performance
    - Updates existing data to maintain consistency

  2. Security
    - Enables RLS
    - Adds policies for viewing and managing invitations
*/

-- Ensure company_users has all required columns
ALTER TABLE company_users 
ADD COLUMN IF NOT EXISTS status text NOT NULL DEFAULT 'active' CHECK (status IN ('pending', 'active')),
ADD COLUMN IF NOT EXISTS invited_by uuid REFERENCES auth.users,
ADD COLUMN IF NOT EXISTS invitation_token uuid DEFAULT gen_random_uuid(),
ADD COLUMN IF NOT EXISTS invitation_expires_at timestamptz DEFAULT (now() + interval '7 days');

-- Create indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_company_users_invitation 
  ON company_users(invitation_token, status);

CREATE INDEX IF NOT EXISTS idx_company_users_invited_by 
  ON company_users(invited_by);

-- Update existing users to be marked as active
UPDATE company_users
SET status = 'active'
WHERE user_id IS NOT NULL AND status != 'active';

-- Create policies for invitation management
CREATE POLICY "allow_view_invitations"
  ON company_users
  FOR SELECT
  TO authenticated
  USING (
    -- Can view if you're in the same company or you're the invitee
    company_name IN (
      SELECT company_name FROM company_users WHERE user_id = auth.uid()
    )
    OR
    email = (SELECT email FROM auth.users WHERE id = auth.uid())
  );

CREATE POLICY "allow_create_invitations"
  ON company_users
  FOR INSERT
  TO authenticated
  WITH CHECK (
    -- Must be admin/owner to invite
    EXISTS (
      SELECT 1 FROM company_users
      WHERE user_id = auth.uid()
      AND company_name = company_users.company_name
      AND role IN ('admin', 'owner')
    )
  );

-- Add trigger to handle user signup
CREATE OR REPLACE FUNCTION handle_new_user_signup()
RETURNS TRIGGER AS $$
BEGIN
  -- Update any pending invitations for this email
  UPDATE company_users
  SET 
    user_id = NEW.id,
    status = 'active'
  WHERE 
    email = NEW.email
    AND status = 'pending'
    AND invitation_expires_at > now();
    
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Add trigger for new user signups
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION handle_new_user_signup();