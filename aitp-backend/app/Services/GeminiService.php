<?php

namespace App\Services;

use Illuminate\Http\Client\Response;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;
use Exception;

class GeminiService
{
    protected string $apiKey;
    protected string $baseUrl;
    protected string $defaultModel;
    protected array $fallbackModels;
    protected int $requestTimeout;
    protected int $chatMaxOutputTokens;
    protected int $itineraryMaxOutputTokens;

    public function __construct()
    {
        $this->apiKey = config('services.gemini.api_key', env('GEMINI_API_KEY', ''));
        $this->baseUrl = rtrim(config('services.gemini.base_url', 'https://generativelanguage.googleapis.com/v1beta'), '/');
        $this->defaultModel = trim(config('services.gemini.model', 'gemini-2.5-flash'));
        $this->fallbackModels = array_values(array_filter(array_map(
            'trim',
            explode(',', config('services.gemini.fallback_models', 'gemini-2.5-flash-lite'))
        )));
        $this->requestTimeout = $this->positiveIntConfig('services.gemini.request_timeout', 60);
        $this->chatMaxOutputTokens = $this->positiveIntConfig('services.gemini.chat_max_output_tokens', 1024);
        $this->itineraryMaxOutputTokens = $this->positiveIntConfig('services.gemini.itinerary_max_output_tokens', 4096);
    }

    /**
     * Make a raw call to the Gemini API.
     */
    protected function callGemini(string $systemPrompt, array $contents, bool $jsonMode = false, int $maxTokens = 2048, float $temperature = 0.7): ?string
    {
        if (empty($this->apiKey)) {
            throw new Exception('GEMINI_API_KEY is not set in .env');
        }

        $body = [
            'system_instruction' => [
                'parts' => [['text' => $systemPrompt]],
            ],
            'contents' => $contents,
            'generationConfig' => [
                'temperature' => $temperature,
                'maxOutputTokens' => $maxTokens,
            ],
        ];

        if ($jsonMode) {
            $body['generationConfig']['responseMimeType'] = 'application/json';
        }

        $lastException = null;

        foreach ($this->modelsToTry() as $model) {
            $response = Http::timeout($this->requestTimeout)
                ->acceptJson()
                ->withHeaders([
                    'x-goog-api-key' => $this->apiKey,
                ])
                ->post($this->modelEndpoint($model), $body);

            if ($response->successful()) {
                $data = $response->json();
                return $data['candidates'][0]['content']['parts'][0]['text'] ?? null;
            }

            if ($this->shouldTryNextModel($response)) {
                Log::warning('Gemini model not found, trying fallback model', [
                    'model' => $model,
                    'status' => $response->status(),
                    'body' => $response->body(),
                ]);

                $lastException = new Exception($this->formatGeminiError($model, $response));
                continue;
            }

            Log::error('Gemini API error', [
                'model' => $model,
                'status' => $response->status(),
                'body' => $response->body(),
            ]);
            throw new Exception($this->formatGeminiError($model, $response));
        }

        throw $lastException ?? new Exception('Gemini API request failed before a response was received.');
    }

    protected function modelsToTry(): array
    {
        return array_values(array_unique(array_filter([
            $this->defaultModel,
            ...$this->fallbackModels,
        ])));
    }

    protected function modelEndpoint(string $model): string
    {
        return "{$this->baseUrl}/models/{$model}:generateContent";
    }

    protected function shouldTryNextModel(Response $response): bool
    {
        if ($response->status() !== 404) {
            return false;
        }

        return strtoupper((string) data_get($response->json(), 'error.status')) === 'NOT_FOUND';
    }

    protected function formatGeminiError(string $model, Response $response): string
    {
        $message = data_get($response->json(), 'error.message');

        if (is_string($message) && $message !== '') {
            return "Gemini API request failed for model {$model}: {$message}";
        }

        return "Gemini API request failed for model {$model}: HTTP {$response->status()}";
    }

    protected function positiveIntConfig(string $key, int $default): int
    {
        $value = (int) config($key, $default);

        return $value > 0 ? $value : $default;
    }

    /**
     * Generate trip itinerary using Gemini AI.
     * Returns array matching the DB schema: day_number, description, activities[time_slot, activity_name, location, notes].
     */
    public function generateItinerary(array $data): array
    {
        $destination = $data['destination'] ?? 'Unknown';
        $interests = is_array($data['interests'] ?? null) ? implode(', ', $data['interests']) : ($data['interests'] ?? 'general sightseeing');
        $days = $data['days'] ?? 3;

        $systemPrompt = "You are an expert AI travel planner. Generate detailed, realistic travel itineraries with specific real places, restaurants, and attractions. Always return valid JSON.";

        $userPrompt = <<<PROMPT
Create a {$days}-day trip itinerary for {$destination}.
Traveler interests: {$interests}.

Return ONLY a JSON array. Each element must have:
- "day_number": integer (1, 2, 3...)
- "description": string (brief summary of the day)
- "activities": array of objects, each with:
  - "time_slot": one of "Morning", "Afternoon", or "Evening"
  - "activity_name": string (name of activity — REQUIRED, cannot be null or empty)
  - "location": string (specific real place name)
  - "notes": string (brief tip or detail)

Example format:
[
  {
    "day_number": 1,
    "description": "Day 1: Arrival and city exploration",
    "activities": [
      {"time_slot": "Morning", "activity_name": "Visit Grand Bazaar", "location": "Grand Bazaar, City Center", "notes": "Arrive early to avoid crowds"},
      {"time_slot": "Afternoon", "activity_name": "Lunch at Local Restaurant", "location": "Old Town Square", "notes": "Try the local specialty dish"},
      {"time_slot": "Evening", "activity_name": "Sunset viewpoint visit", "location": "Hilltop Park", "notes": "Great photo opportunity"}
    ]
  }
]

Generate exactly {$days} days. Each day MUST have exactly 3 activities (Morning, Afternoon, Evening). Every activity_name MUST be a non-empty string.
PROMPT;

        $contents = [
            ['role' => 'user', 'parts' => [['text' => $userPrompt]]],
        ];

        try {
            $raw = $this->callGemini($systemPrompt, $contents, true, $this->itineraryMaxOutputTokens, 0.7);
            $itinerary = json_decode($raw, true);

            if (!is_array($itinerary)) {
                Log::warning('Gemini returned non-array for itinerary, falling back to mock', ['raw' => $raw]);
                return $this->fallbackItinerary($destination, $interests, $days);
            }

            // Validate and sanitize
            foreach ($itinerary as &$day) {
                if (empty($day['activities'])) continue;
                foreach ($day['activities'] as &$act) {
                    if (empty($act['activity_name'])) {
                        $act['activity_name'] = ($act['time_slot'] ?? 'General') . ' activity in ' . $destination;
                    }
                }
            }

            return $itinerary;
        } catch (Exception $e) {
            Log::error('Gemini itinerary generation failed, using fallback', ['error' => $e->getMessage()]);
            return $this->fallbackItinerary($destination, $interests, $days);
        }
    }

    /**
     * Generate AI chat response using Gemini.
     * Falls back to mock responses if API key is not configured.
     */
    public function generateChatResponse(string $message, $user, ?array $context = null): string
    {
        $name = $user ? $user->name : 'traveler';
        $destination = $context['destination'] ?? null;

        // If no API key, use mock fallback
        if (empty($this->apiKey) || $this->apiKey === 'your_gemini_api_key_here') {
            return $this->fallbackChatResponse($message, $name, $destination);
        }

        $destInfo = $destination ? "The user is currently viewing a trip to {$destination}. Use this context to give specific, relevant answers about {$destination}." : "The user has not specified a destination yet.";

        $systemPrompt = <<<SYS
You are AITP Assistant, a friendly and knowledgeable AI travel companion built into the AI Trip Planner app.
Your personality: enthusiastic, helpful, concise, and specific.
The user's name is {$name}.
{$destInfo}

Rules:
- Give specific, real recommendations (real restaurant names, real attractions, real tips).
- Keep responses concise (2-4 paragraphs max).
- Use a warm, conversational tone with occasional emojis.
- If asked about food, recommend specific local dishes and real restaurant names.
- If asked about weather, give general climate info for the destination.
- If asked about budget, give practical cost-saving tips.
- Never make up fake establishment names — use well-known or generic descriptive names.
SYS;

        $contents = [
            ['role' => 'user', 'parts' => [['text' => $message]]],
        ];

        try {
            $response = $this->callGemini($systemPrompt, $contents, false, $this->chatMaxOutputTokens, 0.9);
            return $response ?? "I'm sorry, I couldn't process that request. Could you try rephrasing?";
        } catch (Exception $e) {
            Log::error('Gemini chat failed, using fallback', ['error' => $e->getMessage()]);
            return $this->fallbackChatResponse($message, $name, $destination);
        }
    }

    /**
     * Fallback mock chat responses when Gemini API is unavailable.
     */
    private function fallbackChatResponse(string $message, string $name, ?string $destination): string
    {
        $message = strtolower(trim($message));
        $responses = [];
        $destText = $destination ? " in $destination" : "";

        // Greetings
        if (preg_match('/^(hello|hi|hey)/i', $message)) {
            $responses[] = "Hello, $name! I'm your AI travel assistant. How can I help you today? 🌍";
        }

        // Weather
        if (preg_match('/(weather|rain|sun|hot|cold|temperature|climate)/i', $message)) {
            if ($destination) {
                $responses[] = "The weather$destText is currently looking great for a trip! ⛅ Expect mild temperatures and mostly sunny skies.";
            } else {
                $responses[] = "If you tell me your destination, I can give you an idea of what to pack. 🌦️";
            }
        }

        // Food
        if (str_contains($message, 'food') || str_contains($message, 'eat') || str_contains($message, 'restaurant') || str_contains($message, 'dining') || str_contains($message, 'meal')) {
            if ($destination) {
                $responses[] = "The food scene in $destination is incredible! 🍽️ I highly suggest diving into the local street food for authentic and cheap eats, or looking up highly-rated regional specialty restaurants near the main square.";
            } else {
                $responses[] = "I love talking about food! 🍕 If you tell me where you are going, I can recommend the best local dishes to try.";
            }
        }

        // Hotels
        if (str_contains($message, 'hotel') || str_contains($message, 'stay') || str_contains($message, 'sleep') || str_contains($message, 'airbnb')) {
            if ($destination) {
                $responses[] = "For the best place to stay$destText, I recommend staying right in the city center for convenience, or looking for top-rated boutique hotels for a more local feel. 🏨";
            } else {
                $responses[] = "I can find great accommodation options for you! Do you prefer staying in the city center or somewhere quieter? 🏨";
            }
        }

        // Budget
        if (str_contains($message, 'budget') || str_contains($message, 'cheap') || str_contains($message, 'affordable') || str_contains($message, 'cost')) {
            $responses[] = "Traveling economically is completely doable! 💰 I recommend looking for hostels, using public transport, and trying out local street food markets.";
        }

        // Tips
        if (str_contains($message, 'tip') || str_contains($message, 'best') || str_contains($message, 'recommend')) {
            $destName = $destination ?? 'your destination';
            $responses[] = "My best tip for $destName: wake up early! 🌅 You'll beat the crowds at popular attractions and get the best lighting for photos. Also, always carry a bit of local cash.";
        }

        // General fallback
        if (empty($responses)) {
            if ($destination) {
                $responses[] = "I'd love to help you plan your time in $destination! 🌏 You can ask me about food, weather, hotels, budget tips, or anything else about your trip.";
            } else {
                $responses[] = "That's a great question, $name! 🌍 Tell me more about what kind of experiences you enjoy — nature, food, history? — and I'll tailor my suggestions specifically for you.";
            }
        }

        return implode("\n\n", $responses);
    }

    /**
     * Fallback mock itinerary in case Gemini API is unavailable.
     */
    private function fallbackItinerary(string $destination, string $interests, int $days): array
    {
        $interestsArray = is_array($interests) ? $interests : explode(', ', $interests);
        $slots = ['Morning', 'Afternoon', 'Evening'];
        $itinerary = [];

        for ($i = 1; $i <= $days; $i++) {
            $activities = [];
            foreach ($slots as $slot) {
                $type = $interestsArray[array_rand($interestsArray)] ?? 'General';
                $activities[] = [
                    'time_slot' => $slot,
                    'activity_name' => ucfirst($type) . ' activity in ' . $destination,
                    'location' => $destination . ' City Center',
                    'notes' => "A wonderful {$slot} {$type} experience in {$destination}.",
                ];
            }
            $itinerary[] = [
                'day_number' => $i,
                'description' => "Day {$i}: Exploring the best of {$destination}.",
                'activities' => $activities,
            ];
        }

        return $itinerary;
    }
}
