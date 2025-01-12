/*
  # Add scheduled tasks support

  1. New Fields
    - `scheduled_for` (timestamptz) - When the task is scheduled to start
    - `status` (text) - Task status (scheduled, active, completed)

  2. Changes
    - Add scheduled_for column to tasks table
    - Add status column with check constraint
    - Add index for better performance
*/

-- Add scheduled_for column
ALTER TABLE tasks 
ADD COLUMN IF NOT EXISTS scheduled_for timestamptz,
ADD COLUMN IF NOT EXISTS status text NOT NULL DEFAULT 'active' 
  CHECK (status IN ('scheduled', 'active', 'completed'));

-- Add index for better query performance
CREATE INDEX IF NOT EXISTS idx_tasks_scheduled_for 
  ON tasks(scheduled_for, status);

-- Update completed tasks status
UPDATE tasks 
SET status = 'completed' 
WHERE completed_at IS NOT NULL;