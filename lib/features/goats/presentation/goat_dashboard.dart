import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/stat_card.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../../core/constants/app_constants.dart';
import '../../../features/settings/providers/settings_provider.dart';
import '../providers/goat_provider.dart';

/// Goat module dashboard — KPI overview + quick actions.
class GoatDashboard extends StatelessWidget {
  const GoatDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final goat = context.watch<GoatProvider>();
    final settings = context.watch<SettingsProvider>();
    final currency = settings.currencySymbol;
    final theme = Theme.of(context);

    if (goat.isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('🐐 Caprinos')),
        body: const LoadingWidget(message: 'A carregar dados de caprinos...'),
      );
    }

    final activeBatches = goat.batches.where((b) => b.status == BatchStatus.active).toList();
    final totalAnimals = goat.batches.fold<int>(0, (int s, b) => s + b.currentQuantity);
    final totalRevenue = goat.goatSales.fold<double>(0.0, (double s, x) => s + x.total)
        + goat.milkSales.fold<double>(0.0, (double s, x) => s + x.total);
    final totalExpenses = goat.expenses.fold<double>(0.0, (double s, e) => s + e.amount);
    final totalMortality = goat.mortalities.fold<int>(0, (int s, m) => s + m.quantity);
    final totalMilk = goat.milkProductions.fold<double>(0.0, (double s, p) => s + p.quantityLiters);

    return Scaffold(
      appBar: AppBar(
        title: const Text('🐐 Caprinos'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.goNamed('home'),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // KPI Grid
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.4,
              children: [
                StatCard(
                  title: 'Rebanhos Activos',
                  value: '${activeBatches.length}',
                  icon: Icons.inventory_2,
                  color: AppTheme.goatColor,
                ),
                StatCard(
                  title: 'Total de Animais',
                  value: '$totalAnimals',
                  icon: Icons.pets,
                ),
                StatCard(
                  title: 'Receita',
                  value: '$currency${totalRevenue.toStringAsFixed(0)}',
                  icon: Icons.trending_up,
                  color: Colors.green,
                ),
                StatCard(
                  title: 'Despesas',
                  value: '$currency${totalExpenses.toStringAsFixed(0)}',
                  icon: Icons.trending_down,
                  color: Colors.red,
                ),
                StatCard(
                  title: 'Lucro',
                  value: '$currency${(totalRevenue - totalExpenses).toStringAsFixed(0)}',
                  icon: Icons.attach_money,
                  color: (totalRevenue - totalExpenses) >= 0 ? Colors.indigo : Colors.red,
                ),
                StatCard(
                  title: 'Produção Leite',
                  value: '${totalMilk.toStringAsFixed(0)} L',
                  icon: Icons.water_drop,
                  color: Colors.blue,
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Quick actions
            Text('Acções Rápidas', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: () => context.goNamed('goatBatches'),
                  icon: const Icon(Icons.inventory_2),
                  label: const Text('Rebanhos'),
                ),
                FilledButton.tonal(
                  onPressed: () => context.goNamed('goatSales'),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [Icon(Icons.point_of_sale), SizedBox(width: 8), Text('Vendas')],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Recent batches
            if (activeBatches.isNotEmpty) ...[
              Text('Rebanhos Activos', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ...activeBatches.take(5).map((b) => Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppTheme.goatColor.withValues(alpha: 0.15),
                    child: Text(_purposeEmoji(b.purpose.name)),
                  ),
                  title: Text(b.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('${b.currentQuantity}/${b.initialQuantity} animais'),
                  trailing: Text(DateFormat('dd/MM').format(b.entryDate)),
                  onTap: () => context.goNamed('goatBatchDetail', pathParameters: {'id': b.id}),
                ),
              )),
            ],
          ],
        ),
      ),
    );
  }

  String _purposeEmoji(String purpose) {
    switch (purpose) {
      case 'dairy': return '🥛';
      case 'meat': return '🥩';
      default: return '🐐';
    }
  }
}
