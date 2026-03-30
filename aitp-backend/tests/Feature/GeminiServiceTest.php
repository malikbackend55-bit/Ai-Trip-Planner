<?php

namespace Tests\Feature;

use App\Models\User;
use App\Services\GeminiService;
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
}
