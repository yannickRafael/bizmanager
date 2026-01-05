import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/data_manager.dart';
import '../models/product.dart';
import 'package:uuid/uuid.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final _uuid = const Uuid();

  void _showAddProductModal(BuildContext context) {
    String name = '';
    double defaultPrice = 0.0;
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
                'Novo Produto',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Nome do Produto',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.shopping_bag),
                ),
                validator: (val) =>
                    val == null || val.isEmpty ? 'Insira o nome' : null,
                onSaved: (val) => name = val!.trim(),
              ),
              const SizedBox(height: 12),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Preço Padrão',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.attach_money),
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: (val) => val == null || double.tryParse(val) == null
                    ? 'Preço inválido'
                    : null,
                onSaved: (val) => defaultPrice = double.parse(val!),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () {
                  if (formKey.currentState!.validate()) {
                    formKey.currentState!.save();
                    final newProduct = Product(
                      id: _uuid.v4(),
                      name: name,
                      defaultPrice: defaultPrice,
                    );
                    Provider.of<DataManager>(
                      context,
                      listen: false,
                    ).addProduct(newProduct);
                    Navigator.pop(ctx);
                  }
                },
                child: const Text('Guardar Produto'),
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
      appBar: AppBar(title: const Text('Produtos')),
      body: Consumer<DataManager>(
        builder: (context, dataManager, child) {
          if (dataManager.products.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.inventory_2_outlined,
                    size: 64,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Sem produtos.',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () => _showAddProductModal(context),
                    icon: const Icon(Icons.add),
                    label: const Text('Adicionar Produto'),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            itemCount: dataManager.products.length,
            itemBuilder: (context, index) {
              final product = dataManager.products[index];
              return ListTile(
                leading: CircleAvatar(
                  child: Text(product.name[0].toUpperCase()),
                ),
                title: Text(
                  product.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  'Preço Padrão: \$${product.defaultPrice.toStringAsFixed(2)}',
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Apagar Produto?'),
                        content: Text(
                          'Tem a certeza que quer apagar "${product.name}"?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('Cancelar'),
                          ),
                          TextButton(
                            onPressed: () {
                              dataManager.deleteProduct(product.id);
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
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddProductModal(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}
