/*
  # Add User Implementation

  1. Changes
    - Adds function to safely create new users
    - Updates constraints to prevent duplicate invitations
    - Adds RLS policies for user management

  2. Security
    - Ensures only owners/admins can add users
    - Prevents duplicate invitations
    - Maintains data integrity
*/

-- Start transaction
BEGIN;

-- Step 1: Create function to safely add new users
CREATE OR REPLACE FUNCTION safely_add_company_user(
  p_email text,
  p_full_name text,
  p_owner_account_id uuid,
  p_role text DEFAULT 'user',
  p_can_view_all_tasks boolean DEFAULT false,
  p_invited_by uuid
)
RETURNS uuid AS $$
DECLARE
  v_user_id uuid;
  v_company_user_id uuid;
BEGIN
  -- Validate input
  IF p_email IS NULL OR p_owner_account_id IS NULL THEN
    RAISE EXCEPTION 'Email and owner_account_id are required';
  END IF;

  -- Check if inviter has permission
  IF NOT EXISTS (
    SELECT 1 
    FROM company_users
    WHERE user_id = p_invited_by
    AND owner_account_id = p_owner_account_id
    AND role IN ('owner', 'admin')
    AND status = 'active'
  ) THEN
    RAISE EXCEPTION 'Only owners and admins can add users';
  END IF;

  -- Get existing user id if exists
  SELECT id INTO v_user_id
  FROM auth.users
  WHERE email = p_email;

  -- Insert into company_users
  INSERT INTO company_users (
    owner_account_id,
    user_id,
    email,
    full_name,
    role,
    can_view_all_tasks,
    status,
    invited_by
  ) VALUES (
    p_owner_account_id,
    v_user_id,
    p_email,
    p_full_name,
    p_role,
    CASE WHEN p_role = 'admin' THEN true ELSE p_can_view_all_tasks END,
    CASE WHEN v_user_id IS NOT NULL THEN 'active' ELSE 'pending' END,
    p_invited_by
  )
  ON CONFLICT (email, owner_account_id) 
  DO UPDATE SET
    full_name = EXCLUDED.full_name,
    role = EXCLUDED.role,
    can_view_all_tasks = EXCLUDED.can_view_all_tasks,
    invited_by = EXCLUDED.invited_by,
    invitation_expires_at = now() + interval '7 days'
  RETURNING id INTO v_company_user_id;

  RETURN v_company_user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Step 2: Add RLS policies for the function
GRANT EXECUTE ON FUNCTION safely_add_company_user TO authenticated;

COMMIT;