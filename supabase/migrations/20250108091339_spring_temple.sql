/*
  # Fix Company Policies - Final Version

  1. Changes
    - Remove all recursive policies
    - Implement direct company membership checks
    - Fix task visibility rules
    
  2. Security
    - Simple, direct access control
    - Clear ownership hierarchy
    - No circular dependencies
*/

-- Drop existing problematic policies
DROP POLICY IF EXISTS "company_member_access" ON company_users;
DROP POLICY IF EXISTS "company_management" ON company_users;
DROP POLICY IF EXISTS "task_visibility" ON tasks;
DROP POLICY IF EXISTS "task_management" ON tasks;

-- Simple company access policy
CREATE POLICY "company_access"
  ON companies
  FOR SELECT
  TO authenticated
  USING (
    id IN (
      SELECT company_id FROM user_settings WHERE user_id = auth.uid()
    )
  );

-- Direct company membership check
CREATE POLICY "member_access"
  ON company_users
  FOR SELECT
  TO authenticated
  USING (
    user_id = auth.uid()
    OR
    company_id IN (
      SELECT company_id FROM user_settings WHERE user_id = auth.uid()
    )
  );

-- Company management for owners
CREATE POLICY "owner_management"
  ON companies
  FOR ALL
  TO authenticated
  USING (owner_id = auth.uid());

-- Task access policy
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
      SELECT 1 FROM user_settings
      WHERE user_id = auth.uid()
      AND company_id = (
        SELECT company_id FROM user_settings WHERE user_id = tasks.user_id
      )
    )
  );

-- Add necessary indexes
CREATE INDEX IF NOT EXISTS idx_user_settings_company 
  ON user_settings(user_id, company_id);

CREATE INDEX IF NOT EXISTS idx_tasks_user_assignee 
  ON tasks(user_id, assignee_id);