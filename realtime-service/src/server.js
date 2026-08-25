const express = require('express');
const http = require('http');
const cors = require('cors');
require('dotenv').config();

const { validateRuntimeConfig } = require('./config');
const { initSocket, closeSocket, getSocketConnectionsCount, getAllowedOrigins } = require('./socket/socketHandler');
const { initWhatsApp, getWhatsAppStatus, shutdownWhatsApp } = require('./whatsapp/waGateway');
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
    let shutdownOperation;
    const shutdown = (signal) => shutdownOperation ??= (async () => {
        console.log(`Realtime service received ${signal}; shutting down`);
        const forceExit = setTimeout(() => process.exit(1), 5000);
        forceExit.unref();
        await Promise.allSettled([closeSocket(), shutdownWhatsApp()]);
        if (server.listening) {
            await new Promise((resolve) => server.close(resolve));
        }
        clearTimeout(forceExit);
        process.exit(0);
    })();
    process.once('SIGTERM', () => shutdown('SIGTERM'));
    process.once('SIGINT', () => shutdown('SIGINT'));

    const port = validation.config.port;
    server.once('error', (error) => {
        if (error.code === 'EADDRINUSE') {
            console.error(`Realtime Service cannot start: port ${port} is already in use.`);
        } else {
            console.error('Realtime Service failed to start:', error.message);
        }
        process.exitCode = 1;
        void closeSocket();
    });
    server.listen(port, () => {
        console.log(`Realtime Service is running on port ${port}`);
        Promise.resolve(initWhatsApp()).catch((error) => {
            console.error('WhatsApp gateway startup failed:', error.message);
        });
    });
    return server;
}

if (require.main === module) startServer();

module.exports = { createApp, startServer };
