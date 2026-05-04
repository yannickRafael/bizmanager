import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/models/client.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../../features/settings/providers/settings_provider.dart';
import '../../../features/poultry/providers/poultry_provider.dart';
import '../providers/client_provider.dart';

class ClientDetailsScreen extends StatelessWidget {
  final String clientId;
  const ClientDetailsScreen({super.key, required this.clientId});

  @override
  Widget build(BuildContext context) {
    final clientProvider = context.watch<ClientProvider>();
    final poultry = context.watch<PoultryProvider>();
    final settings = context.watch<SettingsProvider>();
    final client = clientProvider.getById(clientId);

    if (client == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Cliente')),
        body: const Center(child: Text('Cliente não encontrado.')),
      );
    }

    final currency = settings.currencySymbol;

    // Calculate client debt from poultry sales
    double totalOwed = 0;
    double totalPaid = 0;
    for (final s in poultry.chickenSales.where((s) => s.clientId == clientId)) {
      totalOwed += s.total;
      totalPaid += s.amountPaid;
    }
    for (final s in poultry.eggSales.where((s) => s.clientId == clientId)) {
      totalOwed += s.total;
      totalPaid += s.amountPaid;
    }
    for (final s in poultry.culledBirdSales.where((s) => s.clientId == clientId)) {
      totalOwed += s.total;
      totalPaid += s.amountPaid;
    }
    final debt = totalOwed - totalPaid;

    return Scaffold(
      appBar: AppBar(title: Text(client.name)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Contact info
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Informação de Contacto', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 12),
                    if (client.phoneNumber.isNotEmpty)
                      _InfoRow(icon: Icons.phone, label: client.phoneNumber),
                    if (client.address.isNotEmpty)
                      _InfoRow(icon: Icons.location_on, label: client.address),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Financial summary
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Resumo Financeiro', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 12),
                    _InfoRow(icon: Icons.receipt, label: 'Total: $currency${totalOwed.toStringAsFixed(2)}'),
                    _InfoRow(icon: Icons.payment, label: 'Pago: $currency${totalPaid.toStringAsFixed(2)}'),
                    _InfoRow(
                      icon: Icons.warning_amber,
                      label: 'Dívida: $currency${debt.toStringAsFixed(2)}',
                      color: debt > 0 ? Colors.red : Colors.green,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Notes
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Notas', style: Theme.of(context).textTheme.titleMedium),
                        IconButton(
                          icon: const Icon(Icons.edit, size: 20),
                          onPressed: () => _editNotes(context, client),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(client.notes.isNotEmpty ? client.notes : 'Sem notas.'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _editNotes(BuildContext context, Client client) {
    final ctrl = TextEditingController(text: client.notes);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Editar Notas'),
        content: TextFormField(controller: ctrl, maxLines: 5, decoration: const InputDecoration(hintText: 'Escreva aqui...')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () {
              context.read<ClientProvider>().updateNotes(client.id, ctrl.text.trim());
              Navigator.pop(ctx);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;

  const _InfoRow({required this.icon, required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color ?? Colors.grey.shade600),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: TextStyle(color: color))),
        ],
      ),
    );
  }
}
