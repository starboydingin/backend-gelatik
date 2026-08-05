<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Rating;
use App\Services\RatingService;
use Illuminate\Http\Request;

class RatingController extends Controller
{
    protected RatingService $ratingService;

    public function __construct(RatingService $ratingService)
    {
        $this->ratingService = $ratingService;
    }

    /** POST /api/rating */
    public function store(Request $request)
    {
        $request->validate([
            'rating' => 'required_without:nilai|integer|min:1|max:5',
            'nilai'  => 'nullable|integer|min:1|max:5',
        ]);

        $nilai = $request->rating ?? $request->nilai;

        $rating = $this->ratingService->beriRating($request->user(), (int) $nilai);

        return response()->json([
            'success' => true,
            'message' => 'Rating berhasil disimpan.',
            'data'    => $rating,
        ], 201);
    }

    /** POST /api/rating/update */
    public function update(Request $request)
    {
        $request->validate([
            'rating' => 'required_without:nilai|integer|min:1|max:5',
            'nilai'  => 'nullable|integer|min:1|max:5',
        ]);

        $nilai = $request->rating ?? $request->nilai;

        $rating = $this->ratingService->updateRating($request->user(), (int) $nilai);

        return response()->json([
            'success' => true,
            'message' => 'Rating berhasil diupdate.',
            'data'    => $rating,
        ]);
    }

    /** GET /api/rating */
    public function index(Request $request)
    {
        $rating = Rating::where('user_id', $request->user()->id)->first();

        return response()->json([
            'success' => true,
            'data'    => $rating,
        ]);
    }
}
