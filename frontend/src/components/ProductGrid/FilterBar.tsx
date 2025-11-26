import React from 'react';
import { ProductFilters } from '../../types';
import styles from './FilterBar.module.css';

interface FilterBarProps {
  filters: ProductFilters;
  onFiltersChange: (filters: ProductFilters) => void;
}

const FilterBar: React.FC<FilterBarProps> = ({ filters, onFiltersChange }) => {
  const handlePriceChange = (type: 'min' | 'max', value: string) => {
    const numValue = value === '' ? null : parseFloat(value);
    onFiltersChange({
      ...filters,
      [type === 'min' ? 'minPrice' : 'maxPrice']: numValue
    });
  };

  const handleDiscountToggle = () => {
    onFiltersChange({
      ...filters,
      hasDiscount: filters.hasDiscount === null ? true : filters.hasDiscount ? false : null
    });
  };

  const handleMinDiscountChange = (value: string) => {
    const numValue = value === '' ? null : parseFloat(value);
    onFiltersChange({
      ...filters,
      minDiscount: numValue
    });
  };

  const handleCustomerTypeChange = (type: 'all' | 'b2b' | 'b2c') => {
    onFiltersChange({
      ...filters,
      customerType: type
    });
  };

  const handleStockToggle = () => {
    onFiltersChange({
      ...filters,
      inStock: filters.inStock === null ? true : filters.inStock ? false : null
    });
  };

  const resetFilters = () => {
    onFiltersChange({
      category: '',
      minPrice: null,
      maxPrice: null,
      hasDiscount: null,
      minDiscount: null,
      customerType: 'all',
      inStock: null
    });
  };

  return (
    <div className={styles['filter-bar']}>
      <div className={styles['filter-section']}>
        <label className={styles['filter-label']}>💰 Price Range</label>
        <div className={styles['price-inputs']}>
          <input
            type="number"
            placeholder="Min"
            value={filters.minPrice ?? ''}
            onChange={(e) => handlePriceChange('min', e.target.value)}
            className={styles['price-input']}
          />
          <span className={styles['price-separator']}>-</span>
          <input
            type="number"
            placeholder="Max"
            value={filters.maxPrice ?? ''}
            onChange={(e) => handlePriceChange('max', e.target.value)}
            className={styles['price-input']}
          />
        </div>
      </div>

      <div className={styles['filter-section']}>
        <label className={styles['filter-label']}>✨ Discount</label>
        <button
          onClick={handleDiscountToggle}
          className={`${styles['toggle-button']} ${
            filters.hasDiscount === true ? styles['active'] : 
            filters.hasDiscount === false ? styles['inactive'] : ''
          }`}
        >
          {filters.hasDiscount === null ? 'All' : filters.hasDiscount ? 'Yes' : 'No'}
        </button>
      </div>

      {filters.hasDiscount === true && (
        <div className={styles['filter-section']}>
          <label className={styles['filter-label']}>📊 Min Discount %</label>
          <input
            type="number"
            placeholder="0"
            min="0"
            max="100"
            value={filters.minDiscount ?? ''}
            onChange={(e) => handleMinDiscountChange(e.target.value)}
            className={styles['discount-input']}
          />
        </div>
      )}

      <div className={styles['filter-section']}>
        <label className={styles['filter-label']}>🏢 Customer Type</label>
        <div className={styles['button-group']}>
          <button
            onClick={() => handleCustomerTypeChange('all')}
            className={`${styles['type-button']} ${filters.customerType === 'all' ? styles['active'] : ''}`}
          >
            All
          </button>
          <button
            onClick={() => handleCustomerTypeChange('b2b')}
            className={`${styles['type-button']} ${filters.customerType === 'b2b' ? styles['active'] : ''}`}
          >
            B2B
          </button>
          <button
            onClick={() => handleCustomerTypeChange('b2c')}
            className={`${styles['type-button']} ${filters.customerType === 'b2c' ? styles['active'] : ''}`}
          >
            B2C
          </button>
        </div>
      </div>

      <div className={styles['filter-section']}>
        <label className={styles['filter-label']}>📦 In Stock</label>
        <button
          onClick={handleStockToggle}
          className={`${styles['toggle-button']} ${
            filters.inStock === true ? styles['active'] : 
            filters.inStock === false ? styles['inactive'] : ''
          }`}
        >
          {filters.inStock === null ? 'All' : filters.inStock ? 'Yes' : 'No'}
        </button>
      </div>

      <button onClick={resetFilters} className={styles['reset-button']}>
        🔄 Reset Filters
      </button>
    </div>
  );
};

export default FilterBar;
