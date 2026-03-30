<?php

namespace Tests\Feature;

use Tests\TestCase;

class ApiAuthenticationTest extends TestCase
{
    public function test_api_requests_return_json_when_unauthenticated(): void
    {
        $response = $this->get('/api/trips');

        $response
            ->assertStatus(401)
            ->assertHeader('content-type', 'application/json')
            ->assertJson([
                'message' => 'Unauthenticated.',
            ]);
    }
}
