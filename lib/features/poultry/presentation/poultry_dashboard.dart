import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/stat_card.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../../core/constants/app_constants.dart';
import '../../../features/settings/providers/settings_provider.dart';
import '../providers/poultry_provider.dart';

/// Poultry module dashboard — KPI overview + quick actions.
class PoultryDashboard extends StatelessWidget {
  const PoultryDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final poultry = context.watch<PoultryProvider>();
    final settings = context.watch<SettingsProvider>();
    final currency = settings.currencySymbol;
    final theme = Theme.of(context);

    if (poultry.isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('🐔 Aves')),
        body: const LoadingWidget(message: 'A carregar dados de aves...'),
      );
    }

    final activeBatches = poultry.batches.where((b) => b.status == BatchStatus.active).toList();
    final totalBirds = activeBatches.fold(0, (s, b) => s + b.currentQuantity);
    final totalRevenue = poultry.chickenSales.fold(0.0, (s, x) => s + x.total)
        + poultry.eggSales.fold(0.0, (s, x) => s + x.total)
        + poultry.culledBirdSales.fold(0.0, (s, x) => s + x.total);
    final totalExpenses = poultry.expenses.fold(0.0, (s, e) => s + e.amount);
    final totalMortality = poultry.mortalities.fold(0, (s, m) => s + m.quantity);

    return Scaffold(
      appBar: AppBar(
        title: const Text('🐔 Aves'),
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
                  title: 'Lotes Activos',
                  value: '${activeBatches.length}',
                  icon: Icons.inventory_2,
                  color: AppTheme.poultryColor,
                ),
                StatCard(
                  title: 'Total de Aves',
                  value: '$totalBirds',
                  icon: Icons.pest_control,
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
                  title: 'Mortalidade',
                  value: '$totalMortality',
                  icon: Icons.heart_broken,
                  color: Colors.orange,
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
                  onPressed: () => context.goNamed('poultryBatches'),
                  icon: const Icon(Icons.inventory_2),
                  label: const Text('Lotes'),
                ),
                FilledButton.tonal(
                  onPressed: () => context.goNamed('poultrySales'),
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
              Text('Lotes Activos', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ...activeBatches.take(5).map((b) => Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppTheme.poultryColor.withValues(alpha: 0.15),
                    child: Text(b.type.name == 'meat' ? '🍗' : '🥚'),
                  ),
                  title: Text(b.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('${b.currentQuantity}/${b.initialQuantity} aves'),
                  trailing: Text(DateFormat('dd/MM').format(b.entryDate)),
                  onTap: () => context.goNamed('poultryBatchDetail', pathParameters: {'id': b.id}),
                ),
              )),
            ],
          ],
        ),
      ),
    );
  }
}

