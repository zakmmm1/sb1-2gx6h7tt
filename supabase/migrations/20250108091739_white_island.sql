/*
  # Fix recursive policies

  1. Changes
    - Drop existing problematic policies
    - Create simplified non-recursive policies
    - Add performance indexes
*/

-- Drop existing problematic policies
DROP POLICY IF EXISTS "company_access" ON companies;
DROP POLICY IF EXISTS "company_users_access" ON company_users;
DROP POLICY IF EXISTS "task_access" ON tasks;

-- Simple company access
CREATE POLICY "company_basic_access"
  ON companies
  FOR SELECT
  TO authenticated
  USING (
    id IN (
      SELECT company_id 
      FROM user_settings 
      WHERE user_id = auth.uid()
    )
  );

-- Simple company users access
CREATE POLICY "company_users_basic_access"
  ON company_users
  FOR SELECT
  TO authenticated
  USING (
    company_id IN (
      SELECT company_id 
      FROM user_settings 
      WHERE user_id = auth.uid()
    )
  );

-- Simple task access
CREATE POLICY "task_basic_access"
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
      FROM user_settings us
      WHERE us.user_id = auth.uid()
      AND us.company_id = (
        SELECT company_id 
        FROM user_settings 
        WHERE user_id = tasks.user_id
      )
    )
  );

-- Add indexes for performance
CREATE INDEX IF NOT EXISTS idx_user_settings_lookup 
  ON user_settings(user_id, company_id);

CREATE INDEX IF NOT EXISTS idx_tasks_lookup 
  ON tasks(user_id, assignee_id);