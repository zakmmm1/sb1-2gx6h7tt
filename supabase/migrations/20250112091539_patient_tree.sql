/*
  # Fix admin permissions and first user handling
  
  1. Changes
    - Ensures first user in a company is automatically an admin
    - Adds trigger to handle admin role assignment
    - Updates existing users to be admins
*/

-- First make all existing users admins
UPDATE company_users
SET 
  role = 'admin',
  can_view_all_tasks = true
WHERE 
  role != 'owner';  -- Preserve owner role where it exists

-- Create function to handle first user in company
CREATE OR REPLACE FUNCTION handle_company_user_creation()
RETURNS TRIGGER AS $$
BEGIN
  -- Check if this is the first user in the company
  IF NOT EXISTS (
    SELECT 1 FROM company_users 
    WHERE company_name = NEW.company_name 
    AND status = 'active'
  ) THEN
    -- Make first user an admin
    NEW.role = 'admin';
    NEW.can_view_all_tasks = true;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger to run before inserting new company users
DROP TRIGGER IF EXISTS ensure_first_user_admin ON company_users;
CREATE TRIGGER ensure_first_user_admin
  BEFORE INSERT ON company_users
  FOR EACH ROW
  EXECUTE FUNCTION handle_company_user_creation();

-- Add index for better performance
CREATE INDEX IF NOT EXISTS idx_company_users_status_lookup 
  ON company_users(company_name, status);