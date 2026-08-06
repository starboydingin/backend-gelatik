const { Server } = require('socket.io');
const axios = require('axios');
const { getRuntimeConfig } = require('../config');

let io;
const connectionRegistry = createConnectionRegistry();

function getAllowedOrigins() {
    return getRuntimeConfig().allowedOrigins;
}

function getRole(identity) {
    if (typeof identity?.role === 'string') return identity.role.toLowerCase();
    if (Array.isArray(identity?.roles) && typeof identity.roles[0] === 'string') {
        return identity.roles[0].toLowerCase();
    }
    if (Array.isArray(identity?.roles) && identity.roles[0]?.name) {
        return String(identity.roles[0].name).toLowerCase();
    }
    return 'user';
}

function getRoomsForIdentity(identity) {
    const userId = Number.parseInt(identity?.id, 10);
    if (!Number.isInteger(userId) || userId <= 0) {
        throw new Error('Authenticated identity has no valid user id');
    }

    const rooms = [`user_${userId}`];
    const role = getRole(identity);
    if (role === 'admin') rooms.push('role_admin');
    if (role === 'superadmin') rooms.push('role_superadmin');
    return rooms;
}

function getRoleRooms(target) {
    if (target === 'admin') return ['role_admin', 'role_superadmin'];
    throw new Error('Unsupported role target');
}

function extractToken(socket) {
    const token = socket?.handshake?.auth?.token;
    return typeof token === 'string' && token.trim() ? token.trim() : null;
}

async function verifyLaravelToken(token) {
    const { laravelBaseUrl } = getRuntimeConfig();
    const response = await axios.get(`${laravelBaseUrl}/api/me`, {
        headers: { Authorization: `Bearer ${token}` },
        timeout: 5000,
    });
    const identity = response.data?.data || response.data?.user || response.data;
    if (!identity || !identity.id) throw new Error('Laravel returned no identity');
    if (String(identity.status) === '0') throw new Error('Inactive user');
    return identity;
}

function createAuthMiddleware({ verifyToken = verifyLaravelToken } = {}) {
    return async (socket, next) => {
        const token = extractToken(socket);
        if (!token) return next(new Error('unauthorized'));

        try {
            socket.user = await verifyToken(token);
            socket.authenticatedRooms = getRoomsForIdentity(socket.user);
            return next();
        } catch (_) {
            return next(new Error('unauthorized'));
        }
    };
}

function createConnectionRegistry() {
    const connections = new Map();
    return {
        add(socketId, rooms) {
            connections.set(socketId, [...rooms]);
        },
        remove(socketId) {
            connections.delete(socketId);
        },
        has(socketId) {
            return connections.has(socketId);
        },
        size() {
            return connections.size;
        },
        rooms(socketId) {
            return connections.get(socketId) || [];
        },
    };
}

function createBroadcaster(socketServer) {
    return {
        broadcastToUser(userId, eventName, payload) {
            socketServer.to(`user_${Number.parseInt(userId, 10)}`).emit(eventName, payload);
        },
        broadcastToRole(target, eventName, payload) {
            for (const room of getRoleRooms(target)) socketServer.to(room).emit(eventName, payload);
        },
        broadcastToAll(eventName, payload) {
            socketServer.emit(eventName, payload);
        },
    };
}

function initSocket(server, { verifyToken } = {}) {
    const allowedOrigins = getAllowedOrigins();
    io = new Server(server, {
        cors: {
            origin: allowedOrigins,
            credentials: true,
            methods: ['GET', 'POST'],
        },
    });

    io.use(createAuthMiddleware({ verifyToken }));
    io.on('connection', (socket) => {
        const rooms = socket.authenticatedRooms;
        for (const room of rooms) socket.join(room);
        connectionRegistry.add(socket.id, rooms);

        socket.on('disconnect', () => {
            connectionRegistry.remove(socket.id);
        });
    });

    return io;
}

function broadcastToUser(userId, eventName, payload) {
    if (io) createBroadcaster(io).broadcastToUser(userId, eventName, payload);
}

function broadcastToRole(target, eventName, payload) {
    if (io) createBroadcaster(io).broadcastToRole(target, eventName, payload);
}

function broadcastToAll(eventName, payload) {
    if (io) createBroadcaster(io).broadcastToAll(eventName, payload);
}

function getSocketConnectionsCount() {
    return io?.engine?.clientsCount || 0;
}

module.exports = {
    broadcastToAll,
    broadcastToRole,
    broadcastToUser,
    createAuthMiddleware,
    createBroadcaster,
    createConnectionRegistry,
    getAllowedOrigins,
    getRole,
    getRoleRooms,
    getRoomsForIdentity,
    getSocketConnectionsCount,
    initSocket,
};
