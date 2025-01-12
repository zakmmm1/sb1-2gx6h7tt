/*
  # Make all existing users admins

  1. Changes
    - Updates all existing company_users to have admin role
    - Sets can_view_all_tasks to true for all users
    - Ensures proper permissions for initial user base
*/

-- Update all existing users to be admins with full permissions
UPDATE company_users
SET 
  role = 'admin',
  can_view_all_tasks = true
WHERE 
  role != 'owner';  -- Preserve owner role where it exists

-- Ensure proper indexes exist
CREATE INDEX IF NOT EXISTS idx_company_users_role_lookup 
  ON company_users(role, company_name);