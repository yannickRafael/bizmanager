import 'package:flutter/material.dart';

/// Placeholder Backup screen — multi-animal backup support.
class BackupScreen extends StatelessWidget {
  const BackupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Cópia de Segurança')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.cloud_upload_outlined, size: 80, color: Colors.blueGrey),
            const SizedBox(height: 24),
            Text(
              'Proteja os seus dados',
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Exporte os dados da sua exploração para um ficheiro ou importe uma cópia anterior.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 40),
            
            _BackupOption(
              icon: Icons.file_download,
              title: 'Exportar Dados',
              subtitle: 'Criar uma cópia de segurança local.',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Funcionalidade de exportação em breve.')),
                );
              },
            ),
            const SizedBox(height: 16),
            _BackupOption(
              icon: Icons.file_upload,
              title: 'Importar Dados',
              subtitle: 'Restaurar a partir de um ficheiro anterior.',
              onTap: () {
                 ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Funcionalidade de importação em breve.')),
                );
              },
              isTonal: true,
            ),
            
            const SizedBox(height: 40),
            const Divider(),
            const SizedBox(height: 16),
            const Text(
              'Nota: Todas as categorias (Aves, Bovinos, Caprinos) são incluídas na mesma cópia de segurança.',
              style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

class _BackupOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool isTonal;

  const _BackupOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.isTonal = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: isTonal ? Colors.indigo : Colors.blue),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}
