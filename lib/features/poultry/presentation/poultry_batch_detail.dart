import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/models/expense.dart';
import '../../../core/models/mortality.dart';
import '../../../core/widgets/confirm_delete_dialog.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../../features/settings/providers/settings_provider.dart';
import '../providers/poultry_provider.dart';
import '../../../models/batch.dart';
import '../../../models/enums.dart';
import '../../../models/egg_production.dart';
import '../../../models/slaughter.dart';

/// Detailed batch view with 5 tabs: Summary, Expenses, Mortality, Production, Sales.
class PoultryBatchDetail extends StatelessWidget {
  final String batchId;
  const PoultryBatchDetail({super.key, required this.batchId});

  @override
  Widget build(BuildContext context) {
    final poultry = context.watch<PoultryProvider>();
    final batch = poultry.getBatchById(batchId);

    if (batch == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Lote')),
        body: const Center(child: Text('Lote não encontrado.')),
      );
    }

    final isClosed = batch.status == BatchStatus.closed;

    return DefaultTabController(
      length: 5,
      child: Scaffold(
        appBar: AppBar(
          title: Text(batch.name),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.goNamed('poultryBatches'),
          ),
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'Resumo'),
              Tab(text: 'Despesas'),
              Tab(text: 'Mortalidade'),
              Tab(text: 'Produção'),
              Tab(text: 'Vendas'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _SummaryTab(batch: batch, poultry: poultry),
            _ExpensesTab(batch: batch, poultry: poultry, isClosed: isClosed),
            _MortalityTab(batch: batch, poultry: poultry, isClosed: isClosed),
            _ProductionTab(batch: batch, poultry: poultry, isClosed: isClosed),
            _SalesTab(batch: batch, poultry: poultry),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════
//  TAB 1: Summary
// ══════════════════════════════════════════
class _SummaryTab extends StatelessWidget {
  final Batch batch;
  final PoultryProvider poultry;
  const _SummaryTab({required this.batch, required this.poultry});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final currency = settings.currencySymbol;
    final expenses = poultry.getExpensesByBatchId(batch.id);
    final mortalities = poultry.getMortalitiesByBatchId(batch.id);
    final totalExpenses = expenses.fold(0.0, (s, e) => s + e.amount);
    final totalMortality = mortalities.fold(0, (s, m) => s + m.quantity);
    final mortalityRate = batch.initialQuantity > 0
        ? (totalMortality / batch.initialQuantity * 100)
        : 0.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _InfoCard(items: [
            _KV('Tipo', batch.type == BatchType.meat ? 'Corte' : 'Postura'),
            _KV('Origem', batch.birdOrigin == BirdOrigin.purchase ? 'Compra' : 'Incubação'),
            _KV('Raça', batch.breedOrLineage),
            _KV('Data Entrada', DateFormat('dd/MM/yyyy').format(batch.entryDate)),
            _KV('Estado', batch.status == BatchStatus.active ? 'Activo' : 'Encerrado'),
          ]),
          const SizedBox(height: 16),
          _InfoCard(items: [
            _KV('Quantidade Inicial', '${batch.initialQuantity}'),
            _KV('Quantidade Actual', '${batch.currentQuantity}'),
            _KV('Mortalidade', '$totalMortality (${mortalityRate.toStringAsFixed(1)}%)'),
            _KV('Custo Aquisição', '$currency${batch.acquisitionCost.toStringAsFixed(2)}'),
            _KV('Total Despesas', '$currency${totalExpenses.toStringAsFixed(2)}'),
          ]),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════
//  TAB 2: Expenses
// ══════════════════════════════════════════
class _ExpensesTab extends StatelessWidget {
  final Batch batch;
  final PoultryProvider poultry;
  final bool isClosed;
  const _ExpensesTab({required this.batch, required this.poultry, required this.isClosed});

  @override
  Widget build(BuildContext context) {
    final expenses = poultry.getExpensesByBatchId(batch.id);
    final settings = context.watch<SettingsProvider>();
    final currency = settings.currencySymbol;

    return Column(
      children: [
        if (!isClosed)
          Padding(
            padding: const EdgeInsets.all(12),
            child: FilledButton.icon(
              onPressed: () => _showAddExpenseDialog(context),
              icon: const Icon(Icons.add),
              label: const Text('Nova Despesa'),
            ),
          ),
        Expanded(
          child: expenses.isEmpty
              ? const Center(child: Text('Sem despesas registadas.'))
              : ListView.builder(
                  itemCount: expenses.length,
                  itemBuilder: (ctx, i) {
                    final e = expenses[i];
                    return ListTile(
                      leading: const Icon(Icons.receipt_long),
                      title: Text(e.description.isNotEmpty ? e.description : e.type.name),
                      subtitle: Text(DateFormat('dd/MM/yyyy').format(e.date)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('$currency${e.amount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                            onPressed: () async {
                              final confirmed = await showDeleteConfirmation(context, itemName: 'esta despesa');
                              if (confirmed) poultry.deleteExpense(e.id);
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  void _showAddExpenseDialog(BuildContext context) {
    final descCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    ExpenseType type = ExpenseType.feed;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Nova Despesa'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<ExpenseType>(
                    value: type,
                    decoration: const InputDecoration(labelText: 'Tipo'),
                    items: ExpenseType.values.map((t) => DropdownMenuItem(
                      value: t,
                      child: Text(_expenseLabel(t)),
                    )).toList(),
                    onChanged: (v) => setState(() => type = v!),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: descCtrl,
                    decoration: const InputDecoration(labelText: 'Descrição'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: amountCtrl,
                    decoration: const InputDecoration(labelText: 'Valor *'),
                    keyboardType: TextInputType.number,
                    validator: (v) => v == null || v.isEmpty || double.tryParse(v) == null ? 'Valor inválido' : null,
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
                  context.read<PoultryProvider>().addExpense(Expense(
                    id: const Uuid().v4(),
                    batchId: batch.id,
                    type: type,
                    description: descCtrl.text.trim(),
                    amount: double.parse(amountCtrl.text),
                    date: DateTime.now(),
                  ));
                  Navigator.pop(ctx);
                }
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }

  String _expenseLabel(ExpenseType t) {
    switch (t) {
      case ExpenseType.feed: return 'Ração';
      case ExpenseType.vaccine: return 'Vacina';
      case ExpenseType.medication: return 'Medicamento';
      case ExpenseType.labor: return 'Mão de Obra';
      case ExpenseType.energy: return 'Energia';
      case ExpenseType.custom: return 'Outro';
    }
  }
}

// ══════════════════════════════════════════
//  TAB 3: Mortality
// ══════════════════════════════════════════
class _MortalityTab extends StatelessWidget {
  final Batch batch;
  final PoultryProvider poultry;
  final bool isClosed;
  const _MortalityTab({required this.batch, required this.poultry, required this.isClosed});

  @override
  Widget build(BuildContext context) {
    final records = poultry.getMortalitiesByBatchId(batch.id);

    return Column(
      children: [
        if (!isClosed)
          Padding(
            padding: const EdgeInsets.all(12),
            child: FilledButton.icon(
              onPressed: () => _showAddMortalityDialog(context),
              icon: const Icon(Icons.add),
              label: const Text('Registar Mortalidade'),
            ),
          ),
        Expanded(
          child: records.isEmpty
              ? const Center(child: Text('Sem registos de mortalidade.'))
              : ListView.builder(
                  itemCount: records.length,
                  itemBuilder: (ctx, i) {
                    final m = records[i];
                    return ListTile(
                      leading: const Icon(Icons.heart_broken, color: Colors.orange),
                      title: Text('${m.quantity} aves'),
                      subtitle: Text('${m.cause ?? "Sem causa"} • ${DateFormat('dd/MM/yyyy').format(m.date)}'),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                        onPressed: () async {
                          final confirmed = await showDeleteConfirmation(context, itemName: 'este registo');
                          if (confirmed) poultry.deleteMortality(m.id);
                        },
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  void _showAddMortalityDialog(BuildContext context) {
    final qtyCtrl = TextEditingController();
    final causeCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Registar Mortalidade'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: qtyCtrl,
                decoration: const InputDecoration(labelText: 'Quantidade *'),
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Obrigatório';
                  final qty = int.tryParse(v);
                  if (qty == null || qty <= 0) return 'Inválido';
                  if (qty > batch.currentQuantity) return 'Excede quantidade actual';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: causeCtrl,
                decoration: const InputDecoration(labelText: 'Causa'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                context.read<PoultryProvider>().addMortality(Mortality(
                  id: const Uuid().v4(),
                  batchId: batch.id,
                  quantity: int.parse(qtyCtrl.text),
                  cause: causeCtrl.text.trim().isNotEmpty ? causeCtrl.text.trim() : null,
                  date: DateTime.now(),
                ));
                Navigator.pop(ctx);
              }
            },
            child: const Text('Registar'),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════
//  TAB 4: Production (eggs for layers)
// ══════════════════════════════════════════
class _ProductionTab extends StatelessWidget {
  final Batch batch;
  final PoultryProvider poultry;
  final bool isClosed;
  const _ProductionTab({required this.batch, required this.poultry, required this.isClosed});

  @override
  Widget build(BuildContext context) {
    if (batch.type == BatchType.meat) {
      // Show slaughters for meat batches
      final slaughters = poultry.getSlaughtersByBatchId(batch.id);
      return Column(
        children: [
          if (!isClosed)
            Padding(
              padding: const EdgeInsets.all(12),
              child: FilledButton.icon(
                onPressed: () => _showAddSlaughterDialog(context),
                icon: const Icon(Icons.add),
                label: const Text('Registar Abate'),
              ),
            ),
          Expanded(
            child: slaughters.isEmpty
                ? const Center(child: Text('Sem abates registados.'))
                : ListView.builder(
                    itemCount: slaughters.length,
                    itemBuilder: (ctx, i) {
                      final s = slaughters[i];
                      return ListTile(
                        leading: const Icon(Icons.content_cut),
                        title: Text('${s.slaughteredQuantity} aves • ${s.totalWeightKg.toStringAsFixed(1)} kg'),
                        subtitle: Text(DateFormat('dd/MM/yyyy').format(s.date)),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                          onPressed: () async {
                            final confirmed = await showDeleteConfirmation(context, itemName: 'este abate');
                            if (confirmed) poultry.deleteSlaughter(s.id);
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      );
    }

    // Show egg production for layer batches
    final prods = poultry.getEggProductionsByBatchId(batch.id);
    return Column(
      children: [
        if (!isClosed)
          Padding(
            padding: const EdgeInsets.all(12),
            child: FilledButton.icon(
              onPressed: () => _showAddEggProductionDialog(context),
              icon: const Icon(Icons.add),
              label: const Text('Registar Produção'),
            ),
          ),
        Expanded(
          child: prods.isEmpty
              ? const Center(child: Text('Sem produção registada.'))
              : ListView.builder(
                  itemCount: prods.length,
                  itemBuilder: (ctx, i) {
                    final p = prods[i];
                    final unitLabel = p.unit == EggUnit.dozens ? 'dúzias' : 'bandejas';
                    return ListTile(
                      leading: const Icon(Icons.egg, color: Colors.amber),
                      title: Text('${p.quantity} $unitLabel • ${p.size.name}'),
                      subtitle: Text(DateFormat('dd/MM/yyyy').format(p.date)),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                        onPressed: () async {
                          final confirmed = await showDeleteConfirmation(context, itemName: 'esta produção');
                          if (confirmed) poultry.deleteEggProduction(p.id);
                        },
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  void _showAddSlaughterDialog(BuildContext context) {
    final qtyCtrl = TextEditingController();
    final weightCtrl = TextEditingController();
    final costCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Registar Abate'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: qtyCtrl,
                decoration: const InputDecoration(labelText: 'Quantidade *'),
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Obrigatório';
                  final qty = int.tryParse(v);
                  if (qty == null || qty <= 0) return 'Inválido';
                  if (qty > batch.currentQuantity) return 'Excede quantidade actual';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(controller: weightCtrl, decoration: const InputDecoration(labelText: 'Peso Total (kg)'), keyboardType: TextInputType.number),
              const SizedBox(height: 12),
              TextFormField(controller: costCtrl, decoration: const InputDecoration(labelText: 'Custo Abate'), keyboardType: TextInputType.number),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                context.read<PoultryProvider>().addSlaughter(Slaughter(
                  id: const Uuid().v4(),
                  batchId: batch.id,
                  slaughteredQuantity: int.parse(qtyCtrl.text),
                  totalWeightKg: double.tryParse(weightCtrl.text) ?? 0,
                  slaughterCost: double.tryParse(costCtrl.text) ?? 0,
                  date: DateTime.now(),
                ));
                Navigator.pop(ctx);
              }
            },
            child: const Text('Registar'),
          ),
        ],
      ),
    );
  }

  void _showAddEggProductionDialog(BuildContext context) {
    final qtyCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    EggUnit unit = EggUnit.dozens;
    EggSize size = EggSize.medium;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Registar Produção de Ovos'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: qtyCtrl,
                  decoration: const InputDecoration(labelText: 'Quantidade *'),
                  keyboardType: TextInputType.number,
                  validator: (v) => v == null || v.isEmpty || double.tryParse(v) == null ? 'Inválido' : null,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<EggUnit>(
                  value: unit,
                  decoration: const InputDecoration(labelText: 'Unidade'),
                  items: const [
                    DropdownMenuItem(value: EggUnit.dozens, child: Text('Dúzias')),
                    DropdownMenuItem(value: EggUnit.trays30, child: Text('Bandejas (30)')),
                  ],
                  onChanged: (v) => setState(() => unit = v!),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<EggSize>(
                  value: size,
                  decoration: const InputDecoration(labelText: 'Tamanho'),
                  items: EggSize.values.map((s) => DropdownMenuItem(value: s, child: Text(s.name))).toList(),
                  onChanged: (v) => setState(() => size = v!),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
            FilledButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  context.read<PoultryProvider>().addEggProduction(EggProduction(
                    id: const Uuid().v4(),
                    batchId: batch.id,
                    unit: unit,
                    quantity: double.parse(qtyCtrl.text),
                    size: size,
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

// ══════════════════════════════════════════
//  TAB 5: Sales summary for this batch
// ══════════════════════════════════════════
class _SalesTab extends StatelessWidget {
  final Batch batch;
  final PoultryProvider poultry;
  const _SalesTab({required this.batch, required this.poultry});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final currency = settings.currencySymbol;
    final chickenSales = poultry.chickenSales.where((s) => s.batchId == batch.id).toList();
    final eggSales = poultry.eggSales.where((s) => s.batchId == batch.id).toList();
    final culledSales = poultry.culledBirdSales.where((s) => s.batchId == batch.id).toList();

    if (chickenSales.isEmpty && eggSales.isEmpty && culledSales.isEmpty) {
      return const Center(child: Text('Sem vendas registadas para este lote.'));
    }

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        if (chickenSales.isNotEmpty) ...[
          Text('Vendas de Frangos', style: Theme.of(context).textTheme.titleSmall),
          ...chickenSales.map((s) => ListTile(
            leading: const Icon(Icons.shopping_cart),
            title: Text('$currency${s.total.toStringAsFixed(2)}'),
            subtitle: Text(DateFormat('dd/MM/yyyy').format(s.date)),
          )),
          const Divider(),
        ],
        if (eggSales.isNotEmpty) ...[
          Text('Vendas de Ovos', style: Theme.of(context).textTheme.titleSmall),
          ...eggSales.map((s) => ListTile(
            leading: const Icon(Icons.egg),
            title: Text('$currency${s.total.toStringAsFixed(2)}'),
            subtitle: Text('${s.quantity} ${s.unit == EggUnit.dozens ? "dz" : "band."} • ${DateFormat('dd/MM').format(s.date)}'),
          )),
          const Divider(),
        ],
        if (culledSales.isNotEmpty) ...[
          Text('Vendas Aves Descartadas', style: Theme.of(context).textTheme.titleSmall),
          ...culledSales.map((s) => ListTile(
            leading: const Icon(Icons.sell),
            title: Text('$currency${s.total.toStringAsFixed(2)}'),
            subtitle: Text('${s.quantity} aves • ${DateFormat('dd/MM').format(s.date)}'),
          )),
        ],
      ],
    );
  }
}

// ══════════════════════════════════════════
//  Shared helper widgets
// ══════════════════════════════════════════
class _InfoCard extends StatelessWidget {
  final List<_KV> items;
  const _InfoCard({required this.items});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: items.map((kv) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(kv.key, style: TextStyle(color: Colors.grey.shade600)),
                Text(kv.value, style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          )).toList(),
        ),
      ),
    );
  }
}

class _KV {
  final String key;
  final String value;
  const _KV(this.key, this.value);
}
