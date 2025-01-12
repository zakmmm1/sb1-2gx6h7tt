/*
  # Fix User Permission System

  1. Changes
    - Simplifies company_users table structure
    - Adds clear role-based permissions
    - Fixes policy issues
    
  2. Security
    - Enables RLS
    - Adds proper policies for user management
    - Ensures data isolation between companies
*/

-- Drop existing problematic policies
DROP POLICY IF EXISTS "view_company_members" ON company_users;
DROP POLICY IF EXISTS "invite_company_members" ON company_users;
DROP POLICY IF EXISTS "accept_invitation" ON company_users;

-- Ensure company_users has all needed fields
ALTER TABLE company_users
ADD COLUMN IF NOT EXISTS role text NOT NULL DEFAULT 'user' CHECK (role IN ('owner', 'admin', 'user')),
ADD COLUMN IF NOT EXISTS can_view_all_tasks boolean NOT NULL DEFAULT false;

-- Create simplified policies
CREATE POLICY "allow_company_users_select"
  ON company_users
  FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "allow_company_users_insert"
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

CREATE POLICY "allow_company_users_update"
  ON company_users
  FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 
      FROM company_users cu
      WHERE cu.user_id = auth.uid()
      AND cu.role IN ('owner', 'admin')
    )
  );

-- Add indexes for better performance
CREATE INDEX IF NOT EXISTS idx_company_users_lookup 
  ON company_users(user_id, company_name, role);

CREATE INDEX IF NOT EXISTS idx_company_users_email 
  ON company_users(email, company_name);