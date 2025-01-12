-- Drop existing problematic policies
DROP POLICY IF EXISTS "task_update_policy" ON tasks;

-- Create comprehensive task policy that includes deletion
CREATE POLICY "task_crud_policy"
  ON tasks
  FOR ALL
  TO authenticated
  USING (
    user_id = auth.uid()
    OR assignee_id = auth.uid()
    OR EXISTS (
      SELECT 1 
      FROM company_users cu
      WHERE cu.user_id = auth.uid()
      AND cu.company_id IN (
        SELECT company_id 
        FROM company_users 
        WHERE user_id = tasks.user_id
      )
    )
  );

-- Add index for better performance
CREATE INDEX IF NOT EXISTS idx_tasks_user_lookup 
  ON tasks(user_id, assignee_id);