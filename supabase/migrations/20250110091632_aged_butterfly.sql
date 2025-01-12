/*
  # Fix company users structure

  1. Changes
    - Add company_name column
    - Update existing policies to use company_name
    - Drop old company_id dependencies safely

  2. Security
    - Update policies to use company_name for access control
*/

-- First, drop existing policies that depend on company_id
DROP POLICY IF EXISTS "Users can view their company" ON companies;
DROP POLICY IF EXISTS "Company admins can create invitations" ON company_invitations;
DROP POLICY IF EXISTS "Company members can view invitations" ON company_invitations;
DROP POLICY IF EXISTS "Assigned users can view tasks" ON tasks;
DROP POLICY IF EXISTS "company_users_basic_access" ON company_users;
DROP POLICY IF EXISTS "task_crud_policy" ON tasks;

-- Create new policies using company_name
CREATE POLICY "users_view_company"
  ON companies
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 
      FROM user_settings us
      WHERE us.user_id = auth.uid()
      AND us.company_name = companies.name
    )
  );

CREATE POLICY "company_invitations_create"
  ON company_invitations
  FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 
      FROM user_settings us
      WHERE us.user_id = auth.uid()
      AND us.company_name IS NOT NULL
    )
  );

CREATE POLICY "company_invitations_view"
  ON company_invitations
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 
      FROM user_settings us
      WHERE us.user_id = auth.uid()
      AND us.company_name IS NOT NULL
    )
  );

CREATE POLICY "task_access_policy"
  ON tasks
  FOR ALL
  TO authenticated
  USING (
    user_id = auth.uid()
    OR assignee_id = auth.uid()
    OR EXISTS (
      SELECT 1 
      FROM user_settings us1
      JOIN user_settings us2 ON us1.company_name = us2.company_name
      WHERE us1.user_id = auth.uid()
      AND us2.user_id = tasks.user_id
    )
  );

-- Add company_name to company_users if it doesn't exist
ALTER TABLE company_users 
ADD COLUMN IF NOT EXISTS company_name text;

-- Update company_users policies
CREATE POLICY "company_users_view"
  ON company_users
  FOR SELECT
  TO authenticated
  USING (
    company_name IN (
      SELECT company_name 
      FROM user_settings 
      WHERE user_id = auth.uid()
    )
  );

CREATE POLICY "company_users_manage"
  ON company_users
  FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 
      FROM user_settings us
      WHERE us.user_id = auth.uid()
      AND us.company_name = company_users.company_name
    )
  );

-- Add indexes for better performance
CREATE INDEX IF NOT EXISTS idx_company_users_lookup 
  ON company_users(company_name, user_id);

CREATE INDEX IF NOT EXISTS idx_user_settings_lookup 
  ON user_settings(user_id, company_name);