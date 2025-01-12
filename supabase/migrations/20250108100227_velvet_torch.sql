/*
  # Fix drag and drop policies

  1. Changes
    - Simplify task update policy
    - Add category update policy
    - Add indexes for better performance
*/

-- Drop existing problematic policies
DROP POLICY IF EXISTS "task_update_policy" ON tasks;
DROP POLICY IF EXISTS "category_update_policy" ON categories;

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

-- Create category update policy
CREATE POLICY "category_update_policy"
  ON categories
  FOR UPDATE
  TO authenticated
  USING (true)
  WITH CHECK (user_id = auth.uid());

-- Add indexes for better performance
CREATE INDEX IF NOT EXISTS idx_tasks_user_assignee ON tasks(user_id, assignee_id);
CREATE INDEX IF NOT EXISTS idx_categories_user ON categories(user_id);