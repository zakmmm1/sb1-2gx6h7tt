-- Start transaction
BEGIN;

-- Step 1: Create owner_accounts table if it doesn't exist
CREATE TABLE IF NOT EXISTS owner_accounts (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_id uuid NOT NULL REFERENCES auth.users(id),
  name text NOT NULL,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  UNIQUE(owner_id)
);

-- Step 2: Add owner_account_id to company_users if it doesn't exist
ALTER TABLE company_users
ADD COLUMN IF NOT EXISTS owner_account_id uuid REFERENCES owner_accounts(id);

-- Step 3: Create owner accounts for existing owners
WITH distinct_owners AS (
  SELECT DISTINCT ON (user_id)
    user_id,
    email || '''s Account' as name,
    created_at
  FROM company_users
  WHERE user_id IS NOT NULL
    AND status = 'active'
    AND role IN ('owner', 'admin')
  ORDER BY user_id, created_at ASC
)
INSERT INTO owner_accounts (owner_id, name)
SELECT user_id, name
FROM distinct_owners
ON CONFLICT (owner_id) DO NOTHING;

-- Step 4: Link existing users to their owner accounts
UPDATE company_users cu
SET owner_account_id = oa.id
FROM owner_accounts oa
WHERE (cu.user_id = oa.owner_id OR cu.invited_by = oa.owner_id)
AND cu.owner_account_id IS NULL;

-- Step 5: Create simplified policies
DROP POLICY IF EXISTS "company_users_select" ON company_users;
DROP POLICY IF EXISTS "company_users_insert" ON company_users;

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
      AND cu.owner_account_id = company_users.owner_account_id
      AND cu.role IN ('owner', 'admin')
      AND cu.status = 'active'
    )
  );

-- Step 6: Add indexes for better performance
CREATE INDEX IF NOT EXISTS idx_company_users_owner_lookup 
  ON company_users(owner_account_id, role, status);

CREATE INDEX IF NOT EXISTS idx_owner_accounts_owner 
  ON owner_accounts(owner_id);

COMMIT;