<?php

namespace App\Services;

use Exception;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

class ChatAiService
{
    protected string $mistralApiKey;

    protected string $mistralBaseUrl;

    protected string $mistralModel;

    protected int $mistralRequestTimeout;

    protected int $mistralChatMaxTokens;

    public function __construct(protected GeminiService $fallbackService)
    {
        $this->mistralApiKey = trim((string) config('services.mistral.api_key', ''));
        $this->mistralBaseUrl = rtrim((string) config('services.mistral.base_url', 'https://api.mistral.ai/v1'), '/');
        $this->mistralModel = trim((string) config('services.mistral.model', 'mistral-small-latest'));
        $this->mistralRequestTimeout = max(10, (int) config('services.mistral.request_timeout', 60));
        $this->mistralChatMaxTokens = max(256, (int) config('services.mistral.chat_max_tokens', 900));
    }

    public function generateChatResponse(string $message, $user, ?array $context = null): string
    {
        $context = is_array($context) ? $context : [];
        $language = $this->normalizeLanguage($context['language'] ?? null);
        $destination = $context['destination'] ?? $this->inferDestinationFromMessage($message);

        if (is_string($destination) && trim($destination) !== '') {
            $context['destination'] = $destination;
        }

        if ($this->shouldAttemptMistral()) {
            try {
                $response = $this->callMistralChat(
                    $this->buildSystemPrompt(
                        $message,
                        $user?->name ?? 'traveler',
                        $destination,
                        $language
                    ),
                    $message
                );

                return $this->cleanChatResponse($response);
            } catch (Exception $e) {
                Log::warning('Mistral chat failed, falling back to GeminiService.', [
                    'error' => $e->getMessage(),
                ]);
            }
        }

        return $this->fallbackService->generateChatResponse($message, $user, $context);
    }

    protected function shouldAttemptMistral(): bool
    {
        return $this->mistralApiKey !== '' && $this->mistralModel !== '';
    }

    protected function callMistralChat(
        string $systemPrompt,
        string $prompt,
        float $temperature = 0.7
    ): string {
        $response = Http::timeout($this->mistralRequestTimeout)
            ->acceptJson()
            ->withToken($this->mistralApiKey)
            ->post($this->mistralBaseUrl.'/chat/completions', [
                'model' => $this->mistralModel,
                'temperature' => $temperature,
                'max_tokens' => $this->mistralChatMaxTokens,
                'messages' => [
                    [
                        'role' => 'system',
                        'content' => $systemPrompt,
                    ],
                    [
                        'role' => 'user',
                        'content' => $prompt,
                    ],
                ],
            ]);

        if (! $response->successful()) {
            Log::error('Mistral API error', [
                'status' => $response->status(),
                'body' => $response->body(),
            ]);

            throw new Exception("Mistral request failed: HTTP {$response->status()}");
        }

        $content = data_get($response->json(), 'choices.0.message.content');

        if (is_array($content)) {
            $content = collect($content)
                ->pluck('text')
                ->filter(fn ($part) => is_string($part) && trim($part) !== '')
                ->implode("\n");
        }

        if (! is_string($content) || trim($content) === '') {
            throw new Exception('Mistral returned an empty response.');
        }

        return trim($content);
    }

    protected function buildSystemPrompt(
        string $message,
        string $name,
        ?string $destination,
        string $language
    ): string {
        $destinationInstruction = $destination
            ? "The user is currently asking about {$destination}. Keep the answer specific to {$destination} when relevant."
            : 'If the user mentions a destination, use it directly in the answer.';

        $planInstruction = $this->asksForDetailedPlan($message)
            ? 'The user wants a full plan. If no duration is specified, produce a practical 3-day plan. Use Day 1, Day 2, Day 3 with Morning, Afternoon, and Evening lines.'
            : 'Answer directly and practically based on the exact request.';

        $hotelInstruction = $this->asksForHotels($message)
            ? 'If the user asks for hotels, recommend well-known areas or hotels and briefly explain why each one fits.'
            : 'Do not add hotel advice unless the user asks for it.';

        return <<<SYS
You are AITP Assistant, the travel assistant inside the AI Trip Planner app.
The user's name is {$name}.
{$destinationInstruction}
{$planInstruction}
{$hotelInstruction}

Rules:
- Give useful, complete answers instead of very short replies.
- Keep the answer structured and easy to scan.
- Return plain text only.
- Do not use Markdown syntax like **, __, #, or code blocks.
- Use real places and practical tips when you know them.
- Be honest when live pricing or real-time availability is not available.
- {$this->chatLanguageInstruction($language)}
SYS;
    }

    protected function cleanChatResponse(string $response): string
    {
        $response = str_replace(["\r\n", "\r"], "\n", trim($response));
        $response = preg_replace('/\*\*(.*?)\*\*/u', '$1', $response) ?? $response;
        $response = preg_replace('/__(.*?)__/u', '$1', $response) ?? $response;
        $response = preg_replace('/`([^`]*)`/u', '$1', $response) ?? $response;
        $response = preg_replace('/^\s*#{1,6}\s*/mu', '', $response) ?? $response;
        $response = preg_replace('/^\s*[-*]\s+/mu', '• ', $response) ?? $response;
        $response = preg_replace('/^\s*---+\s*$/mu', '', $response) ?? $response;
        $response = preg_replace("/\n{3,}/", "\n\n", $response) ?? $response;

        return trim($response);
    }

    protected function asksForDetailedPlan(string $message): bool
    {
        $message = mb_strtolower(trim($message));

        return $this->messageContainsAny($message, [
            'plan',
            'planner',
            'itinerary',
            'schedule',
            'trip plan',
            'day by day',
            'program',
            'پلان',
            'پلانەر',
            'بەرنامە',
            'ڕێکخستن',
        ]);
    }

    protected function asksForHotels(string $message): bool
    {
        return $this->messageContainsAny(mb_strtolower(trim($message)), [
            'hotel',
            'hotels',
            'stay',
            'accommodation',
            'hostel',
            'airbnb',
            'هوتێل',
            'نیشتەجێبوون',
            'مانەوە',
        ]);
    }

    protected function inferDestinationFromMessage(string $message): ?string
    {
        $message = trim($message);
        $normalized = mb_strtolower($message);

        $aliases = [
            'hawler' => 'Hawler, Iraq',
            'hewler' => 'Hawler, Iraq',
            'erbil' => 'Hawler, Iraq',
            'paris' => 'Paris, France',
            'tokyo' => 'Tokyo, Japan',
            'london' => 'London, United Kingdom',
            'rome' => 'Rome, Italy',
            'bali' => 'Bali, Indonesia',
            'istanbul' => 'Istanbul, Turkey',
        ];

        foreach ($aliases as $needle => $destination) {
            if (str_contains($normalized, $needle)) {
                return $destination;
            }
        }

        if (preg_match('/\b(?:in|for|to)\s+([a-z][a-z\s-]{2,40})(?:[?.!,]|$)/iu', $message, $matches) === 1) {
            $candidate = trim($matches[1]);
            $candidateNormalized = mb_strtolower($candidate);

            foreach (['trip', 'plan', 'planner', 'itinerary', 'hotel', 'budget'] as $blockedWord) {
                if (str_contains($candidateNormalized, $blockedWord)) {
                    return null;
                }
            }

            if (substr_count($candidate, ' ') <= 2) {
                return ucwords($candidate);
            }
        }

        return null;
    }

    protected function normalizeLanguage(?string $language): string
    {
        return strtolower((string) $language) === 'ckb' ? 'ckb' : 'en';
    }

    protected function chatLanguageInstruction(string $language): string
    {
        if ($language === 'ckb') {
            return 'Reply only in standard Central Kurdish (Sorani) used in Iraq, written in Arabic script. Avoid English except unavoidable place names.';
        }

        return 'Reply in English.';
    }

    protected function messageContainsAny(string $message, array $keywords): bool
    {
        foreach ($keywords as $keyword) {
            $pattern = '/(?<![\p{L}\p{N}])'.preg_quote($keyword, '/').'(?![\p{L}\p{N}])/iu';

            if (preg_match($pattern, $message) === 1) {
                return true;
            }
        }

        return false;
    }
}
