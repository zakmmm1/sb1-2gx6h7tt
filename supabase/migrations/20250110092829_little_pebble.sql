/*
  # Fix company users policies

  1. Changes
    - Simplify company users policies
    - Remove recursive policy checks
    - Add proper role-based access control
    - Fix invitation system

  2. Security
    - Allow all authenticated users to view company users
    - Only admins/owners can invite new users
    - Ensure company name consistency
*/

-- Drop existing problematic policies
DROP POLICY IF EXISTS "anyone_can_view" ON company_users;
DROP POLICY IF EXISTS "admins_can_invite" ON company_users;

-- Create new simplified policies
CREATE POLICY "authenticated_can_view_company_users"
  ON company_users
  FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "admins_can_manage_company_users"
  ON company_users
  FOR INSERT
  TO authenticated
  WITH CHECK (
    -- Verify admin/owner status in their company
    EXISTS (
      SELECT 1 
      FROM company_users cu
      WHERE cu.user_id = auth.uid()
      AND cu.role IN ('owner', 'admin')
      AND cu.company_name = company_users.company_name
    )
  );

-- Add index for better performance
CREATE INDEX IF NOT EXISTS idx_company_users_invite 
  ON company_users(user_id, role, company_name);