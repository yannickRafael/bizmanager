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
  String? _lastBackupDate;

  @override
  void initState() {
    super.initState();
    _loadLastBackupDate();
  }

  Future<void> _loadLastBackupDate() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _lastBackupDate = prefs.getString('last_backup_date'));
  }

  Future<void> _saveLastBackupDate() async {
    final now = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_backup_date', now);
    setState(() => _lastBackupDate = now);
  }

  List<List<dynamic>> _buildAllCsvData(DataManager data) {
    final fmt = DateFormat('yyyy-MM-dd');
    final rows = <List<dynamic>>[];

    rows.add(['=== EXPLORACOES ===']);
    rows.add(['ID', 'Nome', 'Endereco', 'Notas']);
    for (final f in data.farms) rows.add([f.id, f.name, f.address, f.notes]);
    rows.add([]);

    rows.add(['=== LOTES ===']);
    rows.add(['ID', 'Nome', 'ExpedicaoId', 'Tipo', 'Origem', 'Data Entrada', 'Qtd Inicial', 'Qtd Atual', 'Estado', 'Custo Aquisicao', 'Raca', 'Notas']);
    for (final b in data.batches) {
      rows.add([b.id, b.name, b.farmId, b.type.name, b.birdOrigin.name, fmt.format(b.entryDate), b.initialQuantity, b.currentQuantity, b.status.name, b.acquisitionCost, b.breedOrLineage ?? '', b.notes ?? '']);
    }
    rows.add([]);

    rows.add(['=== DESPESAS ===']);
    rows.add(['ID', 'Lote', 'Tipo', 'Descricao', 'Valor', 'Data']);
    for (final e in data.expenses) rows.add([e.id, e.batchId, e.type.name, e.description, e.amount, fmt.format(e.date)]);
    rows.add([]);

    rows.add(['=== MORTALIDADES ===']);
    rows.add(['ID', 'Lote', 'Quantidade', 'Causa', 'Data']);
    for (final m in data.mortalities) rows.add([m.id, m.batchId, m.quantity, m.cause ?? '', fmt.format(m.date)]);
    rows.add([]);

    rows.add(['=== ABATES ===']);
    rows.add(['ID', 'Lote', 'Qtd Abatida', 'Peso Total kg', 'Custo Abate', 'Data']);
    for (final s in data.slaughters) rows.add([s.id, s.batchId, s.slaughteredQuantity, s.totalWeightKg, s.slaughterCost, fmt.format(s.date)]);
    rows.add([]);

    rows.add(['=== PRODUCAO OVOS ===']);
    rows.add(['ID', 'Lote', 'Unidade', 'Quantidade', 'Tamanho', 'Data']);
    for (final p in data.eggProductions) rows.add([p.id, p.batchId, p.unit.name, p.quantity, p.size.name, fmt.format(p.date)]);
    rows.add([]);

    rows.add(['=== VENDAS FRANGO ===']);
    rows.add(['ID', 'Lote', 'Cliente', 'Tipo Venda', 'Total', 'Pago', 'Estado Pagamento', 'Data']);
    for (final s in data.chickenSales) rows.add([s.id, s.batchId, s.clientId ?? '', s.saleType.name, s.total, s.amountPaid, s.paymentStatus.name, fmt.format(s.date)]);
    rows.add([]);

    rows.add(['=== VENDAS OVOS ===']);
    rows.add(['ID', 'Lote', 'Cliente', 'Unidade', 'Quantidade', 'Preco/Unit', 'Total', 'Pago', 'Estado Pagamento', 'Data']);
    for (final s in data.eggSales) rows.add([s.id, s.batchId, s.clientId ?? '', s.unit.name, s.quantity, s.unitPrice, s.total, s.amountPaid, s.paymentStatus.name, fmt.format(s.date)]);
    rows.add([]);

    rows.add(['=== VENDAS DESCARTES ===']);
    rows.add(['ID', 'Lote', 'Cliente', 'Quantidade', 'Preco/Ave', 'Total', 'Pago', 'Estado Pagamento', 'Data']);
    for (final s in data.culledBirdSales) rows.add([s.id, s.batchId, s.clientId ?? '', s.quantity, s.pricePerHead, s.total, s.amountPaid, s.paymentStatus.name, fmt.format(s.date)]);
    rows.add([]);

    rows.add(['=== CLIENTES ===']);
    rows.add(['ID', 'Nome', 'Telefone', 'Endereço', 'Notas']);
    for (final c in data.clients) rows.add([c.id, c.name, c.phoneNumber, c.address, c.notes]);
    rows.add([]);

    rows.add(['=== PARCEIROS ===']);
    rows.add(['ID', 'Nome', 'Tipo', 'Telefone', 'Endereco', 'Notas']);
    for (final p in data.partners) rows.add([p.id, p.name, p.type.name, p.phone, p.address, p.notes]);

    return rows;
  }

  Future<void> _exportToCSV(BuildContext context) async {
    try {
      final dataManager = Provider.of<DataManager>(context, listen: false);
      final csvContent = const ListToCsvConverter().convert(_buildAllCsvData(dataManager));
      final directory = await getTemporaryDirectory();
      final path = '${directory.path}/avicopro_backup_${DateTime.now().millisecondsSinceEpoch}.csv';
      await File(path).writeAsString(csvContent);
      await Share.shareXFiles([XFile(path)], text: 'AvicoPro - Copia de Seguranca CSV');
      await _saveLastBackupDate();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao exportar CSV: $e'), backgroundColor: Colors.red));
      }
    }
  }

  Future<void> _exportToSheets(BuildContext context) async {
    setState(() => _isExporting = true);
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) { setState(() => _isExporting = false); return; }

      final googleAuth = await googleUser.authentication;
      final accessToken = googleAuth.accessToken;
      if (accessToken == null) throw 'Falha ao obter token de acesso';

      final credentials = auth.AccessCredentials(
        auth.AccessToken('Bearer', accessToken, DateTime.now().add(const Duration(hours: 1)).toUtc()),
        null,
        [sheets.SheetsApi.spreadsheetsScope],
      );

      final httpClient = auth.authenticatedClient(http.Client(), credentials);
      final sheetsApi = sheets.SheetsApi(httpClient);
      final prefs = await SharedPreferences.getInstance();
      String? spreadsheetId = prefs.getString('google_sheet_id');

      if (!context.mounted) return;
      final dm = Provider.of<DataManager>(context, listen: false);
      final fmt = DateFormat('yyyy-MM-dd');

      final sheetData = <String, List<List<dynamic>>>{
        'Exploracoes': [['ID', 'Nome', 'Endereco', 'Notas'], ...dm.farms.map((f) => [f.id, f.name, f.address, f.notes])],
        'Lotes':       [['ID', 'Nome', 'Tipo', 'Estado', 'Qtd Inicial', 'Qtd Atual', 'Custo'], ...dm.batches.map((b) => [b.id, b.name, b.type.name, b.status.name, b.initialQuantity, b.currentQuantity, b.acquisitionCost])],
        'Despesas':    [['ID', 'Lote', 'Tipo', 'Descricao', 'Valor', 'Data'], ...dm.expenses.map((e) => [e.id, e.batchId, e.type.name, e.description, e.amount, fmt.format(e.date)])],
        'Mortalidades':[['ID', 'Lote', 'Quantidade', 'Causa', 'Data'], ...dm.mortalities.map((m) => [m.id, m.batchId, m.quantity, m.cause ?? '', fmt.format(m.date)])],
        'Abates':      [['ID', 'Lote', 'Qtd', 'Peso kg', 'Custo', 'Data'], ...dm.slaughters.map((s) => [s.id, s.batchId, s.slaughteredQuantity, s.totalWeightKg, s.slaughterCost, fmt.format(s.date)])],
        'Producao_Ovos':[['ID', 'Lote', 'Unidade', 'Quantidade', 'Tamanho', 'Data'], ...dm.eggProductions.map((p) => [p.id, p.batchId, p.unit.name, p.quantity, p.size.name, fmt.format(p.date)])],
        'Vendas': [
          ['ID', 'Tipo', 'Lote', 'Cliente', 'Total', 'Pago', 'Estado', 'Data'],
          ...dm.chickenSales.map((s) => [s.id, 'Frango', s.batchId, s.clientId ?? '', s.total, s.amountPaid, s.paymentStatus.name, fmt.format(s.date)]),
          ...dm.eggSales.map((s) => [s.id, 'Ovos', s.batchId, s.clientId ?? '', s.total, s.amountPaid, s.paymentStatus.name, fmt.format(s.date)]),
          ...dm.culledBirdSales.map((s) => [s.id, 'Descarte', s.batchId, s.clientId ?? '', s.total, s.amountPaid, s.paymentStatus.name, fmt.format(s.date)]),
        ],
        'Clientes':    [['ID', 'Nome', 'Telefone', 'Endereço'], ...dm.clients.map((c) => [c.id, c.name, c.phoneNumber, c.address])],
        'Parceiros':   [['ID', 'Nome', 'Tipo', 'Telefone'], ...dm.partners.map((p) => [p.id, p.name, p.type.name, p.phone])],
      };

      if (spreadsheetId == null) {
        final created = await sheetsApi.spreadsheets.create(
          sheets.Spreadsheet(properties: sheets.SpreadsheetProperties(title: 'AvicoPro Backup')),
        );
        spreadsheetId = created.spreadsheetId;
        await prefs.setString('google_sheet_id', spreadsheetId!);
      }

      final doc = await sheetsApi.spreadsheets.get(spreadsheetId);
      final existingTitles = doc.sheets?.map((s) => s.properties?.title).toSet() ?? {};
      final addRequests = sheetData.keys
          .where((t) => !existingTitles.contains(t))
          .map((t) => sheets.Request(addSheet: sheets.AddSheetRequest(properties: sheets.SheetProperties(title: t))))
          .toList();

      if (addRequests.isNotEmpty) {
        await sheetsApi.spreadsheets.batchUpdate(
          sheets.BatchUpdateSpreadsheetRequest(requests: addRequests), spreadsheetId,
        );
      }

      for (final entry in sheetData.entries) {
        await sheetsApi.spreadsheets.values.update(
          sheets.ValueRange(values: entry.value), spreadsheetId, '${entry.key}!A1', valueInputOption: 'USER_ENTERED',
        );
      }

      await _saveLastBackupDate();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Dados exportados para Google Sheets!'), backgroundColor: Colors.green));
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
      appBar: AppBar(title: const Text('Copia de Seguranca')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                color: Theme.of(context).colorScheme.primaryContainer,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      const Icon(Icons.cloud_done_outlined, size: 48, color: Colors.green),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Copia de Seguranca', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text(
                              _lastBackupDate == null ? 'Nunca efectuada.' : 'Ultimo backup: $_lastBackupDate',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Text('Escolha o destino', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              if (_isExporting)
                const Center(child: CircularProgressIndicator())
              else ...[
                FilledButton.icon(
                  onPressed: () => _exportToSheets(context),
                  icon: const Icon(Icons.table_chart),
                  label: const Text('Exportar para Google Sheets'),
                  style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), backgroundColor: Colors.green[700]),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => _exportToCSV(context),
                  icon: const Icon(Icons.download),
                  label: const Text('Exportar para CSV (Partilhar)'),
                  style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                ),
              ],
              const SizedBox(height: 32),
              const Divider(),
              const SizedBox(height: 16),
              Text('Dados incluidos no backup', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              ...[
                ('Exploracoes', Icons.home_work),
                ('Lotes / Bandos', Icons.pets),
                ('Despesas', Icons.receipt),
                ('Mortalidades', Icons.warning),
                ('Abates', Icons.cut),
                ('Producao de Ovos', Icons.egg),
                ('Vendas (Frango, Ovos, Descarte)', Icons.sell),
                ('Clientes', Icons.people),
                ('Parceiros', Icons.handshake),
              ].map((item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Icon(item.$2, size: 18, color: Colors.grey),
                    const SizedBox(width: 12),
                    Text(item.$1),
                  ],
                ),
              )),
            ],
          ),
        ),
      ),
    );
  }
}
