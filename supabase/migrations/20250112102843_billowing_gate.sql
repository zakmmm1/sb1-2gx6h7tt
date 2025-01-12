-- Drop existing problematic policies
DROP POLICY IF EXISTS "allow_select_company_users" ON company_users;
DROP POLICY IF EXISTS "allow_insert_company_users" ON company_users;

-- Create new simplified policies
CREATE POLICY "company_users_select"
  ON company_users
  FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "company_users_insert"
  ON company_users
  FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 
      FROM company_users cu
      WHERE cu.user_id = auth.uid()
      AND cu.role IN ('owner', 'admin')
      AND cu.status = 'active'
    )
  );

-- Add index for better performance
CREATE INDEX IF NOT EXISTS idx_company_users_role_status 
  ON company_users(role, status);