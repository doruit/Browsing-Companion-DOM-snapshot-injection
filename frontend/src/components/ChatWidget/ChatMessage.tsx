import React from 'react';
import ReactMarkdown from 'react-markdown';
import remarkGfm from 'remark-gfm';
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
    <div className={`${styles['chat-message']} ${styles[message.role]}`}>
      <div className={styles['message-bubble']}>
        <ReactMarkdown remarkPlugins={[remarkGfm]}>
          {message.content}
        </ReactMarkdown>
      </div>
      <div className={styles['message-time']}>{formatTime(message.timestamp)}</div>
    </div>
  );
};
