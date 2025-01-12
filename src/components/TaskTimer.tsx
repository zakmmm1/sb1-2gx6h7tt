import React, { useEffect, useState } from 'react';
import { TimeDisplay } from './TimeDisplay';
import { calculateTimeElapsed } from '../utils/timeUtils';

interface TaskTimerProps {
  startTime?: Date;
  isRunning: boolean;
}

export const TaskTimer: React.FC<TaskTimerProps> = ({ startTime, isRunning }) => {
  const [timeState, setTimeState] = useState({ hours: 0, minutes: 0, seconds: 0 });

  useEffect(() => {
    if (!startTime || !isRunning) {
      setTimeState({ hours: 0, minutes: 0, seconds: 0 });
      return;
    }

    const interval = setInterval(() => {
      const elapsed = calculateTimeElapsed(startTime);
      setTimeState(elapsed);
    }, 1000);

    return () => clearInterval(interval);
  }, [startTime, isRunning]);

  return (
    <TimeDisplay
      hours={timeState.hours}
      minutes={timeState.minutes}
      seconds={timeState.seconds}
      color="text-blue-600"
    />
  );
};