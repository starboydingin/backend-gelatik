require('dotenv').config();

const validateApiKey = (req, res, next) => {
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
        return res.status(401).json({ error: 'Missing Authorization header' });
    }

    const token = authHeader.slice('Bearer '.length).trim();
    if (token !== process.env.INTERNAL_SERVICE_API_KEY) {
        return res.status(401).json({ error: 'Invalid API Key' });
    }

    next();
};

module.exports = validateApiKey;
