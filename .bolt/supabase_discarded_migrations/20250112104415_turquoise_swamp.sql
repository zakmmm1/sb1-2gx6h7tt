/*
  # Fix ON CONFLICT Error

  1. Changes
    - Adds unique constraint for email per owner account
    - Updates indexes for better performance
    - Ensures proper conflict handling

  2. Security
    - Maintains existing RLS policies
    - Preserves data integrity
*/

-- Start transaction
BEGIN;

-- Step 1: Add unique constraint for email per owner account
ALTER TABLE company_users
DROP CONSTRAINT IF EXISTS company_users_email_owner_key,
ADD CONSTRAINT company_users_email_owner_key 
  UNIQUE (email, owner_account_id);

-- Step 2: Add indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_company_users_email_owner 
  ON company_users(email, owner_account_id)
  WHERE status = 'pending';

CREATE INDEX IF NOT EXISTS idx_company_users_email_status 
  ON company_users(email, status)
  WHERE status = 'pending';

-- Step 3: Update existing records to ensure no conflicts
UPDATE company_users
SET status = 'active'
WHERE user_id IS NOT NULL 
AND status != 'active';

-- Step 4: Clean up any duplicate pending invitations
WITH latest_invites AS (
  SELECT DISTINCT ON (email, owner_account_id)
    id,
    email,
    owner_account_id,
    created_at
  FROM company_users
  WHERE status = 'pending'
  ORDER BY email, owner_account_id, created_at DESC
)
DELETE FROM company_users cu
WHERE status = 'pending'
AND NOT EXISTS (
  SELECT 1 
  FROM latest_invites li 
  WHERE li.id = cu.id
);

COMMIT;