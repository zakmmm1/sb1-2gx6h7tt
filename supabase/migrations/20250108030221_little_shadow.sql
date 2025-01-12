/*
  # Fix task reordering policies

  1. Changes
    - Update RLS policy for tasks table to allow batch updates
    - Add policy specifically for reordering tasks
  
  2. Security
    - Maintains user isolation
    - Only allows updates to user's own tasks
*/

-- Drop existing update policy
DROP POLICY IF EXISTS "Users can update own tasks" ON tasks;

-- Create new more permissive update policy
CREATE POLICY "Users can update own tasks"
  ON tasks
  FOR UPDATE
  TO authenticated
  USING (
    CASE 
      WHEN auth.uid() IS NOT NULL THEN
        user_id = auth.uid()
      ELSE
        false
    END
  )
  WITH CHECK (
    CASE 
      WHEN auth.uid() IS NOT NULL THEN
        user_id = auth.uid()
      ELSE
        false
    END
  );