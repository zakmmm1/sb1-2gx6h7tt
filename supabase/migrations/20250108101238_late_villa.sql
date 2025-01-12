-- Drop existing problematic policies
DROP POLICY IF EXISTS "task_update_policy" ON tasks;

-- Create simplified task update policy
CREATE POLICY "task_update_policy"
  ON tasks
  FOR UPDATE
  TO authenticated
  USING (
    user_id = auth.uid()
    OR assignee_id = auth.uid()
    OR EXISTS (
      SELECT 1 
      FROM company_users cu1
      JOIN company_users cu2 ON cu1.company_id = cu2.company_id
      WHERE cu1.user_id = auth.uid()
      AND cu2.user_id = tasks.user_id
    )
  );

-- Add index for better performance
CREATE INDEX IF NOT EXISTS idx_tasks_order_lookup 
  ON tasks("order", user_id, assignee_id);