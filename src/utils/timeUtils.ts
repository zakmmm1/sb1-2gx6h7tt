interface TimeUnits {
  hours: number;
  minutes: number;
  seconds: number;
}

export const calculateTimeElapsed = (startDate: Date, endDate: Date = new Date()): TimeUnits => {
  const diff = endDate.getTime() - startDate.getTime();
  
  const seconds = Math.floor((diff / 1000) % 60);
  const minutes = Math.floor((diff / (1000 * 60)) % 60);
  const hours = Math.floor(diff / (1000 * 60 * 60));
  
  return { hours, minutes, seconds };
};

export const getTimeColor = (hours: number): string => {
  if (hours < 5) return 'text-green-500';
  if (hours < 10) return 'text-orange-500';
  if (hours < 15) return 'text-orange-700';
  if (hours < 24) return 'text-red-500';
  return 'text-red-700';
};

export const formatTimeUnit = (value: number): string => {
  return value.toString().padStart(2, '0');
};

export const formatDuration = (hours: number): string => {
  const fullHours = Math.floor(hours);
  const minutes = Math.round((hours - fullHours) * 60);
  
  if (fullHours === 0) {
    return `${minutes}m`;
  }
  
  return `${fullHours}h ${minutes}m`;
};

export const formatInTimezone = (date: Date, timezone?: string): string => {
  return date.toLocaleString(undefined, {
    timeZone: timezone || Intl.DateTimeFormat().resolvedOptions().timeZone
  });
};