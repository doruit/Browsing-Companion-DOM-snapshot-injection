const express = require('express');
const axios = require('axios');
const router = express.Router();

const AI_SERVICE_URL = process.env.AI_SERVICE_URL || 'http://localhost:8000';

/**
 * POST /api/chat
 * Process chat message with optional DOM snapshot
 */
router.post('/', async (req, res) => {
  try {
    const { message, dom_snapshot, session_id } = req.body;
    const userId = req.user.userId;

    if (!message) {
      return res.status(400).json({ error: 'Message is required' });
    }

    // Forward request to Python AI service
    const response = await axios.post(`${AI_SERVICE_URL}/process-chat`, {
      user_id: userId,
      message: message,
      dom_snapshot: dom_snapshot || null,
      session_id: session_id || null
    });

    res.json(response.data);
  } catch (error) {
    console.error('Error processing chat:', error.message);
    
    if (error.response) {
      res.status(error.response.status).json({
        error: error.response.data.detail || 'Error processing chat'
      });
    } else {
      res.status(500).json({ error: 'Failed to communicate with AI service' });
    }
  }
});

/**
 * GET /api/chat/history/:sessionId
 * Get chat history for a session
 */
router.get('/history/:sessionId', async (req, res) => {
  try {
    const { sessionId } = req.params;
    
    // This would query Cosmos DB for conversation history
    // For now, return a placeholder
    res.json({
      session_id: sessionId,
      messages: [],
      message: 'Chat history retrieval not yet implemented'
    });
  } catch (error) {
    console.error('Error fetching chat history:', error.message);
    res.status(500).json({ error: 'Failed to fetch chat history' });
  }
});

module.exports = router;
