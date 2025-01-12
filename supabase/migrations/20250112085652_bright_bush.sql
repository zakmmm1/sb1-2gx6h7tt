/*
  # Fix User Permission System
  
  1. Changes
    - Add invitation system fields to company_users
    - Simplify permission model
    - Add proper invitation handling
    
  2. Security
    - Ensure proper RLS policies
    - Add validation constraints
*/

-- First clean up existing tables and policies
DROP TABLE IF EXISTS user_permissions CASCADE;
DROP TABLE IF EXISTS user_roles CASCADE;

-- Ensure company_users has all needed fields
ALTER TABLE company_users
ADD COLUMN IF NOT EXISTS role text NOT NULL DEFAULT 'user' CHECK (role IN ('owner', 'admin', 'user')),
ADD COLUMN IF NOT EXISTS can_view_all_tasks boolean NOT NULL DEFAULT false,
ADD COLUMN IF NOT EXISTS status text NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'active')),
ADD COLUMN IF NOT EXISTS invitation_token uuid DEFAULT gen_random_uuid(),
ADD COLUMN IF NOT EXISTS invitation_expires_at timestamptz DEFAULT (now() + interval '7 days');

-- Create simple policies for company_users
DROP POLICY IF EXISTS "anyone_can_view_company_users" ON company_users;
DROP POLICY IF EXISTS "admins_can_invite_users" ON company_users;

-- Policy for viewing company users
CREATE POLICY "view_company_members"
  ON company_users
  FOR SELECT
  TO authenticated
  USING (true);

-- Policy for inviting users
CREATE POLICY "invite_company_members"
  ON company_users
  FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 
      FROM company_users
      WHERE user_id = auth.uid()
      AND role IN ('owner', 'admin')
      AND status = 'active'
    )
  );

-- Policy for accepting invitations
CREATE POLICY "accept_invitation"
  ON company_users
  FOR UPDATE
  TO authenticated
  USING (
    email = (SELECT email FROM auth.users WHERE id = auth.uid())
    AND status = 'pending'
    AND invitation_expires_at > now()
  );

-- Add function to handle user signup
CREATE OR REPLACE FUNCTION handle_user_signup()
RETURNS TRIGGER AS $$
BEGIN
  -- Check for pending invitations
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

-- Add trigger for new user signups
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION handle_user_signup();

-- Add indexes for better performance
CREATE INDEX IF NOT EXISTS idx_company_users_email_status 
  ON company_users(email, status);
CREATE INDEX IF NOT EXISTS idx_company_users_user_company 
  ON company_users(user_id, company_name, status);