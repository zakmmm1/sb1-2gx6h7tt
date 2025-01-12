/*
  # Fix Company Policies and Add Company Management

  1. Changes
    - Drop problematic recursive policies
    - Create new non-recursive policies for company_users
    - Add company management functions
    - Fix task policies to work with company context
    
  2. Security
    - Ensure proper access control for company members
    - Prevent infinite recursion in policies
    - Maintain data isolation between companies
*/

-- Drop all existing policies on company_users to start fresh
DROP POLICY IF EXISTS "Users can view company members" ON company_users;
DROP POLICY IF EXISTS "Company owners can manage members" ON company_users;

-- Create new non-recursive policies
CREATE POLICY "view_company_members"
  ON company_users
  FOR SELECT
  TO authenticated
  USING (
    company_id IN (
      SELECT company_id 
      FROM user_settings 
      WHERE user_id = auth.uid()
    )
  );

CREATE POLICY "manage_company_members"
  ON company_users
  FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 
      FROM user_settings us
      JOIN companies c ON c.id = us.company_id
      WHERE us.user_id = auth.uid()
      AND c.owner_id = auth.uid()
      AND c.id = company_users.company_id
    )
  );

-- Update tasks policy to work with company context
CREATE POLICY "company_tasks_access"
  ON tasks
  FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 
      FROM user_settings us
      WHERE us.user_id = auth.uid()
      AND us.company_id = (
        SELECT company_id 
        FROM user_settings 
        WHERE user_id = tasks.user_id
      )
    )
  );

-- Add helper function to get user's company
CREATE OR REPLACE FUNCTION get_user_company(user_uuid uuid)
RETURNS uuid AS $$
BEGIN
  RETURN (
    SELECT company_id 
    FROM user_settings 
    WHERE user_id = user_uuid
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;