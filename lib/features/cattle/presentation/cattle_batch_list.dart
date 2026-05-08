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
import '../providers/cattle_provider.dart';
import '../models/cattle_batch.dart';
import '../models/cattle_enums.dart';

/// Cattle batch listing with create/delete/close.
class CattleBatchList extends StatelessWidget {
  const CattleBatchList({super.key});

  @override
  Widget build(BuildContext context) {
    final cattle = context.watch<CattleProvider>();
    final farms = context.watch<FarmProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('🐄 Manadas'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.goNamed('cattleDashboard'),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddBatchModal(context),
        child: const Icon(Icons.add),
      ),
      body: cattle.isLoading
          ? const LoadingWidget()
          : cattle.batches.isEmpty
              ? EmptyStateWidget(
                  icon: Icons.pets_outlined,
                  message: 'Nenhuma manada de bovinos registada.',
                  actionLabel: 'Criar Manada',
                  onAction: () => _showAddBatchModal(context),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: cattle.batches.length,
                  itemBuilder: (ctx, i) {
                    final b = cattle.batches[i];
                    final farm = farms.getById(b.farmId);
                    final isClosed = b.status == BatchStatus.closed;

                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isClosed
                              ? Colors.grey.shade300
                              : AppTheme.cattleColor.withValues(alpha: 0.15),
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
                                warningMessage: 'Todas as despesas, mortalidades, e vendas desta manada serão eliminadas.',
                              );
                              if (confirmed) cattle.deleteBatch(b.id);
                            } else if (action == 'close') {
                              final updated = b.copyWithStatus(
                                isClosed ? BatchStatus.active : BatchStatus.closed,
                              );
                              cattle.updateBatch(updated);
                            }
                          },
                          itemBuilder: (_) => [
                            PopupMenuItem(
                              value: 'close',
                              child: Text(isClosed ? 'Reabrir Manada' : 'Encerrar Manada'),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Text('Eliminar', style: TextStyle(color: Colors.red)),
                            ),
                          ],
                        ),
                        onTap: () => context.goNamed('cattleBatchDetail', pathParameters: {'id': b.id}),
                      ),
                    );
                  },
                ),
    );
  }

  String _purposeEmoji(CattlePurpose purpose) {
    switch (purpose) {
      case CattlePurpose.dairy: return '🥛';
      case CattlePurpose.beef: return '🥩';
      case CattlePurpose.dual: return '🐄';
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
    final costCtrl = TextEditingController();
    final breedCtrl = TextEditingController();
    final maleCtrl = TextEditingController();
    final femaleCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    String farmId = farms.first.id;
    CattlePurpose purpose = CattlePurpose.dual;

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
                  Text('Nova Manada de Bovinos', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: 'Nome da Manada *'),
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
                  DropdownButtonFormField<CattlePurpose>(
                    value: purpose,
                    decoration: const InputDecoration(labelText: 'Finalidade'),
                    items: const [
                      DropdownMenuItem(value: CattlePurpose.dairy, child: Text('Leiteiro')),
                      DropdownMenuItem(value: CattlePurpose.beef, child: Text('Corte')),
                      DropdownMenuItem(value: CattlePurpose.dual, child: Text('Duplo Propósito')),
                    ],
                    onChanged: (v) => setState(() => purpose = v!),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: maleCtrl,
                          decoration: const InputDecoration(labelText: '♂ Machos *'),
                          keyboardType: TextInputType.number,
                          validator: (v) {
                            final n = int.tryParse(v ?? '');
                            if (n == null || n < 0) return 'Inválido';
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: femaleCtrl,
                          decoration: const InputDecoration(labelText: '♀ Fêmeas *'),
                          keyboardType: TextInputType.number,
                          validator: (v) {
                            final n = int.tryParse(v ?? '');
                            if (n == null || n < 0) return 'Inválido';
                            return null;
                          },
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
                  TextFormField(
                    controller: costCtrl,
                    decoration: const InputDecoration(labelText: 'Custo Aquisição'),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: () {
                      if (formKey.currentState!.validate()) {
                        final males = int.tryParse(maleCtrl.text) ?? 0;
                        final females = int.tryParse(femaleCtrl.text) ?? 0;
                        final qty = males + females;
                        if (qty <= 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Indique pelo menos um animal.')),
                          );
                          return;
                        }
                        context.read<CattleProvider>().addBatch(CattleBatch(
                          id: const Uuid().v4(),
                          farmId: farmId,
                          name: nameCtrl.text.trim(),
                          entryDate: DateTime.now(),
                          initialQuantity: qty,
                          currentQuantity: qty,
                          breedOrLineage: breedCtrl.text.trim(),
                          acquisitionCost: double.tryParse(costCtrl.text) ?? 0,
                          status: BatchStatus.active,
                          maleCount: males,
                          femaleCount: females,
                          purpose: purpose,
                        ));
                        Navigator.pop(ctx);
                      }
                    },
                    child: const Text('Criar Manada'),
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
