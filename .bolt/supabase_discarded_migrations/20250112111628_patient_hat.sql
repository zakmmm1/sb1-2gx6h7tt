@@ .. @@
   p_owner_account_id uuid,
   p_role text DEFAULT 'user',
   p_can_view_all_tasks boolean DEFAULT false,
-  p_invited_by uuid
+  p_invited_by uuid,
+  p_user_id uuid DEFAULT NULL
 )
 RETURNS uuid AS $$
 DECLARE
-  v_user_id uuid;
   v_company_user_id uuid;
 BEGIN
   -- Validate input
@@ .. @@
     RAISE EXCEPTION 'Only owners and admins can add users';
   END IF;

-  -- Get existing user id if exists
-  SELECT id INTO v_user_id
-  FROM auth.users
-  WHERE email = p_email;
-
   -- Insert into company_users
   INSERT INTO company_users (
     owner_account_id,
     user_id,
     email,
     full_name,
     role,
     can_view_all_tasks,
     status,
     invited_by
   ) VALUES (
     p_owner_account_id,
-    v_user_id,
+    p_user_id,
     p_email,
     p_full_name,
     p_role,
     CASE WHEN p_role = 'admin' THEN true ELSE p_can_view_all_tasks END,
-    CASE WHEN v_user_id IS NOT NULL THEN 'active' ELSE 'pending' END,
+    CASE WHEN p_user_id IS NOT NULL THEN 'active' ELSE 'pending' END,
     p_invited_by
   )