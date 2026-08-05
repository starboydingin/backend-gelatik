const { Server } = require('socket.io');
const axios = require('axios');
require('dotenv').config();

let io;

const getAllowedOrigins = () => {
    if (process.env.SOCKET_CORS_ORIGINS) {
        const origins = process.env.SOCKET_CORS_ORIGINS.split(',').map(o => o.trim()).filter(Boolean);
        if (origins.length > 0) return origins;
    }
    // Fallback aman jika env tidak diset (hanya localhost, TANPA wildcard '*')
    return ['http://localhost:8000', 'http://localhost:3000'];
};

const initSocket = (server) => {
    const allowedOrigins = getAllowedOrigins();
    io = new Server(server, {
        cors: {
            origin: allowedOrigins,
            credentials: true,
            methods: ["GET", "POST"]
        }
    });

    io.on('connection', async (socket) => {
        const token = socket.handshake.auth.token;
        if (!token) {
            console.log('Socket disconnected: No token provided');
            return socket.disconnect();
        }

        try {
            // Validasi token ke Laravel
            const response = await axios.get(`${process.env.LARAVEL_BASE_URL}/api/me`, {
                headers: {
                    Authorization: `Bearer ${token}`
                }
            });

            const userId = response.data.id || response.data.user?.id; // Sesuaikan dengan struktur response Laravel
            if (userId) {
                const roomName = `user_${userId}`;
                socket.join(roomName);
                console.log(`User ${userId} joined room ${roomName}`);
            } else {
                console.log('Socket disconnected: User ID not found in response');
                socket.disconnect();
            }

        } catch (error) {
            console.log('Socket disconnected: Invalid token', error.message);
            socket.disconnect();
        }

        socket.on('disconnect', () => {
            console.log('User disconnected', socket.id);
        });
    });
};

const broadcastToUser = (userId, eventName, payload) => {
    if (io) {
        io.to(`user_${userId}`).emit(eventName, payload);
        console.log(`Broadcast to user_${userId}: ${eventName}`);
    }
};

const broadcastToAll = (eventName, payload) => {
    if (io) {
        io.emit(eventName, payload);
        console.log(`Broadcast to all: ${eventName}`);
    }
};

const getSocketConnectionsCount = () => {
    if (io) {
        return io.engine.clientsCount;
    }
    return 0;
};

module.exports = {
    initSocket,
    broadcastToUser,
    broadcastToAll,
    getSocketConnectionsCount,
    getAllowedOrigins
};
