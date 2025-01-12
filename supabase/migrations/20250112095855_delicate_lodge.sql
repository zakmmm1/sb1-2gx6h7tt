/*
  # Fix Company and User Structure
  
  1. Changes
    - Simplify company user management
    - Fix user creation flow
    - Clean up constraints
  
  2. Security
    - Maintain RLS policies
    - Add proper validation
*/

-- Start transaction
BEGIN;

-- Step 1: Ensure company_users has correct structure
ALTER TABLE company_users
ALTER COLUMN company_name SET NOT NULL,
ALTER COLUMN email SET NOT NULL,
ALTER COLUMN role SET NOT NULL,
ALTER COLUMN role SET DEFAULT 'user',
ALTER COLUMN can_view_all_tasks SET NOT NULL,
ALTER COLUMN can_view_all_tasks SET DEFAULT false,
ALTER COLUMN status SET NOT NULL,
ALTER COLUMN status SET DEFAULT 'pending';

-- Step 2: Add proper constraints
ALTER TABLE company_users
DROP CONSTRAINT IF EXISTS valid_role,
ADD CONSTRAINT valid_role CHECK (role IN ('owner', 'admin', 'user')),
DROP CONSTRAINT IF EXISTS valid_status,
ADD CONSTRAINT valid_status CHECK (status IN ('pending', 'active'));

-- Step 3: Create simplified policies
DROP POLICY IF EXISTS "allow_view_company_users" ON company_users;
DROP POLICY IF EXISTS "allow_invite_company_users" ON company_users;

CREATE POLICY "anyone_can_view_company_users"
  ON company_users
  FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "admins_can_invite_users"
  ON company_users
  FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 
      FROM company_users cu
      WHERE cu.user_id = auth.uid()
      AND cu.company_name = company_users.company_name
      AND cu.role IN ('owner', 'admin')
      AND cu.status = 'active'
    )
  );

-- Step 4: Add index for better performance
CREATE INDEX IF NOT EXISTS idx_company_users_lookup 
  ON company_users(email, company_name, role, status);

-- Step 5: Update existing users
UPDATE company_users
SET 
  status = 'active',
  role = CASE 
    WHEN user_id IS NOT NULL AND NOT EXISTS (
      SELECT 1 FROM company_users cu2 
      WHERE cu2.company_name = company_users.company_name 
      AND cu2.created_at < company_users.created_at
    ) THEN 'owner'
    ELSE role
  END,
  can_view_all_tasks = CASE 
    WHEN role IN ('owner', 'admin') THEN true
    ELSE can_view_all_tasks
  END
WHERE user_id IS NOT NULL;

COMMIT;