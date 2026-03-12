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

        // Monthly trends (Last 6 months)
        $monthlyTrends = Trip::selectRaw("TO_CHAR(created_at, 'Mon') as month, COUNT(*) as count")
            ->where('created_at', '>=', now()->subMonths(6))
            ->groupBy('month')
            ->orderByRaw("MIN(created_at) ASC")
            ->get();

        // Top Destinations
        $topDestinations = Trip::selectRaw("destination, COUNT(*) as count, SUM(budget) as total_budget")
            ->groupBy('destination')
            ->orderBy('count', 'desc')
            ->limit(5)
            ->get();

        return response()->json([
            'totalTrips' => Trip::count(),
            'totalUsers' => User::count(),
            'totalRevenue' => Trip::sum('budget'),
            'completedTrips' => Trip::where('status', 'Completed')->count(),
            'monthlyTrends' => $monthlyTrends,
            'topDestinations' => $topDestinations,
            'userRetention' => 84, // Simplified mock for now
            'conversionRate' => '4.2%',
        ]);
    }
}
