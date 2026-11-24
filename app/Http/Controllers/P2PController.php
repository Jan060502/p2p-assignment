<?php

namespace App\Http\Controllers;

use App\Models\User;
use App\Services\P2PService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;
use Exception;

class P2PController extends Controller
{
    public function __construct(private P2PService $p2p) {}

    // 1. Login & Dashboard
    public function index()
    {
        if (!Auth::check()) {
            $users = User::with(['company', 'roles'])->get();
            return view('login', compact('users'));
        }

        $user = Auth::user();
        $companyId = $user->company_id;

        // Company Isolation: Only fetch data for logged-in user's company
        $budgets = DB::table('budgets')
            ->join('cost_centres', 'budgets.cost_centre_id', '=', 'cost_centres.id')
            ->where('budgets.company_id', $companyId)
            ->select('cost_centres.code', 'budgets.*')
            ->get();

        $prs = DB::table('purchase_requisitions')->where('company_id', $companyId)->orderByDesc('id')->get();
        $pos = DB::table('purchase_orders')->where('company_id', $companyId)->orderByDesc('id')->get();
        $invoices = DB::table('invoices')->where('company_id', $companyId)->orderByDesc('id')->get();
        $costCentres = DB::table('cost_centres')->where('company_id', $companyId)->get();
        $vendors = DB::table('vendors')->where('company_id', $companyId)->where('is_active', true)->get();
        $items = DB::table('items')->get();
        $uoms = DB::table('uoms')->get();

        return view('dashboard', compact('user', 'budgets', 'prs', 'pos', 'invoices', 'costCentres', 'vendors', 'items', 'uoms'));
    }

    public function quickLogin(Request $request)
    {
        Auth::loginUsingId($request->user_id);
        return redirect('/');
    }

    public function logout()
    {
        Auth::logout();
        return redirect('/');
    }

    // 2. Create & Submit Purchase Requisition (PR)[cite: 1]
    public function createPr(Request $request)
    {
        $user = Auth::user();
        $item = DB::table('items')->where('id', $request->item_id)->first();
        $amount = bcmul((string)$request->quantity, (string)$request->estimated_price, 2);

        $prId = DB::table('purchase_requisitions')->insertGetId([
            'company_id' => $user->company_id,
            'requester_id' => $user->id,
            'cost_centre_id' => $request->cost_centre_id,
            'needed_by' => now()->addDays(7)->toDateString(),
            'status' => 'SUBMITTED',
            'total_estimated_amount' => $amount,
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        DB::table('pr_items')->insert([
            'purchase_requisition_id' => $prId,
            'item_id' => $item->id,
            'uom_code' => $request->uom_code,
            'quantity' => $request->quantity,
            'estimated_price' => $request->estimated_price,
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        // Build approval chain & bind to this PR ID[cite: 1]
        $this->p2p->buildApprovalChain('PR', $amount, $item->category, $user->id);
        DB::table('document_approvals')->where('approvable_type', 'PR')->where('approvable_id', 0)->update(['approvable_id' => $prId]);
        $this->p2p->logAudit('PR', $prId, $user->id, 'DRAFT', 'SUBMITTED', 'PR Created & Submitted');

        return back()->with('success', "PR #{$prId} created and submitted!");
    }

    // 3. Approve PR[cite: 1]
    public function approvePr(int $id)
    {
        $user = Auth::user();
        $pr = DB::table('purchase_requisitions')->where('id', $id)->first();

        // Company isolation check[cite: 1]
        if (!$pr || $pr->company_id !== $user->company_id) abort(403, 'Unauthorized company access');
        // Self-approval block[cite: 1]
        if ($pr->requester_id === $user->id) return back()->with('error', 'You cannot approve your own PR!');

        DB::table('purchase_requisitions')->where('id', $id)->update(['status' => 'APPROVED', 'updated_at' => now()]);
        $this->p2p->logAudit('PR', $id, $user->id, 'SUBMITTED', 'APPROVED', 'PR Approved');

        return back()->with('success', "PR #{$id} Approved!");
    }

    // 4. Convert PR to PO[cite: 1]
    public function createPo(Request $request)
    {
        $user = Auth::user();
        $pr = DB::table('purchase_requisitions')->where('id', $request->pr_id)->first();
        if (!$pr || $pr->company_id !== $user->company_id) abort(403);

        $prItem = DB::table('pr_items')->where('purchase_requisition_id', $pr->id)->first();
        $item = DB::table('items')->where('id', $prItem->item_id)->first();
        $vendor = DB::table('vendors')->where('id', $request->vendor_id)->first();
        $company = DB::table('companies')->where('id', $user->company_id)->first();
        $uom = DB::table('uoms')->where('code', $prItem->uom_code)->first();

        $taxable = bcmul((string)$prItem->quantity, (string)$request->agreed_price, 2);
        $gst = $this->p2p->calculateGst($taxable, (string)$item->gst_rate, $company->state, $vendor->state);
        $total = bcadd($taxable, bcadd(bcadd($gst['cgst'], $gst['sgst'], 2), $gst['igst'], 2), 2);

        $poId = DB::table('purchase_orders')->insertGetId([
            'company_id' => $user->company_id,
            'vendor_id' => $vendor->id,
            'cost_centre_id' => $pr->cost_centre_id,
            'created_by' => $user->id,
            'status' => 'PENDING_APPROVAL',
            'taxable_amount' => $taxable,
            'cgst_amount' => $gst['cgst'],
            'sgst_amount' => $gst['sgst'],
            'igst_amount' => $gst['igst'],
            'total_amount' => $total,
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        DB::table('po_items')->insert([
            'purchase_order_id' => $poId,
            'pr_item_id' => $prItem->id,
            'item_id' => $item->id,
            'uom_code' => $prItem->uom_code,
            'quantity' => $prItem->quantity,
            'base_quantity' => bcmul((string)$prItem->quantity, (string)$uom->factor, 2),
            'unit_price' => $request->agreed_price,
            'gst_rate' => $item->gst_rate,
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        DB::table('purchase_requisitions')->where('id', $pr->id)->update(['status' => 'CONVERTED']);
        $this->p2p->logAudit('PO', $poId, $user->id, 'DRAFT', 'PENDING_APPROVAL', "Converted from PR #{$pr->id}");

        return back()->with('success', "PO #{$poId} created (Total: ₹{$total})!");
    }

    // 5. Approve PO (Triggers Budget Lock)[cite: 1]
    public function approvePo(int $id)
    {
        $user = Auth::user();
        $po = DB::table('purchase_orders')->where('id', $id)->first();
        if (!$po || $po->company_id !== $user->company_id) abort(403);

        try {
            $this->p2p->approvePurchaseOrder($id, $user->id);
            return back()->with('success', "PO #{$id} Approved and Budget Committed!");
        } catch (Exception $e) {
            return back()->with('error', $e->getMessage());
        }
    }

    // 6. Record GRN[cite: 1]
    public function recordGrn(Request $request, int $poId)
    {
        $user = Auth::user();
        $po = DB::table('purchase_orders')->where('id', $poId)->first();
        if (!$po || $po->company_id !== $user->company_id) abort(403);

        $poItem = DB::table('po_items')->where('purchase_order_id', $poId)->first();

        try {
            $this->p2p->recordGrn($poId, $user->id, [[
                'po_item_id' => $poItem->id,
                'uom_code' => $request->uom_code,
                'received_qty' => $request->accepted_qty,
                'accepted_qty' => $request->accepted_qty,
            ]]);
            return back()->with('success', "GRN recorded for PO #{$poId}!");
        } catch (Exception $e) {
            return back()->with('error', $e->getMessage());
        }
    }

    // 7. Create & Post Invoice (3-Way Match)[cite: 1]
    public function createInvoice(Request $request, int $poId)
    {
        $user = Auth::user();
        $po = DB::table('purchase_orders')->where('id', $poId)->first();
        if (!$po || $po->company_id !== $user->company_id) abort(403);

        $poItem = DB::table('po_items')->where('purchase_order_id', $poId)->first();

        try {
            $res = $this->p2p->createAndMatchInvoice($poId, $request->invoice_number, now()->toDateString(), [[
                'po_item_id' => $poItem->id,
                'billed_qty' => $request->billed_qty,
                'unit_price' => $request->unit_price,
                'gst_rate' => $poItem->gst_rate,
            ]]);

            if ($res['status'] === 'MATCHED') {
                // Post invoice and move budget from Committed to Spent[cite: 1]
                DB::table('invoices')->where('id', $res['invoice_id'])->update(['status' => 'POSTED']);
                DB::table('budgets')
                    ->where('company_id', $po->company_id)
                    ->where('cost_centre_id', $po->cost_centre_id)
                    ->update([
                        'committed' => DB::raw("committed - {$po->total_amount}"),
                        'spent' => DB::raw("spent + {$po->total_amount}"),
                    ]);
                return back()->with('success', "Invoice MATCHED & POSTED! Budget moved to Spent.");
            }

            return back()->with('error', "Invoice ON_HOLD: " . implode(', ', $res['hold_reasons']));
        } catch (Exception $e) {
            return back()->with('error', $e->getMessage());
        }
    }
}