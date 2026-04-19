<?php

namespace Tests\Feature;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class ProfileUpdateTest extends TestCase
{
    use RefreshDatabase;

    public function test_authenticated_user_can_update_profile(): void
    {
        $user = User::factory()->create([
            'phone' => '7500000000',
        ]);

        Sanctum::actingAs($user);

        $response = $this->putJson('/api/user', [
            'name' => 'Updated Traveler',
            'email' => $user->email,
            'phone' => '7511111111',
        ]);

        $response
            ->assertOk()
            ->assertJson([
                'name' => 'Updated Traveler',
                'email' => $user->email,
                'phone' => '7511111111',
            ]);

        $this->assertDatabaseHas('users', [
            'id' => $user->id,
            'name' => 'Updated Traveler',
            'email' => $user->email,
            'phone' => '7511111111',
        ]);
    }

    public function test_profile_update_rejects_duplicate_email(): void
    {
        $user = User::factory()->create([
            'phone' => '7500000000',
        ]);
        $otherUser = User::factory()->create();

        Sanctum::actingAs($user);

        $response = $this->putJson('/api/user', [
            'name' => $user->name,
            'email' => $otherUser->email,
            'phone' => '7522222222',
        ]);

        $response
            ->assertStatus(422)
            ->assertJsonValidationErrors(['email']);
    }
}
