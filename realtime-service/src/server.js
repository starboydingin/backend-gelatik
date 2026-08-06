const express = require('express');
const http = require('http');
const cors = require('cors');
require('dotenv').config();

const { validateRuntimeConfig } = require('./config');
const { initSocket, getSocketConnectionsCount, getAllowedOrigins } = require('./socket/socketHandler');
const { initWhatsApp, getWhatsAppStatus } = require('./whatsapp/waGateway');
const internalRoutes = require('./routes/internal');

function createApp() {
    const app = express();
    app.use(cors({ origin: getAllowedOrigins(), credentials: true }));
    app.use(express.json({ limit: '100kb' }));
    app.use('/internal', internalRoutes);
    app.get('/health', (_req, res) => res.json({
        status: 'ok',
        socketConnections: getSocketConnectionsCount(),
        whatsappStatus: getWhatsAppStatus(),
    }));
    return app;
}

function startServer() {
    const validation = validateRuntimeConfig();
    if (!validation.ok) {
        throw new Error(`Invalid realtime configuration: ${validation.errors.join('; ')}`);
    }

    const app = createApp();
    const server = http.createServer(app);
    initSocket(server);
    Promise.resolve(initWhatsApp()).catch((error) => {
        console.error('WhatsApp gateway startup failed:', error.message);
    });

    const shutdown = (signal) => {
        console.log(`Realtime service received ${signal}; shutting down`);
        server.close(() => process.exit(0));
    };
    process.once('SIGTERM', () => shutdown('SIGTERM'));
    process.once('SIGINT', () => shutdown('SIGINT'));

    const port = validation.config.port;
    server.listen(port, () => console.log(`Realtime Service is running on port ${port}`));
    return server;
}

if (require.main === module) startServer();

module.exports = { createApp, startServer };
