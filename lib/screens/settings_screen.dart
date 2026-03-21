import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/data_manager.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Only one language for now, Portuguese
    const selectedLanguage = 'pt';
    
    // Currencies list
    const currencies = [
      '\$', '€', '£', 'R\$', 'Kz', 'MZN', 'AOA', 'CHF'
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Definições')),
      body: Consumer<DataManager>(
        builder: (context, data, child) {
          return ListView(
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
              const Divider(),
              ListTile(
                title: const Text('Moeda'),
                subtitle: const Text('Símbolo monetário usado na aplicação'),
                trailing: DropdownButton<String>(
                  value: data.currencySymbol,
                  items: currencies.map((c) {
                    return DropdownMenuItem(value: c, child: Text(c));
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      data.setCurrencySymbol(val);
                    }
                  },
                ),
              ),
              const Divider(),
              const ListTile(
                title: Text('Sobre'),
                subtitle: Text('BizManager v1.0.0'),
              ),
            ],
          );
        },
      ),
    );
  }
}
