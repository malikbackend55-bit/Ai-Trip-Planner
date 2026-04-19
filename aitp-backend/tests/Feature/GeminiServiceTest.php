<?php

namespace Tests\Feature;

use App\Models\User;
use App\Services\GeminiService;
use Illuminate\Http\Client\Request;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Http;
use Tests\TestCase;

class GeminiServiceTest extends TestCase
{
    public function test_chat_response_retries_with_fallback_model_after_not_found(): void
    {
        config([
            'services.gemini.api_key' => 'test-key',
            'services.gemini.base_url' => 'https://generativelanguage.googleapis.com/v1beta',
            'services.gemini.model' => 'gemini-2.5-flash',
            'services.gemini.fallback_models' => 'gemini-2.5-flash-lite',
            'services.ollama.enabled' => false,
        ]);

        Http::fake([
            'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent' => Http::response([
                'error' => [
                    'status' => 'NOT_FOUND',
                    'message' => 'Requested entity was not found.',
                ],
            ], 404),
            'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-lite:generateContent' => Http::response([
                'candidates' => [[
                    'content' => [
                        'parts' => [[
                            'text' => 'Fallback model reply',
                        ]],
                    ],
                ]],
            ], 200),
        ]);

        $service = new GeminiService;
        $response = $service->generateChatResponse('Plan me a trip', new User(['name' => 'Tester']));

        $this->assertSame('Fallback model reply', $response);
        Http::assertSentCount(2);
    }

    public function test_chat_response_caps_max_output_tokens_for_faster_chat(): void
    {
        config([
            'services.gemini.api_key' => 'test-key',
            'services.gemini.base_url' => 'https://generativelanguage.googleapis.com/v1beta',
            'services.gemini.model' => 'gemini-2.5-flash',
            'services.gemini.chat_max_output_tokens' => 8192,
            'services.ollama.enabled' => false,
        ]);

        Http::fake([
            'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent' => Http::response([
                'candidates' => [[
                    'content' => [
                        'parts' => [[
                            'text' => 'Configured token reply',
                        ]],
                    ],
                ]],
            ], 200),
        ]);

        $service = new GeminiService;
        $response = $service->generateChatResponse('Plan me a trip', new User(['name' => 'Tester']));

        $this->assertSame('Configured token reply', $response);
        Http::assertSent(function (Request $request) {
            return data_get($request->data(), 'generationConfig.maxOutputTokens') === 320;
        });
    }

    public function test_missing_api_key_returns_fallback_for_chat_response(): void
    {
        config([
            'services.gemini.api_key' => '',
            'services.ollama.enabled' => false,
        ]);

        $service = new GeminiService;
        $response = $service->generateChatResponse(
            'Plan a romantic evening in Paris',
            new User(['name' => 'Tester']),
            ['destination' => 'Paris'],
        );

        $this->assertStringContainsString("I can't reach Gemini right now", $response);
        $this->assertStringContainsString('Paris', $response);
    }

    public function test_api_failures_return_fallback_for_chat_response(): void
    {
        config([
            'services.gemini.api_key' => 'test-key',
            'services.gemini.base_url' => 'https://generativelanguage.googleapis.com/v1beta',
            'services.gemini.model' => 'gemini-2.5-flash',
            'services.ollama.enabled' => false,
        ]);

        Http::fake([
            'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent' => Http::response([
                'error' => [
                    'status' => 'UNAVAILABLE',
                    'message' => 'Upstream failure.',
                ],
            ], 503),
        ]);

        $service = new GeminiService;
        $response = $service->generateChatResponse(
            'What is the weather in Paris?',
            new User(['name' => 'Tester']),
            ['destination' => 'Paris'],
        );

        $this->assertNotEmpty($response);
        $this->assertStringContainsString('Paris', $response);
    }

    public function test_api_failures_fall_back_to_ollama_when_enabled(): void
    {
        config([
            'services.gemini.api_key' => 'test-key',
            'services.gemini.base_url' => 'https://generativelanguage.googleapis.com/v1beta',
            'services.gemini.model' => 'gemini-2.5-flash',
            'services.ollama.enabled' => true,
            'services.ollama.base_url' => 'http://127.0.0.1:11434',
            'services.ollama.model' => 'llama3:latest',
            'services.ollama.request_timeout' => 120,
        ]);

        Http::fake([
            'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent' => Http::response([
                'error' => [
                    'status' => 'PERMISSION_DENIED',
                    'message' => 'Project denied.',
                ],
            ], 403),
            'http://127.0.0.1:11434/api/generate' => Http::response([
                'response' => 'Ollama hotel recommendation',
            ], 200),
        ]);

        $service = new GeminiService;
        $response = $service->generateChatResponse(
            'Plan a romantic evening in Paris',
            new User(['name' => 'Tester']),
            ['destination' => 'Paris'],
        );

        $this->assertSame('Ollama hotel recommendation', $response);
    }

    public function test_fatal_gemini_errors_are_bypassed_for_subsequent_requests(): void
    {
        Cache::forget('services.gemini.bypass_until');

        config([
            'services.gemini.api_key' => 'test-key',
            'services.gemini.base_url' => 'https://generativelanguage.googleapis.com/v1beta',
            'services.gemini.model' => 'gemini-2.5-flash',
            'services.gemini.fatal_cooldown_seconds' => 900,
            'services.ollama.enabled' => true,
            'services.ollama.base_url' => 'http://127.0.0.1:11434',
            'services.ollama.model' => 'llama3:latest',
            'services.ollama.request_timeout' => 120,
        ]);

        Http::fake([
            'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent' => Http::response([
                'error' => [
                    'status' => 'PERMISSION_DENIED',
                    'message' => 'Consumer has been suspended.',
                ],
            ], 403),
            'http://127.0.0.1:11434/api/generate' => Http::sequence()
                ->push(['response' => 'First Ollama reply'], 200)
                ->push(['response' => 'Second Ollama reply'], 200),
        ]);

        $service = new GeminiService;

        $firstResponse = $service->generateChatResponse(
            'Plan a relaxed art-focused evening in Paris',
            new User(['name' => 'Tester']),
            ['destination' => 'Paris'],
        );

        $secondResponse = $service->generateChatResponse(
            'Describe a calm Paris neighborhood walk with music and galleries',
            new User(['name' => 'Tester']),
            ['destination' => 'Paris'],
        );

        $this->assertSame('First Ollama reply', $firstResponse);
        $this->assertSame('Second Ollama reply', $secondResponse);
        Http::assertSentCount(3);
    }

    public function test_sorani_language_returns_sorani_fallback_chat_response(): void
    {
        config([
            'services.gemini.api_key' => '',
            'services.ollama.enabled' => false,
        ]);

        $service = new GeminiService;
        $response = $service->generateChatResponse(
            'سڵاو',
            new User(['name' => 'Tester']),
            ['destination' => 'هەولێر', 'language' => 'ckb'],
        );

        $this->assertStringContainsString('سڵاو', $response);
        $this->assertStringContainsString('Tester', $response);
    }

    public function test_weather_questions_use_live_open_meteo_data_when_enabled(): void
    {
        config([
            'services.gemini.api_key' => '',
            'services.ollama.enabled' => false,
            'services.open_meteo.enabled' => true,
            'services.open_meteo.geocoding_url' => 'https://geocoding-api.open-meteo.com/v1/search',
            'services.open_meteo.forecast_url' => 'https://api.open-meteo.com/v1/forecast',
        ]);

        Http::fake([
            'https://geocoding-api.open-meteo.com/v1/search*' => Http::response([
                'results' => [[
                    'name' => 'Paris',
                    'country' => 'France',
                    'latitude' => 48.85341,
                    'longitude' => 2.3488,
                    'timezone' => 'Europe/Paris',
                ]],
            ], 200),
            'https://api.open-meteo.com/v1/forecast*' => Http::response([
                'current' => [
                    'temperature_2m' => 17.4,
                    'apparent_temperature' => 16.8,
                    'weather_code' => 2,
                    'wind_speed_10m' => 11.7,
                ],
                'daily' => [
                    'weather_code' => [2],
                    'temperature_2m_max' => [19.2],
                    'temperature_2m_min' => [11.1],
                    'precipitation_probability_max' => [15],
                ],
            ], 200),
        ]);

        $service = new GeminiService;
        $response = $service->generateChatResponse(
            'play garmi chona',
            new User(['name' => 'Tester']),
            ['destination' => 'Paris, France', 'language' => 'ckb'],
        );

        $this->assertStringContainsString('Paris, France', $response);
        $this->assertStringContainsString('17°C', $response);
        $this->assertStringContainsString('پلەی گەرمی', $response);
    }

    public function test_weather_questions_for_distant_trip_dates_explain_forecast_limit(): void
    {
        config([
            'services.gemini.api_key' => '',
            'services.ollama.enabled' => false,
            'services.open_meteo.enabled' => true,
            'services.open_meteo.geocoding_url' => 'https://geocoding-api.open-meteo.com/v1/search',
            'services.open_meteo.forecast_url' => 'https://api.open-meteo.com/v1/forecast',
        ]);

        Http::fake([
            'https://geocoding-api.open-meteo.com/v1/search*' => Http::response([
                'results' => [[
                    'name' => 'Paris',
                    'country' => 'France',
                    'latitude' => 48.85341,
                    'longitude' => 2.3488,
                    'timezone' => 'Europe/Paris',
                ]],
            ], 200),
        ]);

        $service = new GeminiService;
        $response = $service->generateChatResponse(
            '🌦️ کەشووهەوای گەشتەکەم چۆنە؟',
            new User(['name' => 'Tester']),
            [
                'destination' => 'Paris, France',
                'language' => 'ckb',
                'start_date' => Carbon::now()->addDays(30)->toDateString(),
            ],
        );

        $this->assertStringContainsString('16 ڕۆژی داهاتوو', $response);
        $this->assertStringContainsString('Paris, France', $response);
    }

    public function test_hotel_price_questions_explain_live_data_is_unavailable(): void
    {
        config([
            'services.gemini.api_key' => '',
            'services.ollama.enabled' => false,
            'services.open_meteo.enabled' => false,
        ]);

        $service = new GeminiService;
        $response = $service->generateChatResponse(
            'Give me hotel names and prices in Paris',
            new User(['name' => 'Tester']),
            ['destination' => 'Paris', 'language' => 'en'],
        );

        $this->assertStringContainsString('live hotel feed', $response);
        $this->assertStringContainsString('Paris', $response);
    }

    public function test_hotel_questions_do_not_trigger_weather_fallback(): void
    {
        config([
            'services.gemini.api_key' => '',
            'services.ollama.enabled' => false,
            'services.open_meteo.enabled' => false,
        ]);

        $service = new GeminiService;
        $response = $service->generateChatResponse(
            'give me best hotel to state for 1and 2 day',
            new User(['name' => 'Tester']),
            ['destination' => 'Tokyo, Japan', 'language' => 'en'],
        );

        $this->assertStringNotContainsString('weather in Tokyo', $response);
        $this->assertStringContainsString('Shinjuku', $response);
        $this->assertStringContainsString('Ueno', $response);
    }

    public function test_itinerary_generation_falls_back_to_ollama_when_gemini_fails(): void
    {
        config([
            'services.gemini.api_key' => 'test-key',
            'services.gemini.base_url' => 'https://generativelanguage.googleapis.com/v1beta',
            'services.gemini.model' => 'gemini-2.5-flash',
            'services.ollama.enabled' => true,
            'services.ollama.base_url' => 'http://127.0.0.1:11434',
            'services.ollama.model' => 'llama3:latest',
            'services.ollama.request_timeout' => 120,
        ]);

        Http::fake([
            'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent' => Http::response([
                'error' => [
                    'status' => 'PERMISSION_DENIED',
                    'message' => 'Project denied.',
                ],
            ], 403),
            'http://127.0.0.1:11434/api/generate' => Http::response([
                'response' => json_encode([
                    [
                        'day_number' => 1,
                        'description' => 'Arrival and sightseeing',
                        'activities' => [
                            [
                                'time_slot' => 'Morning',
                                'activity_name' => 'Visit Montmartre',
                                'location' => 'Montmartre',
                                'notes' => 'Start early',
                            ],
                            [
                                'time_slot' => 'Afternoon',
                                'activity_name' => 'Lunch in Le Marais',
                                'location' => 'Le Marais',
                                'notes' => 'Try a cafe',
                            ],
                            [
                                'time_slot' => 'Evening',
                                'activity_name' => 'Seine river walk',
                                'location' => 'Seine',
                                'notes' => 'Great views',
                            ],
                        ],
                    ],
                ]),
            ], 200),
        ]);

        $service = new GeminiService;
        $itinerary = $service->generateItinerary([
            'destination' => 'Paris',
            'interests' => ['food', 'history'],
            'days' => 1,
        ]);

        $this->assertSame('Visit Montmartre', $itinerary[0]['activities'][0]['activity_name']);
        $this->assertSame('Arrival and sightseeing', $itinerary[0]['description']);
    }

    public function test_itinerary_generation_normalizes_days_wrapper_from_ollama(): void
    {
        config([
            'services.gemini.api_key' => 'test-key',
            'services.gemini.base_url' => 'https://generativelanguage.googleapis.com/v1beta',
            'services.gemini.model' => 'gemini-2.5-flash',
            'services.ollama.enabled' => true,
            'services.ollama.base_url' => 'http://127.0.0.1:11434',
            'services.ollama.model' => 'llama3:latest',
            'services.ollama.request_timeout' => 120,
        ]);

        Http::fake([
            'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent' => Http::response([
                'error' => [
                    'status' => 'PERMISSION_DENIED',
                    'message' => 'Project denied.',
                ],
            ], 403),
            'http://127.0.0.1:11434/api/generate' => Http::response([
                'response' => json_encode([
                    'days' => [
                        [
                            'day_number' => 1,
                            'description' => 'Arrival and city exploration',
                            'activities' => [
                                [
                                    'time_slot' => 'Morning',
                                    'activity_name' => 'Visit Eiffel Tower',
                                    'location' => 'Eiffel Tower, Champ de Mars',
                                    'notes' => 'Start the day strong',
                                ],
                            ],
                        ],
                    ],
                ]),
            ], 200),
        ]);

        $service = new GeminiService;
        $itinerary = $service->generateItinerary([
            'destination' => 'Paris',
            'interests' => ['food', 'history'],
            'days' => 1,
        ]);

        $this->assertCount(1, $itinerary);
        $this->assertSame('Visit Eiffel Tower', $itinerary[0]['activities'][0]['activity_name']);
    }
}
