/*
  # Fix task reordering policy

  1. Changes
    - Drop existing problematic policies
    - Create new simplified policy for task updates
    - Add index for better performance
    
  2. Security
    - Allows users to update their own tasks
    - Allows assigned users to update tasks
    - Allows company members to update tasks
*/

-- Drop existing problematic policies
DROP POLICY IF EXISTS "task_update_policy" ON tasks;

-- Create new simplified policy for task updates
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
      FROM company_users cu1
      JOIN company_users cu2 ON cu1.company_id = cu2.company_id
      WHERE cu1.user_id = auth.uid()
      AND cu2.user_id = tasks.user_id
    )
  );

-- Add index for better performance
CREATE INDEX IF NOT EXISTS idx_tasks_update_lookup 
  ON tasks(user_id, assignee_id);