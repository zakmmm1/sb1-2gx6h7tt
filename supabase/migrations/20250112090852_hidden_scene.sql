-- Drop existing problematic policies first
DROP POLICY IF EXISTS "company_users_view" ON company_users;
DROP POLICY IF EXISTS "company_users_manage" ON company_users;

-- Ensure company_users has the correct structure
ALTER TABLE company_users 
DROP COLUMN IF EXISTS invited_by CASCADE;

ALTER TABLE company_users 
ADD COLUMN IF NOT EXISTS email text NOT NULL,
ADD COLUMN IF NOT EXISTS full_name text,
ADD COLUMN IF NOT EXISTS role text NOT NULL DEFAULT 'user',
ADD COLUMN IF NOT EXISTS can_view_all_tasks boolean NOT NULL DEFAULT false;

-- Add role validation
ALTER TABLE company_users
DROP CONSTRAINT IF EXISTS valid_role;

ALTER TABLE company_users
ADD CONSTRAINT valid_role CHECK (role IN ('owner', 'admin', 'user'));

-- Create new simplified policies
CREATE POLICY "company_users_select"
  ON company_users
  FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "company_users_insert"
  ON company_users
  FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 
      FROM company_users cu
      WHERE cu.user_id = auth.uid()
      AND cu.role IN ('owner', 'admin')
    )
  );

-- Add index for better performance
CREATE INDEX IF NOT EXISTS idx_company_users_lookup 
  ON company_users(user_id, company_name, role);