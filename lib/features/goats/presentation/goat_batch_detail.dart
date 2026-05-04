import 'package:flutter/material.dart';

/// Placeholder — will be fully built in Phase 6.
class GoatBatchDetail extends StatelessWidget {
  final String batchId;
  const GoatBatchDetail({super.key, required this.batchId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('🐐 Detalhe do Rebanho')),
      body: Center(child: Text('Batch: $batchId — Em desenvolvimento')),
    );
  }
}
