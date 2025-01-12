import { supabase } from './supabase';

interface UserPermissions {
  role: 'admin' | 'user';
  can_view_all_tasks: boolean;
}

export async function getUserPermissions(userId: string): Promise<UserPermissions | null> {
  const { data, error } = await supabase
    .from('user_permissions')
    .select('role, can_view_all_tasks')
    .eq('user_id', userId)
    .single();

  if (error) {
    console.error('Error fetching user permissions:', error);
    return null;
  }

  return data;
}

export async function updateUserPermissions(
  userId: string,
  permissions: Partial<UserPermissions>
): Promise<void> {
  const { error } = await supabase
    .from('user_permissions')
    .upsert({
      user_id: userId,
      ...permissions
    });

  if (error) throw error;
}

export async function getCompanyUsers(): Promise<Array<{
  user_id: string;
  email: string;
  full_name: string;
  role: 'admin' | 'user';
  can_view_all_tasks: boolean;
}>> {
  const { data: companyUsers, error: companyError } = await supabase
    .from('company_users')
    .select('user_id, email, full_name');

  if (companyError) throw companyError;

  const { data: permissions, error: permissionsError } = await supabase
    .from('user_permissions')
    .select('user_id, role, can_view_all_tasks');

  if (permissionsError) throw permissionsError;

  // Merge company users with their permissions
  return companyUsers.map(user => {
    const userPermissions = permissions.find(p => p.user_id === user.user_id) || {
      role: 'user',
      can_view_all_tasks: true
    };

    return {
      ...user,
      role: userPermissions.role,
      can_view_all_tasks: userPermissions.can_view_all_tasks
    };
  });
}

export async function updateTaskUsers(
  taskId: string,
  userIds: string[]
): Promise<void> {
  const { error } = await supabase
    .from('tasks')
    .update({ included_users: userIds })
    .eq('id', taskId);

  if (error) throw error;
}