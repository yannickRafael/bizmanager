import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';

import '../../../core/widgets/confirm_delete_dialog.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../../features/settings/providers/settings_provider.dart';
import '../../../features/clients/providers/client_provider.dart';
import '../providers/poultry_provider.dart';
import '../../../models/enums.dart';
import '../../../models/sale.dart';

/// All poultry sales across batches — 3 tabs: Chicken, Egg, Culled.
class PoultrySalesScreen extends StatelessWidget {
  const PoultrySalesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('🐔 Vendas de Aves'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.goNamed('poultryDashboard'),
          ),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Frangos'),
              Tab(text: 'Ovos'),
              Tab(text: 'Descarte'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _ChickenSalesTab(),
            _EggSalesTab(),
            _CulledBirdSalesTab(),
          ],
        ),
      ),
    );
  }
}

class _ChickenSalesTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final poultry = context.watch<PoultryProvider>();
    final clients = context.watch<ClientProvider>();
    final settings = context.watch<SettingsProvider>();
    final currency = settings.currencySymbol;
    final sales = poultry.chickenSales;

    if (sales.isEmpty) {
      return const EmptyStateWidget(
        icon: Icons.shopping_cart_outlined,
        message: 'Nenhuma venda de frangos registada.',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: sales.length,
      itemBuilder: (ctx, i) {
        final s = sales[i];
        final client = s.clientId != null ? clients.getById(s.clientId!) : null;
        final batch = poultry.getBatchById(s.batchId);

        return Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: _statusColor(s.paymentStatus),
              child: const Icon(Icons.shopping_cart, color: Colors.white, size: 20),
            ),
            title: Text('$currency${s.total.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(
              '${client?.name ?? "Sem cliente"} • ${batch?.name ?? "?"} • ${DateFormat('dd/MM').format(s.date)}',
            ),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
              onPressed: () async {
                final confirmed = await showDeleteConfirmation(context, itemName: 'esta venda');
                if (confirmed) poultry.deleteChickenSale(s.id);
              },
            ),
          ),
        );
      },
    );
  }
}

class _EggSalesTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final poultry = context.watch<PoultryProvider>();
    final clients = context.watch<ClientProvider>();
    final settings = context.watch<SettingsProvider>();
    final currency = settings.currencySymbol;
    final sales = poultry.eggSales;

    if (sales.isEmpty) {
      return const EmptyStateWidget(
        icon: Icons.egg_outlined,
        message: 'Nenhuma venda de ovos registada.',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: sales.length,
      itemBuilder: (ctx, i) {
        final s = sales[i];
        final client = s.clientId != null ? clients.getById(s.clientId!) : null;
        final unitLabel = s.unit == EggUnit.dozens ? 'dz' : 'band.';

        return Card(
          child: ListTile(
            leading: const Icon(Icons.egg, color: Colors.amber),
            title: Text('$currency${s.total.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('${s.quantity} $unitLabel • ${client?.name ?? "Sem cliente"} • ${DateFormat('dd/MM').format(s.date)}'),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
              onPressed: () async {
                final confirmed = await showDeleteConfirmation(context, itemName: 'esta venda');
                if (confirmed) poultry.deleteEggSale(s.id);
              },
            ),
          ),
        );
      },
    );
  }
}

class _CulledBirdSalesTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final poultry = context.watch<PoultryProvider>();
    final clients = context.watch<ClientProvider>();
    final settings = context.watch<SettingsProvider>();
    final currency = settings.currencySymbol;
    final sales = poultry.culledBirdSales;

    if (sales.isEmpty) {
      return const EmptyStateWidget(
        icon: Icons.sell_outlined,
        message: 'Nenhuma venda de aves descartadas.',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: sales.length,
      itemBuilder: (ctx, i) {
        final s = sales[i];
        final client = s.clientId != null ? clients.getById(s.clientId!) : null;

        return Card(
          child: ListTile(
            leading: const Icon(Icons.sell),
            title: Text('$currency${s.total.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('${s.quantity} aves • ${client?.name ?? "Sem cliente"} • ${DateFormat('dd/MM').format(s.date)}'),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
              onPressed: () async {
                final confirmed = await showDeleteConfirmation(context, itemName: 'esta venda');
                if (confirmed) poultry.deleteCulledBirdSale(s.id);
              },
            ),
          ),
        );
      },
    );
  }
}

Color _statusColor(PaymentStatus status) {
  switch (status) {
    case PaymentStatus.paid: return Colors.green;
    case PaymentStatus.partial: return Colors.orange;
    case PaymentStatus.pending: return Colors.red;
  }
}
