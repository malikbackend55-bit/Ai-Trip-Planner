<?php

namespace Tests\Feature;

use App\Models\User;
use App\Services\ChatAiService;
use Exception;
use Laravel\Sanctum\Sanctum;
use Mockery;
use Tests\TestCase;

class ChatControllerTest extends TestCase
{
    public function test_chat_returns_service_unavailable_when_service_throws(): void
    {
        $user = User::factory()->make();
        Sanctum::actingAs($user);

        $mock = Mockery::mock(ChatAiService::class);
        $mock->shouldReceive('generateChatResponse')
            ->once()
            ->andThrow(new Exception('Unexpected service failure.'));

        $this->app->instance(ChatAiService::class, $mock);

        $response = $this->postJson('/api/chat', [
            'message' => 'Recommend hotels in Paris',
            'context' => ['destination' => 'Paris'],
        ]);

        $response->assertStatus(503)->assertJson([
            'status' => 'error',
            'message' => 'Unexpected service failure.',
        ]);
    }
}
