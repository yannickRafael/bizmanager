import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/confirm_delete_dialog.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../../features/farms/providers/farm_provider.dart';
import '../providers/goat_provider.dart';
import '../models/goat_batch.dart';
import '../models/goat_enums.dart';

/// Goat batch listing with create/delete/close.
class GoatBatchList extends StatelessWidget {
  const GoatBatchList({super.key});

  @override
  Widget build(BuildContext context) {
    final goat = context.watch<GoatProvider>();
    final farms = context.watch<FarmProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('🐐 Rebanhos'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.goNamed('goatDashboard'),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddBatchModal(context),
        child: const Icon(Icons.add),
      ),
      body: goat.isLoading
          ? const LoadingWidget()
          : goat.batches.isEmpty
              ? EmptyStateWidget(
                  icon: Icons.pets_outlined,
                  message: 'Nenhum rebanho de caprinos registado.',
                  actionLabel: 'Criar Rebanho',
                  onAction: () => _showAddBatchModal(context),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: goat.batches.length,
                  itemBuilder: (ctx, i) {
                    final b = goat.batches[i];
                    final farm = farms.getById(b.farmId);
                    final isClosed = b.status == BatchStatus.closed;

                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isClosed
                              ? Colors.grey.shade300
                              : AppTheme.goatColor.withValues(alpha: 0.15),
                          child: Text(_purposeEmoji(b.purpose)),
                        ),
                        title: Text(
                          b.name,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isClosed ? Colors.grey : null,
                          ),
                        ),
                        subtitle: Text(
                          '${b.currentQuantity}/${b.initialQuantity} animais'
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
                                warningMessage: 'Todas as despesas, mortalidades, e vendas deste rebanho serão eliminadas.',
                              );
                              if (confirmed) goat.deleteBatch(b.id);
                            } else if (action == 'close') {
                              final updated = b.copyWithStatus(
                                isClosed ? BatchStatus.active : BatchStatus.closed,
                              );
                              goat.updateBatch(updated);
                            }
                          },
                          itemBuilder: (_) => [
                            PopupMenuItem(
                              value: 'close',
                              child: Text(isClosed ? 'Reabrir Rebanho' : 'Encerrar Rebanho'),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Text('Eliminar', style: TextStyle(color: Colors.red)),
                            ),
                          ],
                        ),
                        onTap: () => context.goNamed('goatBatchDetail', pathParameters: {'id': b.id}),
                      ),
                    );
                  },
                ),
    );
  }

  String _purposeEmoji(GoatPurpose purpose) {
    switch (purpose) {
      case GoatPurpose.dairy: return '🥛';
      case GoatPurpose.meat: return '🥩';
      case GoatPurpose.dual: return '🐐';
    }
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
    GoatPurpose purpose = GoatPurpose.dual;

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
                  Text('Novo Rebanho de Caprinos', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: 'Nome do Rebanho *'),
                    validator: (v) => v == null || v.isEmpty ? 'Obrigatório' : null,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: farmId,
                    decoration: const InputDecoration(labelText: 'Exploração'),
                    items: farms.map((f) => DropdownMenuItem<String>(value: f.id, child: Text(f.name))).toList(),
                    onChanged: (v) => setState(() => farmId = v!),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<GoatPurpose>(
                    value: purpose,
                    decoration: const InputDecoration(labelText: 'Finalidade'),
                    items: const [
                      DropdownMenuItem(value: GoatPurpose.dairy, child: Text('Leiteiro')),
                      DropdownMenuItem(value: GoatPurpose.meat, child: Text('Corte')),
                      DropdownMenuItem(value: GoatPurpose.dual, child: Text('Duplo Propósito')),
                    ],
                    onChanged: (v) => setState(() => purpose = v!),
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
                        context.read<GoatProvider>().addBatch(GoatBatch(
                          id: const Uuid().v4(),
                          farmId: farmId,
                          name: nameCtrl.text.trim(),
                          entryDate: DateTime.now(),
                          initialQuantity: qty,
                          currentQuantity: qty,
                          breedOrLineage: breedCtrl.text.trim(),
                          acquisitionCost: double.tryParse(costCtrl.text) ?? 0,
                          status: BatchStatus.active,
                          maleCount: int.tryParse(maleCtrl.text) ?? 0,
                          femaleCount: int.tryParse(femaleCtrl.text) ?? 0,
                          purpose: purpose,
                        ));
                        Navigator.pop(ctx);
                      }
                    },
                    child: const Text('Criar Rebanho'),
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
