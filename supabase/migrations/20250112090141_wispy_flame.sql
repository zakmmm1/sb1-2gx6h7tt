/*
  # Fix Company Users Table

  1. Changes
    - Adds missing invited_by column
    - Ensures all required columns exist
    - Fixes column constraints
*/

-- Add missing columns to company_users
ALTER TABLE company_users 
ADD COLUMN IF NOT EXISTS invited_by uuid REFERENCES auth.users,
ADD COLUMN IF NOT EXISTS invitation_token uuid DEFAULT gen_random_uuid(),
ADD COLUMN IF NOT EXISTS invitation_expires_at timestamptz DEFAULT (now() + interval '7 days');

-- Add index for better query performance
CREATE INDEX IF NOT EXISTS idx_company_users_invited_by 
  ON company_users(invited_by);

-- Update existing rows to have valid invitation data
UPDATE company_users
SET 
  invitation_token = gen_random_uuid(),
  invitation_expires_at = (now() + interval '7 days')
WHERE invitation_token IS NULL;