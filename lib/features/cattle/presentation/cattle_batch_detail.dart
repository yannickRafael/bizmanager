import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/models/expense.dart';
import '../../../core/models/mortality.dart';
import '../../../core/widgets/confirm_delete_dialog.dart';
import '../../../features/settings/providers/settings_provider.dart';
import '../providers/cattle_provider.dart';
import '../models/cattle_batch.dart';
import '../models/cattle_enums.dart';
import '../models/cattle_models.dart';

/// Detailed cattle batch view with 5 tabs: Summary, Expenses, Mortality, Production, Sales.
class CattleBatchDetail extends StatelessWidget {
  final String batchId;
  const CattleBatchDetail({super.key, required this.batchId});

  @override
  Widget build(BuildContext context) {
    final cattle = context.watch<CattleProvider>();
    final batch = cattle.getBatchById(batchId);

    if (batch == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Manada')),
        body: const Center(child: Text('Manada não encontrada.')),
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
            onPressed: () => context.goNamed('cattleBatches'),
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
            _SummaryTab(batch: batch, cattle: cattle),
            _ExpensesTab(batch: batch, cattle: cattle, isClosed: isClosed),
            _MortalityTab(batch: batch, cattle: cattle, isClosed: isClosed),
            _ProductionTab(batch: batch, cattle: cattle, isClosed: isClosed),
            _SalesTab(batch: batch, cattle: cattle),
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
  final CattleBatch batch;
  final CattleProvider cattle;
  const _SummaryTab({required this.batch, required this.cattle});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final currency = settings.currencySymbol;
    final expenses = cattle.getExpensesByBatchId(batch.id);
    final mortalities = cattle.getMortalitiesByBatchId(batch.id);
    final milkProds = cattle.getMilkProductionsByBatchId(batch.id);
    final calfBirths = cattle.getCalfBirthsByBatchId(batch.id);
    final totalExpenses = expenses.fold<double>(0.0, (double s, e) => s + e.amount);
    final totalMortality = mortalities.fold<int>(0, (int s, m) => s + m.quantity);
    final totalMilk = milkProds.fold<double>(0.0, (double s, p) => s + p.quantityLiters);
    final totalCalves = calfBirths.fold<int>(0, (int s, c) => s + c.quantity);
    final mortalityRate = batch.initialQuantity > 0
        ? (totalMortality / batch.initialQuantity * 100)
        : 0.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _InfoCard(items: [
            _KV('Finalidade', _purposeLabel(batch.purpose)),
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
          const SizedBox(height: 16),
          _InfoCard(items: [
            _KV('Produção Leite Total', '${totalMilk.toStringAsFixed(1)} L'),
            _KV('Total Crias Nascidas', '$totalCalves'),
          ]),
        ],
      ),
    );
  }

  String _purposeLabel(CattlePurpose p) {
    switch (p) {
      case CattlePurpose.dairy: return 'Leiteiro';
      case CattlePurpose.beef: return 'Corte';
      case CattlePurpose.dual: return 'Duplo Propósito';
    }
  }
}

// ══════════════════════════════════════════
//  TAB 2: Expenses
// ══════════════════════════════════════════
class _ExpensesTab extends StatelessWidget {
  final CattleBatch batch;
  final CattleProvider cattle;
  final bool isClosed;
  const _ExpensesTab({required this.batch, required this.cattle, required this.isClosed});

  @override
  Widget build(BuildContext context) {
    final expenses = cattle.getExpensesByBatchId(batch.id);
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
                              if (confirmed) cattle.deleteExpense(e.id);
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
                  context.read<CattleProvider>().addExpense(Expense(
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
  final CattleBatch batch;
  final CattleProvider cattle;
  final bool isClosed;
  const _MortalityTab({required this.batch, required this.cattle, required this.isClosed});

  @override
  Widget build(BuildContext context) {
    final records = cattle.getMortalitiesByBatchId(batch.id);

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
                      title: Text('${m.quantity} animais'),
                      subtitle: Text('${m.cause ?? "Sem causa"} • ${DateFormat('dd/MM/yyyy').format(m.date)}'),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                        onPressed: () async {
                          final confirmed = await showDeleteConfirmation(context, itemName: 'este registo');
                          if (confirmed) cattle.deleteMortality(m.id);
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
                context.read<CattleProvider>().addMortality(Mortality(
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
//  TAB 4: Production (milk + calf births)
// ══════════════════════════════════════════
class _ProductionTab extends StatelessWidget {
  final CattleBatch batch;
  final CattleProvider cattle;
  final bool isClosed;
  const _ProductionTab({required this.batch, required this.cattle, required this.isClosed});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          const TabBar(
            tabs: [
              Tab(text: 'Leite'),
              Tab(text: 'Nascimentos'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _MilkSubTab(batch: batch, cattle: cattle, isClosed: isClosed),
                _CalfBirthSubTab(batch: batch, cattle: cattle, isClosed: isClosed),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MilkSubTab extends StatelessWidget {
  final CattleBatch batch;
  final CattleProvider cattle;
  final bool isClosed;
  const _MilkSubTab({required this.batch, required this.cattle, required this.isClosed});

  @override
  Widget build(BuildContext context) {
    final prods = cattle.getMilkProductionsByBatchId(batch.id);

    return Column(
      children: [
        if (!isClosed)
          Padding(
            padding: const EdgeInsets.all(12),
            child: FilledButton.icon(
              onPressed: () => _showAddMilkDialog(context),
              icon: const Icon(Icons.add),
              label: const Text('Registar Produção'),
            ),
          ),
        Expanded(
          child: prods.isEmpty
              ? const Center(child: Text('Sem produção de leite registada.'))
              : ListView.builder(
                  itemCount: prods.length,
                  itemBuilder: (ctx, i) {
                    final p = prods[i];
                    final sessionLabel = p.session != null ? ' • ${_sessionLabel(p.session!)}' : '';
                    return ListTile(
                      leading: const Icon(Icons.water_drop, color: Colors.blue),
                      title: Text('${p.quantityLiters.toStringAsFixed(1)} litros$sessionLabel'),
                      subtitle: Text(DateFormat('dd/MM/yyyy').format(p.date)),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                        onPressed: () async {
                          final confirmed = await showDeleteConfirmation(context, itemName: 'esta produção');
                          if (confirmed) cattle.deleteMilkProduction(p.id);
                        },
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  void _showAddMilkDialog(BuildContext context) {
    final qtyCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    MilkSession? session;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Registar Produção de Leite'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: qtyCtrl,
                  decoration: const InputDecoration(labelText: 'Litros *'),
                  keyboardType: TextInputType.number,
                  validator: (v) => v == null || v.isEmpty || double.tryParse(v) == null ? 'Valor inválido' : null,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<MilkSession?>(
                  value: session,
                  decoration: const InputDecoration(labelText: 'Sessão (opcional)'),
                  items: const [
                    DropdownMenuItem(value: null, child: Text('Sem sessão')),
                    DropdownMenuItem(value: MilkSession.morning, child: Text('Manhã')),
                    DropdownMenuItem(value: MilkSession.afternoon, child: Text('Tarde')),
                    DropdownMenuItem(value: MilkSession.evening, child: Text('Noite')),
                  ],
                  onChanged: (v) => setState(() => session = v),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
            FilledButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  context.read<CattleProvider>().addMilkProduction(MilkProduction(
                    id: const Uuid().v4(),
                    batchId: batch.id,
                    quantityLiters: double.parse(qtyCtrl.text),
                    session: session,
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

  String _sessionLabel(MilkSession s) {
    switch (s) {
      case MilkSession.morning: return 'Manhã';
      case MilkSession.afternoon: return 'Tarde';
      case MilkSession.evening: return 'Noite';
    }
  }
}

class _CalfBirthSubTab extends StatelessWidget {
  final CattleBatch batch;
  final CattleProvider cattle;
  final bool isClosed;
  const _CalfBirthSubTab({required this.batch, required this.cattle, required this.isClosed});

  @override
  Widget build(BuildContext context) {
    final births = cattle.getCalfBirthsByBatchId(batch.id);

    return Column(
      children: [
        if (!isClosed)
          Padding(
            padding: const EdgeInsets.all(12),
            child: FilledButton.icon(
              onPressed: () => _showAddCalfBirthDialog(context),
              icon: const Icon(Icons.add),
              label: const Text('Registar Nascimento'),
            ),
          ),
        Expanded(
          child: births.isEmpty
              ? const Center(child: Text('Sem nascimentos registados.'))
              : ListView.builder(
                  itemCount: births.length,
                  itemBuilder: (ctx, i) {
                    final b = births[i];
                    final sexLabel = b.sex != null ? ' • ${b.sex}' : '';
                    return ListTile(
                      leading: const Icon(Icons.child_care, color: Colors.brown),
                      title: Text('${b.quantity} crias$sexLabel'),
                      subtitle: Text('${b.notes ?? ""} • ${DateFormat('dd/MM/yyyy').format(b.date)}'),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                        onPressed: () async {
                          final confirmed = await showDeleteConfirmation(context, itemName: 'este nascimento');
                          if (confirmed) cattle.deleteCalfBirth(b.id);
                        },
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  void _showAddCalfBirthDialog(BuildContext context) {
    final qtyCtrl = TextEditingController(text: '1');
    final notesCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    String? sex;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Registar Nascimento'),
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
                    if (int.tryParse(v) == null || int.parse(v) <= 0) return 'Inválido';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String?>(
                  value: sex,
                  decoration: const InputDecoration(labelText: 'Sexo (opcional)'),
                  items: const [
                    DropdownMenuItem(value: null, child: Text('Não especificado')),
                    DropdownMenuItem(value: 'Macho', child: Text('Macho')),
                    DropdownMenuItem(value: 'Fêmea', child: Text('Fêmea')),
                    DropdownMenuItem(value: 'Misto', child: Text('Misto')),
                  ],
                  onChanged: (v) => setState(() => sex = v),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: notesCtrl,
                  decoration: const InputDecoration(labelText: 'Notas'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
            FilledButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  context.read<CattleProvider>().addCalfBirth(CalfBirth(
                    id: const Uuid().v4(),
                    batchId: batch.id,
                    quantity: int.parse(qtyCtrl.text),
                    sex: sex,
                    notes: notesCtrl.text.trim().isNotEmpty ? notesCtrl.text.trim() : null,
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
  final CattleBatch batch;
  final CattleProvider cattle;
  const _SalesTab({required this.batch, required this.cattle});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final currency = settings.currencySymbol;
    final cattleSales = cattle.cattleSales.where((s) => s.batchId == batch.id).toList();
    final milkSales = cattle.milkSales.where((s) => s.batchId == batch.id).toList();

    if (cattleSales.isEmpty && milkSales.isEmpty) {
      return const Center(child: Text('Sem vendas registadas para esta manada.'));
    }

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        if (cattleSales.isNotEmpty) ...[
          Text('Vendas de Gado', style: Theme.of(context).textTheme.titleSmall),
          ...cattleSales.map((s) => ListTile(
            leading: const Icon(Icons.shopping_cart),
            title: Text('$currency${s.total.toStringAsFixed(2)}'),
            subtitle: Text('${s.quantity} animais • ${s.saleType.name == "live" ? "Vivo" : "Abatido"} • ${DateFormat('dd/MM').format(s.date)}'),
          )),
          const Divider(),
        ],
        if (milkSales.isNotEmpty) ...[
          Text('Vendas de Leite', style: Theme.of(context).textTheme.titleSmall),
          ...milkSales.map((s) => ListTile(
            leading: const Icon(Icons.water_drop, color: Colors.blue),
            title: Text('$currency${s.total.toStringAsFixed(2)}'),
            subtitle: Text('${s.quantityLiters.toStringAsFixed(1)} L • ${DateFormat('dd/MM').format(s.date)}'),
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
