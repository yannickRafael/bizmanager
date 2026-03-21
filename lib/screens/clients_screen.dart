import 'client_details_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/data_manager.dart';
import '../models/client.dart';
import 'package:uuid/uuid.dart';

class ClientsScreen extends StatefulWidget {
  const ClientsScreen({super.key});

  @override
  State<ClientsScreen> createState() => _ClientsScreenState();
}

class _ClientsScreenState extends State<ClientsScreen> {
  final _uuid = const Uuid();
  String _searchQuery = '';

  void _showAddClientModal(BuildContext context, {Client? existingClient}) {
    String name = existingClient?.name ?? '';
    String phone = existingClient?.phoneNumber ?? '';
    String address = existingClient?.address ?? '';
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
                existingClient == null ? 'Novo Cliente' : 'Editar Cliente',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: name,
                decoration: const InputDecoration(
                  labelText: 'Nome',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (val) =>
                    val == null || val.isEmpty ? 'Insira um nome' : null,
                onSaved: (val) => name = val!.trim(),
              ),
              const SizedBox(height: 12),
              TextFormField(
                initialValue: phone,
                decoration: const InputDecoration(
                  labelText: 'Telefone',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
                onSaved: (val) => phone = val?.trim() ?? '',
              ),
              const SizedBox(height: 12),
              TextFormField(
                initialValue: address,
                decoration: const InputDecoration(
                  labelText: 'Endereço',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_on),
                ),
                onSaved: (val) => address = val?.trim() ?? '',
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () {
                  if (formKey.currentState!.validate()) {
                    formKey.currentState!.save();
                    if (existingClient != null) {
                      final updatedClient = Client(
                        id: existingClient.id,
                        name: name,
                        phoneNumber: phone,
                        address: address,
                        notes: existingClient.notes,
                      );
                      Provider.of<DataManager>(context, listen: false).updateClient(updatedClient);
                    } else {
                      final newClient = Client(
                        id: _uuid.v4(),
                        name: name,
                        phoneNumber: phone,
                        address: address,
                      );
                      Provider.of<DataManager>(context, listen: false).addClient(newClient);
                    }
                    Navigator.pop(ctx);
                  }
                },
                child: Text(existingClient == null ? 'Guardar Cliente' : 'Guardar Alterações'),
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
        title: const Text('Clientes'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Pesquisar por nome ou telefone',
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
          final filteredClients = dataManager.clients.where((c) =>
              c.name.toLowerCase().contains(_searchQuery) ||
              c.phoneNumber.replaceAll(' ', '').contains(_searchQuery.replaceAll(' ', ''))).toList();

          if (dataManager.clients.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.people_outline,
                    size: 64,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Sem clientes.',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () => _showAddClientModal(context),
                    icon: const Icon(Icons.add),
                    label: const Text('Adicionar Primeiro Cliente'),
                  ),
                ],
              ),
            );
          }

          if (filteredClients.isEmpty) {
            return const Center(child: Text('Nenhum cliente encontrado.'));
          }

          return ListView.builder(
            itemCount: filteredClients.length,
            itemBuilder: (context, index) {
              final client = filteredClients[index];
              return Dismissible(
                key: ValueKey(client.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                confirmDismiss: (direction) async {
                  return await showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Apagar Cliente?'),
                      content: const Text(
                        'Tem a certeza que quer apagar este cliente?',
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
                },
                onDismissed: (direction) {
                  Provider.of<DataManager>(context, listen: false).deleteClient(client.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Cliente apagado')),
                  );
                },
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text(client.name[0].toUpperCase()),
                  ),
                  title: Text(
                    client.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    client.phoneNumber.isNotEmpty
                        ? client.phoneNumber
                        : 'Sem telefone',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _showAddClientModal(context, existingClient: client),
                      ),
                      const Icon(Icons.chevron_right),
                    ],
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ClientDetailsScreen(clientId: client.id),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddClientModal(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}
