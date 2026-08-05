const { makeWASocket, useMultiFileAuthState, DisconnectReason, fetchLatestBaileysVersion, Browsers } = require('@whiskeysockets/baileys');
const qrcode = require('qrcode-terminal');
const path = require('path');

let sock;
let isConnected = false;

const initWhatsApp = async () => {
    const { version } = await fetchLatestBaileysVersion();
    const sessionDir = process.env.WHATSAPP_SESSION_PATH || './auth_session';
    const authPath = path.isAbsolute(sessionDir) ? sessionDir : path.resolve(__dirname, '../../', sessionDir);
    const { state, saveCreds } = await useMultiFileAuthState(authPath);

    sock = makeWASocket({
        version,
        auth: state,
        browser: Browsers.ubuntu('Chrome'),
        printQRInTerminal: false // Kita handle QR manual pakai qrcode-terminal yang lebih clear
    });

    sock.ev.on('creds.update', saveCreds);

    sock.ev.on('connection.update', (update) => {
        const { connection, lastDisconnect, qr } = update;
        
        if (qr) {
            console.log('\n--- SCAN QR CODE INI DENGAN WHATSAPP ANDA ---');
            qrcode.generate(qr, { small: true });
            console.log('--------------------------------------------\n');
        }

        if (connection === 'close') {
            isConnected = false;
            const shouldReconnect = (lastDisconnect.error)?.output?.statusCode !== DisconnectReason.loggedOut;
            console.log('WhatsApp connection closed due to ', lastDisconnect.error, ', reconnecting ', shouldReconnect);
            
            // reconnect if not logged out
            if (shouldReconnect) {
                initWhatsApp();
            }
        } else if (connection === 'open') {
            isConnected = true;
            console.log('WhatsApp gateway is connected!');
        } else if (connection === 'connecting') {
            console.log('WhatsApp gateway is connecting...');
        }
    });
};

const sendWhatsAppMessage = async (nomorWa, message) => {
    if (!isConnected || !sock) {
        return { status: 'failed', error: 'WhatsApp is not connected' };
    }

    try {
        // Format nomor Indonesia dari 08... ke 628...
        let formattedNumber = nomorWa;
        if (formattedNumber.startsWith('0')) {
            formattedNumber = '62' + formattedNumber.substring(1);
        }
        // Tambahkan @s.whatsapp.net
        const jid = `${formattedNumber}@s.whatsapp.net`;

        await sock.sendMessage(jid, { text: message });
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
    getWhatsAppStatus
};
