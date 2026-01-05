import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/data_manager.dart';
import '../models/client.dart';
import '../models/request.dart';
import 'package:intl/intl.dart';

class ClientDetailsScreen extends StatefulWidget {
  final String clientId;

  const ClientDetailsScreen({super.key, required this.clientId});

  @override
  State<ClientDetailsScreen> createState() => _ClientDetailsScreenState();
}

class _ClientDetailsScreenState extends State<ClientDetailsScreen> {
  final _notesController = TextEditingController();
  bool _isInit = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isInit) {
      final client = Provider.of<DataManager>(
        context,
        listen: false,
      ).getClientById(widget.clientId);
      if (client != null) {
        _notesController.text = client.notes;
      }
      _isInit = false;
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  void _saveNotes() {
    Provider.of<DataManager>(
      context,
      listen: false,
    ).updateClientNotes(widget.clientId, _notesController.text);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Notes saved')));
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DataManager>(
      builder: (context, data, _) {
        final client = data.getClientById(widget.clientId);
        if (client == null)
          return const Scaffold(body: Center(child: Text('Client not found')));

        final clientOrders = data.requests
            .where((r) => r.clientId == widget.clientId)
            .toList();

        // Calculate Debt
        double totalDebt = 0;
        for (var order in clientOrders) {
          totalDebt += (order.totalPrice - order.amountPaid);
        }

        // Sort orders desc
        clientOrders.sort((a, b) => b.date.compareTo(a.date));

        return Scaffold(
          appBar: AppBar(title: Text(client.name)),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header Info
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.phone,
                              size: 20,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              client.phoneNumber.isNotEmpty
                                  ? client.phoneNumber
                                  : 'Sem telefone',
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on,
                              size: 20,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              client.address.isNotEmpty
                                  ? client.address
                                  : 'Sem endereço',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Debt Card
                Card(
                  color: Colors.red.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        const Text(
                          'Dívida Total',
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '\$${totalDebt.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Notes Section
                Text(
                  'Notas',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _notesController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    hintText: 'Adicionar notas aqui (ex: tem troco...)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.icon(
                    onPressed: _saveNotes,
                    icon: const Icon(Icons.save),
                    label: const Text('Guardar Notas'),
                  ),
                ),
                const SizedBox(height: 24),

                // Order History
                Text(
                  'Histórico de Pedidos',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                if (clientOrders.isEmpty)
                  const Text('Nenhum pedido encontrado.')
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: clientOrders.length,
                    itemBuilder: (ctx, index) {
                      final order = clientOrders[index];
                      Color statusColor;
                      String statusText;
                      switch (order.paymentStatus) {
                        case PaymentStatus.paid:
                          statusColor = Colors.green;
                          statusText = 'PAGO';
                          break;
                        case PaymentStatus.pending:
                          statusColor = Colors.orange;
                          statusText = 'PENDENTE';
                          break;
                        case PaymentStatus.partial:
                          statusColor = Colors.blue;
                          statusText = 'PARCIAL';
                          break;
                      }

                      String productText = order.type == ProductType.chicken
                          ? 'FRANGO'
                          : 'OVOS';

                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          title: Text(
                            '$productText - \$${order.totalPrice.toStringAsFixed(2)}',
                          ),
                          subtitle: Text(
                            DateFormat('dd/MM/yyyy').format(order.date),
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: statusColor),
                            ),
                            child: Text(
                              statusText,
                              style: TextStyle(
                                color: statusColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                // Space for bottom
                const SizedBox(height: 40),
              ],
            ),
          ),
        );
      },
    );
  }
}
