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
import 'backup_screen.dart';
import 'reports_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('AvícoPro', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: theme.colorScheme.primaryContainer,
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: theme.colorScheme.primary),
              child: const Text('Menu', style: TextStyle(color: Colors.white, fontSize: 24)),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Início'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.home_work),
              title: const Text('Explorações'),
              onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const FarmsScreen())); },
            ),
            ListTile(
              leading: const Icon(Icons.pets),
              title: const Text('Lotes / Bandos'),
              onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const BatchesScreen())); },
            ),
            ListTile(
              leading: const Icon(Icons.people),
              title: const Text('Clientes'),
              onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const ClientsScreen())); },
            ),
            ListTile(
              leading: const Icon(Icons.sell),
              title: const Text('Vendas'),
              onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const SalesScreen())); },
            ),
            ListTile(
              leading: const Icon(Icons.handshake),
              title: const Text('Parceiros'),
              onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const PartnersScreen())); },
            ),
            ListTile(
              leading: const Icon(Icons.bar_chart),
              title: const Text('Relatórios de Lucro'),
              onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportsScreen())); },
            ),
            ListTile(
              leading: const Icon(Icons.backup),
              title: const Text('Cópia de Segurança'),
              onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const BackupScreen())); },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Definições'),
              onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())); },
            ),
          ],
        ),
      ),
      body: Consumer<DataManager>(
        builder: (context, dataManager, child) {
          final meatBatches = dataManager.batches.where((b) => b.type == BatchType.meat).toList();
          final layerBatches = dataManager.batches.where((b) => b.type == BatchType.layer).toList();

          final activeMeatBatches = meatBatches.where((b) => b.status == BatchStatus.active).toList();
          final activeLayerBatches = layerBatches.where((b) => b.status == BatchStatus.active).toList();

          int liveMeatBirds = activeMeatBatches.fold(0, (sum, b) => sum + b.currentQuantity);
          int liveLayerBirds = activeLayerBatches.fold(0, (sum, b) => sum + b.currentQuantity);

          double meatExpenses = dataManager.expenses.where((e) => meatBatches.any((b) => b.id == e.batchId)).fold(0, (s,e) => s+e.amount);
          double layerExpenses = dataManager.expenses.where((e) => layerBatches.any((b) => b.id == e.batchId)).fold(0, (s,e) => s+e.amount);
          double totalExpenses = meatExpenses + layerExpenses;

          double meatRevenue = dataManager.chickenSales.fold(0.0, (s,x) => s+x.total);
          double eggRevenue = dataManager.eggSales.fold(0.0, (s,x) => s+x.total);
          double culledRevenue = dataManager.culledBirdSales.fold(0.0, (s,x) => s+x.total);
          // Assuming culled chickens are mostly layers
          double layerRevenue = eggRevenue + culledRevenue;
          double totalRevenue = meatRevenue + layerRevenue;

          final currency = dataManager.currencySymbol;

          return DefaultTabController(
            length: 3,
            child: Column(
              children: [
                const TabBar(
                  tabs: [
                    Tab(text: 'Geral'),
                    Tab(text: 'Corte'),
                    Tab(text: 'Postura'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      // TAB: GERAL
                      SingleChildScrollView(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                Expanded(child: _buildSummaryCard(context, title: 'Receita Total', value: '$currency${totalRevenue.toStringAsFixed(2)}', icon: Icons.trending_up, color: Colors.green)),
                                const SizedBox(width: 12),
                                Expanded(child: _buildSummaryCard(context, title: 'Despesa Total', value: '$currency${totalExpenses.toStringAsFixed(2)}', icon: Icons.trending_down, color: Colors.red)),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(child: _buildSummaryCard(context, title: 'Lucro Líquido', value: '$currency${(totalRevenue - totalExpenses).toStringAsFixed(2)}', icon: Icons.attach_money, color: Colors.indigo)),
                              ],
                            ),
                            const SizedBox(height: 32),
                            Text('Ações Rápidas', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 16),
                            _buildActionButton(context, label: 'Lotes / Bandos', icon: Icons.pets, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BatchesScreen()))),
                            const SizedBox(height: 12),
                            _buildActionButton(context, label: 'Registar Vendas', icon: Icons.sell, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SalesScreen()))),
                          ],
                        ),
                      ),

                      // TAB: CORTE (Meat)
                      SingleChildScrollView(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                Expanded(child: _buildSummaryCard(context, title: 'Aves Vivas', value: '$liveMeatBirds', icon: Icons.pets, color: Colors.orange)),
                                const SizedBox(width: 12),
                                Expanded(child: _buildSummaryCard(context, title: 'Lotes Ativos', value: '${activeMeatBatches.length}', icon: Icons.inventory_2, color: Colors.blueGrey)),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(child: _buildSummaryCard(context, title: 'Receitas (Corte)', value: '$currency${meatRevenue.toStringAsFixed(2)}', icon: Icons.trending_up, color: Colors.green)),
                                const SizedBox(width: 12),
                                Expanded(child: _buildSummaryCard(context, title: 'Despesas (Corte)', value: '$currency${meatExpenses.toStringAsFixed(2)}', icon: Icons.trending_down, color: Colors.red)),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // TAB: POSTURA (Layers)
                      SingleChildScrollView(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                Expanded(child: _buildSummaryCard(context, title: 'Poedeiras Vivas', value: '$liveLayerBirds', icon: Icons.pets, color: Colors.blue)),
                                const SizedBox(width: 12),
                                Expanded(child: _buildSummaryCard(context, title: 'Lotes Ativos', value: '${activeLayerBatches.length}', icon: Icons.inventory_2, color: Colors.blueGrey)),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(child: _buildSummaryCard(context, title: 'Receitas (Postura)', value: '$currency${layerRevenue.toStringAsFixed(2)}', icon: Icons.trending_up, color: Colors.green)),
                                const SizedBox(width: 12),
                                Expanded(child: _buildSummaryCard(context, title: 'Despesas (Postura)', value: '$currency${layerExpenses.toStringAsFixed(2)}', icon: Icons.trending_down, color: Colors.red)),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildSummaryCard(
                                    context, 
                                    title: 'Total Produzido', 
                                    value: '${dataManager.eggProductions.fold(0.0, (s,p) => s+p.quantity)}', 
                                    icon: Icons.egg, 
                                    color: Colors.amber,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context, {required String title, required String value, required IconData icon, required Color color}) {
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
            Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Text(title, style: TextStyle(color: Colors.grey[600], fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, {required String label, required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(12)),
        child: Row(
          children: [
            Icon(icon, size: 28),
            const SizedBox(width: 16),
            Text(label, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
            const Spacer(),
            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
