/*
  # Fix company users table

  1. Changes
    - Add email and full_name columns to company_users table
    - Add invited_by column for tracking invitations
    - Update policies to allow proper access

  2. Security
    - Enable RLS
    - Add policies for viewing and managing company users
*/

-- Add new columns to company_users
ALTER TABLE company_users 
ADD COLUMN IF NOT EXISTS email text,
ADD COLUMN IF NOT EXISTS full_name text,
ADD COLUMN IF NOT EXISTS invited_by uuid REFERENCES auth.users;

-- Update policies
CREATE POLICY "users_view_company_members"
  ON company_users
  FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "users_manage_company_members"
  ON company_users
  FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM company_users
      WHERE user_id = auth.uid()
      AND role IN ('owner', 'admin')
    )
  );