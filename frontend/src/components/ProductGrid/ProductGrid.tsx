import React, { useState, useEffect, useRef } from 'react';
import styles from './ProductGrid.module.css';
import { Product } from '../../types';
import { apiClient } from '../../utils/api';

interface ProductGridProps {
  onProductElementsChange: (elements: HTMLElement[], products: Product[]) => void;
}

export const ProductGrid: React.FC<ProductGridProps> = ({ onProductElementsChange }) => {
  const [products, setProducts] = useState<Product[]>([]);
  const [loading, setLoading] = useState(true);
  const [categoryFilter, setCategoryFilter] = useState('');
  const [searchQuery, setSearchQuery] = useState('');
  const productRefs = useRef<Map<string, HTMLDivElement>>(new Map());

  useEffect(() => {
    loadProducts();
  }, [categoryFilter]);

  useEffect(() => {
    // Notify parent of product elements for observation
    const elements = Array.from(productRefs.current.values());
    onProductElementsChange(elements, products);
  }, [products, onProductElementsChange]);

  const loadProducts = async () => {
    setLoading(true);
    try {
      const filters: any = {};
      if (categoryFilter) filters.category = categoryFilter;
      if (searchQuery) filters.search = searchQuery;

      const response = await apiClient.getProducts(filters);
      setProducts(response.products);
    } catch (error) {
      console.error('Error loading products:', error);
    } finally {
      setLoading(false);
    }
  };

  const handleSearch = () => {
    loadProducts();
  };

  const categories = ['formal', 'athletic', 'casual', 'outdoor', 'work'];

  if (loading) {
    return <div className={styles.loading}>Loading products...</div>;
  }

  return (
    <>
      <div className={styles.filters}>
        <div className={styles.filterGroup}>
          <label className={styles.filterLabel}>Category:</label>
          <select
            className={styles.filterSelect}
            value={categoryFilter}
            onChange={(e) => setCategoryFilter(e.target.value)}
          >
            <option value="">All Categories</option>
            {categories.map((cat) => (
              <option key={cat} value={cat}>
                {cat.charAt(0).toUpperCase() + cat.slice(1)}
              </option>
            ))}
          </select>
        </div>

        <input
          type="text"
          className={styles.searchInput}
          placeholder="Search shoes..."
          value={searchQuery}
          onChange={(e) => setSearchQuery(e.target.value)}
          onKeyPress={(e) => e.key === 'Enter' && handleSearch()}
        />

        <button onClick={handleSearch} style={{ padding: '8px 16px', cursor: 'pointer' }}>
          Search
        </button>
      </div>

      <div className={styles.productGrid}>
        {products.map((product) => (
          <div
            key={product.id}
            className={styles.productCard}
            data-product-id={product.id}
            ref={(el) => {
              if (el) productRefs.current.set(product.id, el);
            }}
          >
            <div className={styles.productImage}>
              👟
              {product.discount > 0 && <div className={styles.productDiscount}>-{product.discount}%</div>}
            </div>
            <div className={styles.productInfo}>
              <div className={styles.productCategory}>{product.category}</div>
              <h3 className={styles.productName}>{product.name}</h3>
              <p className={styles.productDescription}>{product.description}</p>
              <div className={styles.productFooter}>
                <div className={styles.productPrice}>${product.price.toFixed(2)}</div>
                <div className={styles.productBadges}>
                  {product.b2b_available && <span className={`${styles.badge} ${styles.badgeB2b}`}>B2B</span>}
                  {product.b2c_available && <span className={`${styles.badge} ${styles.badgeB2c}`}>B2C</span>}
                  {product.in_stock ? (
                    <span className={`${styles.badge} ${styles.badgeStock}`}>In Stock</span>
                  ) : (
                    <span className={`${styles.badge} ${styles.badgeOut}`}>Out</span>
                  )}
                </div>
              </div>
            </div>
          </div>
        ))}
      </div>
    </>
  );
};
