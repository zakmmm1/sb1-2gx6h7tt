/*
  # Fix company users policies

  1. Changes
    - Simplifies company users policies to avoid recursion
    - Ensures proper admin/owner checks
    - Maintains data isolation between companies

  2. Security
    - Maintains proper access control
    - Prevents unauthorized access
*/

-- Drop existing problematic policies
DROP POLICY IF EXISTS "company_users_access" ON company_users;
DROP POLICY IF EXISTS "company_users_invite" ON company_users;

-- Create new non-recursive policies
CREATE POLICY "view_company_members"
  ON company_users
  FOR SELECT
  TO authenticated
  USING (
    -- Users can view members of their own company
    company_name = (
      SELECT company_name 
      FROM user_settings 
      WHERE user_id = auth.uid()
      AND company_name IS NOT NULL
    )
  );

CREATE POLICY "invite_company_members"
  ON company_users
  FOR INSERT
  TO authenticated
  WITH CHECK (
    -- Only admins/owners can invite
    EXISTS (
      SELECT 1 
      FROM company_users cu
      WHERE cu.user_id = auth.uid()
      AND cu.company_name = company_users.company_name
      AND cu.role IN ('owner', 'admin')
    )
    AND
    -- Must be for the same company as the inviter
    company_name = (
      SELECT company_name 
      FROM user_settings 
      WHERE user_id = auth.uid()
      AND company_name IS NOT NULL
    )
  );

-- Add index for better performance
CREATE INDEX IF NOT EXISTS idx_company_users_role_lookup 
  ON company_users(company_name, user_id, role);