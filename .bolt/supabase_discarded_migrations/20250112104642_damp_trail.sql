/*
  # Fix Unique Constraint and Duplicates

  1. Changes
    - Adds unique constraint for (email, owner_account_id)
    - Removes duplicate rows causing conflicts
    - Updates indexes for better performance

  2. Security
    - Maintains existing RLS policies
    - Preserves data integrity by keeping most recent entries
*/

-- Start transaction
BEGIN;

-- Step 1: Remove duplicates before adding constraint
WITH duplicates AS (
  SELECT id
  FROM (
    SELECT 
      id,
      ROW_NUMBER() OVER (
        PARTITION BY email, owner_account_id 
        ORDER BY 
          status = 'active' DESC, -- Keep active users
          created_at DESC         -- Then most recent
      ) AS row_num
    FROM company_users
  ) ranked
  WHERE row_num > 1
)
DELETE FROM company_users
WHERE id IN (SELECT id FROM duplicates);

-- Step 2: Add unique constraint
ALTER TABLE company_users
DROP CONSTRAINT IF EXISTS company_users_email_owner_unique,
ADD CONSTRAINT company_users_email_owner_unique 
  UNIQUE (email, owner_account_id);

-- Step 3: Add optimized indexes
CREATE INDEX IF NOT EXISTS idx_company_users_email_owner_status
  ON company_users(email, owner_account_id, status);

-- Step 4: Update existing records to ensure consistency
UPDATE company_users
SET status = 'active'
WHERE user_id IS NOT NULL 
AND status != 'active';

COMMIT;