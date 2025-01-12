-- First ensure all required columns exist with correct constraints
ALTER TABLE company_users 
ALTER COLUMN invited_by DROP NOT NULL,
ALTER COLUMN status SET DEFAULT 'pending',
ALTER COLUMN status SET NOT NULL;

-- Add missing constraints if they don't exist
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint 
    WHERE conname = 'company_users_status_check'
  ) THEN
    ALTER TABLE company_users 
    ADD CONSTRAINT company_users_status_check 
    CHECK (status IN ('pending', 'active'));
  END IF;
END $$;

-- Update any NULL statuses to 'active' for existing users
UPDATE company_users
SET status = 'active'
WHERE user_id IS NOT NULL AND status IS NULL;

-- Drop existing problematic policies
DROP POLICY IF EXISTS "allow_view_invitations" ON company_users;
DROP POLICY IF EXISTS "allow_create_invitations" ON company_users;

-- Create simplified policies
CREATE POLICY "anyone_can_view_company_users"
  ON company_users
  FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "admins_can_invite_users"
  ON company_users
  FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 
      FROM company_users cu
      WHERE cu.user_id = auth.uid()
      AND cu.company_name = company_users.company_name
      AND cu.role IN ('owner', 'admin')
    )
  );

-- Add indexes for better performance
CREATE INDEX IF NOT EXISTS idx_company_users_invitation_lookup 
  ON company_users(email, company_name, status);