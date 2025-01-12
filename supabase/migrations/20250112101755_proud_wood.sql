-- Start transaction
BEGIN;

-- Step 1: Drop existing policies
DROP POLICY IF EXISTS "allow_view_users" ON company_users;
DROP POLICY IF EXISTS "allow_invite_users" ON company_users;
DROP POLICY IF EXISTS "anyone_can_view_company_users" ON company_users;
DROP POLICY IF EXISTS "admins_can_invite_users" ON company_users;

-- Step 2: Create owner_accounts table
CREATE TABLE IF NOT EXISTS owner_accounts (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_id uuid NOT NULL REFERENCES auth.users(id),
  name text NOT NULL,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Step 3: Add owner_account_id to company_users
ALTER TABLE company_users
ADD COLUMN IF NOT EXISTS owner_account_id uuid REFERENCES owner_accounts(id);

-- Step 4: Create initial owner accounts from existing owners
WITH first_owners AS (
  SELECT DISTINCT ON (user_id)
    user_id,
    email,
    created_at
  FROM company_users
  WHERE role = 'owner'
  OR (
    role = 'admin' 
    AND status = 'active'
  )
  ORDER BY user_id, created_at ASC
)
INSERT INTO owner_accounts (owner_id, name)
SELECT 
  user_id,
  email || '''s Account' -- Use email as base for account name
FROM first_owners
WHERE user_id IS NOT NULL;

-- Step 5: Link existing users to their owner accounts
UPDATE company_users cu
SET owner_account_id = oa.id
FROM owner_accounts oa
WHERE cu.user_id = oa.owner_id
OR cu.invited_by = oa.owner_id;

-- Step 6: Create new policies for owner-based access
CREATE POLICY "company_users_view"
  ON company_users
  FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "company_users_invite"
  ON company_users
  FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 
      FROM company_users cu
      WHERE cu.user_id = auth.uid()
      AND cu.owner_account_id = company_users.owner_account_id
      AND cu.role IN ('owner', 'admin')
      AND cu.status = 'active'
    )
  );

-- Step 7: Add indexes for better performance
CREATE INDEX IF NOT EXISTS idx_company_users_owner_account 
  ON company_users(owner_account_id, role, status);

CREATE INDEX IF NOT EXISTS idx_owner_accounts_owner 
  ON owner_accounts(owner_id);

COMMIT;