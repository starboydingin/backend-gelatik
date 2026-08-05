const express = require('express');
const http = require('http');
const cors = require('cors');
require('dotenv').config();

const { initSocket, getSocketConnectionsCount, getAllowedOrigins } = require('./socket/socketHandler');
const { initWhatsApp, getWhatsAppStatus } = require('./whatsapp/waGateway');
const internalRoutes = require('./routes/internal');

const app = express();
const server = http.createServer(app);

// Middleware
app.use(cors({
    origin: getAllowedOrigins(),
    credentials: true
}));
app.use(express.json());

// Routes
app.use('/internal', internalRoutes);

app.get('/health', (req, res) => {
    res.json({
        status: 'ok',
        socketConnections: getSocketConnectionsCount(),
        whatsappStatus: getWhatsAppStatus()
    });
});

// Initialize Services
initSocket(server);
initWhatsApp();

const PORT = process.env.PORT || 4000;
server.listen(PORT, () => {
    console.log(`Realtime Service is running on port ${PORT}`);
});
