import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/data_manager.dart';
import '../models/farm.dart';
import 'package:uuid/uuid.dart';

class FarmsScreen extends StatefulWidget {
  const FarmsScreen({super.key});

  @override
  State<FarmsScreen> createState() => _FarmsScreenState();
}

class _FarmsScreenState extends State<FarmsScreen> {
  final _uuid = const Uuid();
  String _searchQuery = '';

  void _showAddFarmModal(BuildContext context, {Farm? existingFarm}) {
    String name = existingFarm?.name ?? '';
    String address = existingFarm?.address ?? '';
    String notes = existingFarm?.notes ?? '';
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          left: 20,
          right: 20,
          top: 20,
        ),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                existingFarm == null ? 'Nova Exploração' : 'Editar Exploração',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: name,
                decoration: const InputDecoration(
                  labelText: 'Nome da Exploração',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.home_work),
                ),
                validator: (val) =>
                    val == null || val.isEmpty ? 'Insira um nome' : null,
                onSaved: (val) => name = val!.trim(),
              ),
              const SizedBox(height: 12),
              TextFormField(
                initialValue: address,
                decoration: const InputDecoration(
                  labelText: 'Endereço / Localização',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_on),
                ),
                onSaved: (val) => address = val?.trim() ?? '',
              ),
              const SizedBox(height: 12),
              TextFormField(
                initialValue: notes,
                decoration: const InputDecoration(
                  labelText: 'Notas',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.notes),
                ),
                onSaved: (val) => notes = val?.trim() ?? '',
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () {
                  if (formKey.currentState!.validate()) {
                    formKey.currentState!.save();
                    if (existingFarm != null) {
                      final updatedFarm = Farm(
                        id: existingFarm.id,
                        name: name,
                        address: address,
                        notes: notes,
                      );
                      Provider.of<DataManager>(context, listen: false).updateFarm(updatedFarm);
                    } else {
                      final newFarm = Farm(
                        id: _uuid.v4(),
                        name: name,
                        address: address,
                        notes: notes,
                      );
                      Provider.of<DataManager>(context, listen: false).addFarm(newFarm);
                    }
                    Navigator.pop(ctx);
                  }
                },
                child: Text(existingFarm == null ? 'Guardar Exploração' : 'Guardar Alterações'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Explorações'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Pesquisar por nome',
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
        ),
      ),
      body: Consumer<DataManager>(
        builder: (context, dataManager, child) {
          final filteredFarms = dataManager.farms.where((f) =>
              f.name.toLowerCase().contains(_searchQuery)).toList();

          if (dataManager.farms.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.home_work_outlined,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Nenhuma exploração registada.',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () => _showAddFarmModal(context),
                    icon: const Icon(Icons.add),
                    label: const Text('Adicionar Primeira Exploração'),
                  ),
                ],
              ),
            );
          }

          if (filteredFarms.isEmpty) {
            return const Center(child: Text('Nenhuma exploração encontrada.'));
          }

          return ListView.builder(
            itemCount: filteredFarms.length,
            itemBuilder: (context, index) {
              final farm = filteredFarms[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: const CircleAvatar(
                    child: Icon(Icons.home_work),
                  ),
                  title: Text(
                    farm.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    farm.address.isNotEmpty ? farm.address : 'Sem localização',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _showAddFarmModal(context, existingFarm: farm),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Apagar Exploração?'),
                              content: const Text(
                                'Tem a certeza que quer apagar esta exploração?\n\nAtenção: Lotes associados perderão a referência.',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, false),
                                  child: const Text('Cancelar'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, true),
                                  child: const Text(
                                    'Apagar',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ),
                              ],
                            ),
                          );

                          if (confirm == true && context.mounted) {
                            Provider.of<DataManager>(context, listen: false).deleteFarm(farm.id);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Exploração apagada')),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddFarmModal(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}
