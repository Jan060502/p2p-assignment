<!DOCTYPE html>
<html>
<head><title>P2P Login</title></head>
<body style="font-family: sans-serif; padding: 30px;">
    <h2>Acme Industries - Procure-to-Pay (Select Role to Login)</h2>
    <form method="POST" action="{{ route('quick.login') }}">
        @csrf
        <select name="user_id" style="padding: 8px; width: 400px;">
            @foreach($users as $u)
                <option value="{{ $u->id }}">
                    [{{ $u->company->code }}] {{ $u->email }} ({{ $u->roles->pluck('name')->join(', ') }})
                </option>
            @endforeach
        </select>
        <button type="submit" style="padding: 8px 16px;">Login</button>
    </form>
</body>
</html>