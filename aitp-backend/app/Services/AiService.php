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
                'activity_name' => "$type activity in $destination",
                'description' => "A wonderful $slot $type experience in the heart of $destination.",
                'location' => "$destination City Center"
            ];
        }
        
        return $activities;
    }

    /**
     * Generate a mock AI chat response based on user input.
     */
    public function generateChatResponse(string $message, $user, ?array $context = null)
    {
        $message = strtolower(trim($message));
        $name = $user ? $user->name : 'there';
        $responses = [];
        
        // Extract Destination if explicitly mentioned
        $destination = null;

        // Try getting it from the frontend context first
        if ($context && isset($context['destination'])) {
            $destination = $context['destination'];
        } 
        // Fallback to text matching
        else if (preg_match('/(in|for|to)\s+([a-z\s]+)(weather|trip|stay)?/i', $message, $matches)) {
            $words = explode(' ', trim($matches[2]));
            if (count($words) <= 3) {
                $destination = ucwords(trim($matches[2]));
            }
        }
        
        if (!$destination && preg_match('/(paris|tokyo|london|rome|new york|bali|arbil|erbīl)/i', $message, $matches)) {
            $destination = ucwords($matches[1]);
        }
        $destText = $destination ? " in $destination" : "";

        // 1. Greetings
        if (preg_match('/^(hello|hi|hey)/i', $message)) {
            $responses[] = "Hello, $name! I'm your AI travel assistant.";
        }

        // 2. Weather Queries
        if (preg_match('/(weather|rain|sun|hot|cold|temperature|climate|snow|storm|cloud|warm)/i', $message)) {
            if ($destination) {
                $responses[] = "The weather$destText is currently looking great for a trip! ⛅ Expect mild temperatures and mostly sunny skies.";
            } else {
                $responses[] = "Checking the weather is a smart move! If you tell me your destination, I can give you an idea of what to pack. 🌦️";
            }
        }

        // 3. Accommodation / Sleep
        if (str_contains($message, 'hotel') || str_contains($message, 'airbnb') || str_contains($message, 'sleep') || str_contains($message, 'slep') || str_contains($message, 'stay')) {
            if ($destination) {
                $responses[] = "For the best place to sleep$destText, I highly recommend staying right in the city center for convenience, or looking for top-rated boutique hotels/Airbnbs for a more local feel.";
            } else {
                $responses[] = "I can certainly find great accommodation options for you! Do you prefer staying right in the city center to be close to the action, or somewhere quieter?";
            }
        }

        // 4. Budget
        if (str_contains($message, 'budget') || str_contains($message, 'cheap') || str_contains($message, 'affordable') || str_contains($message, 'cost')) {
            $responses[] = "Traveling economically is completely doable! I recommend looking for hostels, using public transport tickets, and trying out local street food markets.";
        }

        // 5. Food
        if (str_contains($message, 'food') || str_contains($message, 'eat') || str_contains($message, 'restaurant') || str_contains($message, 'dining') || str_contains($message, 'meal')) {
            if ($destination) {
                $responses[] = "The food scene in $destination is incredible! I highly suggest diving into the local street food for authentic and cheap eats, or looking up highly-rated regional specialty restaurants near the main square.";
            } else {
                $responses[] = "I love talking about food! 🍕 If you tell me where you are going, I can recommend the best local dishes to try.";
            }
        }

        // 5. General Tips
        if (str_contains($message, 'tip') || str_contains($message, 'tinp') || str_contains($message, 'best')) {
            $destName = $destination ? $destination : 'your destination';
            $responses[] = "My best tip for your trip to $destName is to wake up early! You'll beat the crowds at popular attractions and get the best lighting for your photos. Also, always carry a bit of local cash.";
        }

        // 6. Dates
        if (str_contains($message, 'date') || str_contains($message, 'when')) {
            $responses[] = "Changing dates is easy. Just head over to the 'Plan Your Trip' tab and use the calendar to pick your exact travel days!";
        }

        // 7. General Inquiry if nothing specific was hit
        if (empty($responses)) {
            if ($destination) {
               $responses[] = "Planning a trip to $destination sounds exciting! Are you traveling solo, as a couple, or with a group?"; 
            } else {
               $responses[] = "That sounds like an amazing thought, $name! 🌍 Tell me more about what kind of experiences you enjoy—nature, food, history?—and I'll tailor our travel plans specifically for you.";
            }
        } else if (count($responses) > 1 && !preg_match('/^(hello|hi|hey)/i', $message)) {
            // Add a friendly prefix if we are answering multiple things
            array_unshift($responses, "I can definitely help you with all of that, $name! 🌍");
        }

        return implode("\n\n", $responses);
    }
}
