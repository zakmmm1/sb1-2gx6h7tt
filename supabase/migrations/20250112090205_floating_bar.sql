/*
  # Fix Invitation System

  1. Changes
    - Ensures company_users has all required columns first
    - Sets up proper constraints and defaults
    - Adds proper indexes
*/

-- First ensure all required columns exist
ALTER TABLE company_users 
ADD COLUMN IF NOT EXISTS invited_by uuid REFERENCES auth.users,
ADD COLUMN IF NOT EXISTS invitation_token uuid DEFAULT gen_random_uuid(),
ADD COLUMN IF NOT EXISTS invitation_expires_at timestamptz DEFAULT (now() + interval '7 days'),
ADD COLUMN IF NOT EXISTS status text DEFAULT 'pending' CHECK (status IN ('pending', 'active'));

-- Add proper indexes
CREATE INDEX IF NOT EXISTS idx_company_users_invitation 
  ON company_users(invitation_token, status);

CREATE INDEX IF NOT EXISTS idx_company_users_invited_by 
  ON company_users(invited_by);

-- Update existing users to be marked as active
UPDATE company_users
SET status = 'active'
WHERE user_id IS NOT NULL;