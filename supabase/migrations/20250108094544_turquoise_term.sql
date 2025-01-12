/*
  # Add task reordering policy

  1. Changes
    - Add policy to allow updating task order
    - Add index for better performance

  2. Security
    - Only authenticated users can reorder tasks
    - Users can only reorder tasks they have access to
*/

-- Add policy for reordering tasks
CREATE POLICY "users_reorder_tasks"
  ON tasks
  FOR UPDATE
  TO authenticated
  USING (
    user_id = auth.uid()
    OR
    EXISTS (
      SELECT 1 FROM company_users cu
      WHERE cu.user_id = auth.uid()
      AND cu.company_id IN (
        SELECT company_id FROM company_users
        WHERE user_id = tasks.user_id
      )
    )
  )
  WITH CHECK (true);

-- Add index for better performance
CREATE INDEX IF NOT EXISTS idx_tasks_order 
  ON tasks("order");