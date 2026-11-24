<!DOCTYPE html>
<html>
<head><title>P2P Dashboard</title></head>
<body style="font-family: sans-serif; padding: 20px;">
    <div style="display:flex; justify-content:space-between; background:#eee; padding:10px;">
        <div>
            <strong>Logged in as:</strong> {{ $user->email }} |
            <strong>Company ID:</strong> {{ $user->company_id }} |
            <strong>Roles:</strong> {{ $user->roles->pluck('name')->join(', ') }}
        </div>
        <form method="POST" action="{{ route('logout') }}">@csrf <button>Switch User / Logout</button></form>
    </div>

    @if(session('success')) <p style="color:green; font-weight:bold;">✔ {{ session('success') }}</p> @endif
    @if(session('error')) <p style="color:red; font-weight:bold;">✖ {{ session('error') }}</p> @endif

    <h3>1. Cost Centre Budgets (FY 2026-27)</h3>
    <table border="1" cellpadding="6" cellspacing="0">
        <tr><th>Cost Centre</th><th>Total Budget</th><th>Committed</th><th>Spent</th><th>Available</th></tr>
        @foreach($budgets as $b)
        <tr>
            <td>{{ $b->code }}</td>
            <td>₹{{ $b->total_budget }}</td>
            <td>₹{{ $b->committed }}</td>
            <td>₹{{ $b->spent }}</td>
            <td><strong>₹{{ number_format($b->total_budget - $b->committed - $b->spent, 2) }}</strong></td>
        </tr>
        @endforeach
    </table>

    <hr>
    <h3>2. Raise Purchase Requisition (PR)</h3>
    <form method="POST" action="{{ route('pr.create') }}">
        @csrf
        Cost Centre: <select name="cost_centre_id">@foreach($costCentres as $cc)<option value="{{$cc->id}}">{{$cc->code}}</option>@endforeach</select>
        Item: <select name="item_id">@foreach($items as $i)<option value="{{$i->id}}">{{$i->code}} - {{$i->name}} ({{$i->category}})</option>@endforeach</select>
        UoM: <select name="uom_code">@foreach($uoms as $u)<option value="{{$u->code}}">{{$u->code}}</option>@endforeach</select>
        Qty: <input type="number" name="quantity" value="50" required style="width:70px;">
        Est. Price: <input type="number" name="estimated_price" value="250" required style="width:80px;">
        <button type="submit">Submit PR</button>
    </form>

    <h4>Purchase Requisitions</h4>
    <table border="1" cellpadding="6" cellspacing="0">
        <tr><th>ID</th><th>Amount</th><th>Status</th><th>Action</th></tr>
        @foreach($prs as $pr)
        <tr>
            <td>PR #{{ $pr->id }}</td>
            <td>₹{{ $pr->total_estimated_amount }}</td>
            <td>{{ $pr->status }}</td>
            <td>
                @if($pr->status === 'SUBMITTED')
                    <form method="POST" action="{{ route('pr.approve', $pr->id) }}" style="display:inline;">@csrf <button>Approve PR</button></form>
                @elseif($pr->status === 'APPROVED')
                    <form method="POST" action="{{ route('po.create') }}" style="display:inline;">
                        @csrf
                        <input type="hidden" name="pr_id" value="{{ $pr->id }}">
                        <select name="vendor_id">@foreach($vendors as $v)<option value="{{$v->id}}">{{$v->name}} ({{$v->state}})</option>@endforeach</select>
                        Agreed Price: <input type="number" name="agreed_price" value="245" style="width:70px;">
                        <button>Convert to PO</button>
                    </form>
                @endif
            </td>
        </tr>
        @endforeach
    </table>

    <hr>
    <h3>3. Purchase Orders (PO), GRN & 3-Way Match Invoice</h3>
    <table border="1" cellpadding="6" cellspacing="0">
        <tr><th>PO #</th><th>Taxable</th><th>CGST</th><th>SGST</th><th>IGST</th><th>Total</th><th>Status</th><th>Actions (Approve / GRN / Invoice)</th></tr>
        @foreach($pos as $po)
        <tr>
            <td>PO #{{ $po->id }}</td>
            <td>₹{{ $po->taxable_amount }}</td>
            <td>₹{{ $po->cgst_amount }}</td>
            <td>₹{{ $po->sgst_amount }}</td>
            <td>₹{{ $po->igst_amount }}</td>
            <td><strong>₹{{ $po->total_amount }}</strong></td>
            <td>{{ $po->status }}</td>
            <td>
                @if($po->status === 'PENDING_APPROVAL')
                    <form method="POST" action="{{ route('po.approve', $po->id) }}">@csrf <button>Approve PO (Lock Budget)</button></form>
                @endif

                @if(in_array($po->status, ['APPROVED', 'PARTIALLY_RECEIVED']))
                    <form method="POST" action="{{ route('grn.create', $po->id) }}" style="margin-bottom:5px;">
                        @csrf
                        GRN Qty: <input type="number" name="accepted_qty" value="50" style="width:60px;">
                        <select name="uom_code">@foreach($uoms as $u)<option value="{{$u->code}}">{{$u->code}}</option>@endforeach</select>
                        <button>Record GRN</button>
                    </form>
                @endif

                @if(in_array($po->status, ['PARTIALLY_RECEIVED', 'RECEIVED']))
                    <form method="POST" action="{{ route('invoice.create', $po->id) }}">
                        @csrf
                        Inv #: <input type="text" name="invoice_number" value="INV-{{ rand(100,999) }}" style="width:80px;">
                        Qty: <input type="number" name="billed_qty" value="50" style="width:50px;">
                        Price: <input type="number" step="0.01" name="unit_price" value="245" style="width:60px;">
                        <button>Post Invoice (3-Way Match)</button>
                    </form>
                @endif
            </td>
        </tr>
        @endforeach
    </table>
</body>
</html>