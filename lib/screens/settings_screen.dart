import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String selectedLanguage = 'pt'; // Default to Portuguese

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Definições')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ListTile(
            title: const Text('Idioma'),
            subtitle: const Text('Selecione o idioma da aplicação'),
            trailing: DropdownButton<String>(
              value: selectedLanguage,
              items: const [
                DropdownMenuItem(value: 'pt', child: Text('Português')),
              ],
              onChanged: (val) {
                // Only PT supported for now
              },
            ),
          ),
        ],
      ),
    );
  }
}
