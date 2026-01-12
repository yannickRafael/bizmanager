import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import '../services/data_manager.dart';

class BackupScreen extends StatelessWidget {
  const BackupScreen({super.key});

  Future<void> _exportData(BuildContext context) async {
    try {
      final dataManager = Provider.of<DataManager>(context, listen: false);
      final clients = dataManager.clients;
      final products = dataManager.products;
      final requests = dataManager.requests;

      // 1. Prepare CSV Data
      List<List<dynamic>> csvData = [];

      // Section: Clients
      csvData.add(['--- CLIENTS ---']);
      csvData.add(['ID', 'Name', 'Phone', 'Address', 'Notes']);
      for (var c in clients) {
        csvData.add([c.id, c.name, c.phoneNumber, c.address, c.notes]);
      }
      csvData.add([]); // Empty line

      // Section: Products
      csvData.add(['--- PRODUCTS ---']);
      csvData.add(['ID', 'Name', 'Default Price']);
      for (var p in products) {
        csvData.add([p.id, p.name, p.defaultPrice]);
      }
      csvData.add([]); // Empty line

      // Section: Orders
      csvData.add(['--- ORDERS ---']);
      csvData.add([
        'ID',
        'Client ID',
        'Product',
        'Amount',
        'Total Price',
        'Paid Amount',
        'Status',
        'Date',
      ]);
      for (var r in requests) {
        csvData.add([
          r.id,
          r.clientId,
          r.productName,
          r.amount,
          r.totalPrice,
          r.amountPaid,
          r.paymentStatus.name,
          DateFormat('yyyy-MM-dd HH:mm').format(r.date),
        ]);
      }

      // 2. Generate CSV String
      String csvContent = const ListToCsvConverter().convert(csvData);

      // 3. Save to File
      final directory = await getTemporaryDirectory();
      final path =
          '${directory.path}/bizmanager_backup_${DateTime.now().millisecondsSinceEpoch}.csv';
      final file = File(path);
      await file.writeAsString(csvContent);

      // 4. Share
      await Share.shareXFiles([XFile(path)], text: 'BizManager Backup');
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao exportar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cópia de Segurança')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.backup_outlined, size: 80, color: Colors.blue),
              const SizedBox(height: 24),
              Text(
                'Exportar Dados',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Gere um ficheiro CSV com todos os seus Clientes, Produtos e Pedidos. Pode guardá-lo ou enviá-lo por email.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 48),
              FilledButton.icon(
                onPressed: () => _exportData(context),
                icon: const Icon(Icons.download),
                label: const Text('Exportar para CSV'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
