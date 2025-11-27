import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import styles from './Navbar.module.css';
import { apiClient } from '../../utils/api';
import { Search, ShoppingBag, Heart, User, Menu, X } from 'lucide-react';

export const Navbar: React.FC = () => {
  const navigate = useNavigate();
  const userJson = localStorage.getItem('user');
  const user = userJson ? JSON.parse(userJson) : null;
  const [searchQuery, setSearchQuery] = useState('');
  const [mobileMenuOpen, setMobileMenuOpen] = useState(false);

  const handleLogout = () => {
    apiClient.clearToken();
    localStorage.removeItem('user');
    navigate('/');
  };

  return (
    <header className={styles.header}>
      {/* Top bar with promo */}
      <div className={styles.topBar}>
        <span>🚚 Free shipping on orders over $100 | 🔄 30-day easy returns</span>
      </div>
      
      {/* Main navbar */}
      <nav className={styles.navbar}>
        <div className={styles.navbarLeft}>
          <button 
            className={styles.mobileMenuBtn}
            onClick={() => setMobileMenuOpen(!mobileMenuOpen)}
          >
            {mobileMenuOpen ? <X size={24} /> : <Menu size={24} />}
          </button>
          
          <div className={styles.navbarBrand}>
            <span className={styles.brandIcon}>👟</span>
            <div className={styles.brandText}>
              <span className={styles.brandName}>STRIDE</span>
              <span className={styles.brandTagline}>Footwear Co.</span>
            </div>
          </div>
        </div>

        <div className={`${styles.navLinks} ${mobileMenuOpen ? styles.mobileOpen : ''}`}>
          <a href="#" className={`${styles.navLink} ${styles.active}`}>New Arrivals</a>
          <a href="#" className={styles.navLink}>Men</a>
          <a href="#" className={styles.navLink}>Women</a>
          <a href="#" className={styles.navLink}>Kids</a>
          <a href="#" className={styles.navLink}>Sale</a>
        </div>

        <div className={styles.navbarRight}>
          <div className={styles.searchContainer}>
            <Search size={18} className={styles.searchIcon} />
            <input 
              type="text" 
              placeholder="Search shoes..." 
              className={styles.searchInput}
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
            />
          </div>
          
          <div className={styles.navbarActions}>
            <button className={styles.iconButton} title="Wishlist">
              <Heart size={20} />
              <span className={styles.badge}>3</span>
            </button>
            <button className={styles.iconButton} title="Cart">
              <ShoppingBag size={20} />
              <span className={styles.badge}>2</span>
            </button>
            <div className={styles.userDropdown}>
              <button className={styles.iconButton} title="Account">
                <User size={20} />
              </button>
              <div className={styles.dropdownMenu}>
                {user && <span className={styles.userName}>{user.name}</span>}
                <button onClick={handleLogout} className={styles.logoutBtn}>
                  Sign Out
                </button>
              </div>
            </div>
          </div>
        </div>
      </nav>
    </header>
  );
};
