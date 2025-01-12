/*
  # Implement multi-user features

  1. Changes
    - Add user roles and permissions
    - Add task collaboration support
    - Fix recursive policy issues

  2. Security
    - Enable RLS
    - Add proper access control policies
*/

-- Create user_roles table
CREATE TABLE IF NOT EXISTS user_roles (
  user_id uuid PRIMARY KEY REFERENCES auth.users,
  role text NOT NULL CHECK (role IN ('admin', 'user')),
  can_view_all_tasks boolean NOT NULL DEFAULT true,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Enable RLS on user_roles
ALTER TABLE user_roles ENABLE ROW LEVEL SECURITY;

-- Add task collaboration support
ALTER TABLE tasks 
ADD COLUMN IF NOT EXISTS collaborators uuid[] DEFAULT ARRAY[]::uuid[];

-- Create policies for user_roles
CREATE POLICY "users_view_own_role"
  ON user_roles
  FOR SELECT
  TO authenticated
  USING (
    user_id = auth.uid()
    OR
    EXISTS (
      SELECT 1 
      FROM company_users cu
      WHERE cu.user_id = auth.uid()
      AND cu.role = 'admin'
    )
  );

CREATE POLICY "admins_manage_roles"
  ON user_roles
  FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 
      FROM company_users cu
      WHERE cu.user_id = auth.uid()
      AND cu.role = 'admin'
    )
  );

-- Update task policies
CREATE POLICY "task_access"
  ON tasks
  FOR ALL
  TO authenticated
  USING (
    -- User owns the task
    user_id = auth.uid()
    OR
    -- User is assigned to the task
    assignee_id = auth.uid()
    OR
    -- User is a collaborator
    auth.uid() = ANY(collaborators)
    OR
    -- User is admin
    EXISTS (
      SELECT 1 
      FROM company_users cu
      WHERE cu.user_id = auth.uid()
      AND cu.role = 'admin'
    )
    OR
    -- User has view all tasks permission and is in same company
    EXISTS (
      SELECT 1 
      FROM user_roles ur
      JOIN company_users cu1 ON cu1.user_id = ur.user_id
      JOIN company_users cu2 ON cu2.company_name = cu1.company_name
      WHERE ur.user_id = auth.uid()
      AND ur.can_view_all_tasks = true
      AND cu2.user_id = tasks.user_id
    )
  );

-- Add trigger to update updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_user_roles_updated_at
  BEFORE UPDATE ON user_roles
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Create function to set initial user role
CREATE OR REPLACE FUNCTION set_initial_user_role()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO user_roles (user_id, role, can_view_all_tasks)
  VALUES (
    NEW.user_id,
    CASE 
      WHEN NEW.role = 'admin' THEN 'admin'
      ELSE 'user'
    END,
    CASE 
      WHEN NEW.role = 'admin' THEN true
      ELSE false
    END
  )
  ON CONFLICT (user_id) DO NOTHING;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for new company users
CREATE TRIGGER set_user_role_trigger
  AFTER INSERT ON company_users
  FOR EACH ROW
  EXECUTE FUNCTION set_initial_user_role();

-- Add indexes for better performance
CREATE INDEX IF NOT EXISTS idx_tasks_collaborators 
  ON tasks USING gin(collaborators);

CREATE INDEX IF NOT EXISTS idx_user_roles_lookup 
  ON user_roles(user_id, role);