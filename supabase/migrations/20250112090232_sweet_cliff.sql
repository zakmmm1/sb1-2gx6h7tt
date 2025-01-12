/*
  # Fix Invitation System Loop

  1. Changes
    - Consolidates all invitation-related changes into a single migration
    - Removes duplicate column additions
    - Ensures proper order of operations
*/

-- Drop any existing invitation tables to start fresh
DROP TABLE IF EXISTS company_invitations CASCADE;

-- Ensure company_users has all required columns
DO $$ 
BEGIN
  -- Add status column if it doesn't exist
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'company_users' AND column_name = 'status'
  ) THEN
    ALTER TABLE company_users ADD COLUMN status text DEFAULT 'active';
    ALTER TABLE company_users ADD CONSTRAINT valid_status CHECK (status IN ('pending', 'active'));
  END IF;

  -- Add invitation columns if they don't exist
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'company_users' AND column_name = 'invited_by'
  ) THEN
    ALTER TABLE company_users ADD COLUMN invited_by uuid REFERENCES auth.users;
    ALTER TABLE company_users ADD COLUMN invitation_token uuid DEFAULT gen_random_uuid();
    ALTER TABLE company_users ADD COLUMN invitation_expires_at timestamptz DEFAULT (now() + interval '7 days');
  END IF;
END $$;

-- Create indexes if they don't exist
CREATE INDEX IF NOT EXISTS idx_company_users_invitation 
  ON company_users(invitation_token, status);

CREATE INDEX IF NOT EXISTS idx_company_users_invited_by 
  ON company_users(invited_by);

-- Update existing users to be marked as active
UPDATE company_users
SET status = 'active'
WHERE user_id IS NOT NULL AND status IS NULL;