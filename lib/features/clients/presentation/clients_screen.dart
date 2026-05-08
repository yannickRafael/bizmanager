import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../../core/models/client.dart';
import '../../../core/widgets/confirm_delete_dialog.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../../core/widgets/loading_widget.dart';
import '../providers/client_provider.dart';

class ClientsScreen extends StatelessWidget {
  const ClientsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ClientProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Clientes'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.goNamed('home'),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddClientDialog(context),
        child: const Icon(Icons.person_add),
      ),
      body: provider.isLoading
          ? const LoadingWidget(message: 'A carregar clientes...')
          : provider.clients.isEmpty
              ? EmptyStateWidget(
                  icon: Icons.people_outline,
                  message: 'Nenhum cliente registado.',
                  actionLabel: 'Adicionar Cliente',
                  onAction: () => _showAddClientDialog(context),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: provider.clients.length,
                  itemBuilder: (ctx, i) {
                    final client = provider.clients[i];
                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                          child: Text(client.name.isNotEmpty ? client.name[0].toUpperCase() : '?'),
                        ),
                        title: Text(client.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: client.phoneNumber.isNotEmpty ? Text(client.phoneNumber) : null,
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                          onPressed: () async {
                            final confirmed = await showDeleteConfirmation(context, itemName: client.name);
                            if (confirmed) provider.remove(client.id);
                          },
                        ),
                        onTap: () => context.goNamed('clientDetails', pathParameters: {'id': client.id}),
                      ),
                    );
                  },
                ),
    );
  }

  void _showAddClientDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final addressCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Novo Cliente'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
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
                  controller: phoneCtrl,
                  decoration: const InputDecoration(labelText: 'Telefone'),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: addressCtrl,
                  decoration: const InputDecoration(labelText: 'Endereço'),
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
                context.read<ClientProvider>().add(Client(
                  id: const Uuid().v4(),
                  name: nameCtrl.text.trim(),
                  phoneNumber: phoneCtrl.text.trim(),
                  address: addressCtrl.text.trim(),
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
