-- Drop existing problematic policies
DROP POLICY IF EXISTS "Users can view their company members" ON company_users;
DROP POLICY IF EXISTS "Owners can manage all company members" ON company_users;
DROP POLICY IF EXISTS "Admins can manage non-admin members" ON company_users;

-- Create company_invitations table
CREATE TABLE IF NOT EXISTS company_invitations (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid REFERENCES companies NOT NULL,
  email text NOT NULL,
  role text NOT NULL CHECK (role IN ('admin', 'member')),
  token uuid DEFAULT gen_random_uuid(),
  expires_at timestamptz NOT NULL DEFAULT (now() + interval '7 days'),
  created_at timestamptz DEFAULT now(),
  created_by uuid REFERENCES auth.users NOT NULL,
  accepted_at timestamptz,
  UNIQUE (company_id, email)
);

ALTER TABLE company_invitations ENABLE ROW LEVEL SECURITY;

-- Simplified company_users policies
CREATE POLICY "Company users can view members"
  ON company_users
  FOR SELECT
  TO authenticated
  USING (
    company_id IN (
      SELECT cu.company_id 
      FROM company_users cu 
      WHERE cu.user_id = auth.uid()
    )
  );

CREATE POLICY "Company owners can manage members"
  ON company_users
  FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 
      FROM companies c
      WHERE c.id = company_users.company_id 
      AND c.owner_id = auth.uid()
    )
  );

-- Company invitations policies
CREATE POLICY "Company admins can create invitations"
  ON company_invitations
  FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 
      FROM company_users cu
      WHERE cu.company_id = company_invitations.company_id 
      AND cu.user_id = auth.uid()
      AND cu.role IN ('owner', 'admin')
    )
  );

CREATE POLICY "Company members can view invitations"
  ON company_invitations
  FOR SELECT
  TO authenticated
  USING (
    company_id IN (
      SELECT cu.company_id 
      FROM company_users cu 
      WHERE cu.user_id = auth.uid()
    )
  );

CREATE POLICY "Invited users can accept invitations"
  ON company_invitations
  FOR UPDATE
  TO authenticated
  USING (
    email = (SELECT email FROM auth.users WHERE id = auth.uid())
    AND accepted_at IS NULL
    AND expires_at > now()
  )
  WITH CHECK (
    email = (SELECT email FROM auth.users WHERE id = auth.uid())
    AND accepted_at IS NULL
    AND expires_at > now()
  );