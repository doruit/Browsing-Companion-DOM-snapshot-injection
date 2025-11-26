import React, { useState, useEffect, useRef } from 'react';
import styles from './ChatWidget.module.css';
import { ChatMessageComponent } from './ChatMessage';
import { ChatComposer } from './ChatComposer';
import { ChatMessage, DOMSnapshot } from '../../types';
import { apiClient } from '../../utils/api';

interface ChatWidgetProps {
  onCaptureSnapshot: () => DOMSnapshot | null;
}

export const ChatWidget: React.FC<ChatWidgetProps> = ({ onCaptureSnapshot }) => {
  const [messages, setMessages] = useState<ChatMessage[]>([]);
  const [isMinimized, setIsMinimized] = useState(false);
  const [isLoading, setIsLoading] = useState(false);
  const [sessionId, setSessionId] = useState<string | null>(null);
  const [visibleCount, setVisibleCount] = useState(0);
  const messagesEndRef = useRef<HTMLDivElement>(null);

  const scrollToBottom = () => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  };

  useEffect(() => {
    scrollToBottom();
  }, [messages]);

  const handleSend = async (message: string) => {
    // Add user message
    const userMessage: ChatMessage = {
      role: 'user',
      content: message,
      timestamp: new Date().toISOString(),
    };
    setMessages((prev) => [...prev, userMessage]);
    setIsLoading(true);

    try {
      // Capture DOM snapshot
      const snapshot = onCaptureSnapshot();
      if (snapshot) {
        setVisibleCount(snapshot.visible_products.length);
      }

      // Send to API
      const response = await apiClient.sendChatMessage(message, snapshot, sessionId || undefined);

      // Add assistant message
      const assistantMessage: ChatMessage = {
        role: 'assistant',
        content: response.response,
        timestamp: response.timestamp,
      };
      setMessages((prev) => [...prev, assistantMessage]);

      // Store session ID
      if (!sessionId) {
        setSessionId(response.session_id);
      }
    } catch (error) {
      const errorMessage: ChatMessage = {
        role: 'assistant',
        content: 'Sorry, I encountered an error. Please try again.',
        timestamp: new Date().toISOString(),
      };
      setMessages((prev) => [...prev, errorMessage]);
      console.error('Chat error:', error);
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <div className={`${styles.chatWidget} ${isMinimized ? styles.minimized : ''}`}>
      <div className={styles.chatHeader} onClick={() => setIsMinimized(!isMinimized)}>
        <h3>Shopping Assistant</h3>
        <div className={styles.chatControls}>
          <button className={styles.chatControlBtn} aria-label={isMinimized ? 'Maximize' : 'Minimize'}>
            {isMinimized ? '▲' : '▼'}
          </button>
        </div>
      </div>

      {!isMinimized && (
        <>
          {visibleCount > 0 && (
            <div className={styles.contextIndicator}>
              📍 Seeing {visibleCount} product{visibleCount !== 1 ? 's' : ''}
            </div>
          )}

          <div className={styles.chatMessages}>
            {messages.length === 0 && (
              <div className={`${styles.chatMessage} ${styles.assistant}`}>
                <div className={styles.messageBubble}>
                  Hi! I'm here to help you find the perfect shoes. I can see what products are visible on your screen
                  and provide personalized recommendations.
                </div>
              </div>
            )}

            {messages.map((msg, idx) => (
              <ChatMessageComponent key={idx} message={msg} />
            ))}

            {isLoading && (
              <div className={`${styles.chatMessage} ${styles.assistant}`}>
                <div className={styles.messageBubble}>
                  <div className={styles.typingIndicator}>
                    <div className={styles.typingDot}></div>
                    <div className={styles.typingDot}></div>
                    <div className={styles.typingDot}></div>
                  </div>
                </div>
              </div>
            )}

            <div ref={messagesEndRef} />
          </div>

          <ChatComposer onSend={handleSend} disabled={isLoading} />
        </>
      )}
    </div>
  );
};
