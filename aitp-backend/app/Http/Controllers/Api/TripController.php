<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Trip;
use App\Services\GeminiService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class TripController extends Controller
{
    protected $geminiService;

    public function __construct(GeminiService $geminiService)
    {
        $this->geminiService = $geminiService;
    }

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

    public function generate(Request $request)
    {
        @set_time_limit(300);

        $validated = $request->validate([
            'destination' => 'required|string|max:255',
            'start_date' => 'required|date',
            'end_date' => 'required|date',
            'interests' => 'required|array',
            'budget' => 'nullable|numeric',
            'language' => 'nullable|string|in:en,ckb',
        ]);

        $start = new \DateTime($validated['start_date']);
        $end = new \DateTime($validated['end_date']);
        $days = $start->diff($end)->days + 1;

        // Create the base trip
        $trip = Auth::user()->trips()->create([
            'destination' => $validated['destination'],
            'start_date' => $validated['start_date'],
            'end_date' => $validated['end_date'],
            'budget' => $validated['budget'] ?? 0,
            'status' => 'Upcoming',
        ]);

        // Generate AI Itinerary
        $itineraryData = $this->geminiService->generateItinerary([
            'destination' => $validated['destination'],
            'interests' => $validated['interests'],
            'days' => $days,
            'language' => $validated['language'] ?? 'en',
        ]);

        // Save Itineraries and Activities
        foreach ($itineraryData as $dayData) {
            $itinerary = $trip->itineraries()->create([
                'day_number' => $dayData['day_number'],
                'description' => $dayData['description'],
            ]);

            foreach ($dayData['activities'] as $activityData) {
                $itinerary->activities()->create($activityData);
            }
        }

        return response()->json($trip->load('itineraries.activities'), 201);
    }

    public function destroy($id)
    {
        $trip = Auth::user()->trips()->findOrFail($id);
        $trip->delete();

        return response()->json(['message' => 'Trip deleted successfully']);
    }
}
