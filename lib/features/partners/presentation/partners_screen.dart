import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/models/partner.dart';
import '../../../core/widgets/confirm_delete_dialog.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../../core/widgets/loading_widget.dart';
import '../providers/partner_provider.dart';

class PartnersScreen extends StatelessWidget {
  const PartnersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PartnerProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Parceiros')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddPartnerDialog(context),
        child: const Icon(Icons.person_add),
      ),
      body: provider.isLoading
          ? const LoadingWidget(message: 'A carregar parceiros...')
          : provider.partners.isEmpty
              ? EmptyStateWidget(
                  icon: Icons.handshake_outlined,
                  message: 'Nenhum parceiro registado.',
                  actionLabel: 'Adicionar Parceiro',
                  onAction: () => _showAddPartnerDialog(context),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: provider.partners.length,
                  itemBuilder: (ctx, i) {
                    final p = provider.partners[i];
                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Theme.of(context).colorScheme.tertiaryContainer,
                          child: const Icon(Icons.handshake),
                        ),
                        title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(_partnerTypeLabel(p.type)),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                          onPressed: () async {
                            final confirmed = await showDeleteConfirmation(context, itemName: p.name);
                            if (confirmed) provider.remove(p.id);
                          },
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  String _partnerTypeLabel(PartnerType type) {
    switch (type) {
      case PartnerType.chickSupplier: return 'Fornecedor de Pintos';
      case PartnerType.feedSupplier: return 'Fornecedor de Ração';
      case PartnerType.veterinarian: return 'Veterinário';
      case PartnerType.slaughterhouse: return 'Matadouro';
      case PartnerType.cattleSupplier: return 'Fornecedor de Bovinos';
      case PartnerType.goatSupplier: return 'Fornecedor de Caprinos';
      case PartnerType.other: return 'Outro';
    }
  }

  void _showAddPartnerDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final addressCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    PartnerType selectedType = PartnerType.feedSupplier;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Novo Parceiro'),
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
                  DropdownButtonFormField<PartnerType>(
                    value: selectedType,
                    decoration: const InputDecoration(labelText: 'Tipo'),
                    items: PartnerType.values.map((t) => DropdownMenuItem(
                      value: t, child: Text(_partnerTypeLabel(t)),
                    )).toList(),
                    onChanged: (v) => setState(() => selectedType = v!),
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
                  context.read<PartnerProvider>().add(Partner(
                    id: const Uuid().v4(),
                    name: nameCtrl.text.trim(),
                    type: selectedType,
                    phone: phoneCtrl.text.trim(),
                    address: addressCtrl.text.trim(),
                  ));
                  Navigator.pop(ctx);
                }
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }
}
