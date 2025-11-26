import React from 'react';
import ReactMarkdown from 'react-markdown';
import remarkGfm from 'remark-gfm';
import styles from './ChatWidget.module.css';
import { ChatMessage } from '../../types';

interface ChatMessageProps {
  message: ChatMessage;
  onProductClick?: (productId: string) => void;
  productMap?: Map<string, string>; // Map of product name -> product id
}

export const ChatMessageComponent: React.FC<ChatMessageProps> = ({ message, onProductClick, productMap }) => {
  const formatTime = (timestamp: string) => {
    const date = new Date(timestamp);
    return date.toLocaleTimeString('en-US', { hour: '2-digit', minute: '2-digit' });
  };

  // Find product ID by matching product name (case-insensitive partial match)
  const findProductId = (text: string): string | null => {
    if (!productMap) return null;
    const lowerText = text.toLowerCase().trim();
    for (const [name, id] of productMap.entries()) {
      if (lowerText.includes(name.toLowerCase()) || name.toLowerCase().includes(lowerText)) {
        return id;
      }
    }
    return null;
  };

  const components = {
    // Make links clickable for product references
    a: ({ node, href, children, ...props }: any) => {
      if (href && href.startsWith('#') && onProductClick) {
        const productId = href.substring(1);
        return (
          <a
            href={href}
            onClick={(e) => {
              e.preventDefault();
              onProductClick(productId);
            }}
            className={styles['product-link']}
            {...props}
          >
            {children}
          </a>
        );
      }
      return <a href={href} {...props}>{children}</a>;
    },
    // Make bold product names clickable
    strong: ({ node, children, ...props }: any) => {
      const text = React.Children.toArray(children).join('');
      const productId = findProductId(text);
      
      if (productId && onProductClick) {
        return (
          <strong
            onClick={() => onProductClick(productId)}
            className={styles['product-link']}
            {...props}
          >
            {children}
          </strong>
        );
      }
      return <strong {...props}>{children}</strong>;
    },
  };

  return (
    <div className={`${styles['chat-message']} ${styles[message.role]}`}>
      <div className={styles['message-bubble']}>
        <ReactMarkdown remarkPlugins={[remarkGfm]} components={components}>
          {message.content}
        </ReactMarkdown>
      </div>
      <div className={styles['message-time']}>{formatTime(message.timestamp)}</div>
    </div>
  );
};
