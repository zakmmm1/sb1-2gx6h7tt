/*
  # Add comments table and notes to tasks

  1. New Tables
    - `comments`
      - `id` (uuid, primary key)
      - `task_id` (uuid, references tasks)
      - `user_id` (uuid, references auth.users)
      - `content` (text)
      - `created_at` (timestamptz)

  2. Changes
    - Add `notes` column to tasks table
*/

-- Add notes column to tasks
ALTER TABLE tasks ADD COLUMN IF NOT EXISTS notes text;

-- Create comments table
CREATE TABLE IF NOT EXISTS comments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  task_id uuid REFERENCES tasks NOT NULL,
  user_id uuid REFERENCES auth.users NOT NULL,
  content text NOT NULL,
  created_at timestamptz DEFAULT now()
);

ALTER TABLE comments ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage their task comments"
  ON comments
  FOR ALL
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);