<?php

use App\Http\Controllers\P2PController;
use Illuminate\Support\Facades\Route;

Route::get('/', [P2PController::class, 'index']);
Route::post('/login', [P2PController::class, 'quickLogin'])->name('quick.login');
Route::post('/logout', [P2PController::class, 'logout'])->name('logout');

Route::middleware('auth')->group(function () {
    Route::post('/pr', [P2PController::class, 'createPr'])->name('pr.create');
    Route::post('/pr/{id}/approve', [P2PController::class, 'approvePr'])->name('pr.approve');
    Route::post('/po', [P2PController::class, 'createPo'])->name('po.create');
    Route::post('/po/{id}/approve', [P2PController::class, 'approvePo'])->name('po.approve');
    Route::post('/po/{id}/grn', [P2PController::class, 'recordGrn'])->name('grn.create');
    Route::post('/po/{id}/invoice', [P2PController::class, 'createInvoice'])->name('invoice.create');
});