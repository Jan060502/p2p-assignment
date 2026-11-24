<?php

namespace App\Services;

use App\Models\AuditLog;
use App\Models\User;
use Illuminate\Support\Facades\DB;
use Exception;

class P2PService
{
    // 1. Audit Trail Helper
    public function logAudit(string $type, int $id, ?int $userId, ?string $from, string $to, ?string $comment = null): void
    {
        AuditLog::create([
            'auditable_type' => $type,
            'auditable_id' => $id,
            'user_id' => $userId,
            'from_status' => $from,
            'to_status' => $to,
            'comment' => $comment,
            'created_at' => now(),
        ]);
    }

    // 2. Approval Chain Generator (M3 + Scenario S2 & S8)[cite: 1]
    public function buildApprovalChain(string $docType, string $amount, ?string $category, int $creatorId): void
    {
        $baseRule = DB::table('approval_rules')
            ->where('document_type', $docType)
            ->where('is_extra_step', false)
            ->where('min_amount', '<=', $amount)
            ->where(function ($q) use ($amount) {
                $q->whereNull('max_amount')->orWhere('max_amount', '>=', $amount);
            })
            ->first();

        $roles = $baseRule ? json_decode($baseRule->approver_roles, true) : [];

        // Check extra step rule (e.g., IT category adds IT Head after Dept Head)[cite: 1]
        if ($category) {
            $extraRule = DB::table('approval_rules')
                ->where('document_type', $docType)
                ->where('is_extra_step', true)
                ->where('category', $category)
                ->first();

            if ($extraRule) {
                $extraRoles = json_decode($extraRule->approver_roles, true);
                $pos = array_search($extraRule->insert_after_role, $roles);
                if ($pos !== false) {
                    array_splice($roles, $pos + 1, 0, $extraRoles);
                } else {
                    $roles = array_merge($roles, $extraRoles);
                }
            }
        }

        $creator = User::with('roles')->find($creatorId);
        $step = 1;

        foreach ($roles as $roleName) {
            // S8: User cannot approve their own document -> skip their own role step[cite: 1]
            $isSelfRole = $creator && $creator->hasRole($roleName);

            DB::table('document_approvals')->insert([
                'approvable_type' => $docType,
                'approvable_id' => request()->route('id') ?? 0, // Replaced below when called with ID
                'step_order' => $step++,
                'role_name' => $roleName,
                'status' => $isSelfRole ? 'SKIPPED' : 'PENDING',
                'comment' => $isSelfRole ? 'Auto-skipped self-approval' : null,
                'created_at' => now(),
                'updated_at' => now(),
            ]);
        }
    }

    // 3. GST Calculation (Intra-state CGST+SGST vs Inter-state IGST)[cite: 1]
    public function calculateGst(string $taxable, string $gstRate, string $companyState, string $vendorState): array
    {
        $totalTax = bcdiv(bcmul($taxable, $gstRate, 4), '100', 2);

        if (strcasecmp(trim($companyState), trim($vendorState)) === 0) {
            $half = bcdiv($totalTax, '2', 2);
            return ['cgst' => $half, 'sgst' => bcsub($totalTax, $half, 2), 'igst' => '0.00'];
        }

        return ['cgst' => '0.00', 'sgst' => '0.00', 'igst' => $totalTax];
    }

    // 4. PO Approval with Concurrency Budget Lock (M2 + Scenario S3)[cite: 1]
    public function approvePurchaseOrder(int $poId, int $userId): void
    {
        DB::transaction(function () use ($poId, $userId) {
            $po = DB::table('purchase_orders')->where('id', $poId)->lockForUpdate()->first();
            if (!$po) throw new Exception('PO not found');
            if ($po->created_by == $userId) throw new Exception('You cannot approve your own PO.'); //[cite: 1]

            // Lock budget row to prevent concurrent negative balance[cite: 1]
            $budget = DB::table('budgets')
                ->where('company_id', $po->company_id)
                ->where('cost_centre_id', $po->cost_centre_id)
                ->where('financial_year', '2026-27')
                ->lockForUpdate()
                ->first();

            $available = bcsub(bcsub($budget->total_budget, $budget->committed, 2), $budget->spent, 2);

            if (bccomp($available, $po->total_amount, 2) < 0) {
                throw new Exception("Insufficient budget! Available: ₹{$available}, Required: ₹{$po->total_amount}"); //[cite: 1]
            }

            DB::table('budgets')->where('id', $budget->id)->update([
                'committed' => bcadd($budget->committed, $po->total_amount, 2),
                'updated_at' => now(),
            ]);

            DB::table('purchase_orders')->where('id', $poId)->update([
                'status' => 'APPROVED',
                'updated_at' => now(),
            ]);

            $this->logAudit('PO', $poId, $userId, $po->status, 'APPROVED', 'PO approved and budget committed');
        });
    }

    // 5. GRN Recording with Unit Conversion & 5% Over-receipt Tolerance (M5 + Scenario S4)[cite: 1]
    public function recordGrn(int $poId, int $userId, array $lines): int
    {
        return DB::transaction(function () use ($poId, $userId, $lines) {
            $po = DB::table('purchase_orders')->where('id', $poId)->lockForUpdate()->first();
            if (!in_array($po->status, ['APPROVED', 'PARTIALLY_RECEIVED'])) {
                throw new Exception('PO must be APPROVED before receiving goods.');
            }

            $grnId = DB::table('grns')->insertGetId([
                'company_id' => $po->company_id,
                'purchase_order_id' => $poId,
                'received_by' => $userId,
                'received_date' => now()->toDateString(),
                'created_at' => now(),
                'updated_at' => now(),
            ]);

            foreach ($lines as $line) {
                $poItem = DB::table('po_items')->where('id', $line['po_item_id'])->lockForUpdate()->first();
                $uom = DB::table('uoms')->where('code', $line['uom_code'])->first();

                // Convert accepted qty to base UoM (e.g., BOX -> PCS)[cite: 1]
                $acceptedBase = bcmul((string)$line['accepted_qty'], (string)$uom->factor, 2);
                $maxAllowed = bcmul((string)$poItem->base_quantity, '1.05', 2); // 5% tolerance[cite: 1]
                $newTotalAccepted = bcadd((string)$poItem->accepted_base_quantity, $acceptedBase, 2);

                if (bccomp($newTotalAccepted, $maxAllowed, 2) > 0) {
                    throw new Exception("Over-receipt blocked! Max allowed (with 5% tolerance): {$maxAllowed}, Attempted total: {$newTotalAccepted}"); //[cite: 1]
                }

                DB::table('grn_items')->insert([
                    'grn_id' => $grnId,
                    'po_item_id' => $poItem->id,
                    'uom_code' => $line['uom_code'],
                    'received_qty' => $line['received_qty'],
                    'accepted_qty' => $line['accepted_qty'],
                    'rejected_qty' => $line['rejected_qty'] ?? 0,
                    'rejection_reason' => $line['rejection_reason'] ?? null,
                    'created_at' => now(),
                    'updated_at' => now(),
                ]);

                DB::table('po_items')->where('id', $poItem->id)->update([
                    'accepted_base_quantity' => $newTotalAccepted,
                    'updated_at' => now(),
                ]);
            }

            // Update PO Status[cite: 1]
            $items = DB::table('po_items')->where('purchase_order_id', $poId)->get();
            $allReceived = $items->every(fn ($i) => bccomp((string)$i->accepted_base_quantity, (string)$i->base_quantity, 2) >= 0);
            $newStatus = $allReceived ? 'RECEIVED' : 'PARTIALLY_RECEIVED';

            DB::table('purchase_orders')->where('id', $poId)->update(['status' => $newStatus, 'updated_at' => now()]);
            $this->logAudit('PO', $poId, $userId, $po->status, $newStatus, "GRN #{$grnId} recorded");

            return $grnId;
        });
    }

    // 6. Invoice & 3-Way Match (M6 + Scenario S5)[cite: 1]
    public function createAndMatchInvoice(int $poId, string $invNumber, string $invDate, array $lines): array
    {
        return DB::transaction(function () use ($poId, $invNumber, $invDate, $lines) {
            $po = DB::table('purchase_orders')->where('id', $poId)->first();
            $holdReasons = [];
            $taxableTotal = '0.00';
            $taxTotal = '0.00';

            foreach ($lines as $line) {
                $poItem = DB::table('po_items')->where('id', $line['po_item_id'])->first();
                $remainingAccepted = bcsub((string)$poItem->accepted_base_quantity, (string)$poItem->invoiced_base_quantity, 2);

                // Check 1: Quantity <= accepted - already invoiced[cite: 1]
                if (bccomp((string)$line['billed_qty'], $remainingAccepted, 2) > 0) {
                    $holdReasons[] = "Item #{$poItem->item_id}: Billed qty ({$line['billed_qty']}) exceeds unbilled accepted qty ({$remainingAccepted}).";
                }

                // Check 2: Price within +/- 2% of PO unit price[cite: 1]
                $minPrice = bcmul((string)$poItem->unit_price, '0.98', 2);
                $maxPrice = bcmul((string)$poItem->unit_price, '1.02', 2);
                if (bccomp((string)$line['unit_price'], $minPrice, 2) < 0 || bccomp((string)$line['unit_price'], $maxPrice, 2) > 0) {
                    $holdReasons[] = "Item #{$poItem->item_id}: Price ({$line['unit_price']}) outside ±2% of PO price ({$poItem->unit_price}).";
                }

                // Check 3: GST Rate match[cite: 1]
                if (bccomp((string)$line['gst_rate'], (string)$poItem->gst_rate, 2) !== 0) {
                    $holdReasons[] = "Item #{$poItem->item_id}: GST rate mismatch.";
                }

                $lineTaxable = bcmul((string)$line['billed_qty'], (string)$line['unit_price'], 2);
                $lineTax = bcdiv(bcmul($lineTaxable, (string)$line['gst_rate'], 4), '100', 2);
                $taxableTotal = bcadd($taxableTotal, $lineTaxable, 2);
                $taxTotal = bcadd($taxTotal, $lineTax, 2);
            }

            $status = empty($holdReasons) ? 'MATCHED' : 'ON_HOLD';
            $grandTotal = bcadd($taxableTotal, $taxTotal, 2);

            $invId = DB::table('invoices')->insertGetId([
                'company_id' => $po->company_id,
                'purchase_order_id' => $poId,
                'vendor_id' => $po->vendor_id,
                'vendor_invoice_number' => $invNumber,
                'invoice_date' => $invDate,
                'status' => $status,
                'hold_reason' => empty($holdReasons) ? null : implode(' | ', $holdReasons),
                'taxable_amount' => $taxableTotal,
                'tax_amount' => $taxTotal,
                'total_amount' => $grandTotal,
                'created_at' => now(),
                'updated_at' => now(),
            ]);

            return ['invoice_id' => $invId, 'status' => $status, 'hold_reasons' => $holdReasons];
        });
    }
}