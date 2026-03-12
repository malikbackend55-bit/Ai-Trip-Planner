<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Trip;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class TripController extends Controller
{
    public function index()
    {
        $trips = Auth::user()->trips()->with('itineraries.activities')->orderBy('created_at', 'desc')->get();
        return response()->json($trips);
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'destination' => 'required|string|max:255',
            'start_date' => 'required|date',
            'end_date' => 'required|date',
            'budget' => 'nullable|numeric',
            'status' => 'nullable|string',
            'image_url' => 'nullable|string',
        ]);

        $trip = Auth::user()->trips()->create($validated);

        return response()->json($trip, 201);
    }

    public function show($id)
    {
        $trip = Auth::user()->trips()->with('itineraries.activities')->findOrFail($id);
        return response()->json($trip);
    }

    public function update(Request $request, $id)
    {
        $trip = Auth::user()->trips()->findOrFail($id);

        $validated = $request->validate([
            'destination' => 'sometimes|required|string|max:255',
            'start_date' => 'sometimes|required|date',
            'end_date' => 'sometimes|required|date',
            'budget' => 'nullable|numeric',
            'status' => 'sometimes|required|string',
            'image_url' => 'nullable|string',
        ]);

        $trip->update($validated);

        return response()->json($trip);
    }

    public function destroy($id)
    {
        $trip = Auth::user()->trips()->findOrFail($id);
        $trip->delete();

        return response()->json(['message' => 'Trip deleted successfully']);
    }
}
