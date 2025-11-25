const express = require('express');
const axios = require('axios');
const router = express.Router();

const AI_SERVICE_URL = process.env.AI_SERVICE_URL || 'http://localhost:8000';

/**
 * GET /api/preferences
 * Get user preferences
 */
router.get('/', async (req, res) => {
  try {
    const userId = req.user.userId;

    const response = await axios.get(`${AI_SERVICE_URL}/preferences/${userId}`);
    res.json(response.data);
  } catch (error) {
    console.error('Error fetching preferences:', error.message);
    
    if (error.response) {
      res.status(error.response.status).json({
        error: error.response.data.detail || 'Error fetching preferences'
      });
    } else {
      res.status(500).json({ error: 'Failed to communicate with AI service' });
    }
  }
});

/**
 * POST /api/preferences
 * Update user preferences
 */
router.post('/', async (req, res) => {
  try {
    const userId = req.user.userId;
    const preferences = req.body;

    const response = await axios.post(
      `${AI_SERVICE_URL}/preferences/${userId}`,
      preferences
    );
    
    res.json(response.data);
  } catch (error) {
    console.error('Error updating preferences:', error.message);
    
    if (error.response) {
      res.status(error.response.status).json({
        error: error.response.data.detail || 'Error updating preferences'
      });
    } else {
      res.status(500).json({ error: 'Failed to communicate with AI service' });
    }
  }
});

module.exports = router;
