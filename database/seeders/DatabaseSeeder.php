<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;

class DatabaseSeeder extends Seeder
{
    public function run(): void
    {
        // 1. Companies[cite: 1]
        $mumId = DB::table('companies')->insertGetId([
            'code' => 'ACME-MUM',
            'name' => 'Acme Mumbai Pvt Ltd',
            'state' => 'Maharashtra',
            'gstin' => '27AAACA1234A1Z5',
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        $blrId = DB::table('companies')->insertGetId([
            'code' => 'ACME-BLR',
            'name' => 'Acme Bengaluru Pvt Ltd',
            'state' => 'Karnataka',
            'gstin' => '29AAACA1234A1Z1',
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        // 2. Roles[cite: 1]
        $roleNames = [
            'Admin', 'Requester', 'Dept Head', 'IT Head',
            'Finance Head', 'CFO', 'Procurement Officer',
            'Store Keeper', 'Accounts'
        ];
        $roleIds = [];
        foreach ($roleNames as $role) {
            $roleIds[$role] = DB::table('roles')->insertGetId([
                'name' => $role,
                'created_at' => now(),
                'updated_at' => now(),
            ]);
        }

        // 3. Users (password for all: password)[cite: 1]
        $users = [
            ['email' => 'admin.mum@acme.test', 'company_id' => $mumId, 'roles' => ['Admin']],
            ['email' => 'req.mum@acme.test', 'company_id' => $mumId, 'roles' => ['Requester']],
            ['email' => 'depthead.mum@acme.test', 'company_id' => $mumId, 'roles' => ['Dept Head', 'Requester']],
            ['email' => 'ithead.mum@acme.test', 'company_id' => $mumId, 'roles' => ['IT Head']],
            ['email' => 'finhead.mum@acme.test', 'company_id' => $mumId, 'roles' => ['Finance Head']],
            ['email' => 'cfo.mum@acme.test', 'company_id' => $mumId, 'roles' => ['CFO']],
            ['email' => 'proc.mum@acme.test', 'company_id' => $mumId, 'roles' => ['Procurement Officer']],
            ['email' => 'store.mum@acme.test', 'company_id' => $mumId, 'roles' => ['Store Keeper']],
            ['email' => 'accounts.mum@acme.test', 'company_id' => $mumId, 'roles' => ['Accounts']],
            ['email' => 'admin.blr@acme.test', 'company_id' => $blrId, 'roles' => ['Admin']],
            ['email' => 'req.blr@acme.test', 'company_id' => $blrId, 'roles' => ['Requester']],
            ['email' => 'depthead.blr@acme.test', 'company_id' => $blrId, 'roles' => ['Dept Head']],
            ['email' => 'proc.blr@acme.test', 'company_id' => $blrId, 'roles' => ['Procurement Officer']],
        ];

        $password = Hash::make('password');
        foreach ($users as $u) {
            $userId = DB::table('users')->insertGetId([
                'name' => explode('@', $u['email'])[0],
                'email' => $u['email'],
                'password' => $password,
                'company_id' => $u['company_id'],
                'created_at' => now(),
                'updated_at' => now(),
            ]);

            foreach ($u['roles'] as $rName) {
                DB::table('role_user')->insert([
                    'user_id' => $userId,
                    'role_id' => $roleIds[$rName],
                ]);
            }
        }

        // 4. Units of Measure[cite: 1]
        DB::table('uoms')->insert([
            ['code' => 'PCS', 'base_unit' => 'PCS', 'factor' => 1, 'created_at' => now(), 'updated_at' => now()],
            ['code' => 'BOX', 'base_unit' => 'PCS', 'factor' => 12, 'created_at' => now(), 'updated_at' => now()],
            ['code' => 'KG', 'base_unit' => 'KG', 'factor' => 1, 'created_at' => now(), 'updated_at' => now()],
            ['code' => 'TON', 'base_unit' => 'KG', 'factor' => 1000, 'created_at' => now(), 'updated_at' => now()],
            ['code' => 'HRS', 'base_unit' => 'HRS', 'factor' => 1, 'created_at' => now(), 'updated_at' => now()],
        ]);

        // 5. Cost Centres & Budgets (FY 2026-27)[cite: 1]
        $budgets = [
            [$mumId, 'PROD', 5000000.00],
            [$mumId, 'IT', 1000000.00],
            [$mumId, 'ADMIN', 200000.00],
            [$mumId, 'SALES', 100000.00],
            [$blrId, 'PROD', 3000000.00],
            [$blrId, 'IT', 500000.00],
        ];

        foreach ($budgets as [$compId, $ccCode, $amount]) {
            $ccId = DB::table('cost_centres')->insertGetId([
                'company_id' => $compId,
                'code' => $ccCode,
                'created_at' => now(),
                'updated_at' => now(),
            ]);

            DB::table('budgets')->insert([
                'company_id' => $compId,
                'cost_centre_id' => $ccId,
                'financial_year' => '2026-27',
                'total_budget' => $amount,
                'committed' => 0,
                'spent' => 0,
                'created_at' => now(),
                'updated_at' => now(),
            ]);
        }

        // 6. Vendors[cite: 1]
        DB::table('vendors')->insert([
            ['company_id' => $mumId, 'code' => 'V001', 'name' => 'Shree Steel Traders', 'state' => 'Maharashtra', 'gstin' => '27AABCS1111A1Z1', 'payment_terms_days' => 30, 'is_active' => true, 'created_at' => now(), 'updated_at' => now()],
            ['company_id' => $mumId, 'code' => 'V002', 'name' => 'Bangalore Tech Supplies', 'state' => 'Karnataka', 'gstin' => '29AABCB2222B1Z2', 'payment_terms_days' => 45, 'is_active' => true, 'created_at' => now(), 'updated_at' => now()],
            ['company_id' => $mumId, 'code' => 'V003', 'name' => 'QuickClean Services', 'state' => 'Maharashtra', 'gstin' => '27AABCQ3333C1Z3', 'payment_terms_days' => 15, 'is_active' => true, 'created_at' => now(), 'updated_at' => now()],
            ['company_id' => $blrId, 'code' => 'V004', 'name' => 'Deccan Packaging', 'state' => 'Karnataka', 'gstin' => '29AABCD4444D1Z4', 'payment_terms_days' => 30, 'is_active' => true, 'created_at' => now(), 'updated_at' => now()],
        ]);

        // 7. Items[cite: 1]
        DB::table('items')->insert([
            ['code' => 'I001', 'name' => 'MS Steel Sheet 2mm', 'category' => 'RAW_MATERIAL', 'base_uom' => 'KG', 'gst_rate' => 18, 'created_at' => now(), 'updated_at' => now()],
            ['code' => 'I002', 'name' => 'Laptop i5 16GB', 'category' => 'IT', 'base_uom' => 'PCS', 'gst_rate' => 18, 'created_at' => now(), 'updated_at' => now()],
            ['code' => 'I003', 'name' => 'A4 Paper Ream', 'category' => 'CONSUMABLES', 'base_uom' => 'PCS', 'gst_rate' => 12, 'created_at' => now(), 'updated_at' => now()],
            ['code' => 'I004', 'name' => 'Housekeeping Service', 'category' => 'SERVICES', 'base_uom' => 'HRS', 'gst_rate' => 18, 'created_at' => now(), 'updated_at' => now()],
            ['code' => 'I005', 'name' => 'Corrugated Box', 'category' => 'CONSUMABLES', 'base_uom' => 'PCS', 'gst_rate' => 12, 'created_at' => now(), 'updated_at' => now()],
            ['code' => 'I006', 'name' => 'Rice (canteen)', 'category' => 'CONSUMABLES', 'base_uom' => 'KG', 'gst_rate' => 0, 'created_at' => now(), 'updated_at' => now()],
        ]);

        // 8. Approval Rules[cite: 1]
        DB::table('approval_rules')->insert([
            ['document_type' => 'PR', 'min_amount' => 0, 'max_amount' => 50000, 'category' => '*', 'approver_roles' => json_encode(['Dept Head']), 'is_extra_step' => false, 'insert_after_role' => null, 'created_at' => now(), 'updated_at' => now()],
            ['document_type' => 'PR', 'min_amount' => 50000.01, 'max_amount' => 500000, 'category' => '*', 'approver_roles' => json_encode(['Dept Head', 'Finance Head']), 'is_extra_step' => false, 'insert_after_role' => null, 'created_at' => now(), 'updated_at' => now()],
            ['document_type' => 'PR', 'min_amount' => 500000.01, 'max_amount' => null, 'category' => '*', 'approver_roles' => json_encode(['Dept Head', 'Finance Head', 'CFO']), 'is_extra_step' => false, 'insert_after_role' => null, 'created_at' => now(), 'updated_at' => now()],
            ['document_type' => 'PR', 'min_amount' => 0, 'max_amount' => null, 'category' => 'IT', 'approver_roles' => json_encode(['IT Head']), 'is_extra_step' => true, 'insert_after_role' => 'Dept Head', 'created_at' => now(), 'updated_at' => now()],
            ['document_type' => 'PO', 'min_amount' => 0, 'max_amount' => 200000, 'category' => '*', 'approver_roles' => json_encode(['Finance Head']), 'is_extra_step' => false, 'insert_after_role' => null, 'created_at' => now(), 'updated_at' => now()],
            ['document_type' => 'PO', 'min_amount' => 200000.01, 'max_amount' => null, 'category' => '*', 'approver_roles' => json_encode(['Finance Head', 'CFO']), 'is_extra_step' => false, 'insert_after_role' => null, 'created_at' => now(), 'updated_at' => now()],
        ]);
    }
}