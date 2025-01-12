/*
  # Fix company users structure

  1. Changes
    - Ensures company_name is required for company_users
    - Updates policies to use company_name consistently
    - Adds proper indexes for performance
    - Maintains existing data integrity

  2. Security
    - Updates RLS policies to use company_name
    - Maintains proper access control for company members
*/

-- First ensure company_name is not null
ALTER TABLE company_users 
ALTER COLUMN company_name SET NOT NULL;

-- Drop existing problematic policies
DROP POLICY IF EXISTS "view_company_users" ON company_users;
DROP POLICY IF EXISTS "manage_company_users" ON company_users;
DROP POLICY IF EXISTS "company_users_view" ON company_users;
DROP POLICY IF EXISTS "company_users_manage" ON company_users;

-- Create new simplified policies
CREATE POLICY "company_users_access"
  ON company_users
  FOR SELECT
  TO authenticated
  USING (
    company_name IN (
      SELECT company_name 
      FROM user_settings 
      WHERE user_id = auth.uid()
      AND company_name IS NOT NULL
    )
  );

CREATE POLICY "company_users_invite"
  ON company_users
  FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 
      FROM user_settings us
      WHERE us.user_id = auth.uid()
      AND us.company_name = company_users.company_name
      AND EXISTS (
        SELECT 1 
        FROM company_users cu
        WHERE cu.user_id = auth.uid()
        AND cu.company_name = company_users.company_name
        AND cu.role IN ('owner', 'admin')
      )
    )
  );

-- Add indexes for better performance
CREATE INDEX IF NOT EXISTS idx_company_users_lookup 
  ON company_users(company_name, user_id, role);

CREATE INDEX IF NOT EXISTS idx_user_settings_company 
  ON user_settings(user_id, company_name);