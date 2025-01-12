/*
  # Fix User Permissions

  1. Changes
    - Updates all existing users to be admins
    - Ensures correct role validation
    - Adds missing indexes
    - Fixes policy issues

  2. Security
    - Maintains RLS
    - Updates policies for better access control
*/

-- First make all existing users admins
UPDATE company_users
SET 
  role = CASE 
    WHEN role = 'owner' THEN 'owner'  -- Preserve owner role
    ELSE 'admin'                      -- Make everyone else admin
  END,
  can_view_all_tasks = true
WHERE status = 'active';

-- Ensure proper role validation
ALTER TABLE company_users
DROP CONSTRAINT IF EXISTS valid_role;

ALTER TABLE company_users
ADD CONSTRAINT valid_role CHECK (role IN ('owner', 'admin', 'user'));

-- Drop existing policies
DROP POLICY IF EXISTS "allow_view_company_users" ON company_users;
DROP POLICY IF EXISTS "allow_invite_company_users" ON company_users;

-- Create simplified policies
CREATE POLICY "anyone_can_view_company_users"
  ON company_users
  FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "admins_can_invite_users"
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
CREATE INDEX IF NOT EXISTS idx_company_users_role_lookup 
  ON company_users(user_id, role, company_name);

CREATE INDEX IF NOT EXISTS idx_company_users_email_lookup 
  ON company_users(email, company_name);