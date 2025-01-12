/*
  # Fix company users policies and constraints

  1. Changes
    - Add NOT NULL constraints
    - Simplify policies
    - Add proper indexes
    - Fix role validation

  2. Security
    - Allow all authenticated users to view company users
    - Only admins/owners can invite new users
*/

-- Ensure required fields are not null
ALTER TABLE company_users
ALTER COLUMN company_name SET NOT NULL,
ALTER COLUMN email SET NOT NULL,
ALTER COLUMN role SET NOT NULL;

-- Drop existing policies
DROP POLICY IF EXISTS "authenticated_can_view_company_users" ON company_users;
DROP POLICY IF EXISTS "admins_can_manage_company_users" ON company_users;

-- Create new simplified policies
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
    -- Check if user is admin/owner in the target company
    EXISTS (
      SELECT 1 
      FROM company_users cu
      WHERE cu.user_id = auth.uid()
      AND cu.company_name = company_users.company_name
      AND cu.role IN ('owner', 'admin')
    )
  );

-- Add role validation
ALTER TABLE company_users
ADD CONSTRAINT valid_role CHECK (role IN ('owner', 'admin', 'member'));

-- Add indexes for better performance
CREATE INDEX IF NOT EXISTS idx_company_users_lookup 
  ON company_users(user_id, company_name, role);

CREATE INDEX IF NOT EXISTS idx_company_users_email 
  ON company_users(email, company_name);