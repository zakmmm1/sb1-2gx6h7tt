-- Drop existing policies
DROP POLICY IF EXISTS "Company members can view other members" ON company_users;
DROP POLICY IF EXISTS "Company admins can manage members" ON company_users;

-- Create new simplified policies
CREATE POLICY "Users can view company members"
  ON company_users
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 
      FROM company_users cu 
      WHERE cu.user_id = auth.uid() 
      AND cu.company_id = company_users.company_id
    )
  );

CREATE POLICY "Admins can manage company members"
  ON company_users
  FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 
      FROM company_users cu 
      WHERE cu.user_id = auth.uid() 
      AND cu.company_id = company_users.company_id 
      AND cu.role IN ('owner', 'admin')
    )
  );

-- Add index to improve policy performance
CREATE INDEX IF NOT EXISTS idx_company_users_lookup 
  ON company_users(user_id, company_id, role);