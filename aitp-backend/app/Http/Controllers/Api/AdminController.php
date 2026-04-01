<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use App\Models\Trip;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;

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

        $today = now()->toDateString();

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

        $completedTrips = Trip::where(function ($query) use ($today) {
            $query->whereIn('status', ['Completed', 'Past'])
                ->orWhere(function ($subQuery) use ($today) {
                    $subQuery->where(function ($statusQuery) {
                        $statusQuery->whereNull('status')
                            ->orWhereNotIn('status', ['Cancelled']);
                    })->whereDate('end_date', '<', $today);
                });
        })->count();

        return response()->json([
            'totalTrips' => Trip::count(),
            'totalUsers' => User::count(),
            'totalRevenue' => Trip::sum('budget'),
            'completedTrips' => $completedTrips,
            'monthlyTrends' => $monthlyTrends,
            'topDestinations' => $topDestinations,
            'userRetention' => 84, // Simplified mock for now
            'conversionRate' => '4.2%',
        ]);
    }

    public function trips()
    {
        if (auth()->user()->role !== 'admin') {
            return response()->json(['message' => 'Forbidden'], 403);
        }

        $trips = Trip::with('user')->orderBy('created_at', 'desc')->get();
        return response()->json($trips);
    }

    public function deleteUser($id)
    {
        if (auth()->user()->role !== 'admin') {
            return response()->json(['message' => 'Forbidden'], 403);
        }

        $user = User::findOrFail($id);
        
        // Prevent deleting oneself
        if ($user->id === auth()->id()) {
            return response()->json(['message' => 'Cannot delete your own account'], 400);
        }

        $user->delete();
        return response()->json(['message' => 'User deleted successfully']);
    }

    public function deleteTrip($id)
    {
        if (auth()->user()->role !== 'admin') {
            return response()->json(['message' => 'Forbidden'], 403);
        }

        $trip = Trip::findOrFail($id);
        $trip->delete();
        return response()->json(['message' => 'Trip deleted successfully']);
    }

    public function createAdmin(Request $request)
    {
        if (auth()->user()->role !== 'admin') {
            return response()->json(['message' => 'Forbidden'], 403);
        }

        $request->validate([
            'name' => 'required|string|max:255',
            'email' => 'required|string|email|max:255|unique:users',
            'password' => 'required|string|min:8',
            'phone' => 'nullable|string|max:20',
        ]);

        $user = User::create([
            'name' => $request->name,
            'email' => $request->email,
            'password' => Hash::make($request->password),
            'phone' => $request->phone ?? '',
            'role' => 'admin',
        ]);

        return response()->json([
            'message' => 'Admin created successfully',
            'user' => $user
        ]);
    }

    public function updateRole(Request $request, $id)
    {
        if (auth()->user()->role !== 'admin') {
            return response()->json(['message' => 'Forbidden'], 403);
        }

        $request->validate([
            'role' => 'required|string|in:admin,user',
        ]);

        $user = User::findOrFail($id);

        // Prevent admin from removing their own admin privileges by accident
        if ($user->id === auth()->id() && $request->role !== 'admin') {
            return response()->json(['message' => 'Cannot change your own role'], 400);
        }

        $user->role = $request->role;
        $user->save();

        return response()->json([
            'message' => 'User role updated successfully',
            'user' => $user
        ]);
    }
}
