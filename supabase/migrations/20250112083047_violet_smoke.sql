/*
  # Fix user permissions policies

  1. Changes
    - Drop existing problematic policies
    - Create simplified non-recursive policies
    - Add default admin policy for first user in company

  2. Security
    - Maintain RLS
    - Ensure proper access control
*/

-- Drop existing problematic policies
DROP POLICY IF EXISTS "Users can view their own permissions" ON user_permissions;
DROP POLICY IF EXISTS "Admins can manage user permissions" ON user_permissions;

-- Create simplified policies
CREATE POLICY "allow_users_view_own_permissions"
  ON user_permissions
  FOR SELECT
  TO authenticated
  USING (
    user_id = auth.uid()
    OR
    EXISTS (
      SELECT 1 
      FROM company_users cu
      WHERE cu.user_id = auth.uid()
      AND cu.role = 'owner'
    )
  );

CREATE POLICY "allow_owners_manage_permissions"
  ON user_permissions
  FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 
      FROM company_users cu
      WHERE cu.user_id = auth.uid()
      AND cu.role = 'owner'
    )
  );

-- Create function to set initial admin permissions
CREATE OR REPLACE FUNCTION set_initial_user_permissions()
RETURNS TRIGGER AS $$
BEGIN
  -- Set the first user in a company as admin
  INSERT INTO user_permissions (user_id, role, can_view_all_tasks)
  VALUES (
    NEW.user_id,
    CASE 
      WHEN NEW.role = 'owner' THEN 'admin'
      ELSE 'user'
    END,
    true
  )
  ON CONFLICT (user_id) DO NOTHING;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for new company users
DROP TRIGGER IF EXISTS set_user_permissions_trigger ON company_users;
CREATE TRIGGER set_user_permissions_trigger
  AFTER INSERT ON company_users
  FOR EACH ROW
  EXECUTE FUNCTION set_initial_user_permissions();

-- Add indexes for better performance
CREATE INDEX IF NOT EXISTS idx_user_permissions_lookup 
  ON user_permissions(user_id, role);

CREATE INDEX IF NOT EXISTS idx_company_users_role_lookup 
  ON company_users(user_id, role);