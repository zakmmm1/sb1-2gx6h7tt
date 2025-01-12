import React, { useState } from 'react';
import { useAuth } from '../../contexts/AuthContext';
import { Mail, Lock, User, Building2, Globe2, Loader, Phone } from 'lucide-react';
import parsePhoneNumber from 'libphonenumber-js';

const commonTimezones = [
  'America/New_York',
  'America/Chicago',
  'America/Denver',
  'America/Los_Angeles',
  'America/Toronto',
  'Europe/London',
  'Europe/Paris',
  'Asia/Tokyo',
  'Asia/Singapore',
  'Australia/Sydney',
  'Pacific/Auckland'
];

export function SignUpForm() {
  const { signUp, loading, error } = useAuth();
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [fullName, setFullName] = useState('');
  const [companyName, setCompanyName] = useState('');
  const [timezone, setTimezone] = useState(
    Intl.DateTimeFormat().resolvedOptions().timeZone
  );
  const [phoneNumber, setPhoneNumber] = useState('');
  const [phoneError, setPhoneError] = useState('');
  const [loadingMessage, setLoadingMessage] = useState('');

  const validatePhoneNumber = (number: string) => {
    if (!number) {
      // Allow empty phone number
      setPhoneError('');
      return true;
    }

    try {
      // Try to parse the number in a more flexible way
      const parsedNumber = parsePhoneNumber(number, 'US');
      if (parsedNumber) {
        setPhoneError('');
        return true;
      }
      
      // If parsing fails but number is at least 10 digits, accept it
      const digitsOnly = number.replace(/\D/g, '');
      if (digitsOnly.length >= 10) {
        setPhoneError('');
        return true;
      }

      setPhoneError('Please enter a valid phone number');
      return false;
    } catch (err) {
      // If parsing fails but number is at least 10 digits, accept it
      const digitsOnly = number.replace(/\D/g, '');
      if (digitsOnly.length >= 10) {
        setPhoneError('');
        return true;
      }
      setPhoneError('Please enter a valid phone number');
      return false;
    }
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    
    setPhoneError('');

    try {
      if (!validatePhoneNumber(phoneNumber)) {
        return;
      }

      await signUp({
        email: email.trim(),
        password,
        fullName,
        companyName,
        timezone,
        phoneNumber
      });
    } catch (err) {
      console.error('Signup error:', err);
    }
  };

  const handlePhoneChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const value = e.target.value;
    setPhoneNumber(value);
    // Only validate if there's a value
    if (value.trim()) validatePhoneNumber(value);
    else setPhoneError('');
  };

  if (loading) {
    return (
      <div className="flex flex-col items-center justify-center py-12 space-y-6">
        <div className="flex items-center justify-center">
          <Loader className="w-8 h-8 animate-spin text-blue-600" />
        </div>
        <p className="text-sm text-gray-500">Creating your account...</p>
      </div>
    );
  }

  return (
    <form onSubmit={handleSubmit} className="space-y-4">
      <div>
        <label htmlFor="fullName" className="block text-sm font-medium text-gray-700">
          Full Name
        </label>
        <div className="mt-1 relative">
          <input
            id="fullName"
            type="text"
            required
            value={fullName}
            onChange={(e) => setFullName(e.target.value)}
            className="appearance-none block w-full px-3 py-2 pl-10 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-blue-500 focus:border-blue-500"
          />
          <User className="w-5 h-5 text-gray-400 absolute left-3 top-2.5" />
        </div>
      </div>

      <div>
        <label htmlFor="companyName" className="block text-sm font-medium text-gray-700">
          Company Name
        </label>
        <div className="mt-1 relative">
          <input
            id="companyName"
            type="text"
            required
            value={companyName}
            onChange={(e) => setCompanyName(e.target.value)}
            className="appearance-none block w-full px-3 py-2 pl-10 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-blue-500 focus:border-blue-500"
          />
          <Building2 className="w-5 h-5 text-gray-400 absolute left-3 top-2.5" />
        </div>
      </div>

      <div>
        <label htmlFor="timezone" className="block text-sm font-medium text-gray-700">
          Timezone
        </label>
        <div className="mt-1 relative">
          <select
            id="timezone"
            value={timezone}
            onChange={(e) => setTimezone(e.target.value)}
            className="appearance-none block w-full px-3 py-2 pl-10 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-blue-500 focus:border-blue-500"
          >
            {commonTimezones.map((tz) => (
              <option key={tz} value={tz}>
                {tz.split('/').pop()?.replace(/_/g, ' ')}
              </option>
            ))}
          </select>
          <Globe2 className="w-5 h-5 text-gray-400 absolute left-3 top-2.5" />
        </div>
      </div>

      <div>
        <label htmlFor="phone" className="block text-sm font-medium text-gray-700">
          Phone Number
        </label>
        <div className="mt-1 relative">
          <input
            id="phone"
            type="tel"
            value={phoneNumber}
            onChange={handlePhoneChange}
            placeholder="(555) 555-5555"
            className={`appearance-none block w-full px-3 py-2 pl-10 border rounded-md shadow-sm focus:outline-none focus:ring-blue-500 focus:border-blue-500 ${
              phoneError ? 'border-red-300' : 'border-gray-300'
            }`}
          />
          <Phone className="w-5 h-5 text-gray-400 absolute left-3 top-2.5" />
        </div>
        {phoneError && (
          <p className="mt-1 text-sm text-red-600">{phoneError}</p>
        )}
      </div>

      <div>
        <label htmlFor="email" className="block text-sm font-medium text-gray-700">
          Email
        </label>
        <div className="mt-1 relative">
          <input
            id="email"
            type="email"
            required
            value={email}
            onChange={(e) => setEmail(e.target.value)}
            className="appearance-none block w-full px-3 py-2 pl-10 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-blue-500 focus:border-blue-500"
          />
          <Mail className="w-5 h-5 text-gray-400 absolute left-3 top-2.5" />
        </div>
      </div>

      <div>
        <label htmlFor="password" className="block text-sm font-medium text-gray-700">
          Password
        </label>
        <div className="mt-1 relative">
          <input
            id="password"
            type="password"
            required
            value={password}
            onChange={(e) => setPassword(e.target.value)}
            className="appearance-none block w-full px-3 py-2 pl-10 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-blue-500 focus:border-blue-500"
          />
          <Lock className="w-5 h-5 text-gray-400 absolute left-3 top-2.5" />
        </div>
      </div>

      {error && (
        <div className="text-red-600 text-sm">{error}</div>
      )}

      <button
        type="submit"
        disabled={loading}
        className="w-full flex justify-center py-2 px-4 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-blue-600 hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 disabled:opacity-50"
      >
        {loading ? (
          <Loader className="w-5 h-5 animate-spin" />
        ) : (
          'Sign Up'
        )}
      </button>
    </form>
  );
}