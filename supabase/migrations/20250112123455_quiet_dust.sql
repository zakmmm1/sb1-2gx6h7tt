/*
  # Fix owner accounts setup

  1. Changes
    - Create owner_accounts table if it doesn't exist
    - Add proper constraints and indexes
    - Create function to handle owner account creation
    - Create trigger to automatically create owner accounts
    - Add policies for owner_accounts table

  2. Security
    - Enable RLS on owner_accounts
    - Add policies for viewing and managing owner accounts
*/

-- Create owner_accounts table if it doesn't exist
CREATE TABLE IF NOT EXISTS owner_accounts (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_id uuid NOT NULL REFERENCES auth.users(id),
  name text NOT NULL,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  UNIQUE(owner_id)
);

-- Enable RLS
ALTER TABLE owner_accounts ENABLE ROW LEVEL SECURITY;

-- Create function to handle owner account creation
CREATE OR REPLACE FUNCTION handle_owner_account_creation()
RETURNS TRIGGER AS $$
BEGIN
  -- Create owner account for new admin users
  IF NEW.role IN ('owner', 'admin') AND NEW.status = 'active' THEN
    INSERT INTO owner_accounts (owner_id, name)
    VALUES (
      NEW.user_id,
      COALESCE(NEW.full_name, NEW.email) || '''s Account'
    )
    ON CONFLICT (owner_id) DO NOTHING;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger for owner account creation
DROP TRIGGER IF EXISTS create_owner_account ON company_users;
CREATE TRIGGER create_owner_account
  AFTER INSERT OR UPDATE ON company_users
  FOR EACH ROW
  EXECUTE FUNCTION handle_owner_account_creation();

-- Create policies for owner_accounts
CREATE POLICY "Users can view their own owner account"
  ON owner_accounts
  FOR SELECT
  TO authenticated
  USING (
    owner_id = auth.uid()
    OR
    EXISTS (
      SELECT 1 
      FROM company_users cu
      WHERE cu.user_id = auth.uid()
      AND cu.owner_account_id = owner_accounts.id
    )
  );

CREATE POLICY "Owners can manage their account"
  ON owner_accounts
  FOR ALL
  TO authenticated
  USING (owner_id = auth.uid())
  WITH CHECK (owner_id = auth.uid());

-- Add indexes for better performance
CREATE INDEX IF NOT EXISTS idx_owner_accounts_owner_id 
  ON owner_accounts(owner_id);

-- Create owner accounts for existing admin users
INSERT INTO owner_accounts (owner_id, name)
SELECT DISTINCT 
  user_id,
  COALESCE(full_name, email) || '''s Account'
FROM company_users
WHERE role IN ('owner', 'admin')
  AND status = 'active'
  AND user_id IS NOT NULL
ON CONFLICT (owner_id) DO NOTHING;