/*
  # Remove priority and status columns
  
  1. Changes
    - Remove priority column from tasks table
    - Remove status column from tasks table (completion status determined by completed_at)
*/

DO $$ 
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'tasks' AND column_name = 'priority'
  ) THEN
    ALTER TABLE tasks DROP COLUMN priority;
  END IF;

  IF EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'tasks' AND column_name = 'status'
  ) THEN
    ALTER TABLE tasks DROP COLUMN status;
  END IF;
END $$;