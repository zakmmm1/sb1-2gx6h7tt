-- Start transaction
BEGIN;

-- Step 1: Drop existing policies that depend on company_name
DROP POLICY IF EXISTS "anyone_can_view_company_users" ON company_users;
DROP POLICY IF EXISTS "admins_can_invite_users" ON company_users;
DROP POLICY IF EXISTS "allow_view_users" ON company_users;
DROP POLICY IF EXISTS "allow_invite_users" ON company_users;
DROP POLICY IF EXISTS "company_users_view" ON company_users;
DROP POLICY IF EXISTS "company_users_invite" ON company_users;

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
ADD COLUMN owner_account_id uuid REFERENCES owner_accounts(id);

-- Step 4: Migrate existing owners to owner_accounts
INSERT INTO owner_accounts (owner_id, name)
SELECT DISTINCT ON (company_name)
  user_id as owner_id,
  company_name as name
FROM company_users
WHERE role = 'owner'
AND status = 'active'
AND user_id IS NOT NULL;

-- Step 5: Link existing users to their owner accounts
UPDATE company_users cu
SET owner_account_id = oa.id
FROM owner_accounts oa
WHERE cu.company_name = oa.name;

-- Step 6: Make owner_account_id required
ALTER TABLE company_users
ALTER COLUMN owner_account_id SET NOT NULL;

-- Step 7: Now we can safely drop the company_name column
ALTER TABLE company_users
DROP COLUMN company_name;

-- Step 8: Create new indexes
CREATE INDEX idx_company_users_owner_account 
  ON company_users(owner_account_id, role, status);

-- Step 9: Create new policies using owner_account_id
CREATE POLICY "allow_view_users"
  ON company_users
  FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "allow_invite_users"
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

-- Step 10: Update function to use owner_account_id
CREATE OR REPLACE FUNCTION handle_company_user_created()
RETURNS TRIGGER AS $$
DECLARE
  v_auth_user_id uuid;
BEGIN
  -- Get auth user id if exists
  SELECT id INTO v_auth_user_id
  FROM auth.users
  WHERE email = NEW.email;

  -- If auth user exists, activate immediately
  IF v_auth_user_id IS NOT NULL THEN
    NEW.user_id := v_auth_user_id;
    NEW.status := 'active';
  END IF;

  -- If this is the first user under this owner, make them admin
  IF NOT EXISTS (
    SELECT 1 FROM company_users 
    WHERE owner_account_id = NEW.owner_account_id 
    AND status = 'active'
  ) THEN
    NEW.role := 'admin';
    NEW.can_view_all_tasks := true;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMIT;