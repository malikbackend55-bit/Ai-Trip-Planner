<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\TripController;
use App\Http\Controllers\Api\ChatController;
use App\Http\Controllers\Api\AdminController;

Route::post('/register', [AuthController::class, 'register']);
Route::post('/login', [AuthController::class, 'login']);
Route::post('/forgot-password', [AuthController::class, 'forgotPassword']);

Route::middleware('auth:sanctum')->group(function () {
    Route::post('/logout', [AuthController::class, 'logout']);
    
    // Admin Routes
    Route::get('/admin/stats', [AdminController::class, 'stats']);
    Route::get('/admin/users', [AdminController::class, 'users']);
    Route::get('/admin/trips', [AdminController::class, 'trips']);
    Route::get('/admin/export', [AdminController::class, 'export']);
    Route::post('/admin/reset', [AdminController::class, 'reset']);
    Route::delete('/admin/users/{id}', [AdminController::class, 'deleteUser']);
    Route::post('/admin/users', [AdminController::class, 'createAdmin']);
    Route::put('/admin/users/{id}/role', [AdminController::class, 'updateRole']);
    Route::delete('/admin/trips/{id}', [AdminController::class, 'deleteTrip']);

    Route::post('/trips/generate', [TripController::class, 'generate']);
    Route::apiResource('trips', TripController::class);
    Route::post('/chat', [ChatController::class, 'sendMessage']);
    Route::get('/user', function (Request $request) {
        return $request->user();
    });
});
