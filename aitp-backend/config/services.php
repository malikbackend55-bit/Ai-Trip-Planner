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

    'gemini' => [
        'api_key' => env('GEMINI_API_KEY'),
        'base_url' => env('GEMINI_BASE_URL', 'https://generativelanguage.googleapis.com/v1beta'),
        'model' => env('GEMINI_MODEL', 'gemini-2.5-flash'),
        'fallback_models' => env('GEMINI_FALLBACK_MODELS', 'gemini-2.5-flash-lite'),
        'request_timeout' => env('GEMINI_REQUEST_TIMEOUT', 60),
        'chat_max_output_tokens' => env('GEMINI_CHAT_MAX_OUTPUT_TOKENS', 320),
        'itinerary_max_output_tokens' => env('GEMINI_ITINERARY_MAX_OUTPUT_TOKENS', 4096),
        'fatal_cooldown_seconds' => env('GEMINI_FATAL_COOLDOWN_SECONDS', 900),
    ],

    'mistral' => [
        'api_key' => env('MISTRAL_API_KEY'),
        'base_url' => env('MISTRAL_BASE_URL', 'https://api.mistral.ai/v1'),
        'model' => env('MISTRAL_MODEL', 'mistral-small-latest'),
        'request_timeout' => env('MISTRAL_REQUEST_TIMEOUT', 60),
        'chat_max_tokens' => env('MISTRAL_CHAT_MAX_TOKENS', 900),
    ],

    'ollama' => [
        'enabled' => env('OLLAMA_ENABLED', false),
        'base_url' => env('OLLAMA_BASE_URL', 'http://127.0.0.1:11434'),
        'model' => env('OLLAMA_MODEL', 'llama3:latest'),
        'request_timeout' => env('OLLAMA_REQUEST_TIMEOUT', 120),
        'keep_alive' => env('OLLAMA_KEEP_ALIVE', '10m'),
    ],

    'open_meteo' => [
        'enabled' => env('OPEN_METEO_ENABLED', false),
        'geocoding_url' => env('OPEN_METEO_GEOCODING_URL', 'https://geocoding-api.open-meteo.com/v1/search'),
        'forecast_url' => env('OPEN_METEO_FORECAST_URL', 'https://api.open-meteo.com/v1/forecast'),
        'timeout' => env('OPEN_METEO_TIMEOUT', 12),
    ],

];
