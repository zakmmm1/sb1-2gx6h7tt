-- Create companies table
CREATE TABLE IF NOT EXISTS companies (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  created_at timestamptz DEFAULT now(),
  owner_id uuid REFERENCES auth.users NOT NULL
);

ALTER TABLE companies ENABLE ROW LEVEL SECURITY;

-- Create company_users table for managing company members
CREATE TABLE IF NOT EXISTS company_users (
  company_id uuid REFERENCES companies NOT NULL,
  user_id uuid REFERENCES auth.users NOT NULL,
  role text NOT NULL CHECK (role IN ('owner', 'admin', 'member')),
  created_at timestamptz DEFAULT now(),
  PRIMARY KEY (company_id, user_id)
);

ALTER TABLE company_users ENABLE ROW LEVEL SECURITY;

-- Add company_id to user_settings
ALTER TABLE user_settings 
ADD COLUMN IF NOT EXISTS company_id uuid REFERENCES companies,
ADD COLUMN IF NOT EXISTS full_name text;

-- Policies for companies
CREATE POLICY "Users can view their company"
  ON companies
  FOR SELECT
  TO authenticated
  USING (
    id IN (
      SELECT company_id 
      FROM company_users 
      WHERE user_id = auth.uid()
    )
  );

CREATE POLICY "Owners can manage their company"
  ON companies
  FOR ALL
  TO authenticated
  USING (owner_id = auth.uid())
  WITH CHECK (owner_id = auth.uid());

-- Policies for company_users
CREATE POLICY "Company members can view other members"
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

CREATE POLICY "Company admins can manage members"
  ON company_users
  FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 
      FROM company_users 
      WHERE user_id = auth.uid() 
      AND company_id = company_users.company_id 
      AND role IN ('owner', 'admin')
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 
      FROM company_users 
      WHERE user_id = auth.uid() 
      AND company_id = company_users.company_id 
      AND role IN ('owner', 'admin')
    )
  );