/*
  # Fix user invitation system errors
  
  1. Changes
    - Simplify table structure
    - Fix policy conflicts
    - Add proper constraints
    - Clean up existing data
*/

-- First clean up existing problematic data
DELETE FROM company_users WHERE email IS NULL;

-- Ensure company_users has the correct structure
ALTER TABLE company_users DROP CONSTRAINT IF EXISTS company_users_pkey;
ALTER TABLE company_users ADD PRIMARY KEY (email, company_name);

-- Ensure required columns with correct defaults
ALTER TABLE company_users
ALTER COLUMN email SET NOT NULL,
ALTER COLUMN company_name SET NOT NULL,
ALTER COLUMN role SET NOT NULL,
ALTER COLUMN role SET DEFAULT 'user',
ALTER COLUMN can_view_all_tasks SET NOT NULL,
ALTER COLUMN can_view_all_tasks SET DEFAULT false;

-- Drop all existing policies
DROP POLICY IF EXISTS "view_company_users" ON company_users;
DROP POLICY IF EXISTS "manage_invitations" ON company_users;
DROP POLICY IF EXISTS "company_users_view" ON company_users;
DROP POLICY IF EXISTS "company_users_select" ON company_users;
DROP POLICY IF EXISTS "company_users_insert" ON company_users;
DROP POLICY IF EXISTS "company_users_manage" ON company_users;

-- Create single policy for viewing
CREATE POLICY "allow_view_company_users"
  ON company_users
  FOR SELECT
  TO authenticated
  USING (true);

-- Create single policy for inviting
CREATE POLICY "allow_invite_company_users"
  ON company_users
  FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 
      FROM company_users cu
      WHERE cu.user_id = auth.uid()
      AND cu.role IN ('owner', 'admin')
      AND cu.company_name = company_users.company_name
    )
  );

-- Add indexes for better performance
CREATE INDEX IF NOT EXISTS idx_company_users_lookup 
  ON company_users(user_id, company_name, role);

CREATE INDEX IF NOT EXISTS idx_company_users_email 
  ON company_users(email, company_name);