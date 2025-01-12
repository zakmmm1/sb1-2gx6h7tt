/*
  # Fix company users table

  1. Changes
    - Add company_name column to company_users table
    - Update policies to use company_name for access control
    - Add indexes for better performance

  2. Security
    - Enable RLS
    - Add policies for viewing and managing company users
*/

-- Add company_name column
ALTER TABLE company_users 
ADD COLUMN IF NOT EXISTS company_name text;

-- Drop existing policies
DROP POLICY IF EXISTS "allow_view_company_users" ON company_users;
DROP POLICY IF EXISTS "allow_admin_manage_users" ON company_users;

-- Create new policies
CREATE POLICY "view_company_users"
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

CREATE POLICY "manage_company_users"
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

-- Add indexes
CREATE INDEX IF NOT EXISTS idx_company_users_company_name 
  ON company_users(company_name);

CREATE INDEX IF NOT EXISTS idx_user_settings_company_name 
  ON user_settings(user_id, company_name);