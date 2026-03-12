<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use App\Models\Trip;
use Illuminate\Http\Request;

class AdminController extends Controller
{
    public function users()
    {
        if (auth()->user()->role !== 'admin') {
            return response()->json(['message' => 'Forbidden'], 403);
        }

        $users = User::orderBy('created_at', 'desc')->get();
        return response()->json($users);
    }

    public function stats()
    {
        if (auth()->user()->role !== 'admin') {
            return response()->json(['message' => 'Forbidden'], 403);
        }

        return response()->json([
            'totalTrips' => Trip::count(),
            'totalUsers' => User::count(),
            'totalRevenue' => Trip::sum('budget'),
            'completedTrips' => Trip::where('status', 'Completed')->count(),
        ]);
    }
}
