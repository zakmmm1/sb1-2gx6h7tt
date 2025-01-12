/*
  # Fix User Creation Flow
  
  1. Changes
    - Add proper user creation handling
    - Fix company user linking
    - Add automatic owner assignment
  
  2. Security
    - Maintain RLS policies
    - Add proper validation
*/

-- Start transaction
BEGIN;

-- Step 1: Create function to handle new user signup
CREATE OR REPLACE FUNCTION handle_auth_user_created()
RETURNS TRIGGER AS $$
BEGIN
  -- Update any pending invitations for this user
  UPDATE company_users
  SET 
    user_id = NEW.id,
    status = 'active'
  WHERE 
    email = NEW.email
    AND status = 'pending';
    
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Step 2: Create function to handle new company user
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

  -- If this is the first user in the company, make them owner
  IF NOT EXISTS (
    SELECT 1 FROM company_users 
    WHERE company_name = NEW.company_name 
    AND status = 'active'
  ) THEN
    NEW.role := 'owner';
    NEW.can_view_all_tasks := true;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Step 3: Create triggers
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION handle_auth_user_created();

DROP TRIGGER IF EXISTS on_company_user_created ON company_users;
CREATE TRIGGER on_company_user_created
  BEFORE INSERT ON company_users
  FOR EACH ROW
  EXECUTE FUNCTION handle_company_user_created();

-- Step 4: Update existing users
UPDATE company_users
SET 
  status = CASE
    WHEN user_id IS NOT NULL THEN 'active'
    ELSE status
  END,
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
  END;

COMMIT;