const express = require('express');
const router = express.Router();
const products = require('../data/products.json');

/**
 * GET /api/products
 * Get filtered product list based on query parameters
 */
router.get('/', (req, res) => {
  try {
    let filteredProducts = [...products];

    // Filter by category
    if (req.query.category) {
      const categories = req.query.category.split(',');
      filteredProducts = filteredProducts.filter(p => 
        categories.includes(p.category)
      );
    }

    // Filter by customer type (B2B/B2C)
    if (req.query.customer_type) {
      const isB2B = req.query.customer_type === 'b2b';
      filteredProducts = filteredProducts.filter(p => 
        isB2B ? p.b2b_available : p.b2c_available
      );
    }

    // Filter by price range
    if (req.query.min_price) {
      filteredProducts = filteredProducts.filter(p => 
        p.price >= parseFloat(req.query.min_price)
      );
    }
    if (req.query.max_price) {
      filteredProducts = filteredProducts.filter(p => 
        p.price <= parseFloat(req.query.max_price)
      );
    }

    // Filter by discount
    if (req.query.has_discount === 'true') {
      filteredProducts = filteredProducts.filter(p => p.discount > 0);
    } else if (req.query.has_discount === 'false') {
      filteredProducts = filteredProducts.filter(p => p.discount === 0);
    }

    // Filter by minimum discount percentage
    if (req.query.min_discount) {
      filteredProducts = filteredProducts.filter(p => 
        p.discount >= parseFloat(req.query.min_discount)
      );
    }

    // Filter by stock availability
    if (req.query.in_stock === 'true') {
      filteredProducts = filteredProducts.filter(p => p.in_stock);
    } else if (req.query.in_stock === 'false') {
      filteredProducts = filteredProducts.filter(p => !p.in_stock);
    }

    // Search by name
    if (req.query.search) {
      const searchTerm = req.query.search.toLowerCase();
      filteredProducts = filteredProducts.filter(p =>
        p.name.toLowerCase().includes(searchTerm) ||
        p.description.toLowerCase().includes(searchTerm)
      );
    }

    res.json({
      count: filteredProducts.length,
      products: filteredProducts
    });
  } catch (error) {
    console.error('Error fetching products:', error.message);
    res.status(500).json({ error: 'Failed to fetch products' });
  }
});

/**
 * GET /api/products/:id
 * Get a single product by ID
 */
router.get('/:id', (req, res) => {
  try {
    const product = products.find(p => p.id === req.params.id);
    
    if (!product) {
      return res.status(404).json({ error: 'Product not found' });
    }

    res.json(product);
  } catch (error) {
    console.error('Error fetching product:', error.message);
    res.status(500).json({ error: 'Failed to fetch product' });
  }
});

module.exports = router;
