import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/data_manager.dart';
import '../models/batch.dart';
import '../models/enums.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';

// We import batch_detail_screen.dart, though we will create it next.
import 'batch_detail_screen.dart';

class BatchesScreen extends StatefulWidget {
  const BatchesScreen({super.key});

  @override
  State<BatchesScreen> createState() => _BatchesScreenState();
}

class _BatchesScreenState extends State<BatchesScreen> {
  final _uuid = const Uuid();
  String _searchQuery = '';
  BatchType? _filterType;
  BatchStatus? _filterStatus = BatchStatus.active;

  void _showAddBatchModal(BuildContext context, {Batch? existingBatch}) {
    String name = existingBatch?.name ?? '';
    String? farmId = existingBatch?.farmId;
    BatchType type = existingBatch?.type ?? BatchType.meat;
    BirdOrigin origin = existingBatch?.birdOrigin ?? BirdOrigin.purchase;
    DateTime entryDate = existingBatch?.entryDate ?? DateTime.now();
    int initialQuantity = existingBatch?.initialQuantity ?? 0;
    String breed = existingBatch?.breedOrLineage ?? '';
    double acquisitionCost = existingBatch?.acquisitionCost ?? 0.0;
    BatchStatus status = existingBatch?.status ?? BatchStatus.active;
    String notes = existingBatch?.notes ?? '';

    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          final dataManager = Provider.of<DataManager>(ctx, listen: false);

          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              left: 20,
              right: 20,
              top: 20,
            ),
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      existingBatch == null ? 'Novo Lote' : 'Editar Lote',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Name
                    TextFormField(
                      initialValue: name,
                      decoration: const InputDecoration(
                        labelText: 'Nome ou Código do Lote',
                        border: OutlineInputBorder(),
                      ),
                      validator: (val) => val == null || val.isEmpty ? 'Insira um nome' : null,
                      onSaved: (val) => name = val!.trim(),
                    ),
                    const SizedBox(height: 12),

                    // Farm Selection
                    DropdownButtonFormField<String>(
                      value: farmId,
                      decoration: const InputDecoration(
                        labelText: 'Exploração',
                        border: OutlineInputBorder(),
                      ),
                      items: dataManager.farms.map((f) => DropdownMenuItem(
                        value: f.id,
                        child: Text(f.name),
                      )).toList(),
                      validator: (val) => val == null ? 'Selecione a exploração' : null,
                      onChanged: (val) {
                        setState(() => farmId = val);
                      },
                    ),
                    const SizedBox(height: 12),

                    // Type and Origin
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<BatchType>(
                            value: type,
                            decoration: const InputDecoration(
                              labelText: 'Tipo de Lote',
                              border: OutlineInputBorder(),
                            ),
                            items: const [
                              DropdownMenuItem(value: BatchType.meat, child: Text('Corte (Frangos)')),
                              DropdownMenuItem(value: BatchType.layer, child: Text('Postura (Ovos)')),
                            ],
                            onChanged: (val) {
                              if (val != null) setState(() => type = val);
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: DropdownButtonFormField<BirdOrigin>(
                            value: origin,
                            decoration: const InputDecoration(
                              labelText: 'Origem',
                              border: OutlineInputBorder(),
                            ),
                            items: const [
                              DropdownMenuItem(value: BirdOrigin.purchase, child: Text('Compra')),
                              DropdownMenuItem(value: BirdOrigin.incubation, child: Text('Incubação Própria')),
                            ],
                            onChanged: (val) {
                              if (val != null) setState(() => origin = val);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Date and Quantity
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: entryDate,
                                firstDate: DateTime(2000),
                                lastDate: DateTime(2100),
                              );
                              if (picked != null) {
                                setState(() => entryDate = picked);
                              }
                            },
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Data de Entrada',
                                border: OutlineInputBorder(),
                              ),
                              child: Text(DateFormat('dd/MM/yyyy').format(entryDate)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            initialValue: initialQuantity > 0 ? initialQuantity.toString() : '',
                            decoration: const InputDecoration(
                              labelText: 'Qtd Inicial (Aves)',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                            validator: (val) => val == null || int.tryParse(val) == null ? 'Inválido' : null,
                            onSaved: (val) => initialQuantity = int.parse(val!),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Breed and Cost
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            initialValue: breed,
                            decoration: const InputDecoration(
                              labelText: 'Raça / Linhagem',
                              border: OutlineInputBorder(),
                            ),
                            onSaved: (val) => breed = val?.trim() ?? '',
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            initialValue: acquisitionCost > 0 ? acquisitionCost.toStringAsFixed(2) : '',
                            decoration: InputDecoration(
                              labelText: 'Custo de Aquisição',
                              border: const OutlineInputBorder(),
                              prefixText: Provider.of<DataManager>(ctx, listen: false).currencySymbol,
                            ),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            validator: (val) => val == null || val.isEmpty ? null : (double.tryParse(val) == null ? 'Inválido' : null),
                            onSaved: (val) => acquisitionCost = val != null && val.isNotEmpty ? double.parse(val) : 0.0,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Status and Notes
                    DropdownButtonFormField<BatchStatus>(
                      value: status,
                      decoration: const InputDecoration(
                        labelText: 'Estado do Lote',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: BatchStatus.active, child: Text('Activo (Em Criação)')),
                        DropdownMenuItem(value: BatchStatus.closed, child: Text('Encerrado / Liquidado')),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => status = val);
                      },
                    ),
                    const SizedBox(height: 12),
                    
                    TextFormField(
                      initialValue: notes,
                      decoration: const InputDecoration(
                        labelText: 'Notas (Opcional)',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                      onSaved: (val) => notes = val?.trim() ?? '',
                    ),
                    
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: () {
                        if (formKey.currentState!.validate()) {
                          formKey.currentState!.save();
                          
                          int currentQty = existingBatch?.currentQuantity ?? initialQuantity;

                          // Ensure current quantity isn't accidentally overridden improperly by simple edits, 
                          // but if initial is changed, we'd theoretically need to adjust current.
                          // For simplicity in this logic, we keep currentQty unless it's a new batch.
                          if (existingBatch == null) {
                            currentQty = initialQuantity;
                          }

                          if (existingBatch != null) {
                            final updatedBatch = Batch(
                              id: existingBatch.id,
                              farmId: farmId!,
                              name: name,
                              type: type,
                              birdOrigin: origin,
                              entryDate: entryDate,
                              initialQuantity: initialQuantity,
                              currentQuantity: currentQty,
                              breedOrLineage: breed,
                              acquisitionCost: acquisitionCost,
                              status: status,
                              notes: notes,
                            );
                            dataManager.updateBatch(updatedBatch);
                          } else {
                            final newBatch = Batch(
                              id: _uuid.v4(),
                              farmId: farmId!,
                              name: name,
                              type: type,
                              birdOrigin: origin,
                              entryDate: entryDate,
                              initialQuantity: initialQuantity,
                              currentQuantity: currentQty,
                              breedOrLineage: breed,
                              acquisitionCost: acquisitionCost,
                              status: status,
                              notes: notes,
                            );
                            dataManager.addBatch(newBatch);
                          }
                          Navigator.pop(ctx);
                        }
                      },
                      child: Text(existingBatch == null ? 'Criar Lote' : 'Guardar Alterações'),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lotes / Bando'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(110),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Pesquisar por nome ou raça',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  ),
                  onChanged: (val) {
                    setState(() {
                      _searchQuery = val.toLowerCase();
                    });
                  },
                ),
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.all(8),
                child: Row(
                  children: [
                    FilterChip(
                      label: const Text('Activos'),
                      selected: _filterStatus == BatchStatus.active,
                      onSelected: (val) {
                        setState(() {
                          _filterStatus = val ? BatchStatus.active : null;
                        });
                      },
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: const Text('Encerrados'),
                      selected: _filterStatus == BatchStatus.closed,
                      onSelected: (val) {
                        setState(() {
                          _filterStatus = val ? BatchStatus.closed : null;
                        });
                      },
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: const Text('Corte'),
                      selected: _filterType == BatchType.meat,
                      onSelected: (val) {
                        setState(() {
                          _filterType = val ? BatchType.meat : null;
                        });
                      },
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: const Text('Postura'),
                      selected: _filterType == BatchType.layer,
                      onSelected: (val) {
                        setState(() {
                          _filterType = val ? BatchType.layer : null;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      body: Consumer<DataManager>(
        builder: (context, dataManager, child) {
          if (dataManager.farms.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.warning_amber_rounded, size: 64, color: Colors.orange.shade300),
                    const SizedBox(height: 16),
                    const Text('Precisa de registar uma Exploração primeiro.', textAlign: TextAlign.center),
                  ],
                ),
              ),
            );
          }

          var filteredBatches = dataManager.batches.where((b) {
            bool matchesSearch = b.name.toLowerCase().contains(_searchQuery) ||
                                 b.breedOrLineage.toLowerCase().contains(_searchQuery);
            bool matchesStatus = _filterStatus == null || b.status == _filterStatus;
            bool matchesType = _filterType == null || b.type == _filterType;
            return matchesSearch && matchesStatus && matchesType;
          }).toList();

          if (dataManager.batches.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.pets, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text('Sem lotes registados.', style: Theme.of(context).textTheme.bodyLarge),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () => _showAddBatchModal(context),
                    icon: const Icon(Icons.add),
                    label: const Text('Registar Primeiro Lote'),
                  ),
                ],
              ),
            );
          }

          if (filteredBatches.isEmpty) {
            return const Center(child: Text('Nenhum lote encontrado com estes filtros.'));
          }

          return ListView.builder(
            itemCount: filteredBatches.length,
            itemBuilder: (context, index) {
              final batch = filteredBatches[index];
              final farm = dataManager.getFarmById(batch.farmId);
              
              String typeText = batch.type == BatchType.meat ? '🐣 Corte' : '🥚 Postura';
              Color typeColor = batch.type == BatchType.meat ? Colors.orange : Colors.blue;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => BatchDetailScreen(batchId: batch.id),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              batch.name,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: typeColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: typeColor),
                              ),
                              child: Text(
                                typeText,
                                style: TextStyle(
                                  color: typeColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (batch.status == BatchStatus.closed)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.red.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.red),
                                ),
                                child: const Text(
                                  'FECHADO',
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text('Exploração: ${farm?.name ?? "Desconhecida"}'),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Aves Vivas: ${batch.currentQuantity} / ${batch.initialQuantity}'),
                            Text('Idade: ${DateTime.now().difference(batch.entryDate).inDays} dias'),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => _showAddBatchModal(context, existingBatch: batch),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text('Apagar Lote?'),
                                    content: const Text(
                                      'Atenção! Apagar este lote também irá apagar todo o histórico de despesas, mortalidade e produção associados.\nTem a certeza?',
                                    ),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
                                      TextButton(
                                        onPressed: () => Navigator.pop(ctx, true),
                                        child: const Text('Apagar', style: TextStyle(color: Colors.red)),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirm == true && context.mounted) {
                                  // DataManager cascade delete logic (Optional, currently DB doesn't cascade easily, 
                                  // but DataManager can do it or rely on SQLite CASCADE if configured)
                                  // For now, we just delete the batch. Real-world apps should consider cascade.
                                  dataManager.deleteBatch(batch.id);
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lote apagado')));
                                }
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddBatchModal(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}
