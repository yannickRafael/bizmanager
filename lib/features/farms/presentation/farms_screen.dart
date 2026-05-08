import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../../core/models/farm.dart';
import '../../../core/widgets/confirm_delete_dialog.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../../core/widgets/loading_widget.dart';
import '../providers/farm_provider.dart';

class FarmsScreen extends StatelessWidget {
  const FarmsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FarmProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Explorações'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.goNamed('home'),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddFarmDialog(context),
        child: const Icon(Icons.add),
      ),
      body: provider.isLoading
          ? const LoadingWidget(message: 'A carregar explorações...')
          : provider.farms.isEmpty
              ? EmptyStateWidget(
                  icon: Icons.home_work_outlined,
                  message: 'Nenhuma exploração registada.',
                  actionLabel: 'Adicionar Exploração',
                  onAction: () => _showAddFarmDialog(context),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: provider.farms.length,
                  itemBuilder: (ctx, i) {
                    final farm = provider.farms[i];
                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                          child: const Icon(Icons.home_work),
                        ),
                        title: Text(farm.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: farm.address.isNotEmpty ? Text(farm.address) : null,
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                          onPressed: () async {
                            final confirmed = await showDeleteConfirmation(
                              context,
                              itemName: farm.name,
                              warningMessage: 'Todos os lotes desta exploração serão eliminados.',
                            );
                            if (confirmed) provider.remove(farm.id);
                          },
                        ),
                        onTap: () => _showEditFarmDialog(context, farm),
                      ),
                    );
                  },
                ),
    );
  }

  void _showAddFarmDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final addressCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nova Exploração'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Nome *'),
                validator: (v) => v == null || v.isEmpty ? 'Obrigatório' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: addressCtrl,
                decoration: const InputDecoration(labelText: 'Localização'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: notesCtrl,
                decoration: const InputDecoration(labelText: 'Notas'),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                context.read<FarmProvider>().add(Farm(
                  id: const Uuid().v4(),
                  name: nameCtrl.text.trim(),
                  address: addressCtrl.text.trim(),
                  notes: notesCtrl.text.trim(),
                ));
                Navigator.pop(ctx);
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  void _showEditFarmDialog(BuildContext context, Farm farm) {
    final nameCtrl = TextEditingController(text: farm.name);
    final addressCtrl = TextEditingController(text: farm.address);
    final notesCtrl = TextEditingController(text: farm.notes);
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Editar Exploração'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Nome *'),
                validator: (v) => v == null || v.isEmpty ? 'Obrigatório' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: addressCtrl,
                decoration: const InputDecoration(labelText: 'Localização'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: notesCtrl,
                decoration: const InputDecoration(labelText: 'Notas'),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                context.read<FarmProvider>().update(farm.copyWith(
                  name: nameCtrl.text.trim(),
                  address: addressCtrl.text.trim(),
                  notes: notesCtrl.text.trim(),
                ));
                Navigator.pop(ctx);
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }
}
