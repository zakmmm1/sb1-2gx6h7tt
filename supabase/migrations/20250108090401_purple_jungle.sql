-- Drop existing policies to start fresh
DROP POLICY IF EXISTS "Users can view company members" ON company_users;
DROP POLICY IF EXISTS "Admins can manage company members" ON company_users;

-- Create separate policies for different operations
CREATE POLICY "Users can view their company members"
  ON company_users
  FOR SELECT
  TO authenticated
  USING (
    company_id IN (
      SELECT company_id 
      FROM company_users 
      WHERE user_id = auth.uid()
    )
  );

CREATE POLICY "Owners can manage all company members"
  ON company_users
  FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 
      FROM companies 
      WHERE id = company_users.company_id 
      AND owner_id = auth.uid()
    )
  );

CREATE POLICY "Admins can manage non-admin members"
  ON company_users
  FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 
      FROM company_users cu
      WHERE cu.company_id = company_users.company_id 
      AND cu.user_id = auth.uid() 
      AND cu.role = 'admin'
    )
    AND company_users.role = 'member'
  );

-- Add indexes for better performance
CREATE INDEX IF NOT EXISTS idx_company_users_role 
  ON company_users(company_id, user_id, role);

CREATE INDEX IF NOT EXISTS idx_companies_owner 
  ON companies(owner_id);