<?php

namespace Tests\Feature;

use App\Models\User;
use App\Services\P2PService;
use Database\Seeders\DatabaseSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\DB;
use Tests\TestCase;
use Exception;

class P2PModuleTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        $this->seed(DatabaseSeeder::class);
    }

    // Test 1: Happy path Intra-state GST (CGST + SGST)
    public function test_intra_state_gst_splits_into_cgst_and_sgst(): void
    {
        $service = new P2PService();
        $gst = $service->calculateGst('12250.00', '12', 'Maharashtra', 'Maharashtra');
        $this->assertEquals('735.00', $gst['cgst']);
        $this->assertEquals('735.00', $gst['sgst']);
        $this->assertEquals('0.00', $gst['igst']);
    }

    // Test 2: Inter-state GST (IGST)
    public function test_inter_state_gst_charges_full_igst(): void
    {
        $service = new P2PService();
        $gst = $service->calculateGst('195000.00', '18', 'Maharashtra', 'Karnataka');
        $this->assertEquals('0.00', $gst['cgst']);
        $this->assertEquals('0.00', $gst['sgst']);
        $this->assertEquals('35100.00', $gst['igst']);
    }

    // Test 3: IT Category adds extra IT Head approval step (Scenario S2)
    public function test_it_category_pr_adds_it_head_after_dept_head(): void
    {
        $req = User::where('email', 'req.mum@acme.test')->first();
        $service = new P2PService();
        $service->buildApprovalChain('PR', '195000.00', 'IT', $req->id);

        $steps = DB::table('document_approvals')->orderBy('step_order')->pluck('role_name')->toArray();
        $this->assertEquals(['Dept Head', 'IT Head', 'Finance Head'], $steps);
    }

    // Test 4: Self-approval is skipped/blocked (Scenario S8)
    public function test_user_cannot_approve_own_document(): void
    {
        $deptHead = User::where('email', 'depthead.mum@acme.test')->first();
        $service = new P2PService();
        $service->buildApprovalChain('PR', '10000.00', 'CONSUMABLES', $deptHead->id);

        $step = DB::table('document_approvals')->first();
        $this->assertEquals('SKIPPED', $step->status);
    }

    // Test 5: Budget cannot go negative (Scenario S3)
    public function test_budget_cannot_go_negative_when_exhausted(): void
    {
        $service = new P2PService();
        $mum = DB::table('companies')->where('code', 'ACME-MUM')->first();
        $salesCc = DB::table('cost_centres')->where('company_id', $mum->id)->where('code', 'SALES')->first();
        $vendor = DB::table('vendors')->where('company_id', $mum->id)->first();
        $finHead = User::where('email', 'finhead.mum@acme.test')->first();
        $proc = User::where('email', 'proc.mum@acme.test')->first();

        // SALES budget is 1,00,000. Create two POs of 60,000 each
        $po1 = DB::table('purchase_orders')->insertGetId([
            'company_id' => $mum->id, 'vendor_id' => $vendor->id, 'cost_centre_id' => $salesCc->id,
            'created_by' => $proc->id, 'status' => 'PENDING_APPROVAL', 'total_amount' => 60000.00
        ]);
        $po2 = DB::table('purchase_orders')->insertGetId([
            'company_id' => $mum->id, 'vendor_id' => $vendor->id, 'cost_centre_id' => $salesCc->id,
            'created_by' => $proc->id, 'status' => 'PENDING_APPROVAL', 'total_amount' => 60000.00
        ]);

        $service->approvePurchaseOrder($po1, $finHead->id);

        $this->expectException(Exception::class);
        $this->expectExceptionMessage('Insufficient budget');
        $service->approvePurchaseOrder($po2, $finHead->id);
    }

    // Test 6: Over-receipt tolerance 5% blocked (Scenario S4)
    public function test_grn_blocks_over_receipt_above_5_percent(): void
    {
        $service = new P2PService();
        $mum = DB::table('companies')->where('code', 'ACME-MUM')->first();
        $cc = DB::table('cost_centres')->where('company_id', $mum->id)->first();
        $vendor = DB::table('vendors')->where('company_id', $mum->id)->first();
        $item = DB::table('items')->where('code', 'I005')->first();
        $store = User::where('email', 'store.mum@acme.test')->first();

        $poId = DB::table('purchase_orders')->insertGetId([
            'company_id' => $mum->id, 'vendor_id' => $vendor->id, 'cost_centre_id' => $cc->id,
            'created_by' => $store->id, 'status' => 'APPROVED', 'total_amount' => 1000
        ]);
        $poItemId = DB::table('po_items')->insertGetId([
            'purchase_order_id' => $poId, 'item_id' => $item->id, 'uom_code' => 'BOX',
            'quantity' => 10, 'base_quantity' => 120, 'unit_price' => 100, 'gst_rate' => 12
        ]);

        // 120 + 5% = 126 max allowed. Attempting 128 PCS should fail
        $this->expectException(Exception::class);
        $this->expectExceptionMessage('Over-receipt blocked');
        $service->recordGrn($poId, $store->id, [
            ['po_item_id' => $poItemId, 'uom_code' => 'PCS', 'received_qty' => 128, 'accepted_qty' => 128]
        ]);
    }

    // Test 7: 3-Way Match Pass Case
    public function test_three_way_match_passes_within_tolerance(): void
    {
        [$poId, $poItemId] = $this->createApprovedPoWithGrn(100, 100, '25.00');
        $service = new P2PService();
        // +1.6% price (25.40) is within +/- 2%
        $res = $service->createAndMatchInvoice($poId, 'INV-001', '2026-11-24', [
            ['po_item_id' => $poItemId, 'billed_qty' => 100, 'unit_price' => '25.40', 'gst_rate' => '12']
        ]);
        $this->assertEquals('MATCHED', $res['status']);
    }

    // Test 8: 3-Way Match Hold Case 1 - Quantity Exceeded (Scenario S5)
    public function test_three_way_match_holds_on_quantity_mismatch(): void
    {
        [$poId, $poItemId] = $this->createApprovedPoWithGrn(120, 124, '25.00');
        $service = new P2PService();
        $res = $service->createAndMatchInvoice($poId, 'INV-002', '2026-11-24', [
            ['po_item_id' => $poItemId, 'billed_qty' => 130, 'unit_price' => '25.00', 'gst_rate' => '12']
        ]);
        $this->assertEquals('ON_HOLD', $res['status']);
    }

    // Test 9: 3-Way Match Hold Case 2 - Price Variance > 2% (Scenario S5)
    public function test_three_way_match_holds_on_price_mismatch(): void
    {
        [$poId, $poItemId] = $this->createApprovedPoWithGrn(100, 100, '25.00');
        $service = new P2PService();
        // +3.2% price (25.80) exceeds +/- 2%
        $res = $service->createAndMatchInvoice($poId, 'INV-003', '2026-11-24', [
            ['po_item_id' => $poItemId, 'billed_qty' => 100, 'unit_price' => '25.80', 'gst_rate' => '12']
        ]);
        $this->assertEquals('ON_HOLD', $res['status']);
    }

    // Test 10: Company Isolation (Scenario S7)
    public function test_company_isolation_blocks_cross_company_po_access(): void
    {
        $mum = DB::table('companies')->where('code', 'ACME-MUM')->first();
        $cc = DB::table('cost_centres')->where('company_id', $mum->id)->first();
        $vendor = DB::table('vendors')->where('company_id', $mum->id)->first();
        $procMum = User::where('email', 'proc.mum@acme.test')->first();
        $procBlr = User::where('email', 'proc.blr@acme.test')->first();

        $mumPoId = DB::table('purchase_orders')->insertGetId([
            'company_id' => $mum->id, 'vendor_id' => $vendor->id, 'cost_centre_id' => $cc->id,
            'created_by' => $procMum->id, 'status' => 'PENDING_APPROVAL', 'total_amount' => 5000
        ]);

        // Bengaluru user trying to approve Mumbai PO must get 403
        $response = $this->withoutMiddleware(\Illuminate\Foundation\Http\Middleware\ValidateCsrfToken::class)
        ->actingAs($procBlr)
        ->post("/po/{$mumPoId}/approve");
        $response->assertStatus(403);
    }

    private function createApprovedPoWithGrn(int $ordered, int $accepted, string $price): array
    {
        $mum = DB::table('companies')->where('code', 'ACME-MUM')->first();
        $cc = DB::table('cost_centres')->where('company_id', $mum->id)->first();
        $vendor = DB::table('vendors')->where('company_id', $mum->id)->first();
        $item = DB::table('items')->first();
        $user = User::where('email', 'proc.mum@acme.test')->first();

        $poId = DB::table('purchase_orders')->insertGetId([
            'company_id' => $mum->id, 'vendor_id' => $vendor->id, 'cost_centre_id' => $cc->id,
            'created_by' => $user->id, 'status' => 'RECEIVED', 'total_amount' => 1000
        ]);
        $poItemId = DB::table('po_items')->insertGetId([
            'purchase_order_id' => $poId, 'item_id' => $item->id, 'uom_code' => 'PCS',
            'quantity' => $ordered, 'base_quantity' => $ordered,
            'accepted_base_quantity' => $accepted, 'unit_price' => $price, 'gst_rate' => 12
        ]);

        return [$poId, $poItemId];
    }
}