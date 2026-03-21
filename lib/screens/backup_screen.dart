import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import 'package:google_sign_in/google_sign_in.dart' as gsi;
import 'package:googleapis/sheets/v4.dart' as sheets;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:googleapis_auth/auth_io.dart' as auth;
import 'package:http/http.dart' as http;
import '../services/data_manager.dart';

class BackupScreen extends StatefulWidget {
  const BackupScreen({super.key});

  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  final gsi.GoogleSignIn _googleSignIn = gsi.GoogleSignIn(
    scopes: [sheets.SheetsApi.spreadsheetsScope],
  );

  bool _isExporting = false;

  Future<void> _exportToCSV(BuildContext context) async {
    try {
      final dataManager = Provider.of<DataManager>(context, listen: false);

      List<List<dynamic>> csvData = [];
      _buildCsvData(csvData, dataManager);

      String csvContent = const ListToCsvConverter().convert(csvData);

      final directory = await getTemporaryDirectory();
      final path = '${directory.path}/avicopro_backup_${DateTime.now().millisecondsSinceEpoch}.csv';
      final file = File(path);
      await file.writeAsString(csvContent);

      await Share.shareXFiles([XFile(path)], text: 'AvícoPro Backup');
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao exportar CSV: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _buildCsvData(List<List<dynamic>> csvData, DataManager data) {
    csvData.add(['--- EXPLORACOES ---']);
    csvData.add(['ID', 'Nome', 'Endereço', 'Notas']);
    for (var f in data.farms) csvData.add([f.id, f.name, f.address, f.notes]);
    csvData.add([]);

    csvData.add(['--- LOTES ---']);
    csvData.add(['ID', 'Nome', 'Tipo', 'Estado', 'Quantidade Atual']);
    for (var b in data.batches) csvData.add([b.id, b.name, b.type.name, b.status.name, b.currentQuantity]);
    csvData.add([]);

    csvData.add(['--- VENDAS FRANGO ---']);
    csvData.add(['ID', 'Lote', 'Data', 'Total', 'Pago']);
    for (var s in data.chickenSales) csvData.add([s.id, s.batchId, DateFormat('yyyy-MM-dd').format(s.date), s.total, s.amountPaid]);
  }

  Future<void> _exportToSheets(BuildContext context) async {
    setState(() => _isExporting = true);
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        setState(() => _isExporting = false);
        return;
      }

      final googleAuth = await googleUser.authentication;
      final accessToken = googleAuth.accessToken;
      if (accessToken == null) throw 'Falha ao obter token de acesso';

      final accessCredentials = auth.AccessCredentials(
        auth.AccessToken('Bearer', accessToken, DateTime.now().add(const Duration(hours: 1)).toUtc()),
        null,
        [sheets.SheetsApi.spreadsheetsScope],
      );

      final httpClient = auth.authenticatedClient(http.Client(), accessCredentials);
      final sheetsApi = sheets.SheetsApi(httpClient);
      final prefs = await SharedPreferences.getInstance();
      String? spreadsheetId = prefs.getString('google_sheet_id');

      if (!context.mounted) return;
      final dataManager = Provider.of<DataManager>(context, listen: false);

      final farmsData = [
        ['ID', 'Nome', 'Endereço', 'Notas'],
        ...dataManager.farms.map((f) => [f.id, f.name, f.address, f.notes]),
      ];

      final batchesData = [
        ['ID', 'Nome', 'Tipo', 'Estado', 'Qtd Atual'],
        ...dataManager.batches.map((b) => [b.id, b.name, b.type.name, b.status.name, b.currentQuantity]),
      ];

      final salesData = [
        ['ID', 'Tipo Venda', 'Data', 'Total', 'Pago'],
        ...dataManager.chickenSales.map((s) => [s.id, 'Frango', DateFormat('yyyy-MM-dd').format(s.date), s.total, s.amountPaid]),
        ...dataManager.eggSales.map((s) => [s.id, 'Ovos', DateFormat('yyyy-MM-dd').format(s.date), s.total, s.amountPaid]),
      ];

      if (spreadsheetId == null) {
        final spreadsheet = sheets.Spreadsheet(properties: sheets.SpreadsheetProperties(title: 'AvícoPro Backup'));
        final created = await sheetsApi.spreadsheets.create(spreadsheet);
        spreadsheetId = created.spreadsheetId;
        await prefs.setString('google_sheet_id', spreadsheetId!);
      }

      final doc = await sheetsApi.spreadsheets.get(spreadsheetId);
      final existingTitles = doc.sheets?.map((s) => s.properties?.title).toSet() ?? {};

      List<sheets.Request> requests = [];
      for (var title in ['Exploracoes', 'Lotes', 'Vendas']) {
        if (!existingTitles.contains(title)) {
          requests.add(sheets.Request(addSheet: sheets.AddSheetRequest(properties: sheets.SheetProperties(title: title))));
        }
      }

      if (requests.isNotEmpty) {
        await sheetsApi.spreadsheets.batchUpdate(sheets.BatchUpdateSpreadsheetRequest(requests: requests), spreadsheetId);
      }

      await sheetsApi.spreadsheets.values.update(
        sheets.ValueRange(values: farmsData), spreadsheetId, 'Exploracoes!A1', valueInputOption: 'USER_ENTERED',
      );
      await sheetsApi.spreadsheets.values.update(
        sheets.ValueRange(values: batchesData), spreadsheetId, 'Lotes!A1', valueInputOption: 'USER_ENTERED',
      );
      await sheetsApi.spreadsheets.values.update(
        sheets.ValueRange(values: salesData), spreadsheetId, 'Vendas!A1', valueInputOption: 'USER_ENTERED',
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Exportado para Google Sheets!'), backgroundColor: Colors.green));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro Sheets: $e'), backgroundColor: Colors.red));
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
              const Icon(Icons.cloud_upload_outlined, size: 80, color: Colors.green),
              const SizedBox(height: 24),
              Text('Segurança na Nuvem', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              const Text('Guarde os seus dados no Google Sheets ou exporte um ficheiro CSV.', textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: Colors.grey)),
              const SizedBox(height: 48),
              if (_isExporting)
                const CircularProgressIndicator()
              else ...[
                FilledButton.icon(
                  onPressed: () => _exportToSheets(context),
                  icon: const Icon(Icons.table_chart),
                  label: const Text('Exportar para Google Sheets'),
                  style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16), backgroundColor: Colors.green[700]),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () => _exportToCSV(context),
                  icon: const Icon(Icons.download),
                  label: const Text('Exportar para CSV'),
                  style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
