import React, { useState, useEffect, useRef } from 'react';
import styles from './ChatWidget.module.css';
import { ChatMessageComponent } from './ChatMessage';
import { ChatComposer } from './ChatComposer';
import { ChatSuggestions } from './ChatSuggestions';
import { ChatMessage, DOMSnapshot, ProductFilters } from '../../types';
import { apiClient } from '../../utils/api';

interface ChatWidgetProps {
  onCaptureSnapshot: () => DOMSnapshot | null;
  onFiltersUpdate?: (filters: Partial<ProductFilters>) => void;
}

export const ChatWidget: React.FC<ChatWidgetProps> = ({ onCaptureSnapshot, onFiltersUpdate }) => {
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

  const handleSuggestionClick = (suggestionText: string) => {
    handleSend(suggestionText);
  };

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
      console.log('Chat response received:', response);
      console.log('Response content:', response.response);
      console.log('Response type:', typeof response.response);

      // Parse filter updates from response
      if (response.filters && onFiltersUpdate) {
        const filters: Partial<ProductFilters> = {};
        
        if (response.filters.category !== undefined) filters.category = response.filters.category;
        if (response.filters.min_price !== undefined) filters.minPrice = response.filters.min_price;
        if (response.filters.max_price !== undefined) filters.maxPrice = response.filters.max_price;
        if (response.filters.has_discount !== undefined) filters.hasDiscount = response.filters.has_discount;
        if (response.filters.min_discount !== undefined) filters.minDiscount = response.filters.min_discount;
        if (response.filters.customer_type !== undefined) {
          filters.customerType = response.filters.customer_type === 'all' ? 'all' : 
                                 response.filters.customer_type === 'b2b' ? 'b2b' : 'b2c';
        }
        if (response.filters.in_stock !== undefined) filters.inStock = response.filters.in_stock;
        
        onFiltersUpdate(filters);
      }

      // Add assistant message
      const assistantMessage: ChatMessage = {
        role: 'assistant',
        content: response.response || 'I received your message but had trouble generating a response.',
        timestamp: response.timestamp || new Date().toISOString(),
      };
      console.log('Adding assistant message:', assistantMessage);
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
    <div className={`${styles['chat-widget']} ${isMinimized ? styles.minimized : ''}`}>
      <div className={styles['chat-header']} onClick={() => setIsMinimized(!isMinimized)}>
        <h3>Smart Shopping Companion</h3>
        <div className={styles['chat-controls']}>
          <button className={styles['chat-control-btn']} aria-label={isMinimized ? 'Maximize' : 'Minimize'}>
            {isMinimized ? '▲' : '▼'}
          </button>
        </div>
      </div>

      {!isMinimized && (
        <>
          {visibleCount > 0 && (
            <div className={styles['context-indicator']}>
              📍 Seeing {visibleCount} product{visibleCount !== 1 ? 's' : ''}
            </div>
          )}

          <div className={styles['chat-messages']}>
            {messages.length === 0 && (
              <>
                <div className={`${styles['chat-message']} ${styles.assistant}`}>
                  <div className={styles['message-bubble']}>
                    Hi! I'm here to help you find the perfect shoes. I can see what products are visible on your screen
                    and provide personalized recommendations.
                  </div>
                </div>
                <ChatSuggestions onSuggestionClick={handleSuggestionClick} />
              </>
            )}

            {messages.map((msg, idx) => (
              <ChatMessageComponent key={idx} message={msg} />
            ))}

            {isLoading && (
              <div className={`${styles['chat-message']} ${styles.assistant}`}>
                <div className={styles['message-bubble']}>
                  <div className={styles['typing-indicator']}>
                    <div className={styles['typing-dot']}></div>
                    <div className={styles['typing-dot']}></div>
                    <div className={styles['typing-dot']}></div>
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
