import React, { useEffect, useState } from 'react';
import { Clock } from 'lucide-react';
import { calculateTimeElapsed, getTimeColor } from '../utils/timeUtils';
import { TimeDisplay } from './TimeDisplay';

interface TimeTrackerProps {
  createdAt?: Date;
  completedAt?: Date;
}

export const TimeTracker: React.FC<TimeTrackerProps> = ({ createdAt, completedAt }) => {
  const [timeState, setTimeState] = useState(() => {
    if (!createdAt) return { hours: 0, minutes: 0, seconds: 0, color: 'text-gray-500' };
    
    const elapsed = calculateTimeElapsed(createdAt);
    return {
      ...elapsed,
      color: getTimeColor(elapsed.hours)
    };
  });

  useEffect(() => {
    if (!createdAt) return;
    
    if (completedAt) {
      const elapsed = calculateTimeElapsed(createdAt, completedAt);
      setTimeState({
        ...elapsed,
        color: getTimeColor(elapsed.hours)
      });
      return;
    }

    const interval = setInterval(() => {
      const elapsed = calculateTimeElapsed(createdAt);
      setTimeState({
        ...elapsed,
        color: getTimeColor(elapsed.hours)
      });
    }, 1000);

    return () => clearInterval(interval);
  }, [createdAt, completedAt]);

  if (!createdAt) return null;

  return (
    <div className="flex items-center gap-2">
      <Clock className={`w-4 h-4 ${timeState.color}`} />
      <TimeDisplay
        hours={timeState.hours}
        minutes={timeState.minutes}
        seconds={timeState.seconds}
        color={timeState.color}
      />
    </div>
  );
};