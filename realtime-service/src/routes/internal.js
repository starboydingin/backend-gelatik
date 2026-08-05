const express = require('express');
const router = express.Router();
const validateApiKey = require('../middleware/validateApiKey');
const { broadcastToUser, broadcastToAll } = require('../socket/socketHandler');
const { sendWhatsAppMessage } = require('../whatsapp/waGateway');
const axios = require('axios');
require('dotenv').config();

router.use(validateApiKey);

router.post('/broadcast', (req, res) => {
    const { target, user_id, event, payload } = req.body;

    if (!event) {
        return res.status(400).json({ error: 'Event name is required' });
    }

    if (target === 'user') {
        if (!user_id) return res.status(400).json({ error: 'user_id is required for target user' });
        broadcastToUser(user_id, event, payload);
    } else if (target === 'all') {
        broadcastToAll(event, payload);
    } else {
        return res.status(400).json({ error: 'Invalid target type. Use "user" or "all"' });
    }

    res.json({ success: true, message: 'Broadcast sent' });
});

router.post('/wa/send', async (req, res) => {
    const { nomor_wa, message, reference } = req.body;

    if (!nomor_wa || !message) {
        return res.status(400).json({ error: 'nomor_wa and message are required' });
    }

    // Response awal ke Laravel agar tidak menunggu kiriman lama
    res.json({ success: true, message: 'WhatsApp message queued' });

    // Proses pengiriman di background
    const result = await sendWhatsAppMessage(nomor_wa, message);
    
    // Kirim webhook status kembali ke Laravel
    try {
        await axios.post(`${process.env.LARAVEL_BASE_URL}/api/internal/wa/webhook-delivery-status`, {
            status: result.status,
            error: result.error,
            reference: reference
        }, {
            headers: {
                Authorization: `Bearer ${process.env.INTERNAL_SERVICE_API_KEY}`
            }
        });
    } catch (err) {
        console.error('Failed to send webhook status to Laravel:', err.message);
    }
});

module.exports = router;
