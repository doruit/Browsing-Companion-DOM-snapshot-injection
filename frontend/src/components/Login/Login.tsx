import React, { useState, FormEvent } from 'react';
import { useNavigate } from 'react-router-dom';
import styles from './Login.module.css';
import { apiClient } from '../../utils/api';

export const Login: React.FC = () => {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);
  const navigate = useNavigate();

  const handleSubmit = async (e: FormEvent) => {
    e.preventDefault();
    setError('');
    setLoading(true);

    try {
      const response = await apiClient.login(email, password);
      localStorage.setItem('user', JSON.stringify(response.user));
      navigate('/shop');
    } catch (err: any) {
      setError(err.message || 'Login failed. Please check your credentials.');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className={styles['login-container']}>
      <div className={styles['login-card']}>
        <h1 className={styles['login-title']}>👟 Shoe Shop Login</h1>

        <form className={styles['login-form']} onSubmit={handleSubmit}>
          {error && <div className={styles['error-message']}>{error}</div>}

          <div className={styles['form-group']}>
            <label htmlFor="email" className={styles['form-label']}>
              Email
            </label>
            <input
              id="email"
              type="email"
              className={styles['form-input']}
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              required
              disabled={loading}
            />
          </div>

          <div className={styles['form-group']}>
            <label htmlFor="password" className={styles['form-label']}>
              Password
            </label>
            <input
              id="password"
              type="password"
              className={styles['form-input']}
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              required
              disabled={loading}
            />
          </div>

          <button type="submit" className={styles['submit-button']} disabled={loading}>
            {loading ? 'Logging in...' : 'Login'}
          </button>
        </form>

        <div className={styles['demo-credentials']}>
          <h4>Demo Accounts:</h4>
          <ul>
            <li>
              Retail Customer: <code>user1@example.com</code> / <code>password1</code>
            </li>
            <li>
              Retail Customer: <code>user2@example.com</code> / <code>password2</code>
            </li>
            <li>
              Business Customer: <code>b2b@company.com</code> / <code>b2bpass</code>
            </li>
          </ul>
        </div>
      </div>
    </div>
  );
};
