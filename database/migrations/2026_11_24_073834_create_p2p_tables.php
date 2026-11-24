<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        Schema::create('companies', function (Blueprint $table) {
            $table->id();
            $table->string('code')->unique(); 
            $table->string('name');
            $table->string('state');
            $table->string('gstin');
            $table->timestamps();
        });

        Schema::table('users', function (Blueprint $table) {
            $table->foreignId('company_id')->nullable()->constrained()->cascadeOnDelete();
        });

        Schema::create('roles', function (Blueprint $table) {
            $table->id();
            $table->string('name')->unique(); 
            $table->timestamps();
        });

        Schema::create('role_user', function (Blueprint $table) {
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->foreignId('role_id')->constrained()->cascadeOnDelete();
            $table->primary(['user_id', 'role_id']);
        });

        Schema::create('uoms', function (Blueprint $table) {
            $table->id();
            $table->string('code')->unique(); 
            $table->string('base_unit');
            $table->decimal('factor', 10, 4);
            $table->timestamps();
        });

        Schema::create('cost_centres', function (Blueprint $table) {
            $table->id();
            $table->foreignId('company_id')->constrained()->cascadeOnDelete();
            $table->string('code'); 
            $table->timestamps();
        });

        Schema::create('budgets', function (Blueprint $table) {
            $table->id();
            $table->foreignId('company_id')->constrained()->cascadeOnDelete();
            $table->foreignId('cost_centre_id')->constrained()->cascadeOnDelete();
            $table->string('financial_year'); 
            $table->decimal('total_budget', 15, 2);
            $table->decimal('committed', 15, 2)->default(0);
            $table->decimal('spent', 15, 2)->default(0);
            $table->timestamps();
        });

        Schema::create('vendors', function (Blueprint $table) {
            $table->id();
            $table->foreignId('company_id')->constrained()->cascadeOnDelete();
            $table->string('code')->unique();
            $table->string('name');
            $table->string('state');
            $table->string('gstin');
            $table->integer('payment_terms_days')->default(30);
            $table->boolean('is_active')->default(true);
            $table->timestamps();
        });

        Schema::create('items', function (Blueprint $table) {
            $table->id();
            $table->string('code')->unique();
            $table->string('name');
            $table->string('category'); 
            $table->string('base_uom');
            $table->decimal('gst_rate', 5, 2);
            $table->timestamps();
        });

        Schema::create('approval_rules', function (Blueprint $table) {
            $table->id();
            $table->string('document_type'); // PR or PO
            $table->decimal('min_amount', 15, 2);
            $table->decimal('max_amount', 15, 2)->nullable();
            $table->string('category')->nullable();
            $table->json('approver_roles'); 
            $table->boolean('is_extra_step')->default(false);
            $table->string('insert_after_role')->nullable(); 
            $table->timestamps();
        });

        Schema::create('purchase_requisitions', function (Blueprint $table) {
            $table->id();
            $table->foreignId('company_id')->constrained()->cascadeOnDelete();
            $table->foreignId('requester_id')->constrained('users');
            $table->foreignId('cost_centre_id')->constrained();
            $table->date('needed_by');
            $table->string('status')->default('DRAFT');
            $table->decimal('total_estimated_amount', 15, 2)->default(0);
            $table->timestamps();
        });

        Schema::create('pr_items', function (Blueprint $table) {
            $table->id();
            $table->foreignId('purchase_requisition_id')->constrained()->cascadeOnDelete();
            $table->foreignId('item_id')->constrained();
            $table->string('uom_code');
            $table->decimal('quantity', 12, 2);
            $table->decimal('ordered_quantity', 12, 2)->default(0);
            $table->decimal('estimated_price', 15, 2);
            $table->timestamps();
        });

        Schema::create('document_approvals', function (Blueprint $table) {
            $table->id();
            $table->string('approvable_type');
            $table->unsignedBigInteger('approvable_id');
            $table->integer('step_order');
            $table->string('role_name');
            $table->foreignId('approver_id')->nullable()->constrained('users');
            $table->string('status')->default('PENDING');
            $table->text('comment')->nullable();
            $table->timestamp('acted_at')->nullable();
            $table->timestamps();
        });

        Schema::create('purchase_orders', function (Blueprint $table) {
            $table->id();
            $table->foreignId('company_id')->constrained()->cascadeOnDelete();
            $table->foreignId('vendor_id')->constrained();
            $table->foreignId('cost_centre_id')->constrained();
            $table->foreignId('created_by')->constrained('users');
            $table->string('status')->default('DRAFT'); 
            $table->decimal('taxable_amount', 15, 2)->default(0);
            $table->decimal('cgst_amount', 15, 2)->default(0);
            $table->decimal('sgst_amount', 15, 2)->default(0);
            $table->decimal('igst_amount', 15, 2)->default(0);
            $table->decimal('total_amount', 15, 2)->default(0);
            $table->timestamps();
        });

        Schema::create('po_items', function (Blueprint $table) {
            $table->id();
            $table->foreignId('purchase_order_id')->constrained()->cascadeOnDelete();
            $table->foreignId('pr_item_id')->nullable()->constrained('pr_items');
            $table->foreignId('item_id')->constrained();
            $table->string('uom_code');
            $table->decimal('quantity', 12, 2);
            $table->decimal('base_quantity', 12, 2); 
            $table->decimal('accepted_base_quantity', 12, 2)->default(0);
            $table->decimal('invoiced_base_quantity', 12, 2)->default(0);
            $table->decimal('unit_price', 15, 2);
            $table->decimal('gst_rate', 5, 2);
            $table->timestamps();
        });

        Schema::create('grns', function (Blueprint $table) {
            $table->id();
            $table->foreignId('company_id')->constrained()->cascadeOnDelete();
            $table->foreignId('purchase_order_id')->constrained();
            $table->foreignId('received_by')->constrained('users');
            $table->date('received_date');
            $table->timestamps();
        });

        Schema::create('grn_items', function (Blueprint $table) {
            $table->id();
            $table->foreignId('grn_id')->constrained()->cascadeOnDelete();
            $table->foreignId('po_item_id')->constrained();
            $table->string('uom_code');
            $table->decimal('received_qty', 12, 2);
            $table->decimal('accepted_qty', 12, 2);
            $table->decimal('rejected_qty', 12, 2)->default(0);
            $table->string('rejection_reason')->nullable();
            $table->timestamps();
        });

        Schema::create('invoices', function (Blueprint $table) {
            $table->id();
            $table->foreignId('company_id')->constrained()->cascadeOnDelete();
            $table->foreignId('purchase_order_id')->constrained();
            $table->foreignId('vendor_id')->constrained();
            $table->string('vendor_invoice_number');
            $table->date('invoice_date');
            $table->string('status')->default('PENDING'); 
            $table->text('hold_reason')->nullable();
            $table->text('override_comment')->nullable();
            $table->decimal('taxable_amount', 15, 2);
            $table->decimal('tax_amount', 15, 2);
            $table->decimal('total_amount', 15, 2);
            $table->timestamps();
            $table->unique(['vendor_id', 'vendor_invoice_number']);
        });

        Schema::create('invoice_items', function (Blueprint $table) {
            $table->id();
            $table->foreignId('invoice_id')->constrained()->cascadeOnDelete();
            $table->foreignId('po_item_id')->constrained();
            $table->decimal('billed_qty', 12, 2);
            $table->decimal('unit_price', 15, 2);
            $table->decimal('gst_rate', 5, 2);
            $table->timestamps();
        });

        Schema::create('audit_logs', function (Blueprint $table) {
            $table->id();
            $table->string('auditable_type');
            $table->unsignedBigInteger('auditable_id');
            $table->foreignId('user_id')->nullable()->constrained('users');
            $table->string('from_status')->nullable();
            $table->string('to_status');
            $table->text('comment')->nullable();
            $table->timestamp('created_at')->useCurrent();
        });
    }

    public function down(): void
    {
        // Drop in reverse order
    }
};