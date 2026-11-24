-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1
-- Generation Time: Nov 24, 2026 at 01:45 PM
-- Server version: 10.4.32-MariaDB
-- PHP Version: 8.2.12

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `p2p_db`
--

-- --------------------------------------------------------

--
-- Table structure for table `approval_rules`
--

CREATE TABLE `approval_rules` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `document_type` varchar(255) NOT NULL,
  `min_amount` decimal(15,2) NOT NULL,
  `max_amount` decimal(15,2) DEFAULT NULL,
  `category` varchar(255) DEFAULT NULL,
  `approver_roles` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL CHECK (json_valid(`approver_roles`)),
  `is_extra_step` tinyint(1) NOT NULL DEFAULT 0,
  `insert_after_role` varchar(255) DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `approval_rules`
--

INSERT INTO `approval_rules` (`id`, `document_type`, `min_amount`, `max_amount`, `category`, `approver_roles`, `is_extra_step`, `insert_after_role`, `created_at`, `updated_at`) VALUES
(1, 'PR', 0.00, 50000.00, '*', '[\"Dept Head\"]', 0, NULL, '2026-11-24 02:57:02', '2026-11-24 02:57:02'),
(2, 'PR', 50000.01, 500000.00, '*', '[\"Dept Head\",\"Finance Head\"]', 0, NULL, '2026-11-24 02:57:02', '2026-11-24 02:57:02'),
(3, 'PR', 500000.01, NULL, '*', '[\"Dept Head\",\"Finance Head\",\"CFO\"]', 0, NULL, '2026-11-24 02:57:02', '2026-11-24 02:57:02'),
(4, 'PR', 0.00, NULL, 'IT', '[\"IT Head\"]', 1, 'Dept Head', '2026-11-24 02:57:02', '2026-11-24 02:57:02'),
(5, 'PO', 0.00, 200000.00, '*', '[\"Finance Head\"]', 0, NULL, '2026-11-24 02:57:02', '2026-11-24 02:57:02'),
(6, 'PO', 200000.01, NULL, '*', '[\"Finance Head\",\"CFO\"]', 0, NULL, '2026-11-24 02:57:02', '2026-11-24 02:57:02');

-- --------------------------------------------------------

--
-- Table structure for table `audit_logs`
--

CREATE TABLE `audit_logs` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `auditable_type` varchar(255) NOT NULL,
  `auditable_id` bigint(20) UNSIGNED NOT NULL,
  `user_id` bigint(20) UNSIGNED DEFAULT NULL,
  `from_status` varchar(255) DEFAULT NULL,
  `to_status` varchar(255) NOT NULL,
  `comment` text DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `audit_logs`
--

INSERT INTO `audit_logs` (`id`, `auditable_type`, `auditable_id`, `user_id`, `from_status`, `to_status`, `comment`, `created_at`) VALUES
(1, 'PR', 1, 1, 'DRAFT', 'SUBMITTED', 'PR Created & Submitted', '2026-11-24 04:11:05'),
(2, 'PR', 2, 1, 'DRAFT', 'SUBMITTED', 'PR Created & Submitted', '2026-11-24 04:11:54'),
(3, 'PR', 2, 4, 'SUBMITTED', 'APPROVED', 'PR Approved', '2026-11-24 04:13:19'),
(4, 'PO', 1, 4, 'DRAFT', 'PENDING_APPROVAL', 'Converted from PR #2', '2026-11-24 04:13:25'),
(5, 'PO', 1, 7, 'PENDING_APPROVAL', 'APPROVED', 'PO approved and budget committed', '2026-11-24 04:14:14'),
(6, 'PO', 1, 7, 'APPROVED', 'RECEIVED', 'GRN #1 recorded', '2026-11-24 04:14:18'),
(7, 'PR', 1, 3, 'SUBMITTED', 'APPROVED', 'PR Approved', '2026-11-24 04:21:22'),
(8, 'PO', 2, 7, 'DRAFT', 'PENDING_APPROVAL', 'Converted from PR #1', '2026-11-24 04:22:08'),
(9, 'PO', 2, 5, 'PENDING_APPROVAL', 'APPROVED', 'PO approved and budget committed', '2026-11-24 04:22:56'),
(10, 'PO', 2, 8, 'APPROVED', 'RECEIVED', 'GRN #4 recorded', '2026-11-24 04:27:43');

-- --------------------------------------------------------

--
-- Table structure for table `budgets`
--

CREATE TABLE `budgets` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `company_id` bigint(20) UNSIGNED NOT NULL,
  `cost_centre_id` bigint(20) UNSIGNED NOT NULL,
  `financial_year` varchar(255) NOT NULL,
  `total_budget` decimal(15,2) NOT NULL,
  `committed` decimal(15,2) NOT NULL DEFAULT 0.00,
  `spent` decimal(15,2) NOT NULL DEFAULT 0.00,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `budgets`
--

INSERT INTO `budgets` (`id`, `company_id`, `cost_centre_id`, `financial_year`, `total_budget`, `committed`, `spent`, `created_at`, `updated_at`) VALUES
(1, 1, 1, '2026-27', 5000000.00, 14455.00, 14455.00, '2026-11-24 02:56:47', '2026-11-24 04:22:55'),
(2, 1, 2, '2026-27', 1000000.00, 0.00, 0.00, '2026-11-24 02:56:51', '2026-11-24 02:56:51'),
(3, 1, 3, '2026-27', 200000.00, 0.00, 0.00, '2026-11-24 02:56:54', '2026-11-24 02:56:54'),
(4, 1, 4, '2026-27', 100000.00, 0.00, 0.00, '2026-11-24 02:56:55', '2026-11-24 02:56:55'),
(5, 2, 5, '2026-27', 3000000.00, 0.00, 0.00, '2026-11-24 02:56:57', '2026-11-24 02:56:57'),
(6, 2, 6, '2026-27', 500000.00, 0.00, 0.00, '2026-11-24 02:56:58', '2026-11-24 02:56:58');

-- --------------------------------------------------------

--
-- Table structure for table `cache`
--

CREATE TABLE `cache` (
  `key` varchar(255) NOT NULL,
  `value` mediumtext NOT NULL,
  `expiration` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `cache_locks`
--

CREATE TABLE `cache_locks` (
  `key` varchar(255) NOT NULL,
  `owner` varchar(255) NOT NULL,
  `expiration` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `companies`
--

CREATE TABLE `companies` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `code` varchar(255) NOT NULL,
  `name` varchar(255) NOT NULL,
  `state` varchar(255) NOT NULL,
  `gstin` varchar(255) NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `companies`
--

INSERT INTO `companies` (`id`, `code`, `name`, `state`, `gstin`, `created_at`, `updated_at`) VALUES
(1, 'ACME-MUM', 'Acme Mumbai Pvt Ltd', 'Maharashtra', '27AAACA1234A1Z5', '2026-11-24 02:55:48', '2026-11-24 02:55:48'),
(2, 'ACME-BLR', 'Acme Bengaluru Pvt Ltd', 'Karnataka', '29AAACA1234A1Z1', '2026-11-24 02:55:49', '2026-11-24 02:55:49');

-- --------------------------------------------------------

--
-- Table structure for table `cost_centres`
--

CREATE TABLE `cost_centres` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `company_id` bigint(20) UNSIGNED NOT NULL,
  `code` varchar(255) NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `cost_centres`
--

INSERT INTO `cost_centres` (`id`, `company_id`, `code`, `created_at`, `updated_at`) VALUES
(1, 1, 'PROD', '2026-11-24 02:56:46', '2026-11-24 02:56:46'),
(2, 1, 'IT', '2026-11-24 02:56:49', '2026-11-24 02:56:49'),
(3, 1, 'ADMIN', '2026-11-24 02:56:52', '2026-11-24 02:56:52'),
(4, 1, 'SALES', '2026-11-24 02:56:54', '2026-11-24 02:56:54'),
(5, 2, 'PROD', '2026-11-24 02:56:57', '2026-11-24 02:56:57'),
(6, 2, 'IT', '2026-11-24 02:56:58', '2026-11-24 02:56:58');

-- --------------------------------------------------------

--
-- Table structure for table `document_approvals`
--

CREATE TABLE `document_approvals` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `approvable_type` varchar(255) NOT NULL,
  `approvable_id` bigint(20) UNSIGNED NOT NULL,
  `step_order` int(11) NOT NULL,
  `role_name` varchar(255) NOT NULL,
  `approver_id` bigint(20) UNSIGNED DEFAULT NULL,
  `status` varchar(255) NOT NULL DEFAULT 'PENDING',
  `comment` text DEFAULT NULL,
  `acted_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `document_approvals`
--

INSERT INTO `document_approvals` (`id`, `approvable_type`, `approvable_id`, `step_order`, `role_name`, `approver_id`, `status`, `comment`, `acted_at`, `created_at`, `updated_at`) VALUES
(1, 'PR', 1, 1, 'Dept Head', NULL, 'PENDING', NULL, NULL, '2026-11-24 04:11:05', '2026-11-24 04:11:05'),
(2, 'PR', 2, 1, 'Dept Head', NULL, 'PENDING', NULL, NULL, '2026-11-24 04:11:54', '2026-11-24 04:11:54'),
(3, 'PR', 2, 2, 'IT Head', NULL, 'PENDING', NULL, NULL, '2026-11-24 04:11:54', '2026-11-24 04:11:54');

-- --------------------------------------------------------

--
-- Table structure for table `failed_jobs`
--

CREATE TABLE `failed_jobs` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `uuid` varchar(255) NOT NULL,
  `connection` text NOT NULL,
  `queue` text NOT NULL,
  `payload` longtext NOT NULL,
  `exception` longtext NOT NULL,
  `failed_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `grns`
--

CREATE TABLE `grns` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `company_id` bigint(20) UNSIGNED NOT NULL,
  `purchase_order_id` bigint(20) UNSIGNED NOT NULL,
  `received_by` bigint(20) UNSIGNED NOT NULL,
  `received_date` date NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `grns`
--

INSERT INTO `grns` (`id`, `company_id`, `purchase_order_id`, `received_by`, `received_date`, `created_at`, `updated_at`) VALUES
(1, 1, 1, 7, '2026-11-24', '2026-11-24 04:14:18', '2026-11-24 04:14:18'),
(4, 1, 2, 8, '2026-11-24', '2026-11-24 04:27:43', '2026-11-24 04:27:43');

-- --------------------------------------------------------

--
-- Table structure for table `grn_items`
--

CREATE TABLE `grn_items` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `grn_id` bigint(20) UNSIGNED NOT NULL,
  `po_item_id` bigint(20) UNSIGNED NOT NULL,
  `uom_code` varchar(255) NOT NULL,
  `received_qty` decimal(12,2) NOT NULL,
  `accepted_qty` decimal(12,2) NOT NULL,
  `rejected_qty` decimal(12,2) NOT NULL DEFAULT 0.00,
  `rejection_reason` varchar(255) DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `grn_items`
--

INSERT INTO `grn_items` (`id`, `grn_id`, `po_item_id`, `uom_code`, `received_qty`, `accepted_qty`, `rejected_qty`, `rejection_reason`, `created_at`, `updated_at`) VALUES
(1, 1, 1, 'PCS', 50.00, 50.00, 0.00, NULL, '2026-11-24 04:14:18', '2026-11-24 04:14:18'),
(2, 4, 2, 'PCS', 50.00, 50.00, 0.00, NULL, '2026-11-24 04:27:43', '2026-11-24 04:27:43');

-- --------------------------------------------------------

--
-- Table structure for table `invoices`
--

CREATE TABLE `invoices` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `company_id` bigint(20) UNSIGNED NOT NULL,
  `purchase_order_id` bigint(20) UNSIGNED NOT NULL,
  `vendor_id` bigint(20) UNSIGNED NOT NULL,
  `vendor_invoice_number` varchar(255) NOT NULL,
  `invoice_date` date NOT NULL,
  `status` varchar(255) NOT NULL DEFAULT 'PENDING',
  `hold_reason` text DEFAULT NULL,
  `override_comment` text DEFAULT NULL,
  `taxable_amount` decimal(15,2) NOT NULL,
  `tax_amount` decimal(15,2) NOT NULL,
  `total_amount` decimal(15,2) NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `invoices`
--

INSERT INTO `invoices` (`id`, `company_id`, `purchase_order_id`, `vendor_id`, `vendor_invoice_number`, `invoice_date`, `status`, `hold_reason`, `override_comment`, `taxable_amount`, `tax_amount`, `total_amount`, `created_at`, `updated_at`) VALUES
(1, 1, 1, 1, 'INV-475', '2026-11-24', 'POSTED', NULL, NULL, 12250.00, 2205.00, 14455.00, '2026-11-24 04:14:31', '2026-11-24 04:14:31'),
(2, 1, 2, 1, 'INV-387', '2026-11-24', 'ON_HOLD', 'Item #1: Price (260) outside ±2% of PO price (245.00).', NULL, 13000.00, 2340.00, 15340.00, '2026-11-24 04:33:55', '2026-11-24 04:33:55');

-- --------------------------------------------------------

--
-- Table structure for table `invoice_items`
--

CREATE TABLE `invoice_items` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `invoice_id` bigint(20) UNSIGNED NOT NULL,
  `po_item_id` bigint(20) UNSIGNED NOT NULL,
  `billed_qty` decimal(12,2) NOT NULL,
  `unit_price` decimal(15,2) NOT NULL,
  `gst_rate` decimal(5,2) NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `items`
--

CREATE TABLE `items` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `code` varchar(255) NOT NULL,
  `name` varchar(255) NOT NULL,
  `category` varchar(255) NOT NULL,
  `base_uom` varchar(255) NOT NULL,
  `gst_rate` decimal(5,2) NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `items`
--

INSERT INTO `items` (`id`, `code`, `name`, `category`, `base_uom`, `gst_rate`, `created_at`, `updated_at`) VALUES
(1, 'I001', 'MS Steel Sheet 2mm', 'RAW_MATERIAL', 'KG', 18.00, '2026-11-24 02:57:02', '2026-11-24 02:57:02'),
(2, 'I002', 'Laptop i5 16GB', 'IT', 'PCS', 18.00, '2026-11-24 02:57:02', '2026-11-24 02:57:02'),
(3, 'I003', 'A4 Paper Ream', 'CONSUMABLES', 'PCS', 12.00, '2026-11-24 02:57:02', '2026-11-24 02:57:02'),
(4, 'I004', 'Housekeeping Service', 'SERVICES', 'HRS', 18.00, '2026-11-24 02:57:02', '2026-11-24 02:57:02'),
(5, 'I005', 'Corrugated Box', 'CONSUMABLES', 'PCS', 12.00, '2026-11-24 02:57:02', '2026-11-24 02:57:02'),
(6, 'I006', 'Rice (canteen)', 'CONSUMABLES', 'KG', 0.00, '2026-11-24 02:57:02', '2026-11-24 02:57:02');

-- --------------------------------------------------------

--
-- Table structure for table `jobs`
--

CREATE TABLE `jobs` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `queue` varchar(255) NOT NULL,
  `payload` longtext NOT NULL,
  `attempts` tinyint(3) UNSIGNED NOT NULL,
  `reserved_at` int(10) UNSIGNED DEFAULT NULL,
  `available_at` int(10) UNSIGNED NOT NULL,
  `created_at` int(10) UNSIGNED NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `job_batches`
--

CREATE TABLE `job_batches` (
  `id` varchar(255) NOT NULL,
  `name` varchar(255) NOT NULL,
  `total_jobs` int(11) NOT NULL,
  `pending_jobs` int(11) NOT NULL,
  `failed_jobs` int(11) NOT NULL,
  `failed_job_ids` longtext NOT NULL,
  `options` mediumtext DEFAULT NULL,
  `cancelled_at` int(11) DEFAULT NULL,
  `created_at` int(11) NOT NULL,
  `finished_at` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `migrations`
--

CREATE TABLE `migrations` (
  `id` int(10) UNSIGNED NOT NULL,
  `migration` varchar(255) NOT NULL,
  `batch` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `migrations`
--

INSERT INTO `migrations` (`id`, `migration`, `batch`) VALUES
(1, '0001_01_01_000000_create_users_table', 1),
(2, '0001_01_01_000001_create_cache_table', 1),
(3, '0001_01_01_000002_create_jobs_table', 1),
(4, '2026_11_24_073834_create_p2p_tables', 1);

-- --------------------------------------------------------

--
-- Table structure for table `password_reset_tokens`
--

CREATE TABLE `password_reset_tokens` (
  `email` varchar(255) NOT NULL,
  `token` varchar(255) NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `po_items`
--

CREATE TABLE `po_items` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `purchase_order_id` bigint(20) UNSIGNED NOT NULL,
  `pr_item_id` bigint(20) UNSIGNED DEFAULT NULL,
  `item_id` bigint(20) UNSIGNED NOT NULL,
  `uom_code` varchar(255) NOT NULL,
  `quantity` decimal(12,2) NOT NULL,
  `base_quantity` decimal(12,2) NOT NULL,
  `accepted_base_quantity` decimal(12,2) NOT NULL DEFAULT 0.00,
  `invoiced_base_quantity` decimal(12,2) NOT NULL DEFAULT 0.00,
  `unit_price` decimal(15,2) NOT NULL,
  `gst_rate` decimal(5,2) NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `po_items`
--

INSERT INTO `po_items` (`id`, `purchase_order_id`, `pr_item_id`, `item_id`, `uom_code`, `quantity`, `base_quantity`, `accepted_base_quantity`, `invoiced_base_quantity`, `unit_price`, `gst_rate`, `created_at`, `updated_at`) VALUES
(1, 1, 2, 2, 'PCS', 50.00, 50.00, 50.00, 0.00, 245.00, 18.00, '2026-11-24 04:13:25', '2026-11-24 04:14:18'),
(2, 2, 1, 1, 'PCS', 50.00, 50.00, 50.00, 0.00, 245.00, 18.00, '2026-11-24 04:22:07', '2026-11-24 04:27:43');

-- --------------------------------------------------------

--
-- Table structure for table `pr_items`
--

CREATE TABLE `pr_items` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `purchase_requisition_id` bigint(20) UNSIGNED NOT NULL,
  `item_id` bigint(20) UNSIGNED NOT NULL,
  `uom_code` varchar(255) NOT NULL,
  `quantity` decimal(12,2) NOT NULL,
  `ordered_quantity` decimal(12,2) NOT NULL DEFAULT 0.00,
  `estimated_price` decimal(15,2) NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `pr_items`
--

INSERT INTO `pr_items` (`id`, `purchase_requisition_id`, `item_id`, `uom_code`, `quantity`, `ordered_quantity`, `estimated_price`, `created_at`, `updated_at`) VALUES
(1, 1, 1, 'PCS', 50.00, 0.00, 250.00, '2026-11-24 04:11:05', '2026-11-24 04:11:05'),
(2, 2, 2, 'PCS', 50.00, 0.00, 250.00, '2026-11-24 04:11:54', '2026-11-24 04:11:54');

-- --------------------------------------------------------

--
-- Table structure for table `purchase_orders`
--

CREATE TABLE `purchase_orders` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `company_id` bigint(20) UNSIGNED NOT NULL,
  `vendor_id` bigint(20) UNSIGNED NOT NULL,
  `cost_centre_id` bigint(20) UNSIGNED NOT NULL,
  `created_by` bigint(20) UNSIGNED NOT NULL,
  `status` varchar(255) NOT NULL DEFAULT 'DRAFT',
  `taxable_amount` decimal(15,2) NOT NULL DEFAULT 0.00,
  `cgst_amount` decimal(15,2) NOT NULL DEFAULT 0.00,
  `sgst_amount` decimal(15,2) NOT NULL DEFAULT 0.00,
  `igst_amount` decimal(15,2) NOT NULL DEFAULT 0.00,
  `total_amount` decimal(15,2) NOT NULL DEFAULT 0.00,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `purchase_orders`
--

INSERT INTO `purchase_orders` (`id`, `company_id`, `vendor_id`, `cost_centre_id`, `created_by`, `status`, `taxable_amount`, `cgst_amount`, `sgst_amount`, `igst_amount`, `total_amount`, `created_at`, `updated_at`) VALUES
(1, 1, 1, 1, 4, 'RECEIVED', 12250.00, 1102.50, 1102.50, 0.00, 14455.00, '2026-11-24 04:13:24', '2026-11-24 04:14:18'),
(2, 1, 1, 1, 7, 'RECEIVED', 12250.00, 1102.50, 1102.50, 0.00, 14455.00, '2026-11-24 04:22:07', '2026-11-24 04:27:43');

-- --------------------------------------------------------

--
-- Table structure for table `purchase_requisitions`
--

CREATE TABLE `purchase_requisitions` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `company_id` bigint(20) UNSIGNED NOT NULL,
  `requester_id` bigint(20) UNSIGNED NOT NULL,
  `cost_centre_id` bigint(20) UNSIGNED NOT NULL,
  `needed_by` date NOT NULL,
  `status` varchar(255) NOT NULL DEFAULT 'DRAFT',
  `total_estimated_amount` decimal(15,2) NOT NULL DEFAULT 0.00,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `purchase_requisitions`
--

INSERT INTO `purchase_requisitions` (`id`, `company_id`, `requester_id`, `cost_centre_id`, `needed_by`, `status`, `total_estimated_amount`, `created_at`, `updated_at`) VALUES
(1, 1, 1, 1, '2026-12-01', 'CONVERTED', 12500.00, '2026-11-24 04:11:05', '2026-11-24 04:21:22'),
(2, 1, 1, 1, '2026-12-01', 'CONVERTED', 12500.00, '2026-11-24 04:11:53', '2026-11-24 04:13:19');

-- --------------------------------------------------------

--
-- Table structure for table `roles`
--

CREATE TABLE `roles` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `name` varchar(255) NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `roles`
--

INSERT INTO `roles` (`id`, `name`, `created_at`, `updated_at`) VALUES
(1, 'Admin', '2026-11-24 02:55:50', '2026-11-24 02:55:50'),
(2, 'Requester', '2026-11-24 02:55:52', '2026-11-24 02:55:52'),
(3, 'Dept Head', '2026-11-24 02:55:52', '2026-11-24 02:55:52'),
(4, 'IT Head', '2026-11-24 02:55:53', '2026-11-24 02:55:53'),
(5, 'Finance Head', '2026-11-24 02:55:54', '2026-11-24 02:55:54'),
(6, 'CFO', '2026-11-24 02:55:56', '2026-11-24 02:55:56'),
(7, 'Procurement Officer', '2026-11-24 02:55:57', '2026-11-24 02:55:57'),
(8, 'Store Keeper', '2026-11-24 02:56:00', '2026-11-24 02:56:00'),
(9, 'Accounts', '2026-11-24 02:56:01', '2026-11-24 02:56:01');

-- --------------------------------------------------------

--
-- Table structure for table `role_user`
--

CREATE TABLE `role_user` (
  `user_id` bigint(20) UNSIGNED NOT NULL,
  `role_id` bigint(20) UNSIGNED NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `role_user`
--

INSERT INTO `role_user` (`user_id`, `role_id`) VALUES
(1, 1),
(2, 2),
(3, 2),
(3, 3),
(4, 4),
(5, 5),
(6, 6),
(7, 7),
(8, 8),
(9, 9),
(10, 1),
(11, 2),
(12, 3),
(13, 7);

-- --------------------------------------------------------

--
-- Table structure for table `sessions`
--

CREATE TABLE `sessions` (
  `id` varchar(255) NOT NULL,
  `user_id` bigint(20) UNSIGNED DEFAULT NULL,
  `ip_address` varchar(45) DEFAULT NULL,
  `user_agent` text DEFAULT NULL,
  `payload` longtext NOT NULL,
  `last_activity` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `sessions`
--

INSERT INTO `sessions` (`id`, `user_id`, `ip_address`, `user_agent`, `payload`, `last_activity`) VALUES
('MRH8DJgAsZpaiSHtAbfMlkXV4sem1jPqryzC4pNC', 9, '127.0.0.1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/157.0.0.0 Safari/537.36', 'YTo1OntzOjY6Il90b2tlbiI7czo0MDoiazdPekQ3RkhiN1ZRMzVnSTdLN3VkbkNpVURWOTE3SE9OZW51d3Y5dSI7czo5OiJfcHJldmlvdXMiO2E6Mjp7czozOiJ1cmwiO3M6MjE6Imh0dHA6Ly8xMjcuMC4wLjE6ODAwMCI7czo1OiJyb3V0ZSI7Tjt9czo2OiJfZmxhc2giO2E6Mjp7czozOiJvbGQiO2E6MDp7fXM6MzoibmV3IjthOjA6e319czoxNzoicGFzc3dvcmRfaGFzaF93ZWIiO3M6NjQ6ImVhZWZhODNkMTY2YzMwYTE3NzMwNGM0NjFkMzY5MjA5ZjQ3MmMxNDVmMGQ3ZjJhZmY2OTE1NzBhMjViZmE4M2EiO3M6NTA6ImxvZ2luX3dlYl81OWJhMzZhZGRjMmIyZjk0MDE1ODBmMDE0YzdmNThlYTRlMzA5ODlkIjtpOjk7fQ==', 1795514636);

-- --------------------------------------------------------

--
-- Table structure for table `uoms`
--

CREATE TABLE `uoms` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `code` varchar(255) NOT NULL,
  `base_unit` varchar(255) NOT NULL,
  `factor` decimal(10,4) NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `uoms`
--

INSERT INTO `uoms` (`id`, `code`, `base_unit`, `factor`, `created_at`, `updated_at`) VALUES
(1, 'PCS', 'PCS', 1.0000, '2026-11-24 02:56:41', '2026-11-24 02:56:41'),
(2, 'BOX', 'PCS', 12.0000, '2026-11-24 02:56:41', '2026-11-24 02:56:41'),
(3, 'KG', 'KG', 1.0000, '2026-11-24 02:56:41', '2026-11-24 02:56:41'),
(4, 'TON', 'KG', 1000.0000, '2026-11-24 02:56:41', '2026-11-24 02:56:41'),
(5, 'HRS', 'HRS', 1.0000, '2026-11-24 02:56:41', '2026-11-24 02:56:41');

-- --------------------------------------------------------

--
-- Table structure for table `users`
--

CREATE TABLE `users` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `name` varchar(255) NOT NULL,
  `email` varchar(255) NOT NULL,
  `email_verified_at` timestamp NULL DEFAULT NULL,
  `password` varchar(255) NOT NULL,
  `remember_token` varchar(100) DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `company_id` bigint(20) UNSIGNED DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `users`
--

INSERT INTO `users` (`id`, `name`, `email`, `email_verified_at`, `password`, `remember_token`, `created_at`, `updated_at`, `company_id`) VALUES
(1, 'admin.mum', 'admin.mum@acme.test', NULL, '$2y$12$0VZQTroWpyjs.Uds.mkiD.DJ3OVX8g.evj2b/gnfQzftQiEbJq8MC', NULL, '2026-11-24 02:56:02', '2026-11-24 02:56:02', 1),
(2, 'req.mum', 'req.mum@acme.test', NULL, '$2y$12$0VZQTroWpyjs.Uds.mkiD.DJ3OVX8g.evj2b/gnfQzftQiEbJq8MC', NULL, '2026-11-24 02:56:06', '2026-11-24 02:56:06', 1),
(3, 'depthead.mum', 'depthead.mum@acme.test', NULL, '$2y$12$0VZQTroWpyjs.Uds.mkiD.DJ3OVX8g.evj2b/gnfQzftQiEbJq8MC', NULL, '2026-11-24 02:56:11', '2026-11-24 02:56:11', 1),
(4, 'ithead.mum', 'ithead.mum@acme.test', NULL, '$2y$12$0VZQTroWpyjs.Uds.mkiD.DJ3OVX8g.evj2b/gnfQzftQiEbJq8MC', NULL, '2026-11-24 02:56:17', '2026-11-24 02:56:17', 1),
(5, 'finhead.mum', 'finhead.mum@acme.test', NULL, '$2y$12$0VZQTroWpyjs.Uds.mkiD.DJ3OVX8g.evj2b/gnfQzftQiEbJq8MC', NULL, '2026-11-24 02:56:19', '2026-11-24 02:56:19', 1),
(6, 'cfo.mum', 'cfo.mum@acme.test', NULL, '$2y$12$0VZQTroWpyjs.Uds.mkiD.DJ3OVX8g.evj2b/gnfQzftQiEbJq8MC', NULL, '2026-11-24 02:56:20', '2026-11-24 02:56:20', 1),
(7, 'proc.mum', 'proc.mum@acme.test', NULL, '$2y$12$0VZQTroWpyjs.Uds.mkiD.DJ3OVX8g.evj2b/gnfQzftQiEbJq8MC', NULL, '2026-11-24 02:56:23', '2026-11-24 02:56:23', 1),
(8, 'store.mum', 'store.mum@acme.test', NULL, '$2y$12$0VZQTroWpyjs.Uds.mkiD.DJ3OVX8g.evj2b/gnfQzftQiEbJq8MC', NULL, '2026-11-24 02:56:26', '2026-11-24 02:56:26', 1),
(9, 'accounts.mum', 'accounts.mum@acme.test', NULL, '$2y$12$0VZQTroWpyjs.Uds.mkiD.DJ3OVX8g.evj2b/gnfQzftQiEbJq8MC', NULL, '2026-11-24 02:56:30', '2026-11-24 02:56:30', 1),
(10, 'admin.blr', 'admin.blr@acme.test', NULL, '$2y$12$0VZQTroWpyjs.Uds.mkiD.DJ3OVX8g.evj2b/gnfQzftQiEbJq8MC', NULL, '2026-11-24 02:56:31', '2026-11-24 02:56:31', 2),
(11, 'req.blr', 'req.blr@acme.test', NULL, '$2y$12$0VZQTroWpyjs.Uds.mkiD.DJ3OVX8g.evj2b/gnfQzftQiEbJq8MC', NULL, '2026-11-24 02:56:34', '2026-11-24 02:56:34', 2),
(12, 'depthead.blr', 'depthead.blr@acme.test', NULL, '$2y$12$0VZQTroWpyjs.Uds.mkiD.DJ3OVX8g.evj2b/gnfQzftQiEbJq8MC', NULL, '2026-11-24 02:56:36', '2026-11-24 02:56:36', 2),
(13, 'proc.blr', 'proc.blr@acme.test', NULL, '$2y$12$0VZQTroWpyjs.Uds.mkiD.DJ3OVX8g.evj2b/gnfQzftQiEbJq8MC', NULL, '2026-11-24 02:56:39', '2026-11-24 02:56:39', 2);

-- --------------------------------------------------------

--
-- Table structure for table `vendors`
--

CREATE TABLE `vendors` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `company_id` bigint(20) UNSIGNED NOT NULL,
  `code` varchar(255) NOT NULL,
  `name` varchar(255) NOT NULL,
  `state` varchar(255) NOT NULL,
  `gstin` varchar(255) NOT NULL,
  `payment_terms_days` int(11) NOT NULL DEFAULT 30,
  `is_active` tinyint(1) NOT NULL DEFAULT 1,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `vendors`
--

INSERT INTO `vendors` (`id`, `company_id`, `code`, `name`, `state`, `gstin`, `payment_terms_days`, `is_active`, `created_at`, `updated_at`) VALUES
(1, 1, 'V001', 'Shree Steel Traders', 'Maharashtra', '27AABCS1111A1Z1', 30, 1, '2026-11-24 02:56:59', '2026-11-24 02:56:59'),
(2, 1, 'V002', 'Bangalore Tech Supplies', 'Karnataka', '29AABCB2222B1Z2', 45, 1, '2026-11-24 02:56:59', '2026-11-24 02:56:59'),
(3, 1, 'V003', 'QuickClean Services', 'Maharashtra', '27AABCQ3333C1Z3', 15, 1, '2026-11-24 02:56:59', '2026-11-24 02:56:59'),
(4, 2, 'V004', 'Deccan Packaging', 'Karnataka', '29AABCD4444D1Z4', 30, 1, '2026-11-24 02:56:59', '2026-11-24 02:56:59');

--
-- Indexes for dumped tables
--

--
-- Indexes for table `approval_rules`
--
ALTER TABLE `approval_rules`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `audit_logs`
--
ALTER TABLE `audit_logs`
  ADD PRIMARY KEY (`id`),
  ADD KEY `audit_logs_user_id_foreign` (`user_id`);

--
-- Indexes for table `budgets`
--
ALTER TABLE `budgets`
  ADD PRIMARY KEY (`id`),
  ADD KEY `budgets_company_id_foreign` (`company_id`),
  ADD KEY `budgets_cost_centre_id_foreign` (`cost_centre_id`);

--
-- Indexes for table `cache`
--
ALTER TABLE `cache`
  ADD PRIMARY KEY (`key`),
  ADD KEY `cache_expiration_index` (`expiration`);

--
-- Indexes for table `cache_locks`
--
ALTER TABLE `cache_locks`
  ADD PRIMARY KEY (`key`),
  ADD KEY `cache_locks_expiration_index` (`expiration`);

--
-- Indexes for table `companies`
--
ALTER TABLE `companies`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `companies_code_unique` (`code`);

--
-- Indexes for table `cost_centres`
--
ALTER TABLE `cost_centres`
  ADD PRIMARY KEY (`id`),
  ADD KEY `cost_centres_company_id_foreign` (`company_id`);

--
-- Indexes for table `document_approvals`
--
ALTER TABLE `document_approvals`
  ADD PRIMARY KEY (`id`),
  ADD KEY `document_approvals_approver_id_foreign` (`approver_id`);

--
-- Indexes for table `failed_jobs`
--
ALTER TABLE `failed_jobs`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `failed_jobs_uuid_unique` (`uuid`);

--
-- Indexes for table `grns`
--
ALTER TABLE `grns`
  ADD PRIMARY KEY (`id`),
  ADD KEY `grns_company_id_foreign` (`company_id`),
  ADD KEY `grns_purchase_order_id_foreign` (`purchase_order_id`),
  ADD KEY `grns_received_by_foreign` (`received_by`);

--
-- Indexes for table `grn_items`
--
ALTER TABLE `grn_items`
  ADD PRIMARY KEY (`id`),
  ADD KEY `grn_items_grn_id_foreign` (`grn_id`),
  ADD KEY `grn_items_po_item_id_foreign` (`po_item_id`);

--
-- Indexes for table `invoices`
--
ALTER TABLE `invoices`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `invoices_vendor_id_vendor_invoice_number_unique` (`vendor_id`,`vendor_invoice_number`),
  ADD KEY `invoices_company_id_foreign` (`company_id`),
  ADD KEY `invoices_purchase_order_id_foreign` (`purchase_order_id`);

--
-- Indexes for table `invoice_items`
--
ALTER TABLE `invoice_items`
  ADD PRIMARY KEY (`id`),
  ADD KEY `invoice_items_invoice_id_foreign` (`invoice_id`),
  ADD KEY `invoice_items_po_item_id_foreign` (`po_item_id`);

--
-- Indexes for table `items`
--
ALTER TABLE `items`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `items_code_unique` (`code`);

--
-- Indexes for table `jobs`
--
ALTER TABLE `jobs`
  ADD PRIMARY KEY (`id`),
  ADD KEY `jobs_queue_index` (`queue`);

--
-- Indexes for table `job_batches`
--
ALTER TABLE `job_batches`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `migrations`
--
ALTER TABLE `migrations`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `password_reset_tokens`
--
ALTER TABLE `password_reset_tokens`
  ADD PRIMARY KEY (`email`);

--
-- Indexes for table `po_items`
--
ALTER TABLE `po_items`
  ADD PRIMARY KEY (`id`),
  ADD KEY `po_items_purchase_order_id_foreign` (`purchase_order_id`),
  ADD KEY `po_items_pr_item_id_foreign` (`pr_item_id`),
  ADD KEY `po_items_item_id_foreign` (`item_id`);

--
-- Indexes for table `pr_items`
--
ALTER TABLE `pr_items`
  ADD PRIMARY KEY (`id`),
  ADD KEY `pr_items_purchase_requisition_id_foreign` (`purchase_requisition_id`),
  ADD KEY `pr_items_item_id_foreign` (`item_id`);

--
-- Indexes for table `purchase_orders`
--
ALTER TABLE `purchase_orders`
  ADD PRIMARY KEY (`id`),
  ADD KEY `purchase_orders_company_id_foreign` (`company_id`),
  ADD KEY `purchase_orders_vendor_id_foreign` (`vendor_id`),
  ADD KEY `purchase_orders_cost_centre_id_foreign` (`cost_centre_id`),
  ADD KEY `purchase_orders_created_by_foreign` (`created_by`);

--
-- Indexes for table `purchase_requisitions`
--
ALTER TABLE `purchase_requisitions`
  ADD PRIMARY KEY (`id`),
  ADD KEY `purchase_requisitions_company_id_foreign` (`company_id`),
  ADD KEY `purchase_requisitions_requester_id_foreign` (`requester_id`),
  ADD KEY `purchase_requisitions_cost_centre_id_foreign` (`cost_centre_id`);

--
-- Indexes for table `roles`
--
ALTER TABLE `roles`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `roles_name_unique` (`name`);

--
-- Indexes for table `role_user`
--
ALTER TABLE `role_user`
  ADD PRIMARY KEY (`user_id`,`role_id`),
  ADD KEY `role_user_role_id_foreign` (`role_id`);

--
-- Indexes for table `sessions`
--
ALTER TABLE `sessions`
  ADD PRIMARY KEY (`id`),
  ADD KEY `sessions_user_id_index` (`user_id`),
  ADD KEY `sessions_last_activity_index` (`last_activity`);

--
-- Indexes for table `uoms`
--
ALTER TABLE `uoms`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uoms_code_unique` (`code`);

--
-- Indexes for table `users`
--
ALTER TABLE `users`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `users_email_unique` (`email`),
  ADD KEY `users_company_id_foreign` (`company_id`);

--
-- Indexes for table `vendors`
--
ALTER TABLE `vendors`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `vendors_code_unique` (`code`),
  ADD KEY `vendors_company_id_foreign` (`company_id`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `approval_rules`
--
ALTER TABLE `approval_rules`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=7;

--
-- AUTO_INCREMENT for table `audit_logs`
--
ALTER TABLE `audit_logs`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=11;

--
-- AUTO_INCREMENT for table `budgets`
--
ALTER TABLE `budgets`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=7;

--
-- AUTO_INCREMENT for table `companies`
--
ALTER TABLE `companies`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT for table `cost_centres`
--
ALTER TABLE `cost_centres`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=7;

--
-- AUTO_INCREMENT for table `document_approvals`
--
ALTER TABLE `document_approvals`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT for table `failed_jobs`
--
ALTER TABLE `failed_jobs`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `grns`
--
ALTER TABLE `grns`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT for table `grn_items`
--
ALTER TABLE `grn_items`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT for table `invoices`
--
ALTER TABLE `invoices`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT for table `invoice_items`
--
ALTER TABLE `invoice_items`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `items`
--
ALTER TABLE `items`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=7;

--
-- AUTO_INCREMENT for table `jobs`
--
ALTER TABLE `jobs`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `migrations`
--
ALTER TABLE `migrations`
  MODIFY `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT for table `po_items`
--
ALTER TABLE `po_items`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT for table `pr_items`
--
ALTER TABLE `pr_items`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT for table `purchase_orders`
--
ALTER TABLE `purchase_orders`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT for table `purchase_requisitions`
--
ALTER TABLE `purchase_requisitions`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT for table `roles`
--
ALTER TABLE `roles`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=10;

--
-- AUTO_INCREMENT for table `uoms`
--
ALTER TABLE `uoms`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;

--
-- AUTO_INCREMENT for table `users`
--
ALTER TABLE `users`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=14;

--
-- AUTO_INCREMENT for table `vendors`
--
ALTER TABLE `vendors`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `audit_logs`
--
ALTER TABLE `audit_logs`
  ADD CONSTRAINT `audit_logs_user_id_foreign` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`);

--
-- Constraints for table `budgets`
--
ALTER TABLE `budgets`
  ADD CONSTRAINT `budgets_company_id_foreign` FOREIGN KEY (`company_id`) REFERENCES `companies` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `budgets_cost_centre_id_foreign` FOREIGN KEY (`cost_centre_id`) REFERENCES `cost_centres` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `cost_centres`
--
ALTER TABLE `cost_centres`
  ADD CONSTRAINT `cost_centres_company_id_foreign` FOREIGN KEY (`company_id`) REFERENCES `companies` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `document_approvals`
--
ALTER TABLE `document_approvals`
  ADD CONSTRAINT `document_approvals_approver_id_foreign` FOREIGN KEY (`approver_id`) REFERENCES `users` (`id`);

--
-- Constraints for table `grns`
--
ALTER TABLE `grns`
  ADD CONSTRAINT `grns_company_id_foreign` FOREIGN KEY (`company_id`) REFERENCES `companies` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `grns_purchase_order_id_foreign` FOREIGN KEY (`purchase_order_id`) REFERENCES `purchase_orders` (`id`),
  ADD CONSTRAINT `grns_received_by_foreign` FOREIGN KEY (`received_by`) REFERENCES `users` (`id`);

--
-- Constraints for table `grn_items`
--
ALTER TABLE `grn_items`
  ADD CONSTRAINT `grn_items_grn_id_foreign` FOREIGN KEY (`grn_id`) REFERENCES `grns` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `grn_items_po_item_id_foreign` FOREIGN KEY (`po_item_id`) REFERENCES `po_items` (`id`);

--
-- Constraints for table `invoices`
--
ALTER TABLE `invoices`
  ADD CONSTRAINT `invoices_company_id_foreign` FOREIGN KEY (`company_id`) REFERENCES `companies` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `invoices_purchase_order_id_foreign` FOREIGN KEY (`purchase_order_id`) REFERENCES `purchase_orders` (`id`),
  ADD CONSTRAINT `invoices_vendor_id_foreign` FOREIGN KEY (`vendor_id`) REFERENCES `vendors` (`id`);

--
-- Constraints for table `invoice_items`
--
ALTER TABLE `invoice_items`
  ADD CONSTRAINT `invoice_items_invoice_id_foreign` FOREIGN KEY (`invoice_id`) REFERENCES `invoices` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `invoice_items_po_item_id_foreign` FOREIGN KEY (`po_item_id`) REFERENCES `po_items` (`id`);

--
-- Constraints for table `po_items`
--
ALTER TABLE `po_items`
  ADD CONSTRAINT `po_items_item_id_foreign` FOREIGN KEY (`item_id`) REFERENCES `items` (`id`),
  ADD CONSTRAINT `po_items_pr_item_id_foreign` FOREIGN KEY (`pr_item_id`) REFERENCES `pr_items` (`id`),
  ADD CONSTRAINT `po_items_purchase_order_id_foreign` FOREIGN KEY (`purchase_order_id`) REFERENCES `purchase_orders` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `pr_items`
--
ALTER TABLE `pr_items`
  ADD CONSTRAINT `pr_items_item_id_foreign` FOREIGN KEY (`item_id`) REFERENCES `items` (`id`),
  ADD CONSTRAINT `pr_items_purchase_requisition_id_foreign` FOREIGN KEY (`purchase_requisition_id`) REFERENCES `purchase_requisitions` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `purchase_orders`
--
ALTER TABLE `purchase_orders`
  ADD CONSTRAINT `purchase_orders_company_id_foreign` FOREIGN KEY (`company_id`) REFERENCES `companies` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `purchase_orders_cost_centre_id_foreign` FOREIGN KEY (`cost_centre_id`) REFERENCES `cost_centres` (`id`),
  ADD CONSTRAINT `purchase_orders_created_by_foreign` FOREIGN KEY (`created_by`) REFERENCES `users` (`id`),
  ADD CONSTRAINT `purchase_orders_vendor_id_foreign` FOREIGN KEY (`vendor_id`) REFERENCES `vendors` (`id`);

--
-- Constraints for table `purchase_requisitions`
--
ALTER TABLE `purchase_requisitions`
  ADD CONSTRAINT `purchase_requisitions_company_id_foreign` FOREIGN KEY (`company_id`) REFERENCES `companies` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `purchase_requisitions_cost_centre_id_foreign` FOREIGN KEY (`cost_centre_id`) REFERENCES `cost_centres` (`id`),
  ADD CONSTRAINT `purchase_requisitions_requester_id_foreign` FOREIGN KEY (`requester_id`) REFERENCES `users` (`id`);

--
-- Constraints for table `role_user`
--
ALTER TABLE `role_user`
  ADD CONSTRAINT `role_user_role_id_foreign` FOREIGN KEY (`role_id`) REFERENCES `roles` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `role_user_user_id_foreign` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `users`
--
ALTER TABLE `users`
  ADD CONSTRAINT `users_company_id_foreign` FOREIGN KEY (`company_id`) REFERENCES `companies` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `vendors`
--
ALTER TABLE `vendors`
  ADD CONSTRAINT `vendors_company_id_foreign` FOREIGN KEY (`company_id`) REFERENCES `companies` (`id`) ON DELETE CASCADE;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
