import React from 'react';
import { formatTimeUnit } from '../utils/timeUtils';

interface TimeDisplayProps {
  hours: number;
  minutes: number;
  seconds: number;
  color: string;
}

export const TimeDisplay: React.FC<TimeDisplayProps> = ({ hours, minutes, seconds, color }) => {
  return (
    <span className={`font-mono ${color}`}>
      {formatTimeUnit(hours)}:{formatTimeUnit(minutes)}:{formatTimeUnit(seconds)}
    </span>
  );
};