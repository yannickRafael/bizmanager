import 'package:flutter/material.dart';

/// Placeholder — will be fully built in Phase 4.
class ClientDetailsScreen extends StatelessWidget {
  final String clientId;
  const ClientDetailsScreen({super.key, required this.clientId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detalhes do Cliente')),
      body: Center(child: Text('Cliente: $clientId — Em migração')),
    );
  }
}
