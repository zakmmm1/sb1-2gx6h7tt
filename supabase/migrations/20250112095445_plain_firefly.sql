/*
  # Company ID Refactor

  1. Changes
    - Add id column to companies table
    - Add unique constraint on company name
    - Update company_users to reference company_id
    - Migrate existing data to use company IDs
    - Update constraints and indexes
  
  2. Security
    - Maintain existing RLS policies
    - Update policies to use company_id
*/

-- Start transaction
BEGIN;

-- Step 1: Add id to companies if it doesn't exist
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'companies' AND column_name = 'id'
  ) THEN
    ALTER TABLE companies ADD COLUMN id uuid DEFAULT gen_random_uuid() PRIMARY KEY;
  END IF;
END $$;

-- Step 2: Add unique constraint on company name
ALTER TABLE companies 
ADD CONSTRAINT companies_name_key UNIQUE (name);

-- Step 3: Add company_id to company_users
ALTER TABLE company_users 
ADD COLUMN IF NOT EXISTS company_id uuid REFERENCES companies(id);

-- Step 4: Create companies for existing company names
WITH new_companies AS (
  SELECT DISTINCT 
    company_name as name,
    first_value(user_id) OVER (
      PARTITION BY company_name 
      ORDER BY created_at
    ) as owner_id
  FROM company_users
  WHERE company_id IS NULL
)
INSERT INTO companies (id, name, owner_id)
SELECT 
  gen_random_uuid(),
  name,
  owner_id
FROM new_companies
ON CONFLICT (name) DO NOTHING;

-- Step 5: Update company_users with company_id
UPDATE company_users cu
SET company_id = c.id
FROM companies c
WHERE cu.company_name = c.name
AND cu.company_id IS NULL;

-- Step 6: Make company_id NOT NULL after migration
ALTER TABLE company_users 
ALTER COLUMN company_id SET NOT NULL;

-- Step 7: Update indexes
DROP INDEX IF EXISTS idx_company_users_company_name;
CREATE INDEX IF NOT EXISTS idx_company_users_company_id 
  ON company_users(company_id);

-- Step 8: Update RLS policies to use company_id
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
      AND cu.company_id = company_users.company_id
      AND cu.role IN ('owner', 'admin')
      AND cu.status = 'active'
    )
  );

-- Step 9: Add foreign key constraint
ALTER TABLE company_users
DROP CONSTRAINT IF EXISTS company_users_company_id_fkey,
ADD CONSTRAINT company_users_company_id_fkey 
  FOREIGN KEY (company_id) 
  REFERENCES companies(id) 
  ON DELETE CASCADE;

-- Verify the migration
SELECT 
  cu.user_id,
  cu.email,
  cu.role,
  c.id as company_id,
  c.name as company_name,
  c.owner_id
FROM company_users cu
JOIN companies c ON cu.company_id = c.id
ORDER BY c.name, cu.email;

COMMIT;