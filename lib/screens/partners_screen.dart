import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/data_manager.dart';
import '../models/partner.dart';
import '../models/enums.dart';
import 'package:uuid/uuid.dart';

class PartnersScreen extends StatefulWidget {
  const PartnersScreen({super.key});

  @override
  State<PartnersScreen> createState() => _PartnersScreenState();
}

class _PartnersScreenState extends State<PartnersScreen> {
  final _uuid = const Uuid();
  String _searchQuery = '';
  PartnerType? _filterType;

  void _showAddPartnerModal(BuildContext context, {Partner? existingPartner}) {
    String name = existingPartner?.name ?? '';
    PartnerType type = existingPartner?.type ?? PartnerType.other;
    String phone = existingPartner?.phone ?? '';
    String address = existingPartner?.address ?? '';
    String notes = existingPartner?.notes ?? '';
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
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
                      existingPartner == null ? 'Novo Parceiro' : 'Editar Parceiro',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      initialValue: name,
                      decoration: const InputDecoration(
                        labelText: 'Nome do Parceiro/Empresa',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.business),
                      ),
                      validator: (val) => val == null || val.isEmpty ? 'Insira um nome' : null,
                      onSaved: (val) => name = val!.trim(),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<PartnerType>(
                      value: type,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Tipo de Parceiro',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.category),
                      ),
                      items: const [
                        DropdownMenuItem(value: PartnerType.chickSupplier, child: Text('Fornecedor de Pintos/Aves')),
                        DropdownMenuItem(value: PartnerType.feedSupplier, child: Text('Fornecedor de Ração')),
                        DropdownMenuItem(value: PartnerType.veterinarian, child: Text('Veterinário / Clínica')),
                        DropdownMenuItem(value: PartnerType.slaughterhouse, child: Text('Matadouro / Abatedouro')),
                        DropdownMenuItem(value: PartnerType.other, child: Text('Outro')),
                      ],
                      onChanged: (val) {
                        if (val != null) setModalState(() => type = val);
                      },
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
                        labelText: 'Morada / Endereço',
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
                          if (existingPartner != null) {
                            final updatedPartner = Partner(
                              id: existingPartner.id,
                              name: name,
                              type: type,
                              phone: phone,
                              address: address,
                              notes: notes,
                            );
                            Provider.of<DataManager>(context, listen: false).updatePartner(updatedPartner);
                          } else {
                            final newPartner = Partner(
                              id: _uuid.v4(),
                              name: name,
                              type: type,
                              phone: phone,
                              address: address,
                              notes: notes,
                            );
                            Provider.of<DataManager>(context, listen: false).addPartner(newPartner);
                          }
                          Navigator.pop(ctx);
                        }
                      },
                      child: Text(existingPartner == null ? 'Guardar Parceiro' : 'Guardar Alterações'),
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

  String _getPartnerTypeString(PartnerType type) {
    switch (type) {
      case PartnerType.chickSupplier: return 'Fornecedor (Aves)';
      case PartnerType.feedSupplier: return 'Fornecedor (Ração)';
      case PartnerType.veterinarian: return 'Veterinário';
      case PartnerType.slaughterhouse: return 'Matadouro';
      case PartnerType.other: return 'Outro';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Parceiros de Negócio'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(110),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
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
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.all(8),
                child: Row(
                  children: [
                    FilterChip(
                      label: const Text('Todos'),
                      selected: _filterType == null,
                      onSelected: (val) {
                        if (val) setState(() => _filterType = null);
                      },
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: const Text('Fornecedores'),
                      selected: _filterType == PartnerType.chickSupplier || _filterType == PartnerType.feedSupplier,
                      onSelected: (val) {
                        if (val) setState(() => _filterType = PartnerType.feedSupplier);
                      },
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: const Text('Veterinários'),
                      selected: _filterType == PartnerType.veterinarian,
                      onSelected: (val) {
                        if (val) setState(() => _filterType = PartnerType.veterinarian);
                      },
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: const Text('Matadouros'),
                      selected: _filterType == PartnerType.slaughterhouse,
                      onSelected: (val) {
                        if (val) setState(() => _filterType = PartnerType.slaughterhouse);
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
          var filteredPartners = dataManager.partners.where((p) {
            bool matchesSearch = p.name.toLowerCase().contains(_searchQuery);
            bool matchesFilter = true;
            if (_filterType == PartnerType.feedSupplier || _filterType == PartnerType.chickSupplier) {
              matchesFilter = (p.type == PartnerType.feedSupplier || p.type == PartnerType.chickSupplier);
            } else if (_filterType != null) {
              matchesFilter = p.type == _filterType;
            }
            return matchesSearch && matchesFilter;
          }).toList();

          if (dataManager.partners.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.handshake_outlined, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text('Nenhum parceiro registado.', style: Theme.of(context).textTheme.bodyLarge),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () => _showAddPartnerModal(context),
                    icon: const Icon(Icons.add),
                    label: const Text('Adicionar Novo Parceiro'),
                  ),
                ],
              ),
            );
          }

          if (filteredPartners.isEmpty) {
            return const Center(child: Text('Nenhum parceiro encontrado.'));
          }

          return ListView.builder(
            itemCount: filteredPartners.length,
            itemBuilder: (context, index) {
              final partner = filteredPartners[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: const CircleAvatar(
                    child: Icon(Icons.business),
                  ),
                  title: Text(
                    partner.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    '${_getPartnerTypeString(partner.type)}\n${partner.phone.isNotEmpty ? partner.phone : 'Sem telefone'}',
                  ),
                  isThreeLine: true,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _showAddPartnerModal(context, existingPartner: partner),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Apagar Parceiro?'),
                              content: const Text('Tem a certeza que quer apagar este registo?'),
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
                            Provider.of<DataManager>(context, listen: false).deletePartner(partner.id);
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Parceiro apagado')));
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
        onPressed: () => _showAddPartnerModal(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}
