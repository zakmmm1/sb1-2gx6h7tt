/*
  # Fix Reordering with Simplified RLS

  Simplifies the RLS policies and adds proper order columns
*/

-- Drop existing problematic policies
DROP POLICY IF EXISTS "task_update_policy" ON tasks;
DROP POLICY IF EXISTS "category_update_policy" ON categories;

-- Add order columns if they don't exist
ALTER TABLE tasks ADD COLUMN IF NOT EXISTS "order" integer DEFAULT 0;
ALTER TABLE categories ADD COLUMN IF NOT EXISTS "order" integer DEFAULT 0;

-- Simple task update policy
CREATE POLICY "task_update_policy"
  ON tasks
  FOR UPDATE
  TO authenticated
  USING (user_id = auth.uid());

-- Simple category update policy
CREATE POLICY "category_update_policy"
  ON categories
  FOR UPDATE
  TO authenticated
  USING (user_id = auth.uid());

-- Add indexes for performance
CREATE INDEX IF NOT EXISTS idx_tasks_order ON tasks("order", user_id);
CREATE INDEX IF NOT EXISTS idx_categories_order ON categories("order", user_id);