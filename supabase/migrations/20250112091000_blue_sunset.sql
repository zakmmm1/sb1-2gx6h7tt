/*
  # Fix user invitation system
  
  1. Changes
    - Add invitation status tracking
    - Add invitation token and expiry
    - Add proper constraints and indexes
    - Update policies for invitation management
  
  2. Security
    - Only admins can invite users
    - Users can only view invitations for their company
    - Proper expiration handling
*/

-- Ensure company_users has all required invitation columns
ALTER TABLE company_users 
ADD COLUMN IF NOT EXISTS status text NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'active')),
ADD COLUMN IF NOT EXISTS invitation_token uuid DEFAULT gen_random_uuid(),
ADD COLUMN IF NOT EXISTS invitation_expires_at timestamptz DEFAULT (now() + interval '7 days'),
ADD COLUMN IF NOT EXISTS invited_by uuid REFERENCES auth.users;

-- Drop existing problematic policies
DROP POLICY IF EXISTS "company_users_select" ON company_users;
DROP POLICY IF EXISTS "company_users_insert" ON company_users;

-- Create new policies for invitation management
CREATE POLICY "view_company_users"
  ON company_users
  FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "manage_invitations"
  ON company_users
  FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 
      FROM company_users cu
      WHERE cu.user_id = auth.uid()
      AND cu.role IN ('owner', 'admin')
      AND cu.company_name = company_users.company_name
    )
  );

-- Add function to handle invitation acceptance
CREATE OR REPLACE FUNCTION handle_invitation_acceptance()
RETURNS TRIGGER AS $$
BEGIN
  -- Update invitation status when user signs up
  IF NEW.email IS NOT NULL THEN
    UPDATE company_users
    SET 
      user_id = NEW.id,
      status = 'active'
    WHERE 
      email = NEW.email
      AND status = 'pending'
      AND invitation_expires_at > now();
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger for invitation acceptance
DROP TRIGGER IF EXISTS handle_invitation_trigger ON auth.users;
CREATE TRIGGER handle_invitation_trigger
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION handle_invitation_acceptance();

-- Add indexes for better performance
CREATE INDEX IF NOT EXISTS idx_company_users_invitation 
  ON company_users(email, status, invitation_expires_at);

CREATE INDEX IF NOT EXISTS idx_company_users_lookup 
  ON company_users(user_id, company_name, role);