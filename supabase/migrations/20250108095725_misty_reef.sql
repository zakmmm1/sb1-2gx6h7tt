/*
  # Fix task reordering policy

  1. Changes
    - Drop existing problematic policies
    - Create new simplified policy for task updates
    - Add index for better performance
    
  2. Security
    - Allows users to update their own tasks
    - Allows assigned users to update tasks
    - Allows company members to update tasks within their company
*/

-- Drop existing problematic policies
DROP POLICY IF EXISTS "task_update_policy" ON tasks;

-- Create new simplified policy for task updates
CREATE POLICY "task_update_policy"
  ON tasks
  FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 
      FROM user_settings us
      WHERE us.user_id = auth.uid()
      AND (
        -- User owns the task
        tasks.user_id = auth.uid()
        OR
        -- User is assigned to the task
        tasks.assignee_id = auth.uid()
        OR
        -- User is in the same company as the task owner
        us.company_id = (
          SELECT us2.company_id 
          FROM user_settings us2 
          WHERE us2.user_id = tasks.user_id
        )
      )
    )
  );

-- Add index for better performance
CREATE INDEX IF NOT EXISTS idx_tasks_update_lookup 
  ON tasks(user_id, assignee_id);