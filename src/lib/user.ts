import { supabase } from './supabase';

interface UserSettings {
  company_name?: string;
  timezone?: string;
}

interface NewUserData {
  email: string;
  full_name: string;
  password: string;
  role: 'admin' | 'user';
  can_view_all_tasks: boolean;
}

export async function addCompanyUser(userData: NewUserData) {
  const { data: { user: currentUser } } = await supabase.auth.getUser();
  
  if (!currentUser) {
    throw new Error('No authenticated user');
  }

  try {
    // Validate input
    if (!userData.email || !userData.full_name || !userData.password) {
      throw new Error('Please fill in all required fields');
    }

    // Validate password strength
    if (userData.password.length < 8) {
      throw new Error('Password must be at least 8 characters');
    }

    // Check if user already exists
    const { data: existingUser } = await supabase
      .from('company_users')
      .select('id, email, status, role')
      .eq('email', userData.email.toLowerCase().trim())
      .maybeSingle();

    if (existingUser?.status === 'active') {
      throw new Error('This user is already part of your company');
    }

    // Create the user in auth
    const { data: authData, error: signUpError } = await supabase.auth.signUp({
      email: userData.email.toLowerCase().trim(),
      password: userData.password,
      options: {
        data: {
          full_name: userData.full_name
        }
      }
    });

    if (signUpError) {
      console.error('Failed to create auth user:', signUpError);
      if (signUpError.message?.includes('already registered')) {
        throw new Error('This email is already registered');
      } else {
        throw new Error('Failed to create user account');
      }
    }

    // Get current user's company context
    const { data: ownerAccount, error: ownerError } = await supabase
      .from('company_users')
      .select('owner_account_id')
      .eq('user_id', currentUser.id)
      .eq('status', 'active')
      .single();

    if (ownerError) {
      console.error('Failed to get user account:', ownerError);
      throw new Error('Failed to verify account settings');
    }

    if (!ownerAccount?.owner_account_id) {
      console.error('No active account found');
      throw new Error('Account not found - please set up your account first');
    }

    const { data: newUser, error: createError } = await supabase
      .from('company_users')
      .insert({
        email: userData.email.toLowerCase().trim(),
        full_name: userData.full_name,
        user_id: authData.user?.id,
        role: userData.role,
        can_view_all_tasks: userData.role === 'admin' ? true : userData.can_view_all_tasks,
        status: 'active',
        invited_by: currentUser.id,
        owner_account_id: ownerAccount.owner_account_id
      })
      .select()
      .single();

    if (createError) {
      console.error('Failed to create company user:', {
        error: createError,
        code: createError.code,
        details: createError.details,
        hint: createError.hint,
        message: createError.message
      });
      throw new Error('Failed to add user. Please try again.');
    }

    // Return success
    console.log('Successfully created new user:', {
      email: userData.email,
      role: userData.role,
      status: 'active'
    });

    return newUser;
  } catch (err) {
    console.error('Add user error:', err);
    throw err instanceof Error ? err : new Error('An unexpected error occurred');
  }
}

export async function updateUserSettings(settings: UserSettings) {
  const { data: { user } } = await supabase.auth.getUser();
  
  if (!user) throw new Error('No authenticated user');
  
  // First check if settings already exist
  const { data: existingSettings } = await supabase
    .from('user_settings')
    .select('*')
    .eq('user_id', user.id)
    .single();

  if (existingSettings) {
    // Update existing settings
    const { error } = await supabase
      .from('user_settings')
      .update(settings)
      .eq('user_id', user.id);

    if (error) throw error;
  } else {
    // Create new settings
    const { error } = await supabase
      .from('user_settings')
      .insert([{
        user_id: user.id,
        ...settings
      }]);

    if (error) throw error;
  }
}

export async function getUserSettings(): Promise<UserSettings | null> {
  const { data: { user } } = await supabase.auth.getUser();
  
  if (!user) {
    throw new Error('No authenticated user');
  }

  try {
    const { data, error } = await supabase
      .from('user_settings')
      .select('*')
      .eq('user_id', user.id)
      .single();
    
    // If no settings exist, create default settings
    if (error?.code === 'PGRST116' || !data) {
      const defaultSettings = {
        user_id: user.id,
        company_name: user.user_metadata?.company_name || 'My Company',
        timezone: user.user_metadata?.timezone || Intl.DateTimeFormat().resolvedOptions().timeZone
      };

      const { data: newSettings, error: createError } = await supabase
        .from('user_settings')
        .upsert([defaultSettings])
        .select()
        .single();

      if (createError) throw createError;
      return newSettings;
    }

    if (error) {
      console.error('Failed to fetch user settings:', error);
      // Return default settings on error
      return {
        company_name: user.user_metadata?.company_name || 'My Company',
        timezone: user.user_metadata?.timezone || Intl.DateTimeFormat().resolvedOptions().timeZone
      };
    }

    return data;
  } catch (err) {
    console.error('Failed to handle user settings:', err);
    // Return default settings on any error
    return {
      company_name: user.user_metadata?.company_name || 'My Company',
      timezone: user.user_metadata?.timezone || Intl.DateTimeFormat().resolvedOptions().timeZone
    };
  }
}