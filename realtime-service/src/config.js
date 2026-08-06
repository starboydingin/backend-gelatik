const DEFAULT_PORT = 4000;

function getRuntimeConfig(env = process.env) {
    const port = Number.parseInt(env.PORT || `${DEFAULT_PORT}`, 10);
    const origins = (env.SOCKET_CORS_ORIGINS || 'http://localhost:8000,http://localhost:3000')
        .split(',')
        .map((origin) => origin.trim())
        .filter(Boolean);

    return {
        port: Number.isInteger(port) && port > 0 ? port : DEFAULT_PORT,
        laravelBaseUrl: (env.LARAVEL_BASE_URL || '').replace(/\/$/, ''),
        internalApiKey: env.INTERNAL_SERVICE_API_KEY || '',
        allowedOrigins: origins,
    };
}

function validateRuntimeConfig(env = process.env) {
    const config = getRuntimeConfig(env);
    const errors = [];

    if (!config.laravelBaseUrl) {
        errors.push('LARAVEL_BASE_URL is required');
    } else {
        try {
            new URL(config.laravelBaseUrl);
        } catch (_) {
            errors.push('LARAVEL_BASE_URL must be a valid URL');
        }
    }

    if (!config.internalApiKey || config.internalApiKey.includes('ganti_dengan')) {
        errors.push('INTERNAL_SERVICE_API_KEY must be configured');
    }

    if (config.allowedOrigins.length === 0) {
        errors.push('SOCKET_CORS_ORIGINS must contain at least one origin');
    }

    return { ok: errors.length === 0, config, errors };
}

module.exports = {
    getRuntimeConfig,
    validateRuntimeConfig,
};
