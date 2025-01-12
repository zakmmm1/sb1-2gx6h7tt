/*
  # Fix User Creation Flow

  1. Changes
    - Adds proper constraints and indexes for owner-based system
    - Updates policies to use owner_account_id
    - Adds trigger to handle new user creation
    - Ensures proper role assignment

  2. Security
    - Enforces proper access control through RLS
    - Only allows admins to manage users in their account
    - Preserves data integrity with constraints
*/

-- Start transaction
BEGIN;

-- Step 1: Ensure proper constraints on company_users
ALTER TABLE company_users
DROP CONSTRAINT IF EXISTS company_users_owner_account_id_role_key,
ADD CONSTRAINT company_users_owner_account_id_role_key 
  UNIQUE (owner_account_id, email);

-- Step 2: Create function to handle new user creation
CREATE OR REPLACE FUNCTION handle_new_user_creation()
RETURNS TRIGGER AS $$
DECLARE
  v_auth_user_id uuid;
  v_owner_account_id uuid;
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

  -- If this is the first user for this owner account, make them admin
  IF NOT EXISTS (
    SELECT 1 
    FROM company_users 
    WHERE owner_account_id = NEW.owner_account_id 
    AND status = 'active'
  ) THEN
    NEW.role := 'admin';
    NEW.can_view_all_tasks := true;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Step 3: Create trigger for new user creation
DROP TRIGGER IF EXISTS on_new_user_creation ON company_users;
CREATE TRIGGER on_new_user_creation
  BEFORE INSERT ON company_users
  FOR EACH ROW
  EXECUTE FUNCTION handle_new_user_creation();

-- Step 4: Create function to handle auth user creation
CREATE OR REPLACE FUNCTION handle_auth_user_creation()
RETURNS TRIGGER AS $$
BEGIN
  -- Update any pending invitations for this user
  UPDATE company_users
  SET 
    user_id = NEW.id,
    status = 'active'
  WHERE 
    email = NEW.email
    AND status = 'pending'
    AND invitation_expires_at > now();
    
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Step 5: Create trigger for auth user creation
DROP TRIGGER IF EXISTS on_auth_user_creation ON auth.users;
CREATE TRIGGER on_auth_user_creation
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION handle_auth_user_creation();

-- Step 6: Update policies to use owner_account_id
DROP POLICY IF EXISTS "company_users_select" ON company_users;
DROP POLICY IF EXISTS "company_users_insert" ON company_users;

CREATE POLICY "allow_view_company_users"
  ON company_users
  FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "allow_manage_company_users"
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
CREATE INDEX IF NOT EXISTS idx_company_users_owner_lookup 
  ON company_users(owner_account_id, role, status);

CREATE INDEX IF NOT EXISTS idx_company_users_email_lookup 
  ON company_users(email, status);

COMMIT;