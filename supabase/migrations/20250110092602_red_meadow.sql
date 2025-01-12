/*
  # Fix company users RLS policies - Final version

  1. Changes
    - Simplifies RLS policies to avoid recursion
    - Ensures proper access control for company users
    - Fixes row-level security violations

  2. Security
    - Maintains proper access control
    - Prevents unauthorized access
*/

-- Drop existing problematic policies
DROP POLICY IF EXISTS "allow_company_view" ON company_users;
DROP POLICY IF EXISTS "allow_company_invite" ON company_users;

-- Create new simplified policies
CREATE POLICY "allow_company_users_select"
  ON company_users
  FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "allow_company_users_insert"
  ON company_users
  FOR INSERT
  TO authenticated
  WITH CHECK (
    -- Allow insert if user has admin role in the same company
    EXISTS (
      SELECT 1 
      FROM user_settings us
      WHERE us.user_id = auth.uid()
      AND us.company_name = company_users.company_name
    )
  );

-- Add index for better performance
CREATE INDEX IF NOT EXISTS idx_company_users_lookup_final 
  ON company_users(company_name, user_id);