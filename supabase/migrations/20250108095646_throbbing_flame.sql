/*
  # Fix task reordering policy

  1. Changes
    - Drop existing problematic policies
    - Create new policy for task updates including reordering
    - Add index for better performance
    
  2. Security
    - Allows users to update tasks they own
    - Allows assigned users to update tasks
    - Allows company members to update tasks
*/

-- Drop existing problematic policies
DROP POLICY IF EXISTS "allow_task_updates" ON tasks;

-- Create new policy for task updates
CREATE POLICY "task_update_policy"
  ON tasks
  FOR UPDATE
  TO authenticated
  USING (
    -- User owns the task
    user_id = auth.uid()
    OR
    -- User is assigned to the task
    assignee_id = auth.uid()
    OR
    -- User is in the same company
    EXISTS (
      SELECT 1 
      FROM user_settings us1
      WHERE us1.user_id = auth.uid()
      AND us1.company_id = (
        SELECT us2.company_id 
        FROM user_settings us2 
        WHERE us2.user_id = tasks.user_id
      )
    )
  );

-- Add index for better performance
CREATE INDEX IF NOT EXISTS idx_tasks_company_lookup 
  ON tasks(user_id, assignee_id);