<?php

namespace App\Services;

use Exception;
use Illuminate\Http\Client\Response;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

class GeminiService
{
    protected const GEMINI_BYPASS_CACHE_KEY = 'services.gemini.bypass_until';

    protected string $apiKey;

    protected string $baseUrl;

    protected string $defaultModel;

    protected array $fallbackModels;

    protected int $requestTimeout;

    protected int $chatMaxOutputTokens;

    protected int $itineraryMaxOutputTokens;

    protected int $geminiFatalCooldownSeconds;

    protected bool $ollamaEnabled;

    protected string $ollamaBaseUrl;

    protected string $ollamaModel;

    protected int $ollamaRequestTimeout;

    protected string $ollamaKeepAlive;

    protected bool $openMeteoEnabled;

    protected string $openMeteoGeocodingUrl;

    protected string $openMeteoForecastUrl;

    protected int $openMeteoTimeout;

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
        $this->chatMaxOutputTokens = max(128, min(
            $this->positiveIntConfig('services.gemini.chat_max_output_tokens', 320),
            320
        ));
        $this->itineraryMaxOutputTokens = $this->positiveIntConfig('services.gemini.itinerary_max_output_tokens', 4096);
        $this->geminiFatalCooldownSeconds = $this->positiveIntConfig('services.gemini.fatal_cooldown_seconds', 900);
        $this->ollamaEnabled = (bool) config('services.ollama.enabled', false);
        $this->ollamaBaseUrl = rtrim((string) config('services.ollama.base_url', 'http://127.0.0.1:11434'), '/');
        $this->ollamaModel = trim((string) config('services.ollama.model', 'llama3:latest'));
        $this->ollamaRequestTimeout = $this->positiveIntConfig('services.ollama.request_timeout', 120);
        $this->ollamaKeepAlive = trim((string) config('services.ollama.keep_alive', '10m'));
        $this->openMeteoEnabled = (bool) config('services.open_meteo.enabled', false);
        $this->openMeteoGeocodingUrl = trim((string) config('services.open_meteo.geocoding_url', 'https://geocoding-api.open-meteo.com/v1/search'));
        $this->openMeteoForecastUrl = trim((string) config('services.open_meteo.forecast_url', 'https://api.open-meteo.com/v1/forecast'));
        $this->openMeteoTimeout = $this->positiveIntConfig('services.open_meteo.timeout', 12);
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
                $this->clearGeminiBypass();

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

            if ($this->shouldBypassFutureGeminiCalls($response)) {
                $this->markGeminiBypass();
            }

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

    protected function shouldAttemptGemini(): bool
    {
        if (empty($this->apiKey) || $this->apiKey === 'your_gemini_api_key_here') {
            return false;
        }

        return ! $this->shouldBypassGemini();
    }

    protected function shouldBypassGemini(): bool
    {
        try {
            $bypassUntil = (int) Cache::get(self::GEMINI_BYPASS_CACHE_KEY, 0);

            if ($bypassUntil <= 0) {
                return false;
            }

            if ($bypassUntil > now()->timestamp) {
                return true;
            }

            Cache::forget(self::GEMINI_BYPASS_CACHE_KEY);
        } catch (\Throwable $e) {
            Log::warning('Unable to read Gemini bypass cache state', ['error' => $e->getMessage()]);
        }

        return false;
    }

    protected function markGeminiBypass(): void
    {
        try {
            $bypassUntil = now()->timestamp + $this->geminiFatalCooldownSeconds;

            Cache::put(
                self::GEMINI_BYPASS_CACHE_KEY,
                $bypassUntil,
                now()->addSeconds($this->geminiFatalCooldownSeconds)
            );
        } catch (\Throwable $e) {
            Log::warning('Unable to write Gemini bypass cache state', ['error' => $e->getMessage()]);
        }
    }

    protected function clearGeminiBypass(): void
    {
        try {
            Cache::forget(self::GEMINI_BYPASS_CACHE_KEY);
        } catch (\Throwable $e) {
            Log::warning('Unable to clear Gemini bypass cache state', ['error' => $e->getMessage()]);
        }
    }

    protected function shouldBypassFutureGeminiCalls(Response $response): bool
    {
        if (! in_array($response->status(), [400, 401, 403, 429], true)) {
            return false;
        }

        $payload = strtolower((string) ($response->body() ?: json_encode($response->json())));

        foreach ([
            'api_key_invalid',
            'permission_denied',
            'consumer_suspended',
            'resource_exhausted',
            'quota',
            'billing',
            'unauthorized',
            'suspended',
            'api key',
        ] as $needle) {
            if (str_contains($payload, $needle)) {
                return true;
            }
        }

        return in_array($response->status(), [401, 403, 429], true);
    }

    protected function normalizeLanguage(?string $language): string
    {
        return strtolower((string) $language) === 'ckb' ? 'ckb' : 'en';
    }

    protected function isSorani(?string $language): bool
    {
        return $this->normalizeLanguage($language) === 'ckb';
    }

    protected function chatLanguageInstruction(?string $language): string
    {
        if ($this->isSorani($language)) {
            return 'Always reply only in standard Central Kurdish (Sorani) used in Iraq, written in Arabic script. Do not answer in English except unavoidable place names.';
        }

        return 'Always reply in English.';
    }

    protected function itineraryLanguageInstruction(?string $language): string
    {
        if ($this->isSorani($language)) {
            return 'Write description, activity_name, and notes only in standard Central Kurdish (Sorani) used in Iraq, written in Arabic script. Keep JSON keys and time_slot values exactly in English.';
        }

        return 'Write description, activity_name, and notes in English. Keep JSON keys and time_slot values exactly in English.';
    }

    protected function responseLooksSorani(string $text): bool
    {
        preg_match_all('/\p{Arabic}/u', $text, $arabicMatches);
        preg_match_all('/[A-Za-z]/', $text, $latinMatches);

        $arabicCount = count($arabicMatches[0]);
        $latinCount = count($latinMatches[0]);

        return $arabicCount >= max(12, $latinCount);
    }

    protected function shouldUseStructuredSoraniFallback(string $message): bool
    {
        $message = strtolower(trim($message));

        if (preg_match('/^(hello|hi|hey|slaw|sllaw|سڵاو)/iu', $message)) {
            return true;
        }

        return $this->messageContainsAny($message, [
            'weather', 'rain', 'sun', 'sunny', 'hot', 'cold', 'temperature', 'climate', 'snow', 'storm', 'cloudy', 'warm',
            'food', 'eat', 'eating', 'restaurant', 'restaurants', 'dining', 'meal', 'meals', 'dish', 'dishes',
            'hotel', 'hotels', 'stay', 'staying', 'sleep', 'airbnb', 'accommodation', 'accommodations', 'hostel', 'hostels',
            'budget', 'cheap', 'affordable', 'cost', 'costs', 'price', 'prices', 'expensive',
            'tip', 'tips', 'advice', 'what should i know',
            'kash', 'kashu', 'hawa', 'hawam', 'baran', 'garm', 'sard',
            'xwardn', 'xwarin', 'restoran', 'otel', 'manawa', 'manewa',
            'budje', 'buje', 'harzan', 'nrx', 'tecuw',
            'amojgari', 'amojgary', 'rawesh', 'chibzanm', 'chi bzanm',
            'کەش', 'کەشووهەوا', 'کەشووهەوای', 'باران', 'گەرم', 'سارد',
            'خواردن', 'چێشت', 'ڕێستوران',
            'هوتێل', 'نیشتەجێبوون', 'مانەوە',
            'بودجە', 'هەرزان', 'نرخ', 'تێچوو',
            'ئامۆژگاری', 'ڕاوێژ', 'چی بزانم',
        ]);
    }

    protected function shouldUseStructuredChatFallback(string $message, string $language): bool
    {
        if ($this->isSorani($language)) {
            return $this->shouldUseStructuredSoraniFallback($message);
        }

        $message = strtolower(trim($message));

        if (preg_match('/^(hello|hi|hey)\b/i', $message)) {
            return true;
        }

        return $this->messageContainsAny($message, [
            'weather', 'rain', 'sun', 'sunny', 'hot', 'cold', 'temperature', 'climate', 'snow', 'storm', 'cloudy', 'warm',
            'food', 'eat', 'eating', 'restaurant', 'restaurants', 'dining', 'meal', 'meals', 'dish', 'dishes',
            'hotel', 'hotels', 'stay', 'staying', 'sleep', 'airbnb', 'accommodation', 'accommodations', 'hostel', 'hostels',
            'budget', 'cheap', 'affordable', 'cost', 'costs', 'price', 'prices', 'expensive',
            'tip', 'tips', 'advice', 'what should i know',
        ]);
    }

    protected function maybeBuildWeatherResponse(
        string $message,
        ?string $destination,
        ?array $context,
        string $language
    ): ?string {
        if (! $this->openMeteoEnabled || ! $this->isWeatherQuestion($message)) {
            return null;
        }

        if (! $destination) {
            return $this->isSorani($language)
                ? 'ئەگەر شوێنی گەشتەکەت پێم بڵێیت، دەتوانم کەشووهەوای وردترت بۆ بپشکنم.'
                : 'Tell me your destination and I can check a more accurate weather summary.';
        }

        try {
            $weather = $this->lookupDestinationWeather($destination, $context);

            return $this->formatWeatherResponse($weather, $message, $language);
        } catch (Exception $e) {
            Log::warning('Weather lookup failed, using weather fallback response', [
                'destination' => $destination,
                'error' => $e->getMessage(),
            ]);
        }

        return $this->isSorani($language)
            ? "ناتوانم ئێستا داتای ڕاستەوخۆی کەشووهەوا بۆ {$destination} بهێنم. ئەگەر دواتر هەوڵ بدەیت، یان نزیکتر بە بەرواری گەشتەکەت بپرسی، وەڵامی وردتر دەدەم."
            : "I can't fetch live weather data for {$destination} right now. Try again shortly or ask again closer to your travel date for a more accurate answer.";
    }

    protected function maybeBuildHotelPricingResponse(
        string $message,
        ?string $destination,
        string $language
    ): ?string {
        $message = mb_strtolower(trim($message));
        $asksHotels = $this->messageContainsAny($message, [
            'hotel', 'hotels', 'stay', 'staying', 'sleep', 'airbnb', 'accommodation', 'accommodations', 'hostel', 'hostels',
            'otel', 'manawa', 'manewa', 'هوتێل', 'نیشتەجێبوون', 'مانەوە',
        ]);
        $asksPricing = $this->messageContainsAny($message, [
            'price', 'prices', 'cost', 'costs', 'rate', 'rates', 'nightly', 'per night', 'cheap', 'budget',
            'nrx', 'tecuw', 'budje', 'buje', 'pricey', 'نرخ', 'تێچوو', 'بودجە',
        ]);

        if (! $asksHotels || ! $asksPricing) {
            return null;
        }

        if ($this->isSorani($language)) {
            if ($destination) {
                return "ئێستا ئەم ئەپە هێشتا داتای ڕاستەوخۆی هوتێل نییە، بۆیە ناتوانم ناوی هوتێلی ڕاستەقینە و نرخی شەو بە شەوی {$destination} بە دڵنیایی بدەم. دەتوانم تەنها ڕێنمایی گشتی بدەم، بەڵام بۆ ناو و نرخە وردەکان پێویستمان بە hotel/booking API هەیە.";
            }

            return 'ئێستا داتای ڕاستەوخۆی هوتێل لە ئەپەکەدا نییە، بۆیە ناتوانم ناوی هوتێل و نرخەکانیان بە دڵنیایی بدەم. بۆ ئەوە پێویستمان بە hotel/booking API هەیە.';
        }

        if ($destination) {
            return "This app does not have a live hotel feed yet, so I can't reliably give exact hotel names and nightly prices for {$destination}. I can give general stay advice, but exact hotel names and prices need a real hotel or booking API.";
        }

        return "This app does not have a live hotel feed yet, so I can't reliably give exact hotel names and prices. Exact hotel names and nightly prices need a real hotel or booking API.";
    }

    protected function isWeatherQuestion(string $message): bool
    {
        return $this->messageContainsAny(mb_strtolower(trim($message)), [
            'weather', 'forecast', 'temperature', 'temp', 'degree', 'degrees', 'climate',
            'kash', 'kashu', 'hawa', 'hawam', 'garm', 'garmi', 'baran', 'sard', 'play', 'pley',
            'کەش', 'کەشووهەوا', 'کەشووهەوای', 'پلە', 'گەرمی', 'باران', 'سارد',
        ]);
    }

    protected function asksExactTemperature(string $message): bool
    {
        return $this->messageContainsAny(mb_strtolower(trim($message)), [
            'temperature', 'temp', 'degree', 'degrees', 'garm', 'garmi', 'play', 'pley',
            'پلە', 'گەرمی',
        ]);
    }

    protected function lookupDestinationWeather(string $destination, ?array $context): array
    {
        $location = $this->geocodeDestination($destination);
        $targetDate = $this->resolveWeatherTargetDate($context, $location['timezone'] ?? null);
        $today = Carbon::now($location['timezone'] ?? config('app.timezone'))->startOfDay();

        if ($targetDate !== null && $targetDate->greaterThan($today->copy()->addDays(15))) {
            return [
                'mode' => 'out_of_range',
                'location' => $location,
                'target_date' => $targetDate->toDateString(),
            ];
        }

        if ($targetDate !== null && ! $targetDate->isSameDay($today)) {
            return $this->lookupDailyForecast($location, $targetDate);
        }

        return $this->lookupCurrentForecast($location);
    }

    protected function geocodeDestination(string $destination): array
    {
        $queries = array_values(array_unique(array_filter([
            trim($destination),
            trim((string) str($destination)->before(',')),
        ])));

        foreach ($queries as $query) {
            $cacheKey = 'services.weather.geocode.'.md5(mb_strtolower($query));
            $result = Cache::remember($cacheKey, now()->addDay(), function () use ($query) {
                $response = Http::timeout($this->openMeteoTimeout)
                    ->acceptJson()
                    ->get($this->openMeteoGeocodingUrl, [
                        'name' => $query,
                        'count' => 1,
                        'language' => 'en',
                        'format' => 'json',
                    ]);

                if (! $response->successful()) {
                    throw new Exception('Geocoding request failed with HTTP '.$response->status());
                }

                return $response->json('results.0');
            });

            if (is_array($result) && isset($result['latitude'], $result['longitude'])) {
                return $result;
            }
        }

        throw new Exception('No matching location was found for '.$destination);
    }

    protected function resolveWeatherTargetDate(?array $context, ?string $timezone): ?Carbon
    {
        $startDate = $context['start_date'] ?? null;

        if (! is_string($startDate) || trim($startDate) === '') {
            return null;
        }

        try {
            return Carbon::parse($startDate, $timezone ?? config('app.timezone'))->startOfDay();
        } catch (\Throwable $e) {
            return null;
        }
    }

    protected function lookupCurrentForecast(array $location): array
    {
        $cacheKey = 'services.weather.current.'.md5(json_encode([
            $location['latitude'] ?? null,
            $location['longitude'] ?? null,
            $location['timezone'] ?? null,
        ]));

        $payload = Cache::remember($cacheKey, now()->addMinutes(10), function () use ($location) {
            $response = Http::timeout($this->openMeteoTimeout)
                ->acceptJson()
                ->get($this->openMeteoForecastUrl, [
                    'latitude' => $location['latitude'],
                    'longitude' => $location['longitude'],
                    'current' => 'temperature_2m,apparent_temperature,weather_code,wind_speed_10m',
                    'daily' => 'weather_code,temperature_2m_max,temperature_2m_min,precipitation_probability_max',
                    'forecast_days' => 1,
                    'timezone' => 'auto',
                ]);

            if (! $response->successful()) {
                throw new Exception('Forecast request failed with HTTP '.$response->status());
            }

            return $response->json();
        });

        return [
            'mode' => 'current',
            'location' => $location,
            'current_temperature' => data_get($payload, 'current.temperature_2m'),
            'apparent_temperature' => data_get($payload, 'current.apparent_temperature'),
            'wind_speed' => data_get($payload, 'current.wind_speed_10m'),
            'weather_code' => data_get($payload, 'current.weather_code', data_get($payload, 'daily.weather_code.0')),
            'temp_max' => data_get($payload, 'daily.temperature_2m_max.0'),
            'temp_min' => data_get($payload, 'daily.temperature_2m_min.0'),
            'precipitation_probability_max' => data_get($payload, 'daily.precipitation_probability_max.0'),
        ];
    }

    protected function lookupDailyForecast(array $location, Carbon $targetDate): array
    {
        $cacheKey = 'services.weather.daily.'.md5(json_encode([
            $location['latitude'] ?? null,
            $location['longitude'] ?? null,
            $targetDate->toDateString(),
        ]));

        $payload = Cache::remember($cacheKey, now()->addMinutes(30), function () use ($location, $targetDate) {
            $response = Http::timeout($this->openMeteoTimeout)
                ->acceptJson()
                ->get($this->openMeteoForecastUrl, [
                    'latitude' => $location['latitude'],
                    'longitude' => $location['longitude'],
                    'daily' => 'weather_code,temperature_2m_max,temperature_2m_min,precipitation_probability_max',
                    'timezone' => 'auto',
                    'start_date' => $targetDate->toDateString(),
                    'end_date' => $targetDate->toDateString(),
                ]);

            if (! $response->successful()) {
                throw new Exception('Daily forecast request failed with HTTP '.$response->status());
            }

            return $response->json();
        });

        return [
            'mode' => 'daily',
            'location' => $location,
            'target_date' => $targetDate->toDateString(),
            'weather_code' => data_get($payload, 'daily.weather_code.0'),
            'temp_max' => data_get($payload, 'daily.temperature_2m_max.0'),
            'temp_min' => data_get($payload, 'daily.temperature_2m_min.0'),
            'precipitation_probability_max' => data_get($payload, 'daily.precipitation_probability_max.0'),
        ];
    }

    protected function formatWeatherResponse(array $weather, string $message, string $language): string
    {
        $isSorani = $this->isSorani($language);
        $locationLabel = $this->weatherLocationLabel($weather['location'] ?? []);
        $asksExactTemperature = $this->asksExactTemperature($message);
        $description = $this->weatherCodeDescription((int) ($weather['weather_code'] ?? 0), $language);

        if (($weather['mode'] ?? null) === 'out_of_range') {
            $date = $weather['target_date'] ?? '';

            return $isSorani
                ? "ناتوانم ئێستا پێشبینی وردی کەشووهەوا بۆ {$date} لە {$locationLabel} بدەم، چونکە پێشبینی تەنها بۆ 16 ڕۆژی داهاتوو بەردەستە. نزیکتر بە بەرواری گەشتەکەت دووبارە بپرسە."
                : "I can't give an exact weather forecast for {$date} in {$locationLabel} yet because forecast data is only available for about the next 16 days. Ask again closer to your trip.";
        }

        if (($weather['mode'] ?? null) === 'daily') {
            $date = $weather['target_date'] ?? '';
            $min = $this->formatTemperature($weather['temp_min'] ?? null);
            $max = $this->formatTemperature($weather['temp_max'] ?? null);
            $rain = $this->formatPercent($weather['precipitation_probability_max'] ?? null);

            return $isSorani
                ? "بۆ {$date} لە {$locationLabel} پێشبینی کەشووهەوا بریتییە لە {$description}. پلەی گەرمی نزم {$min} و بەرز {$max} دەبێت، و ئەگەری باران {$rain} ـە."
                : "For {$date} in {$locationLabel}, the forecast is {$description}. Temperatures are expected to range from {$min} to {$max}, with about a {$rain} chance of rain.";
        }

        $current = $this->formatTemperature($weather['current_temperature'] ?? null);
        $feelsLike = $this->formatTemperature($weather['apparent_temperature'] ?? null);
        $min = $this->formatTemperature($weather['temp_min'] ?? null);
        $max = $this->formatTemperature($weather['temp_max'] ?? null);
        $wind = $this->formatWind($weather['wind_speed'] ?? null);
        $rain = $this->formatPercent($weather['precipitation_probability_max'] ?? null);

        if ($asksExactTemperature) {
            return $isSorani
                ? "ئێستا لە {$locationLabel} پلەی گەرمی نزیکەی {$current} ـە و هەست دەکرێت {$feelsLike}. دۆخی هەوا {$description} ـە و خێرایی با {$wind} ـە."
                : "Right now in {$locationLabel}, the temperature is about {$current} and it feels like {$feelsLike}. Conditions are {$description} with wind around {$wind}.";
        }

        return $isSorani
            ? "ئێستا کەشووهەوای {$locationLabel} {$description} ـە. پلەی گەرمی ئێستا {$current} ـە، و بۆ ئەمڕۆ نێوان {$min} تا {$max} پێشبینی کراوە. ئەگەری باران {$rain} ـە."
            : "Current weather in {$locationLabel}: {$description}. It's about {$current} right now, with temperatures today expected between {$min} and {$max}. Rain chance is around {$rain}.";
    }

    protected function weatherLocationLabel(array $location): string
    {
        $name = trim((string) ($location['name'] ?? ''));
        $country = trim((string) ($location['country'] ?? ''));

        return trim($name.($country !== '' ? ', '.$country : ''));
    }

    protected function formatTemperature(mixed $value): string
    {
        if (! is_numeric($value)) {
            return '--';
        }

        return round((float) $value).'°C';
    }

    protected function formatPercent(mixed $value): string
    {
        if (! is_numeric($value)) {
            return '--';
        }

        return round((float) $value).'%';
    }

    protected function formatWind(mixed $value): string
    {
        if (! is_numeric($value)) {
            return '--';
        }

        return round((float) $value).' km/h';
    }

    protected function weatherCodeDescription(int $code, string $language): string
    {
        $descriptions = [
            0 => ['en' => 'clear skies', 'ckb' => 'ئاسمانی ڕوون'],
            1 => ['en' => 'mostly clear skies', 'ckb' => 'ئاسمانی زۆربەی ڕوون'],
            2 => ['en' => 'partly cloudy skies', 'ckb' => 'هەندێک هەور'],
            3 => ['en' => 'overcast skies', 'ckb' => 'ئاسمانی تەواو هەورگرتوو'],
            45 => ['en' => 'fog', 'ckb' => 'تەم'],
            48 => ['en' => 'depositing rime fog', 'ckb' => 'تەمی سەهۆڵاوی'],
            51 => ['en' => 'light drizzle', 'ckb' => 'نم‌نم بارانی کەم'],
            53 => ['en' => 'moderate drizzle', 'ckb' => 'نم‌نم بارانی مامناوەند'],
            55 => ['en' => 'dense drizzle', 'ckb' => 'نم‌نم بارانی توند'],
            61 => ['en' => 'light rain', 'ckb' => 'بارانی کەم'],
            63 => ['en' => 'moderate rain', 'ckb' => 'بارانی مامناوەند'],
            65 => ['en' => 'heavy rain', 'ckb' => 'بارانی توند'],
            66 => ['en' => 'light freezing rain', 'ckb' => 'بارانی سەهۆڵاوی کەم'],
            67 => ['en' => 'heavy freezing rain', 'ckb' => 'بارانی سەهۆڵاوی توند'],
            71 => ['en' => 'light snow', 'ckb' => 'بەفری کەم'],
            73 => ['en' => 'moderate snow', 'ckb' => 'بەفری مامناوەند'],
            75 => ['en' => 'heavy snow', 'ckb' => 'بەفری توند'],
            77 => ['en' => 'snow grains', 'ckb' => 'دەنکە بەفر'],
            80 => ['en' => 'light rain showers', 'ckb' => 'بارانی کەم بە شێوەی شەوەر'],
            81 => ['en' => 'moderate rain showers', 'ckb' => 'بارانی مامناوەند بە شێوەی شەوەر'],
            82 => ['en' => 'violent rain showers', 'ckb' => 'بارانی توند بە شێوەی شەوەر'],
            85 => ['en' => 'light snow showers', 'ckb' => 'شەوەری بەفری کەم'],
            86 => ['en' => 'heavy snow showers', 'ckb' => 'شەوەری بەفری توند'],
            95 => ['en' => 'thunderstorms', 'ckb' => 'گرمە و برووسکە'],
            96 => ['en' => 'thunderstorms with light hail', 'ckb' => 'گرمە و برووسکە لەگەڵ تەگرگی کەم'],
            99 => ['en' => 'thunderstorms with heavy hail', 'ckb' => 'گرمە و برووسکە لەگەڵ تەگرگی زۆر'],
        ];

        return $descriptions[$code][$this->normalizeLanguage($language)] ?? $descriptions[2][$this->normalizeLanguage($language)];
    }

    protected function finalizeChatResponse(
        string $response,
        string $message,
        string $name,
        ?string $destination,
        string $language
    ): string {
        $response = trim($response);

        if ($response === '') {
            return $this->fallbackChatResponse($message, $name, $destination, $language, false);
        }

        if (! $this->isSorani($language) || $this->responseLooksSorani($response)) {
            return $response;
        }

        try {
            $translated = $this->callOllama(
                'You are a precise translator. Translate the assistant response fully into standard Central Kurdish (Sorani) used in Iraq, written in Arabic script. Return only the translated text.',
                "Translate the following assistant response into standard Central Kurdish (Sorani) used in Iraq. Do not use English except unavoidable place names.\n\n{$response}",
                false,
                $this->chatMaxOutputTokens,
                0.2
            );

            if (is_string($translated) && trim($translated) !== '' && $this->responseLooksSorani($translated)) {
                return trim($translated);
            }
        } catch (Exception $e) {
            Log::warning('Sorani translation pass failed, using fallback chat response', ['error' => $e->getMessage()]);
        }

        return $this->fallbackChatResponse($message, $name, $destination, $language, false);
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
        $language = $this->normalizeLanguage($data['language'] ?? null);

        $systemPrompt = 'You are an expert AI travel planner. Generate detailed, realistic travel itineraries with specific real places, restaurants, and attractions. Always return valid JSON. '.$this->itineraryLanguageInstruction($language);

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

        if (! $this->shouldAttemptGemini()) {
            if (! empty($this->apiKey)) {
                Log::warning('Skipping Gemini itinerary generation due to recent fatal Gemini error.');
            }

            return $this->generateItineraryWithOllamaOrFallback(
                $systemPrompt,
                $userPrompt,
                $destination,
                $interests,
                $days,
                $language
            );
        }

        try {
            $raw = $this->callGemini($systemPrompt, $contents, true, $this->itineraryMaxOutputTokens, 0.7);
            $itinerary = json_decode($raw, true);

            return $this->sanitizeItinerary($itinerary, $destination, $interests, $days, $language);
        } catch (Exception $e) {
            Log::warning('Gemini itinerary generation failed, trying Ollama', ['error' => $e->getMessage()]);

            return $this->generateItineraryWithOllamaOrFallback(
                $systemPrompt,
                $userPrompt,
                $destination,
                $interests,
                $days,
                $language
            );
        }
    }

    protected function generateItineraryWithOllamaOrFallback(
        string $systemPrompt,
        string $userPrompt,
        string $destination,
        string $interests,
        int $days,
        string $language
    ): array {
        try {
            $ollamaRaw = $this->callOllama(
                $systemPrompt,
                $userPrompt,
                true,
                $this->itineraryMaxOutputTokens,
                0.7
            );
            $itinerary = json_decode($ollamaRaw, true);

            return $this->sanitizeItinerary($itinerary, $destination, $interests, $days, $language);
        } catch (Exception $ollamaException) {
            Log::error('Ollama itinerary generation failed, using fallback', ['error' => $ollamaException->getMessage()]);
        }

        return $this->fallbackItinerary($destination, $interests, $days, $language);
    }

    /**
     * Generate AI chat response using Gemini.
     * Falls back to mock responses if API key is not configured.
     */
    public function generateChatResponse(string $message, $user, ?array $context = null): string
    {
        $name = $user ? $user->name : 'traveler';
        $destination = $context['destination'] ?? null;
        $language = $this->normalizeLanguage($context['language'] ?? null);
        $weatherResponse = $this->maybeBuildWeatherResponse($message, $destination, $context, $language);
        $hotelPricingResponse = $this->maybeBuildHotelPricingResponse($message, $destination, $language);

        if ($weatherResponse !== null) {
            return $weatherResponse;
        }

        if ($hotelPricingResponse !== null) {
            return $hotelPricingResponse;
        }

        if (! $this->shouldAttemptGemini()) {
            Log::warning('Skipping Gemini chat and using Ollama or fallback.');

            return $this->generateChatResponseWithOllamaOrFallback($message, $name, $destination, $language, null, $context);
        }

        $destInfo = $destination ? "The user is currently viewing a trip to {$destination}. Use this context to give specific, relevant answers about {$destination}." : 'The user has not specified a destination yet.';

        $systemPrompt = <<<SYS
You are AITP Assistant, a friendly and knowledgeable AI travel companion built into the AI Trip Planner app.
Your personality: enthusiastic, helpful, specific, and practical.
The user's name is {$name}.
{$destInfo}

Rules:
- Give specific, real recommendations (real restaurant names, real attractions, real tips).
- Answer fully when the user asks for a plan, planner, itinerary, or recommendations.
- If the user asks for a plan and no duration is provided, default to a practical 3-day plan.
- Keep the answer structured and easy to scan.
- Use a warm, conversational tone with occasional emojis.
- If asked about food, recommend specific local dishes and real restaurant names.
- If asked about weather, give general climate info for the destination.
- If asked about budget, give practical cost-saving tips.
- Do not claim live hotel prices or exact availability unless that data is explicitly provided.
- Never make up fake establishment names — use well-known or generic descriptive names.
- Return plain text only. Do not use Markdown syntax like **, __, or #.
- Return plain text only. Do not use Markdown syntax like **, __, or #.
- {$this->chatLanguageInstruction($language)}
SYS;

        $contents = [
            ['role' => 'user', 'parts' => [['text' => $message]]],
        ];

        try {
            $response = $this->callGemini($systemPrompt, $contents, false, $this->chatMaxOutputTokens, 0.9);

            return $this->finalizeChatResponse(
                $response ?? '',
                $message,
                $name,
                $destination,
                $language
            );
        } catch (Exception $e) {
            Log::warning('Gemini chat failed, trying Ollama', ['error' => $e->getMessage()]);

            return $this->generateChatResponseWithOllamaOrFallback(
                $message,
                $name,
                $destination,
                $language,
                $systemPrompt,
                $context
            );
        }
    }

    protected function generateChatResponseWithOllamaOrFallback(
        string $message,
        string $name,
        ?string $destination,
        string $language = 'en',
        ?string $systemPrompt = null,
        ?array $context = null
    ): string {
        $weatherResponse = $this->maybeBuildWeatherResponse($message, $destination, $context, $language);
        $hotelPricingResponse = $this->maybeBuildHotelPricingResponse($message, $destination, $language);

        if ($weatherResponse !== null) {
            return $weatherResponse;
        }

        if ($hotelPricingResponse !== null) {
            return $hotelPricingResponse;
        }

        if ($this->shouldUseStructuredChatFallback($message, $language)) {
            return $this->fallbackChatResponse($message, $name, $destination, $language, false);
        }

        if ($systemPrompt === null) {
            $destInfo = $destination ? "The user is currently viewing a trip to {$destination}. Use this context to give specific, relevant answers about {$destination}." : 'The user has not specified a destination yet.';

            $systemPrompt = <<<SYS
You are AITP Assistant, a friendly and knowledgeable AI travel companion built into the AI Trip Planner app.
Your personality: enthusiastic, helpful, specific, and practical.
The user's name is {$name}.
{$destInfo}

Rules:
- Give specific, real recommendations (real restaurant names, real attractions, real tips).
- Answer fully when the user asks for a plan, planner, itinerary, or recommendations.
- If the user asks for a plan and no duration is provided, default to a practical 3-day plan.
- Keep the answer structured and easy to scan.
- Use a warm, conversational tone with occasional emojis.
- If asked about food, recommend specific local dishes and real restaurant names.
- If asked about weather, give general climate info for the destination.
- If asked about budget, give practical cost-saving tips.
- Do not claim live hotel prices or exact availability unless that data is explicitly provided.
- Never make up fake establishment names — use well-known or generic descriptive names.
- {$this->chatLanguageInstruction($language)}
SYS;
        }

        try {
            $response = $this->callOllama($systemPrompt, $message, false, $this->chatMaxOutputTokens, 0.9);

            if (is_string($response) && trim($response) !== '') {
                return $this->finalizeChatResponse(
                    $response,
                    $message,
                    $name,
                    $destination,
                    $language
                );
            }
        } catch (Exception $e) {
            Log::warning('Ollama chat failed, using fallback response', ['error' => $e->getMessage()]);
        }

        return $this->fallbackChatResponse($message, $name, $destination, $language, true);
    }

    protected function callOllama(
        string $systemPrompt,
        string $prompt,
        bool $jsonMode = false,
        int $maxTokens = 2048,
        float $temperature = 0.7
    ): ?string {
        if (! $this->ollamaEnabled || $this->ollamaModel === '') {
            throw new Exception('Ollama is not enabled.');
        }

        $body = [
            'model' => $this->ollamaModel,
            'system' => $systemPrompt,
            'prompt' => $prompt,
            'stream' => false,
            'options' => [
                'temperature' => $temperature,
                'num_predict' => $this->ollamaNumPredict($jsonMode, $maxTokens),
            ],
        ];

        if ($this->ollamaKeepAlive !== '') {
            $body['keep_alive'] = $this->ollamaKeepAlive;
        }

        if ($jsonMode) {
            $body['format'] = 'json';
        }

        $response = Http::timeout($this->ollamaRequestTimeout)
            ->acceptJson()
            ->post($this->ollamaBaseUrl.'/api/generate', $body);

        if (! $response->successful()) {
            Log::error('Ollama API error', [
                'status' => $response->status(),
                'body' => $response->body(),
            ]);

            throw new Exception("Ollama request failed: HTTP {$response->status()}");
        }

        $text = data_get($response->json(), 'response');

        if (! is_string($text) || trim($text) === '') {
            throw new Exception('Ollama returned an empty response.');
        }

        return trim($text);
    }

    protected function ollamaNumPredict(bool $jsonMode, int $maxTokens): int
    {
        $cap = $jsonMode ? 900 : 220;

        return max(128, min($maxTokens, $cap));
    }

    protected function sanitizeItinerary(mixed $itinerary, string $destination, string $interests, int $days, string $language = 'en'): array
    {
        if (is_array($itinerary) && array_key_exists('days', $itinerary) && is_array($itinerary['days'])) {
            $itinerary = $itinerary['days'];
        }

        if (! is_array($itinerary)) {
            Log::warning('AI returned non-array for itinerary, falling back to mock', ['raw' => $itinerary]);

            return $this->fallbackItinerary($destination, $interests, $days, $language);
        }

        $normalized = [];

        foreach ($itinerary as $day) {
            if (! is_array($day)) {
                continue;
            }

            $activities = [];
            $dayNumber = count($normalized) + 1;

            if (! empty($day['activities']) && is_array($day['activities'])) {
                foreach ($day['activities'] as $activityIndex => $act) {
                    if (! is_array($act)) {
                        continue;
                    }

                    $slot = $act['time_slot'] ?? match ($activityIndex) {
                        0 => 'Morning',
                        1 => 'Afternoon',
                        default => 'Evening',
                    };

                    $activities[] = [
                        'time_slot' => $slot,
                        'activity_name' => $act['activity_name'] ?? (
                            $this->isSorani($language)
                                ? "چالاکیی {$slot} لە {$destination}"
                                : $slot.' activity in '.$destination
                        ),
                        'location' => $act['location'] ?? (
                            $this->isSorani($language)
                                ? $destination.' - ناوەندی شار'
                                : $destination.' City Center'
                        ),
                        'notes' => $act['notes'] ?? (
                            $this->isSorani($language)
                                ? 'بە پێشنیاری پلاندانی AI.'
                                : 'Recommended by the AI trip planner.'
                        ),
                    ];
                }
            }

            $normalized[] = [
                'day_number' => (int) ($day['day_number'] ?? $dayNumber),
                'description' => (string) ($day['description'] ?? (
                    $this->isSorani($language)
                        ? "ڕۆژی {$dayNumber} لە {$destination}"
                        : 'Day '.$dayNumber.' in '.$destination
                )),
                'activities' => $activities,
            ];
        }

        if ($normalized === []) {
            Log::warning('AI returned an empty itinerary payload, falling back to mock', ['raw' => $itinerary]);

            return $this->fallbackItinerary($destination, $interests, $days, $language);
        }

        $fallbackDays = $this->fallbackItinerary($destination, $interests, $days, $language);
        $normalizedByDay = [];

        foreach ($normalized as $day) {
            $normalizedByDay[(int) $day['day_number']] = $day;
        }

        $completed = [];

        foreach ($fallbackDays as $fallbackDay) {
            $dayNumber = (int) $fallbackDay['day_number'];
            $day = $normalizedByDay[$dayNumber] ?? $fallbackDay;

            if (count($day['activities']) < 3) {
                $fallbackActivities = $fallbackDay['activities'];
                while (count($day['activities']) < 3) {
                    $day['activities'][] = $fallbackActivities[count($day['activities'])];
                }
            } elseif (count($day['activities']) > 3) {
                $day['activities'] = array_slice($day['activities'], 0, 3);
            }

            $completed[] = $day;
        }

        foreach ($completed as &$day) {
            if (empty($day['activities']) || ! is_array($day['activities'])) {
                $day['activities'] = $fallbackDays[0]['activities'];

                continue;
            }
            foreach ($day['activities'] as &$act) {
                if (empty($act['activity_name'])) {
                    $act['activity_name'] = $this->isSorani($language)
                        ? 'چالاکیی '.($act['time_slot'] ?? 'General').' لە '.$destination
                        : ($act['time_slot'] ?? 'General').' activity in '.$destination;
                }
            }
        }

        return $completed;
    }

    /**
     * Fallback mock chat responses when Gemini API is unavailable.
     */
    private function fallbackChatResponse(string $message, string $name, ?string $destination, string $language = 'en', bool $includeNotice = false): string
    {
        $message = strtolower(trim($message));
        $responses = [];
        $isSorani = $this->isSorani($language);

        $asksWeather = $this->messageContainsAny($message, [
            'weather', 'rain', 'sun', 'sunny', 'hot', 'cold', 'temperature', 'climate', 'snow', 'storm', 'cloudy', 'warm',
            'kash', 'kashu', 'hawa', 'hawam', 'baran', 'garm', 'sard',
            'کەش', 'کەشووهەوا', 'کەشووهەوای', 'باران', 'گەرم', 'سارد',
        ]);
        $asksFood = $this->messageContainsAny($message, [
            'food', 'eat', 'eating', 'restaurant', 'restaurants', 'dining', 'meal', 'meals', 'dish', 'dishes',
            'xwardn', 'xwarin', 'restoran',
            'خواردن', 'چێشت', 'ڕێستوران',
        ]);
        $asksHotels = $this->messageContainsAny($message, [
            'hotel', 'hotels', 'stay', 'staying', 'sleep', 'airbnb', 'accommodation', 'accommodations', 'hostel', 'hostels',
            'otel', 'manawa', 'manewa',
            'هوتێل', 'نیشتەجێبوون', 'مانەوە',
        ]);
        $asksBudget = $this->messageContainsAny($message, [
            'budget', 'cheap', 'affordable', 'cost', 'costs', 'price', 'prices', 'expensive',
            'budje', 'buje', 'harzan', 'nrx', 'tecuw',
            'بودجە', 'هەرزان', 'نرخ', 'تێچوو',
        ]);
        $asksTips = $this->messageContainsAny($message, ['tip', 'tips', 'advice', 'ئامۆژگاری', 'ڕاوێژ'])
            || str_contains($message, 'what should i know')
            || str_contains($message, 'chi bzanm')
            || str_contains($message, 'amojgari')
            || str_contains($message, 'amojgary')
            || str_contains($message, 'rawesh')
            || str_contains($message, 'چی بزانم');

        if (preg_match('/^(hello|hi|hey|slaw|sllaw|سڵاو)/iu', $message)) {
            $responses[] = $isSorani
                ? "سڵاو {$name}! من یارمەتیدەری گەشتی AI ـتەم. چۆن بتوانم یارمەتیت بدەم؟ 🌍"
                : "Hello, {$name}! I'm your AI travel assistant. How can I help you today? 🌍";
        }

        if ($asksWeather) {
            if ($destination) {
                $responses[] = $isSorani
                    ? "کەشووهەوای {$destination} گونجاوە بۆ گەشت. ⛅ بە گشتی چاوەڕوانی پلەی گەرمی ناوەند و ئاسمانی زۆربەی کات ڕوون بکە."
                    : "The weather in {$destination} is currently looking great for a trip! ⛅ Expect mild temperatures and mostly sunny skies.";
            } else {
                $responses[] = $isSorani
                    ? 'ئەگەر شوێنەکەت پێم بڵێیت، دەتوانم بڵێم چی لەگەڵت ببەیت. 🌦️'
                    : 'If you tell me your destination, I can give you an idea of what to pack. 🌦️';
            }
        }

        if ($asksFood) {
            if ($destination) {
                $responses[] = $isSorani
                    ? "خواردنی {$destination} زۆر سەرنجڕاکێشە! 🍽️ پێشنیار دەکەم لە بازاڕ و شەقامی ناوخۆ بخۆیت و هەروەها بگەڕێیت بە دوای ڕێستورانە ناسراوەکانی ناوەندی شار."
                    : "The food scene in {$destination} is incredible! 🍽️ I highly suggest diving into the local street food for authentic and affordable eats, or looking up highly-rated regional specialty restaurants near the main square.";
            } else {
                $responses[] = $isSorani
                    ? 'حەزم لە گفتوگۆ لەسەر خواردنە! 🍕 ئەگەر شوێنەکەت پێم بڵێیت، دەتوانم باشترین خواردنی ناوخۆت پێشنیار بکەم.'
                    : 'I love talking about food! 🍕 If you tell me where you are going, I can recommend the best local dishes to try.';
            }
        }

        if ($asksHotels) {
            $destinationHotelResponse = $this->buildDestinationHotelFallbackResponse(
                $destination,
                $message,
                $language
            );

            if ($destinationHotelResponse !== null) {
                $responses[] = $destinationHotelResponse;
            } else {
                $responses[] = $isSorani
                    ? 'دەتوانم هەڵبژاردەی باشی نیشتەجێبوونت بۆ بدۆزمەوە. حەزت بە ناوەندی شارە یان شوێنێکی ئارام‌تر؟ 🏨'
                    : 'I can find great accommodation options for you! Do you prefer staying in the city center or somewhere quieter? 🏨';
            }
        }

        if ($asksBudget) {
            $responses[] = $isSorani
                ? 'گەشتی ئابووری تەواو ئاسانە! 💰 پێشنیار دەکەم هۆستێل هەڵبژێریت، گواستنەوەی گشتی بەکاربهێنیت و لە بازاڕی خواردنی شەقام بخۆیت.'
                : 'Traveling economically is completely doable! 💰 I recommend looking for hostels, using public transport, and trying local street food markets.';
        }

        if ($asksTips) {
            $destinationName = $destination ?? ($isSorani ? 'شوێنەکەت' : 'your destination');
            $responses[] = $isSorani
                ? "باشترین ئامۆژگاریم بۆ {$destinationName}: زوو لە خەو هەستە! 🌅 ئەوا پێش لە خەڵکی دەگەیتە شوێنە ناسراوەکان و وێنەی باشتر دەگریت. هەروەها هەمیشە هەندێک پارەی ناوخۆییت لەگەڵ بێت."
                : "My best tip for {$destinationName}: wake up early! 🌅 You'll beat the crowds at popular attractions and get the best lighting for photos. Also, always carry a bit of local cash.";
        }

        if (empty($responses)) {
            if ($destination) {
                $responses[] = $isSorani
                    ? "دڵخۆشم یارمەتیت بدەم بۆ پلان دانانی کاتەکانت لە {$destination}! 🌏 دەتوانیت پرسیار بکەیت لەسەر خواردن، کەشووهەوا، هوتێل، ئامۆژگاری بودجە یان هەر شتێکی تر."
                    : "I'd love to help you plan your time in {$destination}! 🌏 You can ask me about food, weather, hotels, budget tips, or anything else about your trip.";
            } else {
                $responses[] = $isSorani
                    ? "پرسیارێکی باشە، {$name}! 🌍 پێم بڵێت حەزت بە چییە — سروشت، خواردن، مێژوو؟ — تا پێشنیارەکانم بۆت تایبەت بکەم."
                    : "That's a great question, {$name}! 🌍 Tell me more about what kind of experiences you enjoy — nature, food, history? — and I'll tailor my suggestions specifically for you.";
            }
        }

        if ($includeNotice) {
            array_unshift(
                $responses,
                $isSorani
                    ? 'ئێستا ناتوانم پەیوەندی بە Gemini بکەم، بەڵام هێشتا دەتوانم یارمەتیت بدەم بە ڕێنماییی گەشتیی کارامە.'
                    : "I can't reach Gemini right now, but I can still help with practical travel guidance."
            );
        }

        return implode("\n\n", $responses);
    }

    private function buildDestinationHotelFallbackResponse(
        ?string $destination,
        string $message,
        string $language
    ): ?string {
        if (! is_string($destination) || trim($destination) === '') {
            return null;
        }

        $isSorani = $this->isSorani($language);
        $normalizedDestination = mb_strtolower(trim((string) str($destination)->before(',')));
        $asksShortStay = $this->asksShortStay($message);

        if (str_contains($normalizedDestination, 'tokyo')) {
            if ($isSorani) {
                return $asksShortStay
                    ? 'بۆ مانەوەی 1-2 ڕۆژ لە تۆکیۆ، باشترین هەڵبژاردەکان شینجوکو بۆ هاتووچۆی ئاسان، ئۆێنۆ بۆ نرخێکی گونجاوتر، یان ناوچەی Tokyo Station/Ginza بۆ مانەوەی ئاسان و پاکن. ئەگەر بودجەت پێم بڵێیت، دەتوانم باشتر سنووردارت بکەم. 🏨'
                    : 'لەلایەن شوێنی مانەوەوە لە تۆکیۆ، شینجوکو بۆ هاتووچۆی ئاسان، شیبویا بۆ ژیانی شەو و گەشت، ئۆێنۆ بۆ بودجەی باشتر، و گینزا بۆ هوتێلی ئارام و پاک هەڵبژاردەی باشن. ئەگەر بودجەت پێم بڵێیت، دەتوانم باشتر سنووردارت بکەم. 🏨';
            }

            return $asksShortStay
                ? 'For a 1-2 day stay in Tokyo, the best areas are Shinjuku for easy train access, Ueno for better value, or the Tokyo Station/Ginza area for the most convenient short stay. If you tell me your budget, I can narrow it down further. 🏨'
                : 'For Tokyo, the best stay areas depend on your style: Shinjuku for transport convenience, Shibuya for nightlife and energy, Ueno for better value, and Ginza for a quieter polished hotel area. If you tell me your budget, I can narrow it down further. 🏨';
        }

        if (str_contains($normalizedDestination, 'paris')) {
            if ($isSorani) {
                return $asksShortStay
                    ? 'بۆ مانەوەی 1-2 ڕۆژ لە پاریس، ناوچەی 1st arrondissement بۆ گەشتی خێرا، Le Marais بۆ هەستێکی جوان و پیادەگەڕی، و 7th arrondissement بۆ نزیکی شوێنە ناسراوەکان باشن. ئەگەر بودجەت پێم بڵێیت، دەتوانم باشتر سنووردارت بکەم. 🏨'
                    : 'لەپاریسدا، 1st arrondissement بۆ گەشتی ناوەندی شار، Le Marais بۆ هەستێکی زۆر جوان و کافێکان، و 7th arrondissement بۆ ناوچەی ئارام و نزیک بە شوێنە ناسراوەکان هەڵبژاردەی باشن. ئەگەر بودجەت پێم بڵێیت، دەتوانم باشتر سنووردارت بکەم. 🏨';
            }

            return $asksShortStay
                ? 'For a 1-2 day stay in Paris, the 1st arrondissement is best for quick sightseeing, Le Marais is great for charm and walkability, and the 7th arrondissement works well if you want a calmer stay near major sights. If you tell me your budget, I can narrow it down further. 🏨'
                : 'In Paris, the best stay areas are the 1st arrondissement for central sightseeing, Le Marais for charm and cafes, and the 7th arrondissement for a calmer stay near major landmarks. If you tell me your budget, I can narrow it down further. 🏨';
        }

        if ($isSorani) {
            return $asksShortStay
                ? "بۆ مانەوەی 1-2 ڕۆژ لە {$destination}، باشترین هەڵبژاردە زۆرجار ناوچەی نزیک بە ناوەندی شار یان وێستگەی سەرەکی گواستنەوەیە بۆ ئەوەی کاتت لە هاتووچۆ کەم بێت. ئەگەر بودجەت پێم بڵێیت، دەتوانم باشتر سنووردارت بکەم. 🏨"
                : "بۆ باشترین مانەوە لە {$destination}، پێشنیار دەکەم لە ناوچەی نزیک بە ناوەندی شار یان هاتووچۆی سەرەکی بژیت بۆ ئاسانی. ئەگەر بودجەت پێم بڵێیت، دەتوانم باشتر سنووردارت بکەم. 🏨";
        }

        return $asksShortStay
            ? "For a 1-2 day stay in {$destination}, it is usually best to stay near the city center or the main transport hub so you lose less time moving around. If you tell me your budget, I can narrow it down further. 🏨"
            : "For the best place to stay in {$destination}, I recommend staying near the city center or the main transport hub for convenience. If you tell me your budget, I can narrow it down further. 🏨";
    }

    private function asksShortStay(string $message): bool
    {
        $message = mb_strtolower(trim($message));

        return preg_match('/\b(?:1|one)\s*(?:-|to|and)?\s*(?:2|two)?\s*day/i', $message) === 1
            || preg_match('/\b(?:2|two)\s*days?\b/i', $message) === 1
            || str_contains($message, '1and 2 day')
            || str_contains($message, '1 and 2 day')
            || str_contains($message, '1-2 day')
            || str_contains($message, '1 2 day');
    }

    private function messageContainsAny(string $message, array $keywords): bool
    {
        $message = mb_strtolower($message);

        foreach ($keywords as $keyword) {
            $normalizedKeyword = mb_strtolower(trim((string) $keyword));

            if ($normalizedKeyword === '') {
                continue;
            }

            $pattern = '/(?<![\p{L}\p{N}])'.preg_quote($normalizedKeyword, '/').'(?![\p{L}\p{N}])/iu';

            if (preg_match($pattern, $message) === 1) {
                return true;
            }
        }

        return false;
    }

    /**
     * Fallback mock itinerary in case Gemini API is unavailable.
     */
    private function fallbackItinerary(string $destination, string $interests, int $days, string $language = 'en'): array
    {
        $interestsArray = is_array($interests) ? $interests : explode(', ', $interests);
        $slots = ['Morning', 'Afternoon', 'Evening'];
        $itinerary = [];
        $isSorani = $this->isSorani($language);

        for ($i = 1; $i <= $days; $i++) {
            $activities = [];
            foreach ($slots as $slot) {
                $type = $interestsArray[array_rand($interestsArray)] ?? 'General';
                $typeLabel = trim((string) $type) !== '' ? trim((string) $type) : ($isSorani ? 'چالاکی' : 'General');
                $activities[] = [
                    'time_slot' => $slot,
                    'activity_name' => $isSorani
                        ? "{$typeLabel} لە {$destination}"
                        : ucfirst($typeLabel).' activity in '.$destination,
                    'location' => $isSorani ? $destination.' - ناوەندی شار' : $destination.' City Center',
                    'notes' => $isSorani
                        ? "ئەمە چالاکییەکی جوانی {$slot} ـە لە {$destination}."
                        : "A wonderful {$slot} {$typeLabel} experience in {$destination}.",
                ];
            }
            $itinerary[] = [
                'day_number' => $i,
                'description' => $isSorani
                    ? "ڕۆژی {$i}: گەڕان بە ناوازەکانی {$destination}."
                    : "Day {$i}: Exploring the best of {$destination}.",
                'activities' => $activities,
            ];
        }

        return $itinerary;
    }
}
