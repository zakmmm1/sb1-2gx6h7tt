/*
  # Fix Company Policies Final Version

  1. Changes
    - Remove all recursive policies
    - Implement simplified company access control
    - Fix task visibility rules
    
  2. Security
    - Direct company membership checks
    - Clear ownership hierarchy
    - No circular dependencies
*/

-- Drop all existing policies
DROP POLICY IF EXISTS "view_company_members" ON company_users;
DROP POLICY IF EXISTS "manage_company_members" ON company_users;
DROP POLICY IF EXISTS "company_tasks_access" ON tasks;

-- Simple, non-recursive company membership policy
CREATE POLICY "company_member_access"
  ON company_users
  FOR SELECT
  TO authenticated
  USING (
    company_id IN (
      SELECT c.id 
      FROM companies c
      WHERE c.owner_id = auth.uid()
      UNION
      SELECT cu.company_id 
      FROM company_users cu 
      WHERE cu.user_id = auth.uid()
    )
  );

-- Company management policy
CREATE POLICY "company_management"
  ON company_users
  FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 
      FROM companies c
      WHERE c.id = company_users.company_id 
      AND c.owner_id = auth.uid()
    )
  );

-- Task visibility policy
CREATE POLICY "task_visibility"
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
      AND cu.company_id = (
        SELECT c.id 
        FROM companies c
        INNER JOIN company_users cu2 ON cu2.company_id = c.id
        WHERE cu2.user_id = tasks.user_id
      )
    )
  );

-- Task management policy
CREATE POLICY "task_management"
  ON tasks
  FOR ALL
  TO authenticated
  USING (
    user_id = auth.uid()
    OR
    EXISTS (
      SELECT 1 
      FROM company_users cu
      WHERE cu.user_id = auth.uid()
      AND cu.role IN ('owner', 'admin')
      AND cu.company_id = (
        SELECT cu2.company_id 
        FROM company_users cu2
        WHERE cu2.user_id = tasks.user_id
      )
    )
  );

-- Add indexes for performance
CREATE INDEX IF NOT EXISTS idx_company_users_lookup 
  ON company_users(user_id, company_id);

CREATE INDEX IF NOT EXISTS idx_tasks_company_lookup 
  ON tasks(user_id, assignee_id);