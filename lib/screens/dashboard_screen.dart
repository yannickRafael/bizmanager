import 'backup_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/data_manager.dart';
import '../models/enums.dart';

import 'clients_screen.dart';
import 'farms_screen.dart';
import 'batches_screen.dart';
import 'settings_screen.dart';
import 'sales_screen.dart';
import 'partners_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'AvícoPro',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: theme.colorScheme.primaryContainer,
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: theme.colorScheme.primary),
              child: const Text(
                'Menu',
                style: TextStyle(color: Colors.white, fontSize: 24),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Início'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.home_work),
              title: const Text('Explorações'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const FarmsScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.pets),
              title: const Text('Lotes / Bandos'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const BatchesScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.people),
              title: const Text('Clientes'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const ClientsScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.sell),
              title: const Text('Vendas'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const SalesScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.handshake),
              title: const Text('Parceiros'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const PartnersScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.backup),
              title: const Text('Cópia de Segurança'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const BackupScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Definições'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
              },
            ),
          ],
        ),
      ),
      body: Consumer<DataManager>(
        builder: (context, dataManager, child) {
          final activeMeatBatches = dataManager.batches.where((b) => b.type == BatchType.meat && b.status == BatchStatus.active).toList();
          final activeLayerBatches = dataManager.batches.where((b) => b.type == BatchType.layer && b.status == BatchStatus.active).toList();

          int liveMeatBirds = activeMeatBatches.fold(0, (sum, b) => sum + b.currentQuantity);
          int liveLayerBirds = activeLayerBatches.fold(0, (sum, b) => sum + b.currentQuantity);

          double totalExpenses = dataManager.expenses.fold(0, (sum, e) => sum + e.amount);
          
          double totalRevenue = 0;
          totalRevenue += dataManager.chickenSales.fold(0.0, (sum, s) => sum + s.total);
          totalRevenue += dataManager.eggSales.fold(0.0, (sum, s) => sum + s.total);
          totalRevenue += dataManager.culledBirdSales.fold(0.0, (sum, s) => sum + s.total);

          final currency = dataManager.currencySymbol;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Visão Geral',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildSummaryCard(
                        context,
                        title: 'Aves de Corte',
                        value: '$liveMeatBirds',
                        icon: Icons.pets,
                        color: Colors.orange,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildSummaryCard(
                        context,
                        title: 'Poedeiras',
                        value: '$liveLayerBirds',
                        icon: Icons.egg,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildSummaryCard(
                        context,
                        title: 'Receita Total',
                        value: '$currency${totalRevenue.toStringAsFixed(2)}',
                        icon: Icons.trending_up,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildSummaryCard(
                        context,
                        title: 'Despesas',
                        value: '$currency${totalExpenses.toStringAsFixed(2)}',
                        icon: Icons.trending_down,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                Text(
                  'Ações Rápidas',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                _buildActionButton(
                  context,
                  label: 'Gerir Lotes',
                  icon: Icons.list_alt,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const BatchesScreen()),
                  ),
                ),
                const SizedBox(height: 12),
                _buildActionButton(
                  context,
                  label: 'Explorações',
                  icon: Icons.home_work,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const FarmsScreen()),
                  ),
                ),
                const SizedBox(height: 12),
                _buildActionButton(
                  context,
                  label: 'Vendas',
                  icon: Icons.sell,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SalesScreen()),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 28, color: color),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, size: 28),
            const SizedBox(width: 16),
            Text(
              label,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
            const Spacer(),
            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
