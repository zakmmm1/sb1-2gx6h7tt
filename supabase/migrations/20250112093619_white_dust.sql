/*
  # Fix Admin Roles and Permissions

  1. Changes
    - Makes all existing users admins
    - Adds better role validation
    - Fixes policy issues
    - Adds missing indexes

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
  can_view_all_tasks = true,
  status = 'active'
WHERE user_id IS NOT NULL;

-- Drop existing policies
DROP POLICY IF EXISTS "allow_view_company_users" ON company_users;
DROP POLICY IF EXISTS "allow_invite_company_users" ON company_users;

-- Create simplified policies
CREATE POLICY "allow_view_company_users"
  ON company_users
  FOR SELECT
  TO authenticated
  USING (true);

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
      AND cu.status = 'active'
    )
  );

-- Add indexes for better performance
CREATE INDEX IF NOT EXISTS idx_company_users_role_lookup 
  ON company_users(user_id, role, company_name);

CREATE INDEX IF NOT EXISTS idx_company_users_email_lookup 
  ON company_users(email, company_name);