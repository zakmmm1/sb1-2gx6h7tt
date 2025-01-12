/*
  # Make all existing users admins

  1. Changes
    - Updates all existing users to be admins with full permissions
    - Preserves owner role where it exists
    - Ensures all users have can_view_all_tasks enabled
*/

-- First make all existing users admins
UPDATE company_users
SET 
  role = CASE 
    WHEN role = 'owner' THEN 'owner'  -- Preserve owner role
    ELSE 'admin'                      -- Make everyone else admin
  END,
  can_view_all_tasks = true;

-- Ensure all users are marked as active
UPDATE company_users
SET status = 'active'
WHERE user_id IS NOT NULL;

-- Create index for better performance
CREATE INDEX IF NOT EXISTS idx_company_users_role_status 
  ON company_users(role, status);