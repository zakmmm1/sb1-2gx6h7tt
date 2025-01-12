-- Start transaction
BEGIN;

-- Step 1: Ensure owner_accounts table exists
CREATE TABLE IF NOT EXISTS owner_accounts (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_id uuid NOT NULL UNIQUE REFERENCES auth.users(id),
  name text NOT NULL,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Step 2: Create owner account for each active admin/owner
WITH new_owners AS (
  SELECT DISTINCT ON (user_id)
    user_id,
    email || '''s Account' as name
  FROM company_users
  WHERE user_id IS NOT NULL
    AND status = 'active'
    AND role IN ('owner', 'admin')
)
INSERT INTO owner_accounts (owner_id, name)
SELECT user_id, name
FROM new_owners
WHERE NOT EXISTS (
  SELECT 1 FROM owner_accounts WHERE owner_id = new_owners.user_id
);

-- Step 3: Link users to owner accounts
UPDATE company_users cu
SET owner_account_id = (
  SELECT oa.id
  FROM owner_accounts oa
  WHERE oa.owner_id = cu.user_id
  OR oa.owner_id = cu.invited_by
  LIMIT 1
)
WHERE owner_account_id IS NULL;

-- Step 4: Ensure all active users have an owner account
WITH new_owners AS (
  SELECT DISTINCT ON (user_id)
    user_id,
    email || '''s Account' as name
  FROM company_users
  WHERE user_id IS NOT NULL
    AND status = 'active'
    AND owner_account_id IS NULL
)
INSERT INTO owner_accounts (owner_id, name)
SELECT user_id, name
FROM new_owners
WHERE NOT EXISTS (
  SELECT 1 FROM owner_accounts WHERE owner_id = new_owners.user_id
);

-- Step 5: Update remaining users to link to their inviter's owner account
UPDATE company_users cu
SET owner_account_id = (
  SELECT oa.id
  FROM owner_accounts oa
  WHERE oa.owner_id = COALESCE(cu.invited_by, cu.user_id)
  LIMIT 1
)
WHERE owner_account_id IS NULL;

-- Step 6: Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_company_users_owner_account 
  ON company_users(owner_account_id, role, status);

CREATE INDEX IF NOT EXISTS idx_owner_accounts_owner 
  ON owner_accounts(owner_id);

-- Step 7: Update policies
DROP POLICY IF EXISTS "company_users_view" ON company_users;
DROP POLICY IF EXISTS "company_users_invite" ON company_users;

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

COMMIT;