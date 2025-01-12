-- Create stored procedure for adding company users
CREATE OR REPLACE FUNCTION add_company_user(
  p_email text,
  p_full_name text,
  p_company_name text,
  p_role text,
  p_can_view_all_tasks boolean,
  p_invited_by uuid
) RETURNS void AS $$
BEGIN
  -- Insert into company_users
  INSERT INTO company_users (
    email,
    full_name,
    company_name,
    role,
    invited_by
  ) VALUES (
    p_email,
    p_full_name,
    p_company_name,
    p_role,
    p_invited_by
  );

  -- Insert into user_roles
  INSERT INTO user_roles (
    user_id,
    role,
    can_view_all_tasks
  ) VALUES (
    p_email,
    p_role,
    CASE 
      WHEN p_role = 'admin' THEN true
      ELSE p_can_view_all_tasks
    END
  );
END;
$$ LANGUAGE plpgsql;