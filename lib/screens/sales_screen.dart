import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/data_manager.dart';
import '../models/enums.dart';
import '../models/sale.dart';
import '../models/batch.dart';
import '../models/client.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';

class SalesScreen extends StatefulWidget {
  const SalesScreen({super.key});

  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _uuid = const Uuid();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // --- Modals ---

  void _showAddChickenSaleModal(BuildContext context) {
    String? batchId;
    String? clientId;
    ChickenSaleType saleType = ChickenSaleType.live;
    PaymentStatus paymentStatus = PaymentStatus.pending;
    double amountPaid = 0.0;
    DateTime date = DateTime.now();

    // Fields for 1 group
    int quantity = 0;
    double pricePerHead = 0.0;

    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final dataManager = Provider.of<DataManager>(context, listen: false);
          final meatBatches = dataManager.batches.where((b) => b.type == BatchType.meat).toList();
          final clients = dataManager.clients;

          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              left: 20, right: 20, top: 20,
            ),
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Venda de Frangos', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: batchId,
                      decoration: const InputDecoration(labelText: 'Lote (Tipo: Carne)', border: OutlineInputBorder()),
                      items: meatBatches.map((b) => DropdownMenuItem(value: b.id, child: Text(b.name))).toList(),
                      validator: (val) => val == null ? 'Selecione um lote' : null,
                      onChanged: (val) { if (val != null) setModalState(() => batchId = val); },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String?>(
                      value: clientId,
                      decoration: const InputDecoration(labelText: 'Cliente (Opcional)', border: OutlineInputBorder()),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('Sem Cliente / Balcão')),
                        ...clients.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))),
                      ],
                      onChanged: (val) { setModalState(() => clientId = val); },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<ChickenSaleType>(
                      value: saleType,
                      decoration: const InputDecoration(labelText: 'Forma de Venda', border: OutlineInputBorder()),
                      items: ChickenSaleType.values.map((s) => DropdownMenuItem(value: s, child: Text(s.name.toUpperCase()))).toList(),
                      onChanged: (val) { if (val != null) setModalState(() => saleType = val); },
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            decoration: const InputDecoration(labelText: 'Qtde Aves', border: OutlineInputBorder()),
                            keyboardType: TextInputType.number,
                            validator: (val) => val == null || int.tryParse(val) == null || int.parse(val) <= 0 ? 'Inválido' : null,
                            onSaved: (val) => quantity = int.parse(val!),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            decoration: InputDecoration(labelText: 'Preço/Ave', border: const OutlineInputBorder(), prefixText: dataManager.currencySymbol),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            validator: (val) => val == null || double.tryParse(val) == null || double.parse(val) <= 0 ? 'Inválido' : null,
                            onSaved: (val) => pricePerHead = double.parse(val!),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<PaymentStatus>(
                            value: paymentStatus,
                            decoration: const InputDecoration(labelText: 'Estado Pagamento', border: OutlineInputBorder()),
                            items: PaymentStatus.values.map((s) => DropdownMenuItem(value: s, child: Text(s.name.toUpperCase()))).toList(),
                            onChanged: (val) { if (val != null) setModalState(() => paymentStatus = val); },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            initialValue: amountPaid.toString(),
                            decoration: InputDecoration(labelText: 'Valor Pago', border: const OutlineInputBorder(), prefixText: dataManager.currencySymbol),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            onSaved: (val) => amountPaid = (val == null || val.isEmpty) ? 0.0 : double.parse(val),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(context: ctx, initialDate: date, firstDate: DateTime(2020), lastDate: DateTime.now());
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
                          
                          final batch = dataManager.getBatchById(batchId!);
                          if (batch != null && saleType == ChickenSaleType.live && quantity > batch.currentQuantity) {
                            ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Quantidade a vender é superior às aves vivas do lote!')));
                            return;
                          }

                          final sale = ChickenSale(
                            id: _uuid.v4(),
                            batchId: batchId!,
                            clientId: clientId,
                            saleType: saleType,
                            date: date,
                            paymentStatus: paymentStatus,
                            amountPaid: paymentStatus == PaymentStatus.paid ? (quantity * pricePerHead) : amountPaid,
                            groups: [ChickenGroup(quantity: quantity, pricePerHead: pricePerHead)],
                          );
                          dataManager.addChickenSale(sale);
                          Navigator.pop(ctx);
                        }
                      },
                      child: const Text('Completar Venda'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
      ),
    );
  }

  void _showAddEggSaleModal(BuildContext context) {
    String? batchId;
    String? clientId;
    EggUnit unit = EggUnit.dozens;
    double quantity = 0.0;
    double unitPrice = 0.0;
    PaymentStatus paymentStatus = PaymentStatus.pending;
    double amountPaid = 0.0;
    DateTime date = DateTime.now();

    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final dataManager = Provider.of<DataManager>(context, listen: false);
          final layerBatches = dataManager.batches.where((b) => b.type == BatchType.layer).toList();
          final clients = dataManager.clients;

          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              left: 20, right: 20, top: 20,
            ),
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Venda de Ovos', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: batchId,
                      decoration: const InputDecoration(labelText: 'Lote (Tipo: Postura)', border: OutlineInputBorder()),
                      items: layerBatches.map((b) => DropdownMenuItem(value: b.id, child: Text(b.name))).toList(),
                      validator: (val) => val == null ? 'Selecione um lote' : null,
                      onChanged: (val) { if (val != null) setModalState(() => batchId = val); },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String?>(
                      value: clientId,
                      decoration: const InputDecoration(labelText: 'Cliente (Opcional)', border: OutlineInputBorder()),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('Sem Cliente / Balcão')),
                        ...clients.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))),
                      ],
                      onChanged: (val) { setModalState(() => clientId = val); },
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<EggUnit>(
                            value: unit,
                            decoration: const InputDecoration(labelText: 'Unidade', border: OutlineInputBorder()),
                            items: EggUnit.values.map((s) => DropdownMenuItem(value: s, child: Text(s.name.toUpperCase()))).toList(),
                            onChanged: (val) { if (val != null) setModalState(() => unit = val); },
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
                    TextFormField(
                      decoration: InputDecoration(labelText: 'Preço por Unidade', border: const OutlineInputBorder(), prefixText: dataManager.currencySymbol),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (val) => val == null || double.tryParse(val) == null || double.parse(val) <= 0 ? 'Inválido' : null,
                      onSaved: (val) => unitPrice = double.parse(val!),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<PaymentStatus>(
                            value: paymentStatus,
                            decoration: const InputDecoration(labelText: 'Estado Pagamento', border: OutlineInputBorder()),
                            items: PaymentStatus.values.map((s) => DropdownMenuItem(value: s, child: Text(s.name.toUpperCase()))).toList(),
                            onChanged: (val) { if (val != null) setModalState(() => paymentStatus = val); },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            initialValue: amountPaid.toString(),
                            decoration: InputDecoration(labelText: 'Valor Pago', border: const OutlineInputBorder(), prefixText: dataManager.currencySymbol),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            onSaved: (val) => amountPaid = (val == null || val.isEmpty) ? 0.0 : double.parse(val),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(context: ctx, initialDate: date, firstDate: DateTime(2020), lastDate: DateTime.now());
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
                          final sale = EggSale(
                            id: _uuid.v4(),
                            batchId: batchId!,
                            clientId: clientId,
                            unit: unit,
                            quantity: quantity,
                            unitPrice: unitPrice,
                            date: date,
                            paymentStatus: paymentStatus,
                            amountPaid: paymentStatus == PaymentStatus.paid ? (quantity * unitPrice) : amountPaid,
                          );
                          dataManager.addEggSale(sale);
                          Navigator.pop(ctx);
                        }
                      },
                      child: const Text('Completar Venda'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
      ),
    );
  }

  void _showAddCulledSaleModal(BuildContext context) {
    String? batchId;
    String? clientId;
    int quantity = 0;
    double pricePerHead = 0.0;
    PaymentStatus paymentStatus = PaymentStatus.pending;
    double amountPaid = 0.0;
    DateTime date = DateTime.now();

    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final dataManager = Provider.of<DataManager>(context, listen: false);
          // Culled birds are usually layers that are too old
          final layerBatches = dataManager.batches.where((b) => b.type == BatchType.layer).toList();
          final clients = dataManager.clients;

          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              left: 20, right: 20, top: 20,
            ),
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Venda de Descartes', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: batchId,
                      decoration: const InputDecoration(labelText: 'Lote (Tipo: Postura)', border: OutlineInputBorder()),
                      items: layerBatches.map((b) => DropdownMenuItem(value: b.id, child: Text(b.name))).toList(),
                      validator: (val) => val == null ? 'Selecione um lote' : null,
                      onChanged: (val) { if (val != null) setModalState(() => batchId = val); },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String?>(
                      value: clientId,
                      decoration: const InputDecoration(labelText: 'Cliente (Opcional)', border: OutlineInputBorder()),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('Sem Cliente / Balcão')),
                        ...clients.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))),
                      ],
                      onChanged: (val) { setModalState(() => clientId = val); },
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            decoration: const InputDecoration(labelText: 'Qtde Aves', border: OutlineInputBorder()),
                            keyboardType: TextInputType.number,
                            validator: (val) => val == null || int.tryParse(val) == null || int.parse(val) <= 0 ? 'Inválido' : null,
                            onSaved: (val) => quantity = int.parse(val!),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            decoration: InputDecoration(labelText: 'Preço/Ave', border: const OutlineInputBorder(), prefixText: dataManager.currencySymbol),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            validator: (val) => val == null || double.tryParse(val) == null || double.parse(val) <= 0 ? 'Inválido' : null,
                            onSaved: (val) => pricePerHead = double.parse(val!),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<PaymentStatus>(
                            value: paymentStatus,
                            decoration: const InputDecoration(labelText: 'Estado Pagamento', border: OutlineInputBorder()),
                            items: PaymentStatus.values.map((s) => DropdownMenuItem(value: s, child: Text(s.name.toUpperCase()))).toList(),
                            onChanged: (val) { if (val != null) setModalState(() => paymentStatus = val); },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            initialValue: amountPaid.toString(),
                            decoration: InputDecoration(labelText: 'Valor Pago', border: const OutlineInputBorder(), prefixText: dataManager.currencySymbol),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            onSaved: (val) => amountPaid = (val == null || val.isEmpty) ? 0.0 : double.parse(val),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(context: ctx, initialDate: date, firstDate: DateTime(2020), lastDate: DateTime.now());
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
                          
                          final batch = dataManager.getBatchById(batchId!);
                          if (batch != null && quantity > batch.currentQuantity) {
                            ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Quantidade a vender é superior às aves vivas do lote!')));
                            return;
                          }

                          final sale = CulledBirdSale(
                            id: _uuid.v4(),
                            batchId: batchId!,
                            clientId: clientId,
                            quantity: quantity,
                            pricePerHead: pricePerHead,
                            date: date,
                            paymentStatus: paymentStatus,
                            amountPaid: paymentStatus == PaymentStatus.paid ? (quantity * pricePerHead) : amountPaid,
                          );
                          dataManager.addCulledBirdSale(sale);
                          Navigator.pop(ctx);
                        }
                      },
                      child: const Text('Completar Venda'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
      ),
    );
  }

  Color _getStatusColor(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.paid: return Colors.green;
      case PaymentStatus.pending: return Colors.orange;
      case PaymentStatus.partial: return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vendas'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Frangos'),
            Tab(text: 'Ovos'),
            Tab(text: 'Descartes'),
          ],
        ),
      ),
      body: Consumer<DataManager>(
        builder: (context, dataManager, child) {
          final chickenSales = dataManager.chickenSales.reversed.toList();
          final eggSales = dataManager.eggSales.reversed.toList();
          final culledSales = dataManager.culledBirdSales.reversed.toList();

          return TabBarView(
            controller: _tabController,
            children: [
              // 1. Frangos
              chickenSales.isEmpty ? const Center(child: Text('Nenhuma venda de frango.')) : ListView.builder(
                itemCount: chickenSales.length,
                itemBuilder: (ctx, i) {
                  final sale = chickenSales[i];
                  final client = sale.clientId != null ? dataManager.getClientById(sale.clientId!) : null;
                  return ListTile(
                    leading: CircleAvatar(backgroundColor: _getStatusColor(sale.paymentStatus), child: const Icon(Icons.money, color: Colors.white)),
                    title: Text(client?.name ?? 'Cliente Balcão'),
                    subtitle: Text('${sale.groups.fold(0, (s,g) => s+g.quantity)} aves (${sale.saleType.name}) - ${DateFormat('dd/MM/yy').format(sale.date)}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('${dataManager.currencySymbol}${sale.total.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => dataManager.deleteChickenSale(sale.id)),
                      ],
                    ),
                  );
                },
              ),

              // 2. Ovos
              eggSales.isEmpty ? const Center(child: Text('Nenhuma venda de ovos.')) : ListView.builder(
                itemCount: eggSales.length,
                itemBuilder: (ctx, i) {
                  final sale = eggSales[i];
                  final client = sale.clientId != null ? dataManager.getClientById(sale.clientId!) : null;
                  return ListTile(
                    leading: CircleAvatar(backgroundColor: _getStatusColor(sale.paymentStatus), child: const Icon(Icons.egg, color: Colors.white)),
                    title: Text(client?.name ?? 'Cliente Balcão'),
                    subtitle: Text('${sale.quantity} ${sale.unit.name} - ${DateFormat('dd/MM/yy').format(sale.date)}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('${dataManager.currencySymbol}${sale.total.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => dataManager.deleteEggSale(sale.id)),
                      ],
                    ),
                  );
                },
              ),

              // 3. Descartes
              culledSales.isEmpty ? const Center(child: Text('Nenhuma venda de descarte.')) : ListView.builder(
                itemCount: culledSales.length,
                itemBuilder: (ctx, i) {
                  final sale = culledSales[i];
                  final client = sale.clientId != null ? dataManager.getClientById(sale.clientId!) : null;
                  return ListTile(
                    leading: CircleAvatar(backgroundColor: _getStatusColor(sale.paymentStatus), child: const Icon(Icons.delete_sweep, color: Colors.white)),
                    title: Text(client?.name ?? 'Cliente Balcão'),
                    subtitle: Text('${sale.quantity} aves - ${DateFormat('dd/MM/yy').format(sale.date)}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('${dataManager.currencySymbol}${sale.total.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => dataManager.deleteCulledBirdSale(sale.id)),
                      ],
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          if (_tabController.index == 0) _showAddChickenSaleModal(context);
          else if (_tabController.index == 1) _showAddEggSaleModal(context);
          else if (_tabController.index == 2) _showAddCulledSaleModal(context);
        },
        icon: const Icon(Icons.add_shopping_cart),
        label: Text(_tabController.index == 0 ? 'Venda Frango' : (_tabController.index == 1 ? 'Venda Ovos' : 'Venda Descarte')),
      ),
    );
  }
}
