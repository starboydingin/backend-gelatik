const express = require('express');
const axios = require('axios');
const validateApiKey = require('../middleware/validateApiKey');
const {
    broadcastToRole,
    broadcastToUser,
    broadcastToAll,
} = require('../socket/socketHandler');
const { normalizePayload } = require('../realtime/eventSchema');
const { sendWhatsAppMessage } = require('../whatsapp/waGateway');
require('dotenv').config();

const router = express.Router();
router.use(validateApiKey);

router.post('/broadcast', (req, res) => {
    const { target, user_id: userId, role, event, payload } = req.body || {};

    if (typeof event !== 'string' || !event.trim()) {
        return res.status(400).json({ error: 'Event name is required' });
    }

    let normalizedPayload;
    try {
        normalizedPayload = normalizePayload(event, payload);
    } catch (error) {
        return res.status(400).json({ error: error.message });
    }

    if (target === 'user') {
        if (!Number.isInteger(Number(userId)) || Number(userId) <= 0) {
            return res.status(400).json({ error: 'user_id must be a positive integer' });
        }
        broadcastToUser(Number(userId), event, normalizedPayload);
    } else if (target === 'role') {
        if (role !== 'admin') {
            return res.status(400).json({ error: 'Only the admin role target is supported' });
        }
        broadcastToRole(role, event, normalizedPayload);
    } else if (target === 'all') {
        // Kept for existing non-personal announcement integrations.
        broadcastToAll(event, normalizedPayload);
    } else {
        return res.status(400).json({ error: 'Invalid target type' });
    }

    return res.json({ success: true, message: 'Broadcast sent' });
});

router.post('/wa/send', async (req, res) => {
    const { nomor_wa, message, reference, delivery_key: deliveryKey } = req.body || {};

    if (!nomor_wa || !message) {
        return res.status(400).json({ error: 'nomor_wa and message are required' });
    }

    const result = await sendWhatsAppMessage(nomor_wa, message, deliveryKey);
    // Do not await the Laravel callback. The local `php artisan serve` process
    // may itself be waiting for this response after sending the admin reply;
    // awaiting the callback here would deadlock the single-process server.
    void axios.post(`${process.env.LARAVEL_BASE_URL}/api/internal/wa/webhook-delivery-status`, {
            status: result.status,
            error: result.error,
            reference,
        }, {
            headers: { Authorization: `Bearer ${process.env.INTERNAL_SERVICE_API_KEY}` },
            timeout: 5000,
        }).catch((err) => {
            console.error('Failed to send webhook status to Laravel:', err.message);
        });

    if (result.status !== 'delivered') {
        return res.status(503).json({ success: false, error: 'WhatsApp delivery failed' });
    }

    return res.json({ success: true, status: result.status, delivery_key: deliveryKey });
});

module.exports = router;
