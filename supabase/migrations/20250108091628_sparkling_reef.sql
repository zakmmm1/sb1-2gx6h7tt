-- Drop existing problematic policies
DROP POLICY IF EXISTS "company_access" ON companies;
DROP POLICY IF EXISTS "member_access" ON company_users;
DROP POLICY IF EXISTS "owner_management" ON companies;
DROP POLICY IF EXISTS "task_access" ON tasks;

-- Basic company access
CREATE POLICY "users_view_own_company"
  ON companies
  FOR SELECT
  TO authenticated
  USING (
    id IN (
      SELECT company_id 
      FROM company_users 
      WHERE user_id = auth.uid()
    )
  );

-- Company users access
CREATE POLICY "users_view_company_members"
  ON company_users
  FOR SELECT
  TO authenticated
  USING (
    company_id IN (
      SELECT company_id 
      FROM company_users 
      WHERE user_id = auth.uid()
    )
  );

-- Task access
CREATE POLICY "users_access_company_tasks"
  ON tasks
  FOR SELECT
  TO authenticated
  USING (
    user_id = auth.uid()
    OR
    assignee_id = auth.uid()
    OR
    EXISTS (
      SELECT 1 
      FROM company_users cu
      WHERE cu.user_id = auth.uid()
      AND cu.company_id IN (
        SELECT company_id 
        FROM company_users 
        WHERE user_id = tasks.user_id
      )
    )
  );

-- Ensure indexes exist for performance
CREATE INDEX IF NOT EXISTS idx_company_users_lookup 
  ON company_users(user_id, company_id);

CREATE INDEX IF NOT EXISTS idx_tasks_lookup 
  ON tasks(user_id, assignee_id);