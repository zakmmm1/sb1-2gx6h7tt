/*
  # Add categories, subtasks, and work sessions

  1. New Tables
    - `categories`
      - `id` (uuid, primary key)
      - `name` (text)
      - `color` (text)
      - `user_id` (uuid, foreign key)
    - `subtasks`
      - `id` (uuid, primary key)
      - `title` (text)
      - `description` (text)
      - `status` (text)
      - `task_id` (uuid, foreign key)
    - `work_sessions`
      - `id` (uuid, primary key)
      - `task_id` (uuid, foreign key)
      - `subtask_id` (uuid, foreign key)
      - `start_time` (timestamptz)
      - `end_time` (timestamptz)
      - `user_id` (uuid, foreign key)

  2. Changes
    - Add `category_id` to existing tasks table
    
  3. Security
    - Enable RLS on all new tables
    - Add policies for authenticated users
*/

-- Categories table
CREATE TABLE IF NOT EXISTS categories (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  color text NOT NULL,
  user_id uuid REFERENCES auth.users NOT NULL,
  created_at timestamptz DEFAULT now()
);

ALTER TABLE categories ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage their categories"
  ON categories
  FOR ALL
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Add category to tasks
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'tasks' AND column_name = 'category_id'
  ) THEN
    ALTER TABLE tasks ADD COLUMN category_id uuid REFERENCES categories;
  END IF;
END $$;

-- Subtasks table
CREATE TABLE IF NOT EXISTS subtasks (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  title text NOT NULL,
  description text,
  status text NOT NULL CHECK (status IN ('new', 'in-progress', 'completed')),
  task_id uuid REFERENCES tasks NOT NULL,
  created_at timestamptz DEFAULT now(),
  completed_at timestamptz,
  user_id uuid REFERENCES auth.users NOT NULL
);

ALTER TABLE subtasks ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage their subtasks"
  ON subtasks
  FOR ALL
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Work sessions table
CREATE TABLE IF NOT EXISTS work_sessions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  task_id uuid REFERENCES tasks,
  subtask_id uuid REFERENCES subtasks,
  start_time timestamptz NOT NULL DEFAULT now(),
  end_time timestamptz,
  user_id uuid REFERENCES auth.users NOT NULL,
  created_at timestamptz DEFAULT now()
);

ALTER TABLE work_sessions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage their work sessions"
  ON work_sessions
  FOR ALL
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);