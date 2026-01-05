import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/data_manager.dart';
import '../models/request.dart';
import '../models/client.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import 'package:flutter_contacts/flutter_contacts.dart' as contacts;
import 'package:permission_handler/permission_handler.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  final _uuid = const Uuid();

  void _showAddOrderModal(BuildContext context) {
    // Variables for Order
    ProductType selectedType = ProductType.eggs;
    double amount = 0;
    double price = 0;
    DateTime date = DateTime.now();

    // Variables for Client Selection
    int selectedTab = 0; // 0: Existing, 1: New
    String? selectedClientId;

    // Variables for New Client
    String newClientName = '';
    String newClientPhone = '';
    String newClientAddress = '';

    final formKey = GlobalKey<FormState>();

    // Controllers to update fields programmatically (e.g. after import)
    final nameController = TextEditingController();
    final phoneController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          Future<void> _pickContact() async {
            if (await Permission.contacts.request().isGranted) {
              final contact = await contacts.FlutterContacts.openExternalPick();
              if (contact != null) {
                setState(() {
                  nameController.text = contact.displayName;
                  if (contact.phones.isNotEmpty) {
                    phoneController.text = contact.phones.first.number;
                  }
                });
              }
            }
          }

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
                      'New Order',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),

                    // Client Section
                    Text(
                      'Client Details',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),

                    // Toggle between Existing and New
                    SegmentedButton<int>(
                      segments: const [
                        ButtonSegment(
                          value: 0,
                          label: Text('Existing'),
                          icon: Icon(Icons.list),
                        ),
                        ButtonSegment(
                          value: 1,
                          label: Text('New / Import'),
                          icon: Icon(Icons.person_add),
                        ),
                      ],
                      selected: {selectedTab},
                      onSelectionChanged: (Set<int> newSelection) {
                        setState(() {
                          selectedTab = newSelection.first;
                        });
                      },
                    ),
                    const SizedBox(height: 16),

                    if (selectedTab == 0) ...[
                      // Existing Client Dropdown
                      Consumer<DataManager>(
                        builder: (context, data, _) {
                          final clients = data.clients;
                          if (clients.isEmpty) {
                            return const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Text(
                                'No clients found. Please switch to "New" to create one.',
                                style: TextStyle(color: Colors.red),
                              ),
                            );
                          }
                          return DropdownButtonFormField<String>(
                            decoration: const InputDecoration(
                              labelText: 'Select Client',
                              border: OutlineInputBorder(),
                            ),
                            value: selectedClientId,
                            items: clients
                                .map(
                                  (c) => DropdownMenuItem(
                                    value: c.id,
                                    child: Text(c.name),
                                  ),
                                )
                                .toList(),
                            onChanged: (val) => selectedClientId = val,
                            validator: (val) => selectedTab == 0 && val == null
                                ? 'Select a client'
                                : null,
                          );
                        },
                      ),
                    ] else ...[
                      // New Client Form
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _pickContact,
                              icon: const Icon(Icons.contacts),
                              label: const Text('Import from Contacts'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: 'Client Name',
                          border: OutlineInputBorder(),
                        ),
                        validator: (val) =>
                            selectedTab == 1 && (val == null || val.isEmpty)
                            ? 'Enter name'
                            : null,
                        onSaved: (val) => newClientName = val!.trim(),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: phoneController,
                        decoration: const InputDecoration(
                          labelText: 'Phone Number',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.phone,
                        onSaved: (val) => newClientPhone = val?.trim() ?? '',
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Address',
                          border: OutlineInputBorder(),
                        ),
                        onSaved: (val) => newClientAddress = val?.trim() ?? '',
                      ),
                    ],

                    const SizedBox(height: 24),
                    Text(
                      'Order Details',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),

                    // Product Type
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
                        if (val != null) setState(() => selectedType = val);
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

                          final dataManager = Provider.of<DataManager>(
                            context,
                            listen: false,
                          );
                          String finalClientId;

                          if (selectedTab == 0) {
                            // Existing
                            finalClientId = selectedClientId!;
                          } else {
                            // Create New Client
                            finalClientId = _uuid.v4();
                            final newClient = Client(
                              id: finalClientId,
                              name: newClientName,
                              phoneNumber: newClientPhone,
                              address: newClientAddress,
                            );
                            dataManager.addClient(newClient);
                          }

                          // Create Order
                          final newRequest = Request(
                            id: _uuid.v4(),
                            clientId: finalClientId,
                            type: selectedType,
                            amount: amount,
                            totalPrice: price,
                            date: date,
                            paymentStatus: PaymentStatus.pending,
                          );
                          dataManager.addRequest(newRequest);
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
        },
      ),
    );
  }

  void _showPaymentDialog(BuildContext context, Request request) {
    double paymentAmount = 0;
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Register Payment'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Total Price: \$${request.totalPrice.toStringAsFixed(2)}'),
              Text('Already Paid: \$${request.amountPaid.toStringAsFixed(2)}'),
              const SizedBox(height: 8),
              Text(
                'Remaining: \$${(request.totalPrice - request.amountPaid).toStringAsFixed(2)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Amount to Pay',
                  border: OutlineInputBorder(),
                  prefixText: '\$',
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: (val) {
                  if (val == null || double.tryParse(val) == null)
                    return 'Invalid amount';
                  if (double.parse(val) <= 0) return 'Must be > 0';
                  return null;
                },
                onSaved: (val) => paymentAmount = double.parse(val!),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                formKey.currentState!.save();
                Provider.of<DataManager>(
                  context,
                  listen: false,
                ).registerPayment(request.id, paymentAmount);
                Navigator.pop(ctx);
              }
            },
            child: const Text('Add Payment'),
          ),
        ],
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
                  onTap: () => _showPaymentDialog(context, req),
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
