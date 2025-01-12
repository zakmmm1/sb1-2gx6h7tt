/*
  # Fix Reordering Policies

  1. Changes
    - Simplify RLS policies for tasks and categories
    - Allow users to update order within their company context
    - Add necessary indexes for performance

  2. Security
    - Maintain data isolation between companies
    - Ensure users can only modify their own data or company data
*/

-- Drop existing problematic policies
DROP POLICY IF EXISTS "task_update_policy" ON tasks;
DROP POLICY IF EXISTS "category_update_policy" ON categories;

-- Create new task update policy
CREATE POLICY "task_update_policy"
  ON tasks
  FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 
      FROM user_settings us
      WHERE us.user_id = auth.uid()
      AND us.company_id = (
        SELECT company_id 
        FROM user_settings 
        WHERE user_id = tasks.user_id
      )
    )
  );

-- Create new category update policy
CREATE POLICY "category_update_policy"
  ON categories
  FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 
      FROM user_settings us
      WHERE us.user_id = auth.uid()
      AND us.company_id = (
        SELECT company_id 
        FROM user_settings 
        WHERE user_id = categories.user_id
      )
    )
  );

-- Add indexes for better performance
CREATE INDEX IF NOT EXISTS idx_tasks_order_lookup 
  ON tasks("order", user_id);

CREATE INDEX IF NOT EXISTS idx_categories_order_lookup 
  ON categories("order", user_id);

CREATE INDEX IF NOT EXISTS idx_user_settings_company_lookup 
  ON user_settings(user_id, company_id);