import { supabase } from './supabase';

interface UserRole {
  role: 'admin' | 'user';
  can_view_all_tasks: boolean;
}

export async function updateUserRole(userId: string, updates: UserRole): Promise<void> {
  const { error } = await supabase
    .from('company_users')
    .update(updates)
    .eq('user_id', userId);

  if (error) throw error;
}

export async function getCompanyUsers(): Promise<Array<{
  user_id: string;
  email: string;
  full_name: string;
  role: 'admin' | 'user';
  can_view_all_tasks: boolean;
}>> {
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) throw new Error('Not authenticated');

  // Get all users in the same company
  const { data: users, error } = await supabase
    .from('company_users')
    .select('user_id, email, full_name, role, can_view_all_tasks')
    .eq('status', 'active');

  if (error) {
    console.error('Failed to get company users:', error);
    throw new Error('Failed to get users');
  }

  return users || [];
}

export async function updateTaskCollaborators(
  taskId: string,
  collaborators: string[]
): Promise<void> {
  const { error } = await supabase
    .from('tasks')
    .update({ collaborators })
    .eq('id', taskId);

  if (error) throw error;
}