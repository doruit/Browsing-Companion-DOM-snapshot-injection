import { DOMSnapshot, Product } from '../types';

/**
 * Utility class to capture visible DOM elements using Intersection Observer
 */
export class DOMCaptureService {
  private visibleProducts: Set<string> = new Set();
  private belowFoldProducts: Set<string> = new Set();
  private observer: IntersectionObserver | null = null;
  private products: Product[] = [];
  private productElements: Map<string, HTMLElement> = new Map();
  private onVisibilityChange?: (visibleCount: number) => void;

  constructor() {
    this.setupObserver();
  }

  /**
   * Set callback for visibility changes
   */
  setOnVisibilityChange(callback: (visibleCount: number) => void) {
    this.onVisibilityChange = callback;
  }

  /**
   * Initialize Intersection Observer to track visible product cards
   */
  private setupObserver() {
    this.observer = new IntersectionObserver(
      (entries) => {
        entries.forEach((entry) => {
          const productId = entry.target.getAttribute('data-product-id');
          if (productId) {
            if (entry.isIntersecting) {
              this.visibleProducts.add(productId);
              this.belowFoldProducts.delete(productId);
            } else {
              this.visibleProducts.delete(productId);
              // Check if product is below the viewport
              const rect = entry.target.getBoundingClientRect();
              if (rect.top > window.innerHeight) {
                this.belowFoldProducts.add(productId);
              }
            }
          }
        });
        
        // Notify about visibility changes
        if (this.onVisibilityChange) {
          this.onVisibilityChange(this.visibleProducts.size);
        }
      },
      {
        root: null, // viewport
        rootMargin: '0px',
        threshold: 0.5, // 50% visible
      }
    );
  }

  /**
   * Start observing product elements
   */
  observeProducts(productElements: HTMLElement[], products: Product[]) {
    this.products = products;
    this.productElements.clear();
    this.belowFoldProducts.clear();
    
    productElements.forEach((element) => {
      const productId = element.getAttribute('data-product-id');
      if (productId) {
        this.productElements.set(productId, element);
        
        // Initially categorize products based on their position
        const rect = element.getBoundingClientRect();
        if (rect.top > window.innerHeight) {
          this.belowFoldProducts.add(productId);
        }
      }
      
      if (this.observer) {
        this.observer.observe(element);
      }
    });
  }

  /**
   * Stop observing all elements
   */
  disconnect() {
    if (this.observer) {
      this.observer.disconnect();
    }
    this.visibleProducts.clear();
    this.belowFoldProducts.clear();
    this.productElements.clear();
  }

  /**
   * Capture snapshot of currently visible products and products below the fold
   */
  captureSnapshot(): DOMSnapshot {
    const visibleProductData = this.products
      .filter((product) => this.visibleProducts.has(product.id))
      .map((product) => ({
        id: product.id,
        name: product.name,
        category: product.category,
        price: product.price,
        discount: product.discount,
        description: product.description,
        visible: true,
      }));

    const belowFoldProductData = this.products
      .filter((product) => this.belowFoldProducts.has(product.id))
      .map((product) => ({
        id: product.id,
        name: product.name,
        category: product.category,
        price: product.price,
        discount: product.discount,
        description: product.description,
        visible: false,
      }));

    return {
      visible_products: visibleProductData,
      below_fold_products: belowFoldProductData,
      page_url: window.location.href,
      timestamp: Date.now(),
    };
  }

  /**
   * Get count of visible products
   */
  getVisibleCount(): number {
    return this.visibleProducts.size;
  }
}
