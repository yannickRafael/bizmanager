import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/home/presentation/home_screen.dart';
import '../../features/farms/presentation/farms_screen.dart';
import '../../features/clients/presentation/clients_screen.dart';
import '../../features/clients/presentation/client_details_screen.dart';
import '../../features/partners/presentation/partners_screen.dart';
import '../../features/reports/presentation/reports_screen.dart';
import '../../features/backup/presentation/backup_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';

// Poultry
import '../../features/poultry/presentation/poultry_dashboard.dart';
import '../../features/poultry/presentation/poultry_batch_list.dart';
import '../../features/poultry/presentation/poultry_batch_detail.dart';
import '../../features/poultry/presentation/poultry_sales_screen.dart';

// Cattle
import '../../features/cattle/presentation/cattle_dashboard.dart';
import '../../features/cattle/presentation/cattle_batch_list.dart';
import '../../features/cattle/presentation/cattle_batch_detail.dart';
import '../../features/cattle/presentation/cattle_sales_screen.dart';

// Goats
import '../../features/goats/presentation/goat_dashboard.dart';
import '../../features/goats/presentation/goat_batch_list.dart';
import '../../features/goats/presentation/goat_batch_detail.dart';
import '../../features/goats/presentation/goat_sales_screen.dart';

/// Centralized routing configuration using go_router.
class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/',
    routes: [
      // ── Home ──
      GoRoute(
        path: '/',
        name: 'home',
        builder: (context, state) => const HomeScreen(),
      ),

      // ── Shared ──
      GoRoute(
        path: '/farms',
        name: 'farms',
        builder: (context, state) => const FarmsScreen(),
      ),
      GoRoute(
        path: '/clients',
        name: 'clients',
        builder: (context, state) => const ClientsScreen(),
      ),
      GoRoute(
        path: '/clients/:id',
        name: 'clientDetails',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return ClientDetailsScreen(clientId: id);
        },
      ),
      GoRoute(
        path: '/partners',
        name: 'partners',
        builder: (context, state) => const PartnersScreen(),
      ),
      GoRoute(
        path: '/reports',
        name: 'reports',
        builder: (context, state) => const ReportsScreen(),
      ),
      GoRoute(
        path: '/backup',
        name: 'backup',
        builder: (context, state) => const BackupScreen(),
      ),
      GoRoute(
        path: '/settings',
        name: 'settings',
        builder: (context, state) => const SettingsScreen(),
      ),

      // ── Poultry 🐔 ──
      GoRoute(
        path: '/poultry',
        name: 'poultryDashboard',
        builder: (context, state) => const PoultryDashboard(),
      ),
      GoRoute(
        path: '/poultry/batches',
        name: 'poultryBatches',
        builder: (context, state) => const PoultryBatchList(),
      ),
      GoRoute(
        path: '/poultry/batches/:id',
        name: 'poultryBatchDetail',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return PoultryBatchDetail(batchId: id);
        },
      ),
      GoRoute(
        path: '/poultry/sales',
        name: 'poultrySales',
        builder: (context, state) => const PoultrySalesScreen(),
      ),

      // ── Cattle 🐄 ──
      GoRoute(
        path: '/cattle',
        name: 'cattleDashboard',
        builder: (context, state) => const CattleDashboard(),
      ),
      GoRoute(
        path: '/cattle/batches',
        name: 'cattleBatches',
        builder: (context, state) => const CattleBatchList(),
      ),
      GoRoute(
        path: '/cattle/batches/:id',
        name: 'cattleBatchDetail',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return CattleBatchDetail(batchId: id);
        },
      ),
      GoRoute(
        path: '/cattle/sales',
        name: 'cattleSales',
        builder: (context, state) => const CattleSalesScreen(),
      ),

      // ── Goats 🐐 ──
      GoRoute(
        path: '/goats',
        name: 'goatDashboard',
        builder: (context, state) => const GoatDashboard(),
      ),
      GoRoute(
        path: '/goats/batches',
        name: 'goatBatches',
        builder: (context, state) => const GoatBatchList(),
      ),
      GoRoute(
        path: '/goats/batches/:id',
        name: 'goatBatchDetail',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return GoatBatchDetail(batchId: id);
        },
      ),
      GoRoute(
        path: '/goats/sales',
        name: 'goatSales',
        builder: (context, state) => const GoatSalesScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Página não encontrada: ${state.error}'),
      ),
    ),
  );
}
