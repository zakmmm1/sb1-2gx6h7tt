/*
  # Fix Reordering Policies

  Updates RLS policies to properly handle task and category reordering.

  1. Changes
    - Simplify task and category update policies
    - Add proper company context checks
    - Ensure proper indexing for performance
*/

-- Drop existing problematic policies
DROP POLICY IF EXISTS "task_update_policy" ON tasks;
DROP POLICY IF EXISTS "category_update_policy" ON categories;

-- Create simplified task update policy
CREATE POLICY "task_update_policy"
  ON tasks
  FOR UPDATE
  TO authenticated
  USING (
    user_id = auth.uid()
    OR
    EXISTS (
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

-- Create simplified category update policy
CREATE POLICY "category_update_policy"
  ON categories
  FOR UPDATE
  TO authenticated
  USING (
    user_id = auth.uid()
    OR
    EXISTS (
      SELECT 1 
      FROM company_users cu
      WHERE cu.user_id = auth.uid()
      AND cu.company_id IN (
        SELECT company_id 
        FROM company_users 
        WHERE user_id = categories.user_id
      )
    )
  );

-- Add indexes for better performance
CREATE INDEX IF NOT EXISTS idx_tasks_reorder 
  ON tasks("order", user_id);

CREATE INDEX IF NOT EXISTS idx_categories_reorder 
  ON categories("order", user_id);

CREATE INDEX IF NOT EXISTS idx_company_users_lookup 
  ON company_users(user_id, company_id);