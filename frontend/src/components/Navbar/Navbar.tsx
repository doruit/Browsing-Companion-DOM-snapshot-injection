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
      <div className={styles.navbarBrand}>
        👟 Shoe Shop
      </div>
      <div className={styles.navbarActions}>
        {user && <span className={styles.userInfo}>Welcome, {user.name}</span>}
        <button className={styles.navbarButton} onClick={handleLogout}>
          Logout
        </button>
      </div>
    </nav>
  );
};
