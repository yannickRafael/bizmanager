import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../features/settings/providers/settings_provider.dart';
import '../../../features/poultry/providers/poultry_provider.dart';
import '../../../features/cattle/providers/cattle_provider.dart';
import '../../../features/goats/providers/goat_provider.dart';

/// Landing screen — animal type selector grid with global summary.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = context.watch<SettingsProvider>();
    final poultry = context.watch<PoultryProvider>();
    final cattle = context.watch<CattleProvider>();
    final goat = context.watch<GoatProvider>();
    final currency = settings.currencySymbol;

    // Global revenue across all modules
    double totalRevenue = 0;
    totalRevenue += poultry.chickenSales.fold(0.0, (s, x) => s + x.total);
    totalRevenue += poultry.eggSales.fold(0.0, (s, x) => s + x.total);
    totalRevenue += poultry.culledBirdSales.fold(0.0, (s, x) => s + x.total);
    totalRevenue += cattle.cattleSales.fold(0.0, (s, x) => s + x.total);
    totalRevenue += cattle.milkSales.fold(0.0, (s, x) => s + x.total);
    totalRevenue += goat.goatSales.fold(0.0, (s, x) => s + x.total);
    totalRevenue += goat.milkSales.fold(0.0, (s, x) => s + x.total);

    double totalExpenses = 0;
    totalExpenses += poultry.expenses.fold(0.0, (s, e) => s + e.amount);
    totalExpenses += cattle.expenses.fold(0.0, (s, e) => s + e.amount);
    totalExpenses += goat.expenses.fold(0.0, (s, e) => s + e.amount);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Farma', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      drawer: _buildDrawer(context),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Animal Module Grid ──
            Text(
              'Os Seus Negócios',
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.2,
              children: [
                _AnimalModuleCard(
                  emoji: '🐔',
                  label: 'Aves',
                  subtitle: '${poultry.batches.length} lotes',
                  color: AppTheme.poultryColor,
                  onTap: () => context.goNamed('poultryDashboard'),
                ),
                _AnimalModuleCard(
                  emoji: '🐄',
                  label: 'Bovinos',
                  subtitle: '${cattle.batches.length} manadas',
                  color: AppTheme.cattleColor,
                  onTap: () => context.goNamed('cattleDashboard'),
                ),
                _AnimalModuleCard(
                  emoji: '🐐',
                  label: 'Caprinos',
                  subtitle: '${goat.batches.length} rebanhos',
                  color: AppTheme.goatColor,
                  onTap: () => context.goNamed('goatDashboard'),
                ),
                _AnimalModuleCard(
                  emoji: '⚙️',
                  label: 'Definições',
                  subtitle: '',
                  color: Colors.grey,
                  onTap: () => context.goNamed('settings'),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // ── Global Summary ──
            Text(
              'Resumo Global',
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _SummaryCard(
                    title: 'Receita Total',
                    value: '$currency${totalRevenue.toStringAsFixed(2)}',
                    icon: Icons.trending_up,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _SummaryCard(
                    title: 'Despesa Total',
                    value: '$currency${totalExpenses.toStringAsFixed(2)}',
                    icon: Icons.trending_down,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _SummaryCard(
              title: 'Lucro Líquido',
              value: '$currency${(totalRevenue - totalExpenses).toStringAsFixed(2)}',
              icon: Icons.attach_money,
              color: (totalRevenue - totalExpenses) >= 0 ? Colors.indigo : Colors.red,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    final theme = Theme.of(context);
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: theme.colorScheme.primary),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text('🐾 Farma', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                SizedBox(height: 4),
                Text('Gestão Animal Inteligente', style: TextStyle(color: Colors.white70, fontSize: 14)),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('Início'),
            onTap: () { Navigator.pop(context); context.goNamed('home'); },
          ),
          ListTile(
            leading: const Icon(Icons.home_work),
            title: const Text('Explorações'),
            onTap: () { Navigator.pop(context); context.goNamed('farms'); },
          ),
          ListTile(
            leading: const Icon(Icons.people),
            title: const Text('Clientes'),
            onTap: () { Navigator.pop(context); context.goNamed('clients'); },
          ),
          ListTile(
            leading: const Icon(Icons.handshake),
            title: const Text('Parceiros'),
            onTap: () { Navigator.pop(context); context.goNamed('partners'); },
          ),
          const Divider(),
          ListTile(
            leading: const Text('🐔', style: TextStyle(fontSize: 20)),
            title: const Text('Aves'),
            onTap: () { Navigator.pop(context); context.goNamed('poultryDashboard'); },
          ),
          ListTile(
            leading: const Text('🐄', style: TextStyle(fontSize: 20)),
            title: const Text('Bovinos'),
            onTap: () { Navigator.pop(context); context.goNamed('cattleDashboard'); },
          ),
          ListTile(
            leading: const Text('🐐', style: TextStyle(fontSize: 20)),
            title: const Text('Caprinos'),
            onTap: () { Navigator.pop(context); context.goNamed('goatDashboard'); },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.bar_chart),
            title: const Text('Relatórios'),
            onTap: () { Navigator.pop(context); context.goNamed('reports'); },
          ),
          ListTile(
            leading: const Icon(Icons.backup),
            title: const Text('Cópia de Segurança'),
            onTap: () { Navigator.pop(context); context.goNamed('backup'); },
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Definições'),
            onTap: () { Navigator.pop(context); context.goNamed('settings'); },
          ),
        ],
      ),
    );
  }
}

class _AnimalModuleCard extends StatelessWidget {
  final String emoji;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _AnimalModuleCard({
    required this.emoji,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withValues(alpha: 0.08),
                color.withValues(alpha: 0.02),
              ],
            ),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 32)),
              const SizedBox(height: 8),
              Text(label, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
              if (subtitle.isNotEmpty)
                Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 28, color: color),
            const SizedBox(height: 12),
            Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Text(title, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}
