import React from 'react';
import { useNavigate } from 'react-router-dom';
import styles from './Navbar.module.css';
import { apiClient } from '../../utils/api';

export const Navbar: React.FC = () => {
  const navigate = useNavigate();
  const userJson = localStorage.getItem('user');
  const user = userJson ? JSON.parse(userJson) : null;

  const handleLogout = () => {
    apiClient.clearToken();
    localStorage.removeItem('user');
    navigate('/');
  };

  return (
    <nav className={styles.navbar}>
      <div className={styles['navbar-brand']}>
        👟 Shoe Shop
      </div>
      <div className={styles['navbar-actions']}>
        {user && <span className={styles['user-info']}>Welcome, {user.name}</span>}
        <button className={styles['navbar-button']} onClick={handleLogout}>
          Logout
        </button>
      </div>
    </nav>
  );
};
