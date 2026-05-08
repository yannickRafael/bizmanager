import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/confirm_delete_dialog.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../../features/farms/providers/farm_provider.dart';
import '../providers/poultry_provider.dart';
import '../../../core/constants/app_constants.dart';
import '../models/poultry_batch.dart';
import '../models/poultry_enums.dart';

/// Poultry batch listing with create/delete.
class PoultryBatchList extends StatelessWidget {
  const PoultryBatchList({super.key});

  @override
  Widget build(BuildContext context) {
    final poultry = context.watch<PoultryProvider>();
    final farms = context.watch<FarmProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('🐔 Lotes de Aves'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.goNamed('poultryDashboard'),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddBatchModal(context),
        child: const Icon(Icons.add),
      ),
      body: poultry.isLoading
          ? const LoadingWidget()
          : poultry.batches.isEmpty
              ? EmptyStateWidget(
                  icon: Icons.egg_outlined,
                  message: 'Nenhum lote de aves registado.',
                  actionLabel: 'Criar Lote',
                  onAction: () => _showAddBatchModal(context),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: poultry.batches.length,
                  itemBuilder: (ctx, i) {
                    final b = poultry.batches[i];
                    final farm = farms.getById(b.farmId);
                    final isClosed = b.status == BatchStatus.closed;

                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isClosed
                              ? Colors.grey.shade300
                              : AppTheme.poultryColor.withValues(alpha: 0.15),
                          child: Text(b.type == BatchType.meat ? '🍗' : '🥚'),
                        ),
                        title: Text(
                          b.name,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isClosed ? Colors.grey : null,
                          ),
                        ),
                        subtitle: Text(
                          '${b.currentQuantity}/${b.initialQuantity} aves'
                          '${(b.maleCount > 0 || b.femaleCount > 0) ? ' • ♂ ${b.maleCount} ♀ ${b.femaleCount}' : ''}'
                          ' • ${farm?.name ?? "?"} • ${DateFormat('dd/MM/yy').format(b.entryDate)}'
                          '${isClosed ? " • ENCERRADO" : ""}',
                        ),
                        trailing: PopupMenuButton<String>(
                          onSelected: (action) async {
                            if (action == 'delete') {
                              final confirmed = await showDeleteConfirmation(
                                context,
                                itemName: b.name,
                                warningMessage: 'Todas as despesas, mortalidades, e vendas deste lote serão eliminadas.',
                              );
                              if (confirmed) poultry.deleteBatch(b.id);
                            } else if (action == 'close') {
                              poultry.updateBatch(
                                b.copyWithStatus(isClosed ? BatchStatus.active : BatchStatus.closed),
                              );
                            }
                          },
                          itemBuilder: (_) => [
                            PopupMenuItem(
                              value: 'close',
                              child: Text(isClosed ? 'Reabrir Lote' : 'Encerrar Lote'),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Text('Eliminar', style: TextStyle(color: Colors.red)),
                            ),
                          ],
                        ),
                        onTap: () => context.goNamed('poultryBatchDetail', pathParameters: {'id': b.id}),
                      ),
                    );
                  },
                ),
    );
  }

  void _showAddBatchModal(BuildContext context) {
    final farms = context.read<FarmProvider>().farms;
    if (farms.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Crie uma exploração primeiro.')),
      );
      return;
    }

    final nameCtrl = TextEditingController();
    final qtyCtrl = TextEditingController();
    final costCtrl = TextEditingController();
    final breedCtrl = TextEditingController();
    final maleCtrl = TextEditingController();
    final femaleCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    String farmId = farms.first.id;
    BatchType batchType = BatchType.meat;
    BirdOrigin origin = BirdOrigin.purchase;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => Padding(
          padding: EdgeInsets.only(
            left: 24, right: 24, top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Novo Lote de Aves', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: 'Nome do Lote *'),
                    validator: (v) => v == null || v.isEmpty ? 'Obrigatório' : null,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: farmId,
                    decoration: const InputDecoration(labelText: 'Exploração'),
                    items: farms.map((f) => DropdownMenuItem(value: f.id, child: Text(f.name))).toList(),
                    onChanged: (v) => setState(() => farmId = v!),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<BatchType>(
                          value: batchType,
                          decoration: const InputDecoration(labelText: 'Tipo'),
                          items: const [
                            DropdownMenuItem(value: BatchType.meat, child: Text('Corte')),
                            DropdownMenuItem(value: BatchType.layer, child: Text('Postura')),
                          ],
                          onChanged: (v) => setState(() => batchType = v!),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<BirdOrigin>(
                          value: origin,
                          decoration: const InputDecoration(labelText: 'Origem'),
                          items: const [
                            DropdownMenuItem(value: BirdOrigin.purchase, child: Text('Compra')),
                            DropdownMenuItem(value: BirdOrigin.incubation, child: Text('Incubação')),
                          ],
                          onChanged: (v) => setState(() => origin = v!),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: qtyCtrl,
                          decoration: const InputDecoration(labelText: 'Quantidade *'),
                          keyboardType: TextInputType.number,
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Obrigatório';
                            if (int.tryParse(v) == null || int.parse(v) <= 0) return 'Inválido';
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: costCtrl,
                          decoration: const InputDecoration(labelText: 'Custo Aquisição'),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: breedCtrl,
                    decoration: const InputDecoration(labelText: 'Raça / Linhagem'),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: maleCtrl,
                          decoration: const InputDecoration(labelText: '♂ Machos'),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: femaleCtrl,
                          decoration: const InputDecoration(labelText: '♀ Fêmeas'),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: () {
                      if (formKey.currentState!.validate()) {
                        final qty = int.parse(qtyCtrl.text);
                        context.read<PoultryProvider>().addBatch(PoultryBatch(
                          id: const Uuid().v4(),
                          farmId: farmId,
                          name: nameCtrl.text.trim(),
                          type: batchType,
                          birdOrigin: origin,
                          entryDate: DateTime.now(),
                          initialQuantity: qty,
                          currentQuantity: qty,
                          breedOrLineage: breedCtrl.text.trim(),
                          acquisitionCost: double.tryParse(costCtrl.text) ?? 0,
                          status: BatchStatus.active,
                          maleCount: int.tryParse(maleCtrl.text) ?? 0,
                          femaleCount: int.tryParse(femaleCtrl.text) ?? 0,
                        ));
                        Navigator.pop(ctx);
                      }
                    },
                    child: const Text('Criar Lote'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
