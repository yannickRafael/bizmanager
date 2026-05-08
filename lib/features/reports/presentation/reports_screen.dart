import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../features/settings/providers/settings_provider.dart';
import '../../../features/poultry/providers/poultry_provider.dart';
import '../../../features/cattle/providers/cattle_provider.dart';
import '../../../features/goats/providers/goat_provider.dart';

/// Multi-animal financial report screen.
class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final currency = settings.currencySymbol;
    final theme = Theme.of(context);

    // Watch all providers to get real-time totals
    final poultry = context.watch<PoultryProvider>();
    final cattle = context.watch<CattleProvider>();
    final goats = context.watch<GoatProvider>();

    // Poultry totals
    final pRevenue = poultry.chickenSales.fold<double>(0.0, (s, x) => s + x.total) +
                     poultry.eggSales.fold<double>(0.0, (s, x) => s + x.total) +
                     poultry.culledBirdSales.fold<double>(0.0, (s, x) => s + x.total);
    final pExpenses = poultry.expenses.fold<double>(0.0, (s, x) => s + x.amount);

    // Cattle totals
    final cRevenue = cattle.cattleSales.fold<double>(0.0, (s, x) => s + x.total) +
                     cattle.milkSales.fold<double>(0.0, (s, x) => s + x.total);
    final cExpenses = cattle.expenses.fold<double>(0.0, (s, x) => s + x.amount);

    // Goat totals
    final gRevenue = goats.goatSales.fold<double>(0.0, (s, x) => s + x.total) +
                     goats.milkSales.fold<double>(0.0, (s, x) => s + x.total);
    final gExpenses = goats.expenses.fold<double>(0.0, (s, x) => s + x.amount);

    final totalRevenue = pRevenue + cRevenue + gRevenue;
    final totalExpenses = pExpenses + cExpenses + gExpenses;
    final totalProfit = totalRevenue - totalExpenses;

    return Scaffold(
      appBar: AppBar(title: const Text('Relatórios Financeiros')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Overall Summary Card
            Card(
              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Text('RESUMO GERAL', style: theme.textTheme.labelLarge?.copyWith(letterSpacing: 1.2)),
                    const SizedBox(height: 8),
                    Text(
                      '$currency${totalProfit.toStringAsFixed(2)}',
                      style: theme.textTheme.headlineLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: totalProfit >= 0 ? Colors.green.shade700 : Colors.red,
                      ),
                    ),
                    Text('Lucro Líquido Total', style: theme.textTheme.bodyMedium),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            Text('Por Categoria', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),

            _ReportCategoryCard(
              title: 'Aves',
              revenue: pRevenue,
              expenses: pExpenses,
              color: AppTheme.poultryColor,
              icon: Icons.egg,
              currency: currency,
            ),
            _ReportCategoryCard(
              title: 'Bovinos',
              revenue: cRevenue,
              expenses: cExpenses,
              color: AppTheme.cattleColor,
              icon: Icons.pets,
              currency: currency,
            ),
            _ReportCategoryCard(
              title: 'Caprinos',
              revenue: gRevenue,
              expenses: gExpenses,
              color: AppTheme.goatColor,
              icon: Icons.agriculture,
              currency: currency,
            ),

            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 12),
            _RowInfo('Total de Receitas', '$currency${totalRevenue.toStringAsFixed(2)}', Colors.green),
            _RowInfo('Total de Despesas', '$currency${totalExpenses.toStringAsFixed(2)}', Colors.red),
          ],
        ),
      ),
    );
  }
}

class _ReportCategoryCard extends StatelessWidget {
  final String title;
  final double revenue;
  final double expenses;
  final Color color;
  final IconData icon;
  final String currency;

  const _ReportCategoryCard({
    required this.title,
    required this.revenue,
    required this.expenses,
    required this.color,
    required this.icon,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    final profit = revenue - expenses;
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: color.withValues(alpha: 0.1),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 12),
                Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const Spacer(),
                Text(
                  '$currency${profit.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: profit >= 0 ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _MiniStat(label: 'Receita', value: revenue, currency: currency),
                _MiniStat(label: 'Despesas', value: expenses, currency: currency),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final double value;
  final String currency;

  const _MiniStat({required this.label, required this.value, required this.currency});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        Text('$currency${value.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w500)),
      ],
    );
  }
}

class _RowInfo extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _RowInfo(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 16)),
        ],
      ),
    );
  }
}
