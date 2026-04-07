<?php

namespace Tests\Feature;

use App\Models\User;
use App\Services\GeminiService;
use Exception;
use Laravel\Sanctum\Sanctum;
use Mockery;
use Tests\TestCase;

class ChatControllerTest extends TestCase
{
    public function test_chat_returns_service_unavailable_when_gemini_fails(): void
    {
        $user = User::factory()->make();
        Sanctum::actingAs($user);

        $mock = Mockery::mock(GeminiService::class);
        $mock->shouldReceive('generateChatResponse')
            ->once()
            ->andThrow(new Exception('Gemini chat is currently unavailable.'));

        $this->app->instance(GeminiService::class, $mock);

        $response = $this->postJson('/api/chat', [
            'message' => 'Recommend hotels in Paris',
            'context' => ['destination' => 'Paris'],
        ]);

        $response->assertStatus(503)->assertJson([
            'status' => 'error',
            'message' => 'Gemini chat is currently unavailable.',
        ]);
    }
}
