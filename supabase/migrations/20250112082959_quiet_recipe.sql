/*
  # Add user roles and permissions

  1. New Tables
    - `user_permissions`
      - `user_id` (uuid, primary key)
      - `role` (text, either 'admin' or 'user')
      - `can_view_all_tasks` (boolean)
      - `created_at` (timestamptz)
      - `updated_at` (timestamptz)

  2. Changes
    - Add `included_users` array to tasks table
    - Add policies for task visibility based on user roles

  3. Security
    - Enable RLS
    - Add policies for permission management
*/

-- Create user_permissions table
CREATE TABLE IF NOT EXISTS user_permissions (
  user_id uuid PRIMARY KEY REFERENCES auth.users,
  role text NOT NULL CHECK (role IN ('admin', 'user')),
  can_view_all_tasks boolean NOT NULL DEFAULT true,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Add included_users array to tasks
ALTER TABLE tasks 
ADD COLUMN IF NOT EXISTS included_users uuid[] DEFAULT ARRAY[]::uuid[];

-- Enable RLS on user_permissions
ALTER TABLE user_permissions ENABLE ROW LEVEL SECURITY;

-- Create policies for user_permissions
CREATE POLICY "Users can view their own permissions"
  ON user_permissions
  FOR SELECT
  TO authenticated
  USING (user_id = auth.uid());

CREATE POLICY "Admins can manage user permissions"
  ON user_permissions
  FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 
      FROM user_permissions up
      WHERE up.user_id = auth.uid()
      AND up.role = 'admin'
    )
  );

-- Update task policies to include user roles and permissions
CREATE POLICY "Users can view tasks based on permissions"
  ON tasks
  FOR SELECT
  TO authenticated
  USING (
    -- User is admin
    EXISTS (
      SELECT 1 
      FROM user_permissions up
      WHERE up.user_id = auth.uid()
      AND up.role = 'admin'
    )
    OR
    -- User has view all tasks permission
    EXISTS (
      SELECT 1 
      FROM user_permissions up
      WHERE up.user_id = auth.uid()
      AND up.can_view_all_tasks = true
    )
    OR
    -- User is included in the task
    auth.uid() = ANY(included_users)
    OR
    -- User is assigned to the task
    auth.uid() = assignee_id
  );

-- Add trigger to update updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_user_permissions_updated_at
  BEFORE UPDATE ON user_permissions
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Create index for better performance
CREATE INDEX IF NOT EXISTS idx_tasks_included_users 
  ON tasks USING gin(included_users);

CREATE INDEX IF NOT EXISTS idx_user_permissions_role 
  ON user_permissions(user_id, role);