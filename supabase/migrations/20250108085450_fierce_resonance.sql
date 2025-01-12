-- Add order column to tasks table
ALTER TABLE tasks ADD COLUMN IF NOT EXISTS "order" integer DEFAULT 0;

-- Update existing tasks to have sequential order
WITH numbered_tasks AS (
  SELECT id, ROW_NUMBER() OVER (ORDER BY created_at) as row_num
  FROM tasks
)
UPDATE tasks
SET "order" = numbered_tasks.row_num
FROM numbered_tasks
WHERE tasks.id = numbered_tasks.id;