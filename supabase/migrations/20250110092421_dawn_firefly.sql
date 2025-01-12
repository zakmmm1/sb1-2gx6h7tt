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
DROP POLICY IF EXISTS "view_company_members" ON company_users;
DROP POLICY IF EXISTS "invite_company_members" ON company_users;

-- Create new non-recursive policies
CREATE POLICY "company_users_view"
  ON company_users
  FOR SELECT
  TO authenticated
  USING (
    -- Users can view members of companies they belong to
    company_name = (
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
    -- Check if user is admin/owner in their company
    EXISTS (
      SELECT 1 
      FROM company_users cu
      WHERE cu.user_id = auth.uid()
      AND cu.role IN ('owner', 'admin')
      AND cu.company_name = (
        SELECT company_name 
        FROM user_settings 
        WHERE user_id = auth.uid()
        AND company_name IS NOT NULL
      )
    )
    AND
    -- Ensure new user is added to the same company
    company_name = (
      SELECT company_name 
      FROM user_settings 
      WHERE user_id = auth.uid()
      AND company_name IS NOT NULL
    )
  );

-- Add index for better performance
CREATE INDEX IF NOT EXISTS idx_company_users_role_company 
  ON company_users(user_id, role, company_name);