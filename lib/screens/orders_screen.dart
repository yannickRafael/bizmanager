import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/data_manager.dart';
import '../models/request.dart';
import '../models/client.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  final _uuid = const Uuid();

  void _showAddOrderModal(BuildContext context) {
    if (Provider.of<DataManager>(context, listen: false).clients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please register a client first.')),
      );
      return;
    }

    String? selectedClientId;
    ProductType selectedType = ProductType.eggs;
    double amount = 0;
    double price = 0;
    DateTime date = DateTime.now();

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
                'New Order',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // Client Dropdown
              Consumer<DataManager>(
                builder: (context, data, _) {
                  return DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Client',
                      border: OutlineInputBorder(),
                    ),
                    value: selectedClientId,
                    items: data.clients
                        .map(
                          (c) => DropdownMenuItem(
                            value: c.id,
                            child: Text(c.name),
                          ),
                        )
                        .toList(),
                    onChanged: (val) => selectedClientId = val,
                    validator: (val) => val == null ? 'Select a client' : null,
                  );
                },
              ),
              const SizedBox(height: 12),

              // Type Dropdown
              DropdownButtonFormField<ProductType>(
                decoration: const InputDecoration(
                  labelText: 'Product',
                  border: OutlineInputBorder(),
                ),
                value: selectedType,
                items: ProductType.values
                    .map(
                      (t) => DropdownMenuItem(
                        value: t,
                        child: Text(t.name.toUpperCase()),
                      ),
                    )
                    .toList(),
                onChanged: (val) {
                  if (val != null) selectedType = val;
                },
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Quantity',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: (val) =>
                          val == null || double.tryParse(val) == null
                          ? 'Invalid qty'
                          : null,
                      onSaved: (val) => amount = double.parse(val!),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Total Price',
                        border: OutlineInputBorder(),
                        prefixText: '\$',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: (val) =>
                          val == null || double.tryParse(val) == null
                          ? 'Invalid price'
                          : null,
                      onSaved: (val) => price = double.parse(val!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () {
                  if (formKey.currentState!.validate()) {
                    formKey.currentState!.save();
                    final newRequest = Request(
                      id: _uuid.v4(),
                      clientId: selectedClientId!,
                      type: selectedType,
                      amount: amount,
                      totalPrice: price,
                      date: date,
                      paymentStatus: PaymentStatus.pending,
                    );
                    Provider.of<DataManager>(
                      context,
                      listen: false,
                    ).addRequest(newRequest);
                    Navigator.pop(ctx);
                  }
                },
                child: const Text('Create Order'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPaymentStatusDialog(BuildContext context, Request request) {
    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Update Payment Status'),
        children: PaymentStatus.values
            .map(
              (status) => SimpleDialogOption(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(status.name.toUpperCase()),
                ),
                onPressed: () {
                  Provider.of<DataManager>(
                    context,
                    listen: false,
                  ).updateRequestStatus(request.id, status);
                  Navigator.pop(ctx);
                },
              ),
            )
            .toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Orders')),
      body: Consumer<DataManager>(
        builder: (context, dataManager, child) {
          if (dataManager.requests.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.shopping_cart_outlined,
                    size: 64,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No orders yet.',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () => _showAddOrderModal(context),
                    icon: const Icon(Icons.add),
                    label: const Text('Create First Order'),
                  ),
                ],
              ),
            );
          }

          // Sort by date descending
          final sortedRequests = List.of(dataManager.requests)
            ..sort((a, b) => b.date.compareTo(a.date));

          return ListView.builder(
            itemCount: sortedRequests.length,
            itemBuilder: (context, index) {
              final req = sortedRequests[index];
              final client = dataManager.getClientById(req.clientId);

              Color statusColor;
              switch (req.paymentStatus) {
                case PaymentStatus.paid:
                  statusColor = Colors.green;
                  break;
                case PaymentStatus.pending:
                  statusColor = Colors.orange;
                  break;
                case PaymentStatus.partial:
                  statusColor = Colors.blue;
                  break;
              }

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  title: Row(
                    children: [
                      Text(
                        req.type.name.toUpperCase(),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      Text(
                        '\$${req.totalPrice.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text('Client: ${client?.name ?? "Unknown"}'),
                      Text(
                        'Qty: ${req.amount} | Date: ${DateFormat('MM/dd/yyyy').format(req.date)}',
                      ),
                      const SizedBox(height: 8),
                      Container(
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
                          req.paymentStatus.name.toUpperCase(),
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  onTap: () => _showPaymentStatusDialog(context, req),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddOrderModal(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}
