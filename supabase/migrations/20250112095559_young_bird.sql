/*
  # Fix Company Ownership Structure

  1. Changes
    - Identify and set original owners
    - Update roles for non-owner admins
    - Set proper permissions for regular users
  
  2. Security
    - Maintain existing RLS policies
    - Ensure proper role hierarchy
*/

-- Start transaction
BEGIN;

-- Step 1: Identify original owners (first user per company)
WITH company_owners AS (
  SELECT DISTINCT ON (company_name)
    user_id,
    company_name,
    created_at
  FROM company_users
  WHERE status = 'active'
  ORDER BY company_name, created_at ASC
)
UPDATE company_users cu
SET 
  role = CASE 
    WHEN co.user_id IS NOT NULL THEN 'owner'  -- Original user becomes owner
    WHEN cu.role = 'admin' THEN 'admin'       -- Keep other admins as admins
    ELSE 'user'                               -- Everyone else is a regular user
  END,
  can_view_all_tasks = CASE
    WHEN co.user_id IS NOT NULL THEN true     -- Owners see everything
    WHEN cu.role = 'admin' THEN true          -- Admins see everything
    ELSE false                                -- Regular users have limited view
  END
FROM company_owners co
WHERE cu.user_id = co.user_id
  AND cu.company_name = co.company_name;

-- Step 2: Ensure all owners have admin privileges
UPDATE company_users
SET can_view_all_tasks = true
WHERE role = 'owner';

-- Step 3: Set proper status for all active users
UPDATE company_users
SET status = 'active'
WHERE user_id IS NOT NULL;

-- Step 4: Add index for better performance
CREATE INDEX IF NOT EXISTS idx_company_users_role_status 
  ON company_users(role, status, company_name);

-- Verify the changes
SELECT 
  company_name,
  role,
  count(*) as user_count,
  bool_and(can_view_all_tasks) as all_can_view_all
FROM company_users
WHERE status = 'active'
GROUP BY company_name, role
ORDER BY company_name, role;

COMMIT;