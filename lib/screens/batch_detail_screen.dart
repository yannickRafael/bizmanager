import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/data_manager.dart';
import '../models/enums.dart';
import '../models/expense.dart';
import '../models/mortality.dart';
import '../models/slaughter.dart';
import '../models/egg_production.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import '../models/batch.dart';

class BatchDetailScreen extends StatefulWidget {
  final String batchId;

  const BatchDetailScreen({super.key, required this.batchId});

  @override
  State<BatchDetailScreen> createState() => _BatchDetailScreenState();
}

class _BatchDetailScreenState extends State<BatchDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isInit = true;
  bool _isMeat = true;
  final _uuid = const Uuid();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isInit) {
      final batch = Provider.of<DataManager>(context, listen: false).getBatchById(widget.batchId);
      if (batch != null) {
        _isMeat = batch.type == BatchType.meat;
      }
      _tabController = TabController(length: 5, vsync: this);
      _tabController.addListener(() {
        if (mounted) setState(() {});
      });
      _isInit = false;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // --- MODALS ---

  void _showAddExpenseModal(BuildContext context, Batch batch) {
    ExpenseType type = ExpenseType.feed;
    String customCat = '';
    String description = '';
    double amount = 0.0;
    DateTime date = DateTime.now();
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setModalState) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom + 20, left: 20, right: 20, top: 20),
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Registar Despesa', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<ExpenseType>(
                    value: type,
                    decoration: const InputDecoration(labelText: 'Tipo de Despesa', border: OutlineInputBorder()),
                    items: ExpenseType.values.map((t) => DropdownMenuItem(value: t, child: Text(t.name.toUpperCase()))).toList(),
                    onChanged: (val) {
                      if (val != null) setModalState(() => type = val);
                    },
                  ),
                  const SizedBox(height: 12),
                  if (type == ExpenseType.custom) ...[
                    TextFormField(
                      decoration: const InputDecoration(labelText: 'Categoria Personalizada', border: OutlineInputBorder()),
                      validator: (val) => val == null || val.isEmpty ? 'Insira a categoria' : null,
                      onSaved: (val) => customCat = val!.trim(),
                    ),
                    const SizedBox(height: 12),
                  ],
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Descrição', border: OutlineInputBorder()),
                    validator: (val) => val == null || val.isEmpty ? 'Insira a descrição' : null,
                    onSaved: (val) => description = val!.trim(),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    decoration: InputDecoration(labelText: 'Valor', border: const OutlineInputBorder(), prefixText: Provider.of<DataManager>(ctx, listen: false).currencySymbol),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: (val) => val == null || double.tryParse(val) == null ? 'Valor inválido' : null,
                    onSaved: (val) => amount = double.parse(val!),
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(context: ctx, initialDate: date, firstDate: batch.entryDate, lastDate: DateTime.now());
                      if (picked != null) setModalState(() => date = picked);
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(labelText: 'Data', border: OutlineInputBorder()),
                      child: Text(DateFormat('dd/MM/yyyy').format(date)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: () {
                      if (formKey.currentState!.validate()) {
                        formKey.currentState!.save();
                        final expense = Expense(id: _uuid.v4(), batchId: widget.batchId, type: type, customCategory: type == ExpenseType.custom ? customCat : null, description: description, amount: amount, date: date);
                        Provider.of<DataManager>(context, listen: false).addExpense(expense);
                        Navigator.pop(ctx);
                      }
                    },
                    child: const Text('Guardar Despesa'),
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  void _showAddMortalityModal(BuildContext context, Batch batch) {
    int quantity = 0;
    String cause = '';
    DateTime date = DateTime.now();
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setModalState) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom + 20, left: 20, right: 20, top: 20),
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Registar Mortalidade', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Quantidade de Aves', border: OutlineInputBorder()),
                    keyboardType: TextInputType.number,
                    validator: (val) => val == null || int.tryParse(val) == null || int.parse(val) <= 0 ? 'Inválido' : null,
                    onSaved: (val) => quantity = int.parse(val!),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Causa (Opcional)', border: OutlineInputBorder()),
                    onSaved: (val) => cause = val?.trim() ?? '',
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(context: ctx, initialDate: date, firstDate: batch.entryDate, lastDate: DateTime.now());
                      if (picked != null) setModalState(() => date = picked);
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(labelText: 'Data', border: OutlineInputBorder()),
                      child: Text(DateFormat('dd/MM/yyyy').format(date)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: () {
                      if (formKey.currentState!.validate()) {
                        formKey.currentState!.save();
                        if (quantity > batch.currentQuantity) {
                          ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Quantidade superior às aves vivas!')));
                          return;
                        }
                        final mort = Mortality(id: _uuid.v4(), batchId: widget.batchId, quantity: quantity, cause: cause.isEmpty ? null : cause, date: date);
                        Provider.of<DataManager>(context, listen: false).addMortality(mort);
                        Navigator.pop(ctx);
                      }
                    },
                    child: const Text('Guardar'),
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  void _showAddSlaughterModal(BuildContext context, Batch batch) {
    int quantity = 0;
    double weight = 0.0;
    double cost = 0.0;
    DateTime date = DateTime.now();
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setModalState) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom + 20, left: 20, right: 20, top: 20),
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Registar Abate', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Qtd de Aves Abatidas', border: OutlineInputBorder()),
                    keyboardType: TextInputType.number,
                    validator: (val) => val == null || int.tryParse(val) == null || int.parse(val) <= 0 ? 'Inválido' : null,
                    onSaved: (val) => quantity = int.parse(val!),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Peso Total (Kg)', border: OutlineInputBorder()),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: (val) => val == null || double.tryParse(val) == null || double.parse(val) <= 0 ? 'Inválido' : null,
                    onSaved: (val) => weight = double.parse(val!),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    decoration: InputDecoration(labelText: 'Custo Associado (Opcional)', border: const OutlineInputBorder(), prefixText: Provider.of<DataManager>(ctx, listen: false).currencySymbol),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    onSaved: (val) => cost = (val == null || val.isEmpty) ? 0.0 : double.parse(val),
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(context: ctx, initialDate: date, firstDate: batch.entryDate, lastDate: DateTime.now());
                      if (picked != null) setModalState(() => date = picked);
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(labelText: 'Data', border: OutlineInputBorder()),
                      child: Text(DateFormat('dd/MM/yyyy').format(date)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: () {
                      if (formKey.currentState!.validate()) {
                        formKey.currentState!.save();
                        if (quantity > batch.currentQuantity) {
                          ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Quantidade superior às aves vivas!')));
                          return;
                        }
                        final slaugh = Slaughter(id: _uuid.v4(), batchId: widget.batchId, slaughteredQuantity: quantity, totalWeightKg: weight, slaughterCost: cost, date: date);
                        Provider.of<DataManager>(context, listen: false).addSlaughter(slaugh);
                        Navigator.pop(ctx);
                      }
                    },
                    child: const Text('Guardar Abate'),
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  void _showAddEggProductionModal(BuildContext context, Batch batch) {
    EggUnit unit = EggUnit.dozens;
    double quantity = 0.0;
    EggSize size = EggSize.medium;
    DateTime date = DateTime.now();
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setModalState) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom + 20, left: 20, right: 20, top: 20),
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Registar Produção de Ovos', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<EggUnit>(
                          value: unit,
                          isExpanded: true,
                          decoration: const InputDecoration(labelText: 'Unidade', border: OutlineInputBorder()),
                          items: EggUnit.values.map((u) => DropdownMenuItem(value: u, child: Text(u.name.toUpperCase()))).toList(),
                          onChanged: (val) {
                            if (val != null) setModalState(() => unit = val);
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          decoration: const InputDecoration(labelText: 'Quantidade', border: OutlineInputBorder()),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          validator: (val) => val == null || double.tryParse(val) == null || double.parse(val) <= 0 ? 'Inválido' : null,
                          onSaved: (val) => quantity = double.parse(val!),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<EggSize>(
                    value: size,
                    decoration: const InputDecoration(labelText: 'Tamanho / Classe', border: OutlineInputBorder()),
                    items: EggSize.values.map((s) => DropdownMenuItem(value: s, child: Text(s.name.toUpperCase()))).toList(),
                    onChanged: (val) {
                      if (val != null) setModalState(() => size = val);
                    },
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(context: ctx, initialDate: date, firstDate: batch.entryDate, lastDate: DateTime.now());
                      if (picked != null) setModalState(() => date = picked);
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(labelText: 'Data', border: OutlineInputBorder()),
                      child: Text(DateFormat('dd/MM/yyyy').format(date)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: () {
                      if (formKey.currentState!.validate()) {
                        formKey.currentState!.save();
                        final prod = EggProduction(id: _uuid.v4(), batchId: widget.batchId, unit: unit, quantity: quantity, size: size, date: date);
                        Provider.of<DataManager>(context, listen: false).addEggProduction(prod);
                        Navigator.pop(ctx);
                      }
                    },
                    child: const Text('Guardar Produção'),
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget? _buildFloatingActionButton(BuildContext context, Batch batch) {
    if (batch.status == BatchStatus.closed) return null; // Can't add to closed batch
    
    switch (_tabController.index) {
      case 1:
        return FloatingActionButton.extended(
          onPressed: () => _showAddExpenseModal(context, batch),
          icon: const Icon(Icons.add),
          label: const Text('Despesa'),
        );
      case 2:
        return FloatingActionButton.extended(
          onPressed: () => _showAddMortalityModal(context, batch),
          icon: const Icon(Icons.add),
          label: const Text('Mortalidade'),
          backgroundColor: Colors.orange,
        );
      case 3:
        if (_isMeat) {
          return FloatingActionButton.extended(
            onPressed: () => _showAddSlaughterModal(context, batch),
            icon: const Icon(Icons.cut),
            label: const Text('Abate'),
            backgroundColor: Colors.indigo,
          );
        } else {
          return FloatingActionButton.extended(
            onPressed: () => _showAddEggProductionModal(context, batch),
            icon: const Icon(Icons.egg),
            label: const Text('Produção Ovos'),
            backgroundColor: Colors.blue,
          );
        }
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DataManager>(
      builder: (context, dataManager, child) {
        final batch = dataManager.getBatchById(widget.batchId);
        
        if (batch == null) {
          return Scaffold(appBar: AppBar(title: const Text('Lote Não Encontrado')), body: const Center(child: Text('Este lote pode ter sido apagado.')));
        }

        final farm = dataManager.getFarmById(batch.farmId);
        final ageInDays = DateTime.now().difference(batch.entryDate).inDays;

        final expenses = dataManager.getExpensesByBatchId(widget.batchId);
        final mortalities = dataManager.getMortalityByBatchId(widget.batchId);
        final slaughters = dataManager.getSlaughtersByBatchId(widget.batchId);
        final eggProductions = dataManager.getEggProductionsByBatchId(widget.batchId);
        
        final chickenSales = dataManager.chickenSales.where((s) => s.batchId == widget.batchId).toList();
        final eggSales = dataManager.eggSales.where((s) => s.batchId == widget.batchId).toList();
        final culledSales = dataManager.culledBirdSales.where((s) => s.batchId == widget.batchId).toList();

        double totalExpenses = expenses.fold(0, (sum, e) => sum + e.amount);
        int totalMortality = mortalities.fold(0, (sum, m) => sum + m.quantity);
        double mortalityRate = batch.initialQuantity > 0 ? (totalMortality / batch.initialQuantity) * 100 : 0;

        return Scaffold(
          appBar: AppBar(
            title: Text(batch.name),
            bottom: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabs: [
                const Tab(text: 'Resumo'),
                const Tab(text: 'Despesas'),
                const Tab(text: 'Mortalidade'),
                if (_isMeat) const Tab(text: 'Abates') else const Tab(text: 'Produção de Ovos'),
                const Tab(text: 'Vendas'),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              // 1. SUMMARY TAB
              ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.home_work),
                      title: const Text('Exploração'),
                      subtitle: Text(farm?.name ?? 'Desconhecida'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(child: _StatCard(title: 'Idade', value: '$ageInDays dias', icon: Icons.calendar_today)),
                      const SizedBox(width: 8),
                      Expanded(child: _StatCard(title: 'Vivas', value: '${batch.currentQuantity}', icon: Icons.pets)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(child: _StatCard(title: 'Mortalidade', value: '${mortalityRate.toStringAsFixed(1)}%', icon: Icons.warning_amber_rounded)),
                      const SizedBox(width: 8),
                      Expanded(child: _StatCard(title: 'Despesas', value: '${dataManager.currencySymbol}${totalExpenses.toStringAsFixed(2)}', icon: Icons.money_off)),
                    ],
                  ),
                ],
              ),

              // 2. EXPENSES TAB
              expenses.isEmpty
                  ? const Center(child: Text('Sem despesas registadas.'))
                  : ListView.builder(
                      itemCount: expenses.length,
                      itemBuilder: (ctx, i) => ListTile(
                        leading: const Icon(Icons.receipt),
                        title: Text(expenses[i].description),
                        subtitle: Text(expenses[i].date.toString().substring(0, 10)),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('${dataManager.currencySymbol}${expenses[i].amount}'),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                dataManager.deleteExpense(expenses[i].id);
                              },
                            )
                          ],
                        ),
                      ),
                    ),

              // 3. MORTALITY TAB
              mortalities.isEmpty
                  ? const Center(child: Text('Sem perdas registadas.'))
                  : ListView.builder(
                      itemCount: mortalities.length,
                      itemBuilder: (ctx, i) => ListTile(
                        leading: const Icon(Icons.warning, color: Colors.orange),
                        title: Text('${mortalities[i].quantity} aves mortas'),
                        subtitle: Text(mortalities[i].cause ?? 'Causa não especificada'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(mortalities[i].date.toString().substring(0, 10)),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                dataManager.deleteMortality(mortalities[i].id);
                              },
                            )
                          ],
                        ),
                      ),
                    ),

              // 4. SLAUGHTERS / EGG PRODUCTION TAB
              if (_isMeat)
                slaughters.isEmpty
                    ? const Center(child: Text('Sem abates registados.'))
                    : ListView.builder(
                        itemCount: slaughters.length,
                        itemBuilder: (ctx, i) => ListTile(
                          leading: const Icon(Icons.cut),
                          title: Text('${slaughters[i].slaughteredQuantity} frangos abatidos'),
                          subtitle: Text('Peso Total: ${slaughters[i].totalWeightKg} kg\nCusto: ${dataManager.currencySymbol}${slaughters[i].slaughterCost}'),
                          isThreeLine: true,
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(slaughters[i].date.toString().substring(0, 10)),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () {
                                  dataManager.deleteSlaughter(slaughters[i].id);
                                },
                              )
                            ],
                          ),
                        ),
                      )
              else
                eggProductions.isEmpty
                    ? const Center(child: Text('Sem produção de ovos registada.'))
                    : ListView.builder(
                        itemCount: eggProductions.length,
                        itemBuilder: (ctx, i) => ListTile(
                          leading: const Icon(Icons.egg),
                          title: Text('${eggProductions[i].quantity} ${eggProductions[i].unit.name}'),
                          subtitle: Text('Classe: ${eggProductions[i].size.name}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(eggProductions[i].date.toString().substring(0, 10)),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () {
                                  dataManager.deleteEggProduction(eggProductions[i].id);
                                },
                              )
                            ],
                          ),
                        ),
                      ),

              // 5. SALES TAB
              ListView(
                children: [
                  if (_isMeat) ...chickenSales.map((s) => ListTile(
                    leading: const Icon(Icons.attach_money, color: Colors.green),
                    title: Text('Venda Frango (${s.saleType.name})'),
                    subtitle: Text(s.date.toString().substring(0, 10)),
                    trailing: Text('${dataManager.currencySymbol}${s.total}'),
                  )),
                  if (!_isMeat) ...eggSales.map((s) => ListTile(
                    leading: const Icon(Icons.attach_money, color: Colors.green),
                    title: Text('Venda Ovos (${s.quantity} ${s.unit.name})'),
                    subtitle: Text(s.date.toString().substring(0, 10)),
                    trailing: Text('${dataManager.currencySymbol}${s.total}'),
                  )),
                  if (!_isMeat) ...culledSales.map((s) => ListTile(
                    leading: const Icon(Icons.attach_money, color: Colors.green),
                    title: Text('Venda Descarte (${s.quantity} aves)'),
                    subtitle: Text(s.date.toString().substring(0, 10)),
                    trailing: Text('${dataManager.currencySymbol}${s.total}'),
                  )),
                  if (chickenSales.isEmpty && eggSales.isEmpty && culledSales.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Center(child: Text('Nenhuma venda registada para este lote.')),
                    ),
                ],
              ),
            ],
          ),
          floatingActionButton: _buildFloatingActionButton(context, batch),
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _StatCard({required this.title, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(title, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          ],
        ),
      ),
    );
  }
}
