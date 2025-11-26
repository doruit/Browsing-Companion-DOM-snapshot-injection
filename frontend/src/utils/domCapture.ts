import { DOMSnapshot, Product } from '../types';

/**
 * Utility class to capture visible DOM elements using Intersection Observer
 */
export class DOMCaptureService {
  private visibleProducts: Set<string> = new Set();
  private observer: IntersectionObserver | null = null;
  private products: Product[] = [];

  constructor() {
    this.setupObserver();
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
            } else {
              this.visibleProducts.delete(productId);
            }
          }
        });
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
    
    productElements.forEach((element) => {
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
  }

  /**
   * Capture snapshot of currently visible products
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

    return {
      visible_products: visibleProductData,
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
