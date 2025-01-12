/*
  # Fix task reordering policy

  1. Changes
    - Add simplified policy for task reordering
    - Add policy for general task updates
    - Add index for better performance
    
  2. Security
    - Allows users to reorder tasks within their company
    - Maintains data integrity while allowing necessary operations
*/

-- Drop existing problematic policies
DROP POLICY IF EXISTS "allow_task_updates" ON tasks;

-- Create policy for task updates (including reordering)
CREATE POLICY "allow_task_updates"
  ON tasks
  FOR UPDATE
  TO authenticated
  USING (
    user_id = auth.uid()
    OR assignee_id = auth.uid()
    OR EXISTS (
      SELECT 1 FROM company_users cu
      WHERE cu.user_id = auth.uid()
      AND cu.company_id IN (
        SELECT company_id FROM company_users
        WHERE user_id = tasks.user_id
      )
    )
  );

-- Add index for better performance
CREATE INDEX IF NOT EXISTS idx_tasks_order 
  ON tasks("order");