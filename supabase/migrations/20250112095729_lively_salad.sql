/*
  # Fix Company Structure and User Creation
  
  1. Changes
    - Ensure companies table exists with proper structure
    - Add proper constraints for company users
    - Fix user creation flow
  
  2. Security
    - Maintain RLS policies
    - Add proper validation
*/

-- Start transaction
BEGIN;

-- Step 1: Ensure companies table has proper structure
CREATE TABLE IF NOT EXISTS companies (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL UNIQUE,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Step 2: Ensure proper company_users structure
ALTER TABLE company_users
ALTER COLUMN company_name SET NOT NULL,
ALTER COLUMN email SET NOT NULL,
ALTER COLUMN role SET NOT NULL,
ALTER COLUMN role SET DEFAULT 'user',
ALTER COLUMN can_view_all_tasks SET NOT NULL,
ALTER COLUMN can_view_all_tasks SET DEFAULT false,
ALTER COLUMN status SET NOT NULL,
ALTER COLUMN status SET DEFAULT 'pending';

-- Step 3: Add proper constraints
ALTER TABLE company_users
DROP CONSTRAINT IF EXISTS valid_role,
ADD CONSTRAINT valid_role CHECK (role IN ('owner', 'admin', 'user')),
DROP CONSTRAINT IF EXISTS valid_status,
ADD CONSTRAINT valid_status CHECK (status IN ('pending', 'active'));

-- Step 4: Create function to handle user creation
CREATE OR REPLACE FUNCTION handle_new_company_user()
RETURNS TRIGGER AS $$
BEGIN
  -- If this is the first user in the company, make them owner
  IF NOT EXISTS (
    SELECT 1 FROM company_users 
    WHERE company_name = NEW.company_name 
    AND status = 'active'
  ) THEN
    NEW.role := 'owner';
    NEW.can_view_all_tasks := true;
  END IF;

  -- If user already exists, update their status
  IF EXISTS (
    SELECT 1 FROM auth.users 
    WHERE email = NEW.email
  ) THEN
    NEW.status := 'active';
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Step 5: Create trigger for new company users
DROP TRIGGER IF EXISTS handle_company_user_trigger ON company_users;
CREATE TRIGGER handle_company_user_trigger
  BEFORE INSERT ON company_users
  FOR EACH ROW
  EXECUTE FUNCTION handle_new_company_user();

-- Step 6: Update indexes
CREATE INDEX IF NOT EXISTS idx_company_users_lookup 
  ON company_users(email, company_name, role, status);

-- Step 7: Update policies
DROP POLICY IF EXISTS "allow_view_company_users" ON company_users;
DROP POLICY IF EXISTS "allow_invite_company_users" ON company_users;

CREATE POLICY "allow_view_company_users"
  ON company_users
  FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "allow_invite_company_users"
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

COMMIT;