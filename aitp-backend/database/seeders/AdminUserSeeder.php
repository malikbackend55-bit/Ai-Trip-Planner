<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\User;
use Illuminate\Support\Facades\Hash;

class AdminUserSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        $email = env('ADMIN_EMAIL', 'admin@aitrip.com');
        $password = env('ADMIN_PASSWORD', 'admin123');
        $name = env('ADMIN_NAME', 'Admin User');
        $phone = env('ADMIN_PHONE', '');

        $user = User::where('email', $email)->first();

        if (!$user) {
            User::create([
                'name' => $name,
                'email' => $email,
                'password' => Hash::make($password),
                'phone' => $phone,
                'role' => 'admin',
            ]);
            return;
        }

        $dirty = false;

        if (($user->role ?? 'user') !== 'admin') {
            $user->role = 'admin';
            $dirty = true;
        }

        if (empty($user->phone) && $phone !== '') {
            $user->phone = $phone;
            $dirty = true;
        }

        if (empty($user->name) && $name !== '') {
            $user->name = $name;
            $dirty = true;
        }

        if ($dirty) {
            $user->save();
        }
    }
}
