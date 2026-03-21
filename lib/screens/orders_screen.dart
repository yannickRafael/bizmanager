import '../models/product.dart';
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
  String _searchQuery = '';

  void _showAddOrderModal(BuildContext context, {Request? existingRequest}) {
    // Variables for Order
    String? selectedProductName = existingRequest?.productName;
    double amount = existingRequest?.amount ?? 0;
    double price = existingRequest?.totalPrice ?? 0;
    DateTime date = existingRequest?.date ?? DateTime.now();

    // Variables for Client Selection
    int selectedTab = existingRequest != null ? 0 : 0; // 0: Existing, 1: New
    String? selectedClientId = existingRequest?.clientId;

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
          Future<void> pickContact() async {
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
                      existingRequest == null ? 'Novo Pedido' : 'Editar Pedido',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),

                    if (existingRequest == null) ...[
                      // Client Section
                      Text(
                        'Detalhes do Cliente',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),

                      // Toggle between Existing and New
                      SegmentedButton<int>(
                        segments: const [
                          ButtonSegment(
                            value: 0,
                            label: Text('Existente'),
                            icon: Icon(Icons.list),
                          ),
                          ButtonSegment(
                            value: 1,
                            label: Text('Novo / Importar'),
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
                        Consumer<DataManager>(
                          builder: (context, data, _) {
                            final clients = data.clients;
                            if (clients.isEmpty) {
                              return const Padding(
                                padding: EdgeInsets.all(8.0),
                                child: Text(
                                  'Nenhum cliente encontrado. Mude para "Novo" para criar.',
                                  style: TextStyle(color: Colors.red),
                                ),
                              );
                            }
                            return DropdownButtonFormField<String>(
                              decoration: const InputDecoration(
                                labelText: 'Selecionar Cliente',
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
                                  ? 'Selecione um cliente'
                                  : null,
                            );
                          },
                        ),
                      ] else ...[
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: pickContact,
                                icon: const Icon(Icons.contacts),
                                label: const Text('Importar de Contactos'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: nameController,
                          decoration: const InputDecoration(
                            labelText: 'Nome do Cliente',
                            border: OutlineInputBorder(),
                          ),
                          validator: (val) =>
                              selectedTab == 1 && (val == null || val.isEmpty)
                              ? 'Insira o nome'
                              : null,
                          onSaved: (val) => newClientName = val!.trim(),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: phoneController,
                          decoration: const InputDecoration(
                            labelText: 'Número de Telefone',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.phone,
                          onSaved: (val) => newClientPhone = val?.trim() ?? '',
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          decoration: const InputDecoration(
                            labelText: 'Endereço',
                            border: OutlineInputBorder(),
                          ),
                          onSaved: (val) => newClientAddress = val?.trim() ?? '',
                        ),
                      ],
                      const SizedBox(height: 24),
                    ],

                    Text(
                      'Detalhes do Pedido',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),

                    // Product Dropdown
                    Consumer<DataManager>(
                      builder: (context, data, _) {
                        return DropdownButtonFormField<String>(
                          decoration: const InputDecoration(
                            labelText: 'Produto',
                            border: OutlineInputBorder(),
                          ),
                          value: selectedProductName,
                          items: data.products
                              .map(
                                (p) => DropdownMenuItem(
                                  value: p.name,
                                  child: Text(p.name.toUpperCase()),
                                ),
                              )
                              .toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                selectedProductName = val;
                                // Find product default price
                                final product = data.products.firstWhere(
                                  (p) => p.name == val,
                                );
                                // Auto update price if amount is set
                                if (amount > 0) {
                                  price = amount * product.defaultPrice;
                                }
                              });
                            }
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            initialValue: amount > 0 ? amount.toString() : null,
                            decoration: const InputDecoration(
                              labelText: 'Quantidade',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            onChanged: (val) {
                              if (val.isNotEmpty &&
                                  double.tryParse(val) != null) {
                                setState(() {
                                  amount = double.parse(val);
                                  // Update price
                                  if (selectedProductName != null) {
                                    final data = Provider.of<DataManager>(
                                      context,
                                      listen: false,
                                    );
                                    final product = data.products.firstWhere(
                                      (p) => p.name == selectedProductName,
                                      orElse: () => Product(
                                        id: '',
                                        name: '',
                                        defaultPrice: 0,
                                      ),
                                    );
                                    price = amount * product.defaultPrice;
                                  }
                                });
                              }
                            },
                            validator: (val) =>
                                val == null || double.tryParse(val) == null
                                ? 'Qtd inválida'
                                : null,
                            onSaved: (val) => amount = double.parse(val!),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            // Key to force rebuild when price changes? No, controller is better.
                            // Using key for simplicity in this context or create a controller.
                            key: ValueKey(price),
                            initialValue: price > 0
                                ? price.toStringAsFixed(2)
                                : null,
                            decoration: InputDecoration(
                              labelText: 'Preço Total',
                              border: const OutlineInputBorder(),
                              prefixText: Provider.of<DataManager>(context, listen: false).currencySymbol,
                            ),
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            validator: (val) =>
                                val == null || double.tryParse(val) == null
                                ? 'Preço inválido'
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
                            finalClientId = selectedClientId!;
                          } else {
                            finalClientId = _uuid.v4();
                            final newClient = Client(
                              id: finalClientId,
                              name: newClientName,
                              phoneNumber: newClientPhone,
                              address: newClientAddress,
                            );
                            dataManager.addClient(newClient);
                          }

                          if (existingRequest != null) {
                            final updatedRequest = Request(
                              id: existingRequest.id,
                              clientId: existingRequest.clientId,
                              productName: selectedProductName!,
                              amount: amount,
                              totalPrice: price,
                              date: date,
                              amountPaid: existingRequest.amountPaid,
                              paymentStatus: existingRequest.paymentStatus,
                            );
                            dataManager.updateRequest(updatedRequest);
                          } else {
                            final newRequest = Request(
                              id: _uuid.v4(),
                              clientId: finalClientId,
                              productName: selectedProductName!,
                              amount: amount,
                              totalPrice: price,
                              date: date,
                              paymentStatus: PaymentStatus.pending,
                            );
                            dataManager.addRequest(newRequest);
                          }
                          Navigator.pop(ctx);
                        }
                      },
                      child: Text(existingRequest == null ? 'Criar Pedido' : 'Guardar Alterações'),
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
      builder: (ctx) {
        final currency = Provider.of<DataManager>(context, listen: false).currencySymbol;
        return AlertDialog(
        title: const Text('Registar Pagamento'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Preço Total: $currency${request.totalPrice.toStringAsFixed(2)}'),
              Text('Já Pago: $currency${request.amountPaid.toStringAsFixed(2)}'),
              const SizedBox(height: 8),
              Text(
                'Remanescente: $currency${(request.totalPrice - request.amountPaid).toStringAsFixed(2)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Valor a Pagar',
                  border: const OutlineInputBorder(),
                  prefixText: currency,
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: (val) {
                  if (val == null || double.tryParse(val) == null) {
                    return 'Valor inválido';
                  }
                  if (double.parse(val) <= 0) return 'Deve ser > 0';
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
            child: const Text('Cancelar'),
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
            child: const Text('Adicionar Pagamento'),
          ),
        ],
      );
    },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pedidos'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Pesquisar produto ou cliente',
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
                    'Sem pedidos ainda.',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () => _showAddOrderModal(context),
                    icon: const Icon(Icons.add),
                    label: const Text('Criar Primeiro Pedido'),
                  ),
                ],
              ),
            );
          }

          // Sort by date descending
          final sortedRequests = List.of(dataManager.requests)
            ..sort((a, b) => b.date.compareTo(a.date));

          final filteredRequests = sortedRequests.where((r) {
            final client = dataManager.getClientById(r.clientId);
            final clientName = client?.name.toLowerCase() ?? '';
            final productName = r.productName.toLowerCase();
            return clientName.contains(_searchQuery) || productName.contains(_searchQuery);
          }).toList();

          if (filteredRequests.isEmpty && _searchQuery.isNotEmpty) {
            return const Center(child: Text('Nenhum pedido encontrado.'));
          }

          return ListView.builder(
            itemCount: filteredRequests.length,
            itemBuilder: (context, index) {
              final req = filteredRequests[index];
              final client = dataManager.getClientById(req.clientId);

              Color statusColor;
              String statusText;
              switch (req.paymentStatus) {
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

              String productText = req.productName.toUpperCase();

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
                        productText,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      Text(
                        '${dataManager.currencySymbol}${req.totalPrice.toStringAsFixed(2)}',
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
                      Text('Cliente: ${client?.name ?? "Desconhecido"}'),
                      Text(
                        'Qtd: ${req.amount} | Data: ${DateFormat('dd/MM/yyyy').format(req.date)}',
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.1),
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
                    ],
                  ),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') {
                        _showAddOrderModal(context, existingRequest: req);
                      } else if (value == 'delete') {
                        showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Apagar Pedido?'),
                            content: const Text(
                              'Tem a certeza que quer apagar este pedido?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx),
                                child: const Text('Cancelar'),
                              ),
                              TextButton(
                                onPressed: () {
                                  Provider.of<DataManager>(context, listen: false).deleteRequest(req.id);
                                  Navigator.pop(ctx);
                                },
                                child: const Text(
                                  'Apagar',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                    },
                    itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                      const PopupMenuItem<String>(
                        value: 'edit',
                        child: Text('Editar'),
                      ),
                      const PopupMenuItem<String>(
                        value: 'delete',
                        child: Text(
                          'Apagar',
                          style: TextStyle(color: Colors.red),
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
