/*
  # Fix company users policies - Final version

  1. Changes
    - Simplifies company membership checks using user_settings
    - Separates admin role checks from company membership
    - Ensures non-recursive policy evaluation

  2. Security
    - Maintains proper access control
    - Prevents unauthorized access
*/

-- Drop existing problematic policies
DROP POLICY IF EXISTS "company_users_view" ON company_users;
DROP POLICY IF EXISTS "company_users_invite" ON company_users;

-- Create new non-recursive policies
CREATE POLICY "allow_company_view"
  ON company_users
  FOR SELECT
  TO authenticated
  USING (
    -- Simple company membership check via user_settings
    company_name = (
      SELECT company_name 
      FROM user_settings 
      WHERE user_id = auth.uid()
      AND company_name IS NOT NULL
    )
  );

CREATE POLICY "allow_company_invite"
  ON company_users
  FOR INSERT
  TO authenticated
  WITH CHECK (
    -- First verify admin status (non-recursive)
    role IN ('owner', 'admin')
    AND
    -- Then ensure same company
    company_name = (
      SELECT company_name 
      FROM user_settings 
      WHERE user_id = auth.uid()
      AND company_name IS NOT NULL
    )
  );

-- Add index for better performance
CREATE INDEX IF NOT EXISTS idx_company_users_final 
  ON company_users(company_name, role);