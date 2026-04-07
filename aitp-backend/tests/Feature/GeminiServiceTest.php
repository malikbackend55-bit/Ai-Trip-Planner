<?php

namespace Tests\Feature;

use App\Models\User;
use App\Services\GeminiService;
use Exception;
use Illuminate\Support\Facades\Http;
use Illuminate\Http\Client\Request;
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

        $service = new GeminiService();
        $response = $service->generateChatResponse('Plan me a trip', new User(['name' => 'Tester']));

        $this->assertSame('Fallback model reply', $response);
        Http::assertSentCount(2);
    }

    public function test_chat_response_uses_configured_max_output_tokens(): void
    {
        config([
            'services.gemini.api_key' => 'test-key',
            'services.gemini.base_url' => 'https://generativelanguage.googleapis.com/v1beta',
            'services.gemini.model' => 'gemini-2.5-flash',
            'services.gemini.chat_max_output_tokens' => 8192,
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

        $service = new GeminiService();
        $response = $service->generateChatResponse('Plan me a trip', new User(['name' => 'Tester']));

        $this->assertSame('Configured token reply', $response);
        Http::assertSent(function (Request $request) {
            return data_get($request->data(), 'generationConfig.maxOutputTokens') === 8192;
        });
    }

    public function test_missing_api_key_throws_for_chat_response(): void
    {
        config([
            'services.gemini.api_key' => '',
        ]);

        $service = new GeminiService();

        $this->expectException(Exception::class);
        $this->expectExceptionMessage('Gemini API is not configured.');

        $service->generateChatResponse(
            'Recommend hotels in Paris',
            new User(['name' => 'Tester']),
            ['destination' => 'Paris'],
        );
    }

    public function test_api_failures_throw_for_chat_response(): void
    {
        config([
            'services.gemini.api_key' => 'test-key',
            'services.gemini.base_url' => 'https://generativelanguage.googleapis.com/v1beta',
            'services.gemini.model' => 'gemini-2.5-flash',
        ]);

        Http::fake([
            'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent' => Http::response([
                'error' => [
                    'status' => 'UNAVAILABLE',
                    'message' => 'Upstream failure.',
                ],
            ], 503),
        ]);

        $service = new GeminiService();

        $this->expectException(Exception::class);
        $this->expectExceptionMessage('Gemini chat is currently unavailable.');

        $service->generateChatResponse(
            'What is the weather in Paris?',
            new User(['name' => 'Tester']),
            ['destination' => 'Paris'],
        );
    }
}
