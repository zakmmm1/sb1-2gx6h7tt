/*
  # Fix task update policies
  
  1. Changes
    - Simplify task update policy to allow reordering
    - Add proper indexes for performance
*/

-- Drop existing problematic policies
DROP POLICY IF EXISTS "task_update_policy" ON tasks;

-- Create simplified task update policy
CREATE POLICY "task_update_policy"
  ON tasks
  FOR UPDATE
  TO authenticated
  USING (true)
  WITH CHECK (
    user_id = auth.uid()
    OR assignee_id = auth.uid()
  );

-- Add index for better performance
CREATE INDEX IF NOT EXISTS idx_tasks_order_lookup 
  ON tasks("order", user_id, assignee_id);