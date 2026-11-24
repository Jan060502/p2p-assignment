<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class AuditLog extends Model
{
    public $timestamps = false;
    protected $guarded = [];

    protected static function booted()
    {
        static::updating(fn () => throw new \RuntimeException('Audit logs cannot be modified.'));
        static::deleting(fn () => throw new \RuntimeException('Audit logs cannot be deleted.'));
    }
}