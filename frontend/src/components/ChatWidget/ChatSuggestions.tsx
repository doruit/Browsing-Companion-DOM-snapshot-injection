import React, { useState, useEffect } from 'react';
import styles from './ChatSuggestions.module.css';

interface Suggestion {
  category: string;
  text: string;
  icon: string;
}

interface ChatSuggestionsProps {
  onSuggestionClick: (text: string) => void;
}

export const ChatSuggestions: React.FC<ChatSuggestionsProps> = ({ onSuggestionClick }) => {
  const [allSuggestions, setAllSuggestions] = useState<Suggestion[]>([]);
  const [currentSuggestions, setCurrentSuggestions] = useState<Suggestion[]>([]);

  // Load suggestions from JSON
  useEffect(() => {
    fetch('/chat-suggestions.json')
      .then(res => res.json())
      .then(data => {
        setAllSuggestions(data.suggestions);
        // Set initial 3 random suggestions
        setCurrentSuggestions(getRandomSuggestions(data.suggestions, 3));
      })
      .catch(err => console.error('Error loading suggestions:', err));
  }, []);

  // Rotate suggestions every 10 seconds
  useEffect(() => {
    if (allSuggestions.length === 0) return;

    const interval = setInterval(() => {
      setCurrentSuggestions(getRandomSuggestions(allSuggestions, 3));
    }, 10000);

    return () => clearInterval(interval);
  }, [allSuggestions]);

  const getRandomSuggestions = (suggestions: Suggestion[], count: number): Suggestion[] => {
    const shuffled = [...suggestions].sort(() => Math.random() - 0.5);
    return shuffled.slice(0, count);
  };

  return (
    <div className={styles['suggestions-container']}>
      <div className={styles['suggestions-header']}>💡 Try asking:</div>
      <div className={styles['suggestions-list']}>
        {currentSuggestions.map((suggestion, index) => (
          <button
            key={`${suggestion.text}-${index}`}
            className={styles['suggestion-button']}
            onClick={() => onSuggestionClick(suggestion.text)}
          >
            <span className={styles['suggestion-icon']}>{suggestion.icon}</span>
            <span className={styles['suggestion-text']}>{suggestion.text}</span>
          </button>
        ))}
      </div>
    </div>
  );
};
