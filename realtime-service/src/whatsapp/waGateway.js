const { makeWASocket, useMultiFileAuthState, DisconnectReason, fetchLatestBaileysVersion, Browsers } = require('@whiskeysockets/baileys');
const qrcode = require('qrcode-terminal');
const path = require('path');

let sock;
let isConnected = false;
let initOperation;
let reconnectTimer;
let reconnectAttempts = 0;
let shuttingDown = false;

const disconnectStatusCode = (error) => error?.output?.statusCode ?? error?.statusCode;
const shouldReconnectAfter = (error) => {
    const statusCode = disconnectStatusCode(error);
    return statusCode !== DisconnectReason.loggedOut && statusCode !== 440;
};

const scheduleReconnect = () => {
    if (shuttingDown || reconnectTimer) return;
    const delay = Math.min(1000 * (2 ** reconnectAttempts), 30000);
    reconnectAttempts += 1;
    reconnectTimer = setTimeout(() => {
        reconnectTimer = undefined;
        initWhatsApp().catch((error) => {
            console.error('WhatsApp reconnect failed:', error.message);
            scheduleReconnect();
        });
    }, delay);
    reconnectTimer.unref?.();
};

const initWhatsApp = async () => {
    if (shuttingDown) return;
    if (initOperation) return initOperation;
    initOperation = createWhatsAppSocket();
    try {
        return await initOperation;
    } finally {
        initOperation = undefined;
    }
};

const createWhatsAppSocket = async () => {
    const { version } = await fetchLatestBaileysVersion();
    const sessionDir = process.env.WHATSAPP_SESSION_PATH || './auth_session';
    const authPath = path.isAbsolute(sessionDir) ? sessionDir : path.resolve(__dirname, '../../', sessionDir);
    const { state, saveCreds } = await useMultiFileAuthState(authPath);

    const currentSocket = makeWASocket({
        version,
        auth: state,
        browser: Browsers.ubuntu('Chrome'),
        printQRInTerminal: false // Kita handle QR manual pakai qrcode-terminal yang lebih clear
    });
    sock = currentSocket;

    currentSocket.ev.on('creds.update', saveCreds);

    currentSocket.ev.on('connection.update', (update) => {
        if (currentSocket !== sock) return;
        const { connection, lastDisconnect, qr } = update;
        
        if (qr) {
            console.log('\n--- SCAN QR CODE INI DENGAN WHATSAPP ANDA ---');
            qrcode.generate(qr, { small: true });
            console.log('--------------------------------------------\n');
        }

        if (connection === 'close') {
            isConnected = false;
            const shouldReconnect = !shuttingDown && shouldReconnectAfter(lastDisconnect?.error);
            console.log('WhatsApp connection closed due to ', lastDisconnect.error, ', reconnecting ', shouldReconnect);
            if (shouldReconnect) scheduleReconnect();
        } else if (connection === 'open') {
            isConnected = true;
            reconnectAttempts = 0;
            if (reconnectTimer) clearTimeout(reconnectTimer);
            reconnectTimer = undefined;
            console.log('WhatsApp gateway is connected!');
        } else if (connection === 'connecting') {
            console.log('WhatsApp gateway is connecting...');
        }
    });
};

const shutdownWhatsApp = async () => {
    shuttingDown = true;
    isConnected = false;
    if (reconnectTimer) clearTimeout(reconnectTimer);
    reconnectTimer = undefined;
    const currentSocket = sock;
    sock = undefined;
    if (!currentSocket) return;
    currentSocket.ev.removeAllListeners();
    try {
        currentSocket.end(new Error('Realtime service shutdown'));
    } catch (error) {
        console.error('WhatsApp shutdown warning:', error.message);
    }
};

const normalizeIndonesianNumber = (nomorWa) => {
    const digits = String(nomorWa || '').replace(/\D/g, '');
    let normalized = digits;

    if (normalized.startsWith('0')) normalized = `62${normalized.slice(1)}`;
    else if (normalized.startsWith('8')) normalized = `62${normalized}`;

    if (!/^628\d{8,12}$/.test(normalized)) {
        throw new Error('Format nomor WhatsApp Indonesia tidak valid');
    }

    return normalized;
};

const sendWhatsAppMessage = async (nomorWa, message, deliveryKey = undefined) => {
    if (!isConnected || !sock) {
        return { status: 'failed', error: 'WhatsApp is not connected' };
    }

    try {
        const formattedNumber = normalizeIndonesianNumber(nomorWa);
        const jid = `${formattedNumber}@s.whatsapp.net`;

        await sock.sendMessage(jid, { text: message }, deliveryKey ? { messageId: deliveryKey } : undefined);
        return { status: 'delivered' };
    } catch (error) {
        console.error('Failed to send WA message:', error);
        return { status: 'failed', error: error.message };
    }
};

const getWhatsAppStatus = () => {
    return isConnected ? 'connected' : 'disconnected';
};

module.exports = {
    initWhatsApp,
    sendWhatsAppMessage,
    getWhatsAppStatus,
    normalizeIndonesianNumber,
    shouldReconnectAfter,
    shutdownWhatsApp,
};
