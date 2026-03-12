<?php

namespace App\Services;

use Exception;

class AiService
{
    /**
     * Generate a trip itinerary using a mock "Smart Agent" that simulates AI.
     * This can be easily swapped for an OpenAI or Gemini API call.
     */
    public function generateItinerary(array $data)
    {
        $destination = $data['destination'] ?? 'Unknown Destination';
        $interests = $data['interests'] ?? [];
        $days = $data['days'] ?? 3;
        
        $itinerary = [];
        
        for ($i = 1; $i <= $days; $i++) {
            $activities = $this->getActivitiesForDay($i, $destination, $interests);
            $itinerary[] = [
                'day_number' => $i,
                'description' => "Day $i: Exploring the best of $destination tailored to your interests.",
                'activities' => $activities
            ];
        }
        
        return $itinerary;
    }

    private function getActivitiesForDay($day, $destination, $interests)
    {
        $slots = ['Morning', 'Afternoon', 'Evening'];
        $activities = [];
        
        foreach ($slots as $slot) {
            $type = $interests[array_rand($interests)] ?? 'General';
            $activities[] = [
                'time_slot' => "$slot",
                'title' => "$type activity in $destination",
                'description' => "A wonderful $slot $type experience in the heart of $destination.",
                'location' => "$destination City Center"
            ];
        }
        
        return $activities;
    }
}
