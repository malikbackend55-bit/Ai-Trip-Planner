<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;

Route::post('/trips/generate', [TripController::class, 'generate']);

Route::get('/user', function (Request $request) {
    return $request->user();
})->middleware('auth:sanctum');
