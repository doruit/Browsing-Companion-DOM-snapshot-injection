import React, { useState, useEffect, useRef } from 'react';
import styles from './ProductGrid.module.css';
import { Product, ProductFilters } from '../../types';
import { apiClient } from '../../utils/api';
import FilterBar from './FilterBar';

interface ProductGridProps {
  onProductElementsChange: (elements: HTMLElement[], products: Product[]) => void;
  externalFilters?: Partial<ProductFilters>;
}

// Array of curated shoe images from Unsplash
const SHOE_IMAGES = [
  'https://images.unsplash.com/photo-1542291026-7eec264c27ff?w=400&h=300&fit=crop&q=80', // Nike sneakers
  'https://images.unsplash.com/photo-1549298916-b41d501d3772?w=400&h=300&fit=crop&q=80', // Red sneakers
  'https://images.unsplash.com/photo-1460353581641-37baddab0fa2?w=400&h=300&fit=crop&q=80', // Black sneakers
  'https://images.unsplash.com/photo-1595950653106-6c9ebd614d3a?w=400&h=300&fit=crop&q=80', // White sneakers
  'https://images.unsplash.com/photo-1551107696-a4b0c5a0d9a2?w=400&h=300&fit=crop&q=80', // Running shoes
  'https://images.unsplash.com/photo-1539185441755-769473a23570?w=400&h=300&fit=crop&q=80', // Leather shoes
  'https://images.unsplash.com/photo-1533867617858-e7b97e060509?w=400&h=300&fit=crop&q=80', // Casual shoes
  'https://images.unsplash.com/photo-1525966222134-fcfa99b8ae77?w=400&h=300&fit=crop&q=80', // Boots
];

export const ProductGrid: React.FC<ProductGridProps> = ({ onProductElementsChange, externalFilters }) => {
  const [products, setProducts] = useState<Product[]>([]);
  const [loading, setLoading] = useState(true);
  const [searchQuery, setSearchQuery] = useState('');
  const [filters, setFilters] = useState<ProductFilters>({
    category: '',
    minPrice: null,
    maxPrice: null,
    hasDiscount: null,
    minDiscount: null,
    customerType: 'all',
    inStock: null
  });
  const productRefs = useRef<Map<string, HTMLDivElement>>(new Map());

  // Merge external filters (from chatbot) with local filters
  useEffect(() => {
    if (externalFilters) {
      setFilters(prev => ({ ...prev, ...externalFilters }));
    }
  }, [externalFilters]);

  useEffect(() => {
    loadProducts();
  }, [filters]);

  useEffect(() => {
    // Notify parent of product elements for observation
    const elements = Array.from(productRefs.current.values());
    onProductElementsChange(elements, products);
  }, [products, onProductElementsChange]);

  const loadProducts = async () => {
    setLoading(true);
    try {
      const apiFilters: any = {};
      if (filters.category) apiFilters.category = filters.category;
      if (searchQuery) apiFilters.search = searchQuery;
      if (filters.minPrice !== null) apiFilters.min_price = filters.minPrice;
      if (filters.maxPrice !== null) apiFilters.max_price = filters.maxPrice;
      if (filters.hasDiscount !== null) apiFilters.has_discount = filters.hasDiscount;
      if (filters.minDiscount !== null) apiFilters.min_discount = filters.minDiscount;
      if (filters.customerType !== 'all') apiFilters.customer_type = filters.customerType;
      if (filters.inStock !== null) apiFilters.in_stock = filters.inStock;

      const response = await apiClient.getProducts(apiFilters);
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

  const handleFiltersChange = (newFilters: ProductFilters) => {
    setFilters(newFilters);
  };

  const categories = ['formal', 'athletic', 'casual', 'outdoor', 'work'];

  if (loading) {
    return <div className={styles.loading}>Loading products...</div>;
  }

  return (
    <>
      <div className={styles.filters}>
        <div className={styles['filter-group']}>
          <label className={styles['filter-label']}>Category:</label>
          <select
            className={styles['filter-select']}
            value={filters.category}
            onChange={(e) => setFilters({ ...filters, category: e.target.value })}
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
          className={styles['search-input']}
          placeholder="Search shoes..."
          value={searchQuery}
          onChange={(e) => setSearchQuery(e.target.value)}
          onKeyPress={(e) => e.key === 'Enter' && handleSearch()}
        />

        <button onClick={handleSearch} style={{ padding: '8px 16px', cursor: 'pointer' }}>
          Search
        </button>
      </div>

      <FilterBar filters={filters} onFiltersChange={handleFiltersChange} />

      <div className={styles['product-grid']}>
        {products.map((product) => (
          <div
            key={product.id}
            className={styles['product-card']}
            data-product-id={product.id}
            ref={(el) => {
              if (el) productRefs.current.set(product.id, el);
            }}
          >
            <div className={styles['product-image']}>
              <img 
                src={SHOE_IMAGES[parseInt(product.id.replace('shoe-', '')) % SHOE_IMAGES.length]} 
                alt={product.name}
                style={{ width: '100%', height: '100%', objectFit: 'cover' }}
                onError={(e) => {
                  const target = e.target as HTMLImageElement;
                  target.style.display = 'none';
                  target.parentElement!.style.fontSize = '48px';
                  target.parentElement!.textContent = '👟';
                }}
              />
              {product.discount > 0 && <div className={styles['product-discount']}>-{product.discount}%</div>}
            </div>
            <div className={styles['product-info']}>
              <div className={styles['product-category']}>{product.category}</div>
              <h3 className={styles['product-name']}>{product.name}</h3>
              <p className={styles['product-description']}>{product.description}</p>
              <div className={styles['product-footer']}>
                <div className={styles['product-price']}>${product.price.toFixed(2)}</div>
                <div className={styles['product-badges']}>
                  {product.b2b_available && <span className={`${styles.badge} ${styles['badge-b2b']}`}>B2B</span>}
                  {product.b2c_available && <span className={`${styles.badge} ${styles['badge-b2c']}`}>B2C</span>}
                  {product.in_stock ? (
                    <span className={`${styles.badge} ${styles['badge-stock']}`}>In Stock</span>
                  ) : (
                    <span className={`${styles.badge} ${styles['badge-out']}`}>Out</span>
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
