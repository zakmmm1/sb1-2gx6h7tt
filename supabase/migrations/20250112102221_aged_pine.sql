-- Drop existing policies
DROP POLICY IF EXISTS "allow_view_users" ON company_users;
DROP POLICY IF EXISTS "allow_invite_users" ON company_users;
DROP POLICY IF EXISTS "company_users_view" ON company_users;
DROP POLICY IF EXISTS "company_users_invite" ON company_users;

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
      AND cu.owner_account_id = company_users.owner_account_id
      AND cu.role IN ('owner', 'admin')
      AND cu.status = 'active'
    )
  );

-- Add indexes for better performance
CREATE INDEX IF NOT EXISTS idx_company_users_lookup 
  ON company_users(owner_account_id, role, status);