-- Drop existing problematic policies
DROP POLICY IF EXISTS "Company users can view members" ON company_users;
DROP POLICY IF EXISTS "Company owners can manage members" ON company_users;

-- Create simplified policies that avoid recursion
CREATE POLICY "Users can view company members"
  ON company_users
  FOR SELECT
  TO authenticated
  USING (
    -- Direct company membership
    EXISTS (
      SELECT 1 
      FROM user_settings us
      WHERE us.user_id = auth.uid()
      AND us.company_id = company_users.company_id
    )
  );

CREATE POLICY "Company owners can manage members"
  ON company_users
  FOR ALL
  TO authenticated
  USING (
    -- User is company owner
    EXISTS (
      SELECT 1 
      FROM companies c
      WHERE c.id = company_users.company_id 
      AND c.owner_id = auth.uid()
    )
  );

-- Add company membership trigger
CREATE OR REPLACE FUNCTION add_company_owner_to_members()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO company_users (company_id, user_id, role)
  VALUES (NEW.id, NEW.owner_id, 'owner');
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER company_owner_membership
  AFTER INSERT ON companies
  FOR EACH ROW
  EXECUTE FUNCTION add_company_owner_to_members();