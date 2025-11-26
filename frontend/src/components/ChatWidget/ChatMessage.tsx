import React from 'react';
import styles from './ChatWidget.module.css';
import { ChatMessage } from '../../types';

interface ChatMessageProps {
  message: ChatMessage;
}

export const ChatMessageComponent: React.FC<ChatMessageProps> = ({ message }) => {
  const formatTime = (timestamp: string) => {
    const date = new Date(timestamp);
    return date.toLocaleTimeString('en-US', { hour: '2-digit', minute: '2-digit' });
  };

  return (
    <div className={`${styles.chatMessage} ${styles[message.role]}`}>
      <div className={styles.messageBubble}>{message.content}</div>
      <div className={styles.messageTime}>{formatTime(message.timestamp)}</div>
    </div>
  );
};
