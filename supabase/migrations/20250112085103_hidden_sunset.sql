-- Drop existing problematic policies
DROP POLICY IF EXISTS "company_users_view" ON company_users;
DROP POLICY IF EXISTS "company_users_invite" ON company_users;

-- Add can_view_all_tasks to company_users if it doesn't exist
ALTER TABLE company_users 
ADD COLUMN IF NOT EXISTS can_view_all_tasks boolean DEFAULT true;

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
      AND cu.role IN ('owner', 'admin')
    )
  );

-- Add indexes for better performance
CREATE INDEX IF NOT EXISTS idx_company_users_lookup 
  ON company_users(user_id, role, can_view_all_tasks);

-- Set default permissions for existing users
UPDATE company_users
SET can_view_all_tasks = true
WHERE can_view_all_tasks IS NULL;