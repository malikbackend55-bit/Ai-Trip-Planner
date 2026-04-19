<?php

namespace Tests\Feature;

use App\Models\User;
use App\Services\ChatAiService;
use App\Services\GeminiService;
use Illuminate\Http\Client\Request;
use Illuminate\Support\Facades\Http;
use Mockery;
use Tests\TestCase;

class ChatAiServiceTest extends TestCase
{
    public function test_mistral_chat_is_used_when_api_key_is_present(): void
    {
        config([
            'services.mistral.api_key' => 'test-mistral-key',
            'services.mistral.base_url' => 'https://api.mistral.ai/v1',
            'services.mistral.model' => 'mistral-small-latest',
            'services.mistral.chat_max_tokens' => 900,
        ]);

        Http::fake([
            'https://api.mistral.ai/v1/chat/completions' => Http::response([
                'choices' => [[
                    'message' => [
                        'content' => "**Day 1**\n- Visit the citadel\n- Try local food",
                    ],
                ]],
            ], 200),
        ]);

        $fallback = Mockery::mock(GeminiService::class);
        $fallback->shouldNotReceive('generateChatResponse');

        $service = new ChatAiService($fallback);
        $response = $service->generateChatResponse(
            'give me planner for hawler trip',
            new User(['name' => 'Tester']),
            ['language' => 'en'],
        );

        $this->assertStringContainsString('Day 1', $response);
        $this->assertStringNotContainsString('**', $response);

        Http::assertSent(function (Request $request) {
            return $request->url() === 'https://api.mistral.ai/v1/chat/completions'
                && data_get($request->data(), 'model') === 'mistral-small-latest'
                && data_get($request->data(), 'max_tokens') === 900;
        });
    }

    public function test_mistral_failures_fall_back_to_existing_chat_service(): void
    {
        config([
            'services.mistral.api_key' => 'test-mistral-key',
            'services.mistral.base_url' => 'https://api.mistral.ai/v1',
            'services.mistral.model' => 'mistral-small-latest',
        ]);

        Http::fake([
            'https://api.mistral.ai/v1/chat/completions' => Http::response([
                'error' => ['message' => 'Upstream unavailable'],
            ], 503),
        ]);

        $fallback = Mockery::mock(GeminiService::class);
        $fallback->shouldReceive('generateChatResponse')
            ->once()
            ->andReturn('Fallback response');

        $service = new ChatAiService($fallback);
        $response = $service->generateChatResponse(
            'plan me a trip to Paris',
            new User(['name' => 'Tester']),
            ['language' => 'en'],
        );

        $this->assertSame('Fallback response', $response);
    }
}
