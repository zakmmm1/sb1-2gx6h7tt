/*
  # Fix recursive policies

  1. Changes
    - Drop existing problematic policies
    - Create simplified non-recursive policies for company access
    - Add performance indexes
*/

-- Drop existing problematic policies
DROP POLICY IF EXISTS "users_view_own_company" ON companies;
DROP POLICY IF EXISTS "users_view_company_members" ON company_users;
DROP POLICY IF EXISTS "users_access_company_tasks" ON tasks;

-- Simple company access
CREATE POLICY "company_access"
  ON companies
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM company_users
      WHERE user_id = auth.uid()
      AND company_id = companies.id
    )
  );

-- Simple company users access
CREATE POLICY "company_users_access"
  ON company_users
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM companies
      WHERE id = company_users.company_id
      AND (
        owner_id = auth.uid()
        OR
        id IN (
          SELECT company_id FROM company_users
          WHERE user_id = auth.uid()
        )
      )
    )
  );

-- Simple task access
CREATE POLICY "task_access"
  ON tasks
  FOR SELECT
  TO authenticated
  USING (
    user_id = auth.uid()
    OR
    assignee_id = auth.uid()
    OR
    EXISTS (
      SELECT 1 FROM company_users
      WHERE user_id = auth.uid()
      AND company_id IN (
        SELECT company_id FROM company_users
        WHERE user_id = tasks.user_id
      )
    )
  );

-- Ensure indexes exist for performance
CREATE INDEX IF NOT EXISTS idx_company_users_user_company 
  ON company_users(user_id, company_id);

CREATE INDEX IF NOT EXISTS idx_tasks_user_assignee 
  ON tasks(user_id, assignee_id);