import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:googleapis/sheets/v4.dart' as sheets;
import 'package:shared_preferences/shared_preferences.dart';
import '../services/data_manager.dart';

class BackupScreen extends StatefulWidget {
  const BackupScreen({super.key});

  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [sheets.SheetsApi.spreadsheetsScope],
  );

  bool _isExporting = false;

  Future<void> _exportToCSV(BuildContext context) async {
    try {
      final dataManager = Provider.of<DataManager>(context, listen: false);
      final clients = dataManager.clients;
      final products = dataManager.products;
      final requests = dataManager.requests;

      // 1. Prepare CSV Data
      List<List<dynamic>> csvData = [];
      _buildCsvData(csvData, clients, products, requests);

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
            content: Text('Erro ao exportar CSV: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _buildCsvData(
    List<List<dynamic>> csvData,
    List<dynamic> clients,
    List<dynamic> products,
    List<dynamic> requests,
  ) {
    csvData.add(['--- CLIENTES ---']);
    csvData.add(['ID', 'Nome', 'Telefone', 'Morada', 'Notas']);
    for (var c in clients) {
      csvData.add([c.id, c.name, c.phoneNumber, c.address, c.notes]);
    }
    csvData.add([]);

    csvData.add(['--- PRODUTOS ---']);
    csvData.add(['ID', 'Nome', 'Preço Padrão']);
    for (var p in products) {
      csvData.add([p.id, p.name, p.defaultPrice]);
    }
    csvData.add([]);

    csvData.add(['--- PEDIDOS ---']);
    csvData.add([
      'ID',
      'ID Cliente',
      'Produto',
      'Qtd',
      'Total',
      'Pago',
      'Estado',
      'Data',
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
  }

  Future<void> _exportToSheets(BuildContext context) async {
    setState(() => _isExporting = true);
    try {
      // 1. Authenticate
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        // Canceled
        setState(() => _isExporting = false);
        return;
      }

      final httpClient = await _googleSignIn.authenticatedClient();
      if (httpClient == null) {
        throw 'Falha na autenticação HTTP';
      }

      final sheetsApi = sheets.SheetsApi(httpClient);
      final prefs = await SharedPreferences.getInstance();
      String? spreadsheetId = prefs.getString('google_sheet_id');

      // 2. Prepare Data
      final dataManager = Provider.of<DataManager>(context, listen: false);

      final clientsData = [
        ['ID', 'Nome', 'Telefone', 'Morada', 'Notas'],
        ...dataManager.clients.map(
          (c) => [c.id, c.name, c.phoneNumber, c.address, c.notes],
        ),
      ];

      final productsData = [
        ['ID', 'Nome', 'Preço Padrão'],
        ...dataManager.products.map((p) => [p.id, p.name, p.defaultPrice]),
      ];

      final ordersData = [
        [
          'ID',
          'ID Cliente',
          'Produto',
          'Qtd',
          'Total',
          'Pago',
          'Estado',
          'Data',
        ],
        ...dataManager.requests.map(
          (r) => [
            r.id,
            r.clientId,
            r.productName,
            r.amount,
            r.totalPrice,
            r.amountPaid,
            r.paymentStatus.name,
            DateFormat('yyyy-MM-dd HH:mm').format(r.date),
          ],
        ),
      ];

      // 3. Create or Update
      if (spreadsheetId == null) {
        // Create New
        final spreadsheet = sheets.Spreadsheet(
          properties: sheets.SpreadsheetProperties(title: 'BizManager Backup'),
        );
        final created = await sheetsApi.spreadsheets.create(spreadsheet);
        spreadsheetId = created.spreadsheetId;
        await prefs.setString('google_sheet_id', spreadsheetId!);
      }

      // 4. Batch Update (Ensure sheets exist and write data)
      final doc = await sheetsApi.spreadsheets.get(spreadsheetId);
      final existingTitles =
          doc.sheets?.map((s) => s.properties?.title).toSet() ?? {};

      List<sheets.Request> requests = [];

      // Ensure Sheets Exist
      for (var title in ['Clientes', 'Produtos', 'Pedidos']) {
        if (!existingTitles.contains(title)) {
          requests.add(
            sheets.Request(
              addSheet: sheets.AddSheetRequest(
                properties: sheets.SheetProperties(title: title),
              ),
            ),
          );
        }
      }

      if (requests.isNotEmpty) {
        await sheetsApi.spreadsheets.batchUpdate(
          sheets.BatchUpdateSpreadsheetRequest(requests: requests),
          spreadsheetId,
        );
      }

      // Write Data
      final valueRangeClients = sheets.ValueRange(values: clientsData);
      final valueRangeProducts = sheets.ValueRange(values: productsData);
      final valueRangeOrders = sheets.ValueRange(values: ordersData);

      await sheetsApi.spreadsheets.values.update(
        valueRangeClients,
        spreadsheetId,
        'Clientes!A1',
        valueInputOption: 'USER_ENTERED',
      );
      await sheetsApi.spreadsheets.values.update(
        valueRangeProducts,
        spreadsheetId,
        'Produtos!A1',
        valueInputOption: 'USER_ENTERED',
      );
      await sheetsApi.spreadsheets.values.update(
        valueRangeOrders,
        spreadsheetId,
        'Pedidos!A1',
        valueInputOption: 'USER_ENTERED',
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Exportado para Google Sheets!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro Sheets: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
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
              const Icon(
                Icons.cloud_upload_outlined,
                size: 80,
                color: Colors.green,
              ),
              const SizedBox(height: 24),
              Text(
                'Segurança na Nuvem',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Guarde os seus dados no Google Sheets ou exporte um ficheiro CSV.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 48),

              if (_isExporting)
                const CircularProgressIndicator()
              else ...[
                FilledButton.icon(
                  onPressed: () => _exportToSheets(context),
                  icon: const Icon(Icons.table_chart),
                  label: const Text('Exportar para Google Sheets'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    backgroundColor: Colors.green[700],
                  ),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () => _exportToCSV(context),
                  icon: const Icon(Icons.download),
                  label: const Text('Exportar para CSV'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
