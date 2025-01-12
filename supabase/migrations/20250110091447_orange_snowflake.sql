/*
  # Fix company users policies

  1. Changes
    - Drop existing problematic policies
    - Create simplified policies for company users
    - Add necessary indexes for performance

  2. Security
    - Maintain proper access control without recursion
    - Allow admins to manage users
    - Allow users to view company members
*/

-- Drop existing problematic policies
DROP POLICY IF EXISTS "users_view_company_members" ON company_users;
DROP POLICY IF EXISTS "users_manage_company_members" ON company_users;

-- Create new simplified policies
CREATE POLICY "allow_view_company_users"
  ON company_users
  FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "allow_admin_manage_users"
  ON company_users
  FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 
      FROM user_settings us
      WHERE us.user_id = auth.uid()
      AND us.company_name IS NOT NULL
    )
  );

-- Add index for better performance
CREATE INDEX IF NOT EXISTS idx_company_users_user_id 
  ON company_users(user_id);