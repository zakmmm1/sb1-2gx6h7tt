import { supabase } from './supabase';

// Simple function to get user's company name
export async function getCompanyName() {
  const { data: { user } } = await supabase.auth.getUser();
  
  if (!user) {
    throw new Error('No authenticated user');
  }

  const { data, error } = await supabase
    .from('user_settings')
    .select('company_name')
    .eq('user_id', user.id)
    .single();

  if (error) throw error;
  return data?.company_name;
}