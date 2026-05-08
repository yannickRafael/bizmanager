import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/confirm_delete_dialog.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../../features/settings/providers/settings_provider.dart';
import '../../../features/clients/providers/client_provider.dart';
import '../providers/goat_provider.dart';
import '../models/goat_enums.dart';
import '../models/goat_models.dart';

/// All goat sales across batches — 2 tabs: Goat Sales + Milk Sales.
class GoatSalesScreen extends StatelessWidget {
  const GoatSalesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('🐐 Vendas de Caprinos'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.goNamed('goatDashboard'),
          ),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Caprinos'),
              Tab(text: 'Leite'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _GoatSalesTab(),
            _GoatMilkSalesTab(),
          ],
        ),
        floatingActionButton: _AddSaleFab(),
      ),
    );
  }
}

class _AddSaleFab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: () => _showAddSaleTypeDialog(context),
      child: const Icon(Icons.add),
    );
  }

  void _showAddSaleTypeDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Nova Venda', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () {
                Navigator.pop(ctx);
                _showAddGoatSaleDialog(context);
              },
              icon: const Icon(Icons.pets),
              label: const Text('Venda de Caprinos'),
            ),
            const SizedBox(height: 8),
            FilledButton.tonal(
              onPressed: () {
                Navigator.pop(ctx);
                _showAddMilkSaleDialog(context);
              },
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [Icon(Icons.water_drop), SizedBox(width: 8), Text('Venda de Leite')],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddGoatSaleDialog(BuildContext context) {
    final goat = context.read<GoatProvider>();
    final clients = context.read<ClientProvider>();
    final batches = goat.batches.where((b) => b.status == BatchStatus.active).toList();

    if (batches.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não há rebanhos activos.')),
      );
      return;
    }

    final qtyCtrl = TextEditingController(text: '1');
    final weightCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    final totalCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    String batchId = batches.first.id;
    String? clientId;
    GoatSaleType saleType = GoatSaleType.live;
    PaymentStatus payStatus = PaymentStatus.paid;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Nova Venda de Caprinos'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: batchId,
                    decoration: const InputDecoration(labelText: 'Rebanho'),
                    items: batches.map((b) => DropdownMenuItem(value: b.id, child: Text(b.name))).toList(),
                    onChanged: (v) => setState(() => batchId = v!),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String?>(
                    value: clientId,
                    decoration: const InputDecoration(labelText: 'Cliente (opcional)'),
                    items: [
                      const DropdownMenuItem<String?>(value: null, child: Text('Sem cliente')),
                      ...clients.clients.map((c) => DropdownMenuItem<String?>(value: c.id, child: Text(c.name))),
                    ],
                    onChanged: (v) => setState(() => clientId = v),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<GoatSaleType>(
                    value: saleType,
                    decoration: const InputDecoration(labelText: 'Tipo de Venda'),
                    items: const [
                      DropdownMenuItem(value: GoatSaleType.live, child: Text('Vivo')),
                      DropdownMenuItem(value: GoatSaleType.slaughtered, child: Text('Abatido')),
                    ],
                    onChanged: (v) => setState(() => saleType = v!),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: qtyCtrl,
                    decoration: const InputDecoration(labelText: 'Quantidade *'),
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Obrigatório';
                      final qty = int.tryParse(v);
                      if (qty == null || qty <= 0) return 'Inválido';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: weightCtrl,
                          decoration: const InputDecoration(labelText: 'Peso (kg)'),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: priceCtrl,
                          decoration: const InputDecoration(labelText: 'Preço/kg'),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: totalCtrl,
                    decoration: const InputDecoration(labelText: 'Total *'),
                    keyboardType: TextInputType.number,
                    validator: (v) => v == null || v.isEmpty || double.tryParse(v) == null ? 'Valor inválido' : null,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<PaymentStatus>(
                    value: payStatus,
                    decoration: const InputDecoration(labelText: 'Estado Pagamento'),
                    items: const [
                      DropdownMenuItem(value: PaymentStatus.paid, child: Text('Pago')),
                      DropdownMenuItem(value: PaymentStatus.partial, child: Text('Parcial')),
                      DropdownMenuItem(value: PaymentStatus.pending, child: Text('Pendente')),
                    ],
                    onChanged: (v) => setState(() => payStatus = v!),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
            FilledButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  final total = double.parse(totalCtrl.text);
                  goat.addGoatSale(GoatSale(
                    id: const Uuid().v4(),
                    batchId: batchId,
                    clientId: clientId,
                    saleType: saleType,
                    quantity: int.parse(qtyCtrl.text),
                    weightKg: double.tryParse(weightCtrl.text),
                    pricePerKg: double.tryParse(priceCtrl.text),
                    total: total,
                    paymentStatus: payStatus.name,
                    amountPaid: payStatus == PaymentStatus.paid ? total : 0,
                    date: DateTime.now(),
                  ));
                  Navigator.pop(ctx);
                }
              },
              child: const Text('Registar'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddMilkSaleDialog(BuildContext context) {
    final goat = context.read<GoatProvider>();
    final clients = context.read<ClientProvider>();
    final batches = goat.batches.where((b) => b.status == BatchStatus.active).toList();

    if (batches.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não há rebanhos activos.')),
      );
      return;
    }

    final qtyCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    String batchId = batches.first.id;
    String? clientId;
    PaymentStatus payStatus = PaymentStatus.paid;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Nova Venda de Leite'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: batchId,
                    decoration: const InputDecoration(labelText: 'Rebanho'),
                    items: batches.map((b) => DropdownMenuItem(value: b.id, child: Text(b.name))).toList(),
                    onChanged: (v) => setState(() => batchId = v!),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String?>(
                    value: clientId,
                    decoration: const InputDecoration(labelText: 'Cliente (opcional)'),
                    items: [
                      const DropdownMenuItem<String?>(value: null, child: Text('Sem cliente')),
                      ...clients.clients.map((c) => DropdownMenuItem<String?>(value: c.id, child: Text(c.name))),
                    ],
                    onChanged: (v) => setState(() => clientId = v),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: qtyCtrl,
                    decoration: const InputDecoration(labelText: 'Litros *'),
                    keyboardType: TextInputType.number,
                    validator: (v) => v == null || v.isEmpty || double.tryParse(v) == null ? 'Valor inválido' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: priceCtrl,
                    decoration: const InputDecoration(labelText: 'Preço/Litro *'),
                    keyboardType: TextInputType.number,
                    validator: (v) => v == null || v.isEmpty || double.tryParse(v) == null ? 'Valor inválido' : null,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<PaymentStatus>(
                    value: payStatus,
                    decoration: const InputDecoration(labelText: 'Estado Pagamento'),
                    items: const [
                      DropdownMenuItem(value: PaymentStatus.paid, child: Text('Pago')),
                      DropdownMenuItem(value: PaymentStatus.partial, child: Text('Parcial')),
                      DropdownMenuItem(value: PaymentStatus.pending, child: Text('Pendente')),
                    ],
                    onChanged: (v) => setState(() => payStatus = v!),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
            FilledButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  final qty = double.parse(qtyCtrl.text);
                  final price = double.parse(priceCtrl.text);
                  final total = qty * price;
                  goat.addMilkSale(GoatMilkSale(
                    id: const Uuid().v4(),
                    batchId: batchId,
                    clientId: clientId,
                    quantityLiters: qty,
                    pricePerLiter: price,
                    total: total,
                    paymentStatus: payStatus.name,
                    amountPaid: payStatus == PaymentStatus.paid ? total : 0,
                    date: DateTime.now(),
                  ));
                  Navigator.pop(ctx);
                }
              },
              child: const Text('Registar'),
            ),
          ],
        ),
      ),
    );
  }
}

class _GoatSalesTab extends StatelessWidget {
  const _GoatSalesTab();

  @override
  Widget build(BuildContext context) {
    final goat = context.watch<GoatProvider>();
    final clients = context.watch<ClientProvider>();
    final settings = context.watch<SettingsProvider>();
    final currency = settings.currencySymbol;
    final sales = goat.goatSales;

    if (sales.isEmpty) {
      return const EmptyStateWidget(
        icon: Icons.shopping_cart_outlined,
        message: 'Nenhuma venda de caprinos registada.',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: sales.length,
      itemBuilder: (ctx, i) {
        final s = sales[i];
        final client = s.clientId != null ? clients.getById(s.clientId!) : null;
        final batch = goat.getBatchById(s.batchId);

        return Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: _statusColor(s.paymentStatus),
              child: const Icon(Icons.pets, color: Colors.white, size: 20),
            ),
            title: Text('$currency${s.total.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(
              '${s.quantity} animais • ${client?.name ?? "Sem cliente"} • ${batch?.name ?? "?"} • ${DateFormat('dd/MM').format(s.date)}',
            ),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
              onPressed: () async {
                final confirmed = await showDeleteConfirmation(context, itemName: 'esta venda');
                if (confirmed) goat.deleteGoatSale(s.id);
              },
            ),
          ),
        );
      },
    );
  }
}

class _GoatMilkSalesTab extends StatelessWidget {
  const _GoatMilkSalesTab();

  @override
  Widget build(BuildContext context) {
    final goat = context.watch<GoatProvider>();
    final clients = context.watch<ClientProvider>();
    final settings = context.watch<SettingsProvider>();
    final currency = settings.currencySymbol;
    final sales = goat.milkSales;

    if (sales.isEmpty) {
      return const EmptyStateWidget(
        icon: Icons.water_drop_outlined,
        message: 'Nenhuma venda de leite registada.',
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
            leading: CircleAvatar(
              backgroundColor: _statusColor(s.paymentStatus),
              child: const Icon(Icons.water_drop, color: Colors.white, size: 20),
            ),
            title: Text('$currency${s.total.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(
              '${s.quantityLiters.toStringAsFixed(1)} L • ${client?.name ?? "Sem cliente"} • ${DateFormat('dd/MM').format(s.date)}',
            ),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
              onPressed: () async {
                final confirmed = await showDeleteConfirmation(context, itemName: 'esta venda');
                if (confirmed) goat.deleteMilkSale(s.id);
              },
            ),
          ),
        );
      },
    );
  }
}

Color _statusColor(String status) {
  switch (status) {
    case 'paid': return Colors.green;
    case 'partial': return Colors.orange;
    default: return Colors.red;
  }
}
