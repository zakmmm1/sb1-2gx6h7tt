/*
  # Make assignee column optional in tasks table

  1. Changes
    - Make assignee column nullable in tasks table
    - Add default value for assignee based on assignee_id
  
  2. Notes
    - This allows tasks to be created without an explicit assignee value
    - The assignee_id field will be the source of truth for task assignment
*/

-- Make assignee column nullable
ALTER TABLE tasks ALTER COLUMN assignee DROP NOT NULL;

-- Add trigger to automatically set assignee based on assignee_id
CREATE OR REPLACE FUNCTION set_task_assignee()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.assignee_id IS NOT NULL THEN
    SELECT email INTO NEW.assignee
    FROM company_users
    WHERE user_id = NEW.assignee_id
    LIMIT 1;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER set_task_assignee_trigger
  BEFORE INSERT OR UPDATE ON tasks
  FOR EACH ROW
  EXECUTE FUNCTION set_task_assignee();