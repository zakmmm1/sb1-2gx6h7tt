/*
  # Fix task reordering policy

  1. Changes
    - Drop existing problematic policy
    - Create new simplified policy for task updates
    - Add index for better performance
    
  2. Security
    - Allows users to update tasks they own or are assigned to
    - Allows company members to update tasks within their company
*/

-- Drop existing problematic policy
DROP POLICY IF EXISTS "allow_task_updates" ON tasks;

-- Create simplified policy for task updates
CREATE POLICY "allow_task_updates"
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
    -- User is in the same company as the task owner
    EXISTS (
      SELECT 1 
      FROM user_settings us1
      JOIN user_settings us2 ON us1.company_id = us2.company_id
      WHERE us1.user_id = auth.uid()
      AND us2.user_id = tasks.user_id
    )
  );

-- Add index for better performance
CREATE INDEX IF NOT EXISTS idx_task_updates_lookup 
  ON tasks(user_id, assignee_id);