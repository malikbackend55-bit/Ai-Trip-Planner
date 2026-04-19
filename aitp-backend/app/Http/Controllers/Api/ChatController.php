<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Services\ChatAiService;
use Illuminate\Support\Facades\Auth;
use Exception;

class ChatController extends Controller
{
    protected $chatAiService;

    public function __construct(ChatAiService $chatAiService)
    {
        $this->chatAiService = $chatAiService;
    }

    public function sendMessage(Request $request)
    {
        $request->validate([
            'message' => 'required|string|max:1000',
            'context' => 'nullable|array'
        ]);

        $message = $request->input('message');
        $context = $request->input('context');
        $user = Auth::user();

        try {
            $response = $this->chatAiService->generateChatResponse($message, $user, $context);
        } catch (Exception $e) {
            return response()->json([
                'status' => 'error',
                'message' => $e->getMessage(),
            ], 503);
        }

        return response()->json([
            'status' => 'success',
            'message' => $response,
            'is_ai' => true
        ]);
    }
}
