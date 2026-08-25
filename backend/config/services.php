<?php

return [

    /*
    |--------------------------------------------------------------------------
    | Third Party Services
    |--------------------------------------------------------------------------
    |
    | This file is for storing the credentials for third party services such
    | as Mailgun, Postmark, AWS and more. This file provides the de facto
    | location for this type of information, allowing packages to have
    | a conventional file to locate the various service credentials.
    |
    */

    'postmark' => [
        'key' => env('POSTMARK_API_KEY'),
    ],

    'resend' => [
        'key' => env('RESEND_API_KEY'),
    ],

    'ses' => [
        'key' => env('AWS_ACCESS_KEY_ID'),
        'secret' => env('AWS_SECRET_ACCESS_KEY'),
        'region' => env('AWS_DEFAULT_REGION', 'us-east-1'),
    ],

    'slack' => [
        'notifications' => [
            'bot_user_oauth_token' => env('SLACK_BOT_USER_OAUTH_TOKEN'),
            'channel' => env('SLACK_BOT_USER_DEFAULT_CHANNEL'),
        ],
    ],

    'chatbot' => [
        'connect_timeout' => (int) env('CHATBOT_AI_CONNECT_TIMEOUT', 2),
        'request_timeout' => (int) env('CHATBOT_AI_REQUEST_TIMEOUT', 5),
        'gemini_attempts' => (int) env('CHATBOT_GEMINI_ATTEMPTS', 1),
        'provider_cooldown' => (int) env('CHATBOT_AI_PROVIDER_COOLDOWN', 30),
        // The PHP runtime on Windows may not have a system CA path configured.
        // Keep TLS verification enabled by using the Composer-provided CA bundle.
        'ca_bundle' => env('CHATBOT_CA_BUNDLE', base_path('vendor/grpc/grpc/etc/roots.pem')),
        'gemini' => [
            'key' => env('GEMINI_API_KEY'),
            'model' => env('GEMINI_MODEL', 'gemini-flash-latest'),
        ],
        'groq' => [
            'key' => env('GROQ_API_KEY'),
            'model' => env('GROQ_MODEL', 'llama-3.3-70b-versatile'),
        ],
    ],

    'local_provision' => [
        'key' => env('LOCAL_PROVISION_KEY'),
    ],

];
