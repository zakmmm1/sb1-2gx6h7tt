-- Add company_name to user_settings
ALTER TABLE user_settings ADD COLUMN IF NOT EXISTS company_name text;

-- Add assignee_id to tasks
ALTER TABLE tasks ADD COLUMN IF NOT EXISTS assignee_id uuid REFERENCES auth.users;

-- Update tasks policies to allow assigned users to view tasks
CREATE POLICY "Assigned users can view tasks"
  ON tasks
  FOR SELECT
  TO authenticated
  USING (
    assignee_id = auth.uid() OR
    user_id = auth.uid() OR
    user_id IN (
      SELECT user_id FROM company_users 
      WHERE company_id = (
        SELECT company_id FROM user_settings 
        WHERE user_id = auth.uid()
      )
    )
  );