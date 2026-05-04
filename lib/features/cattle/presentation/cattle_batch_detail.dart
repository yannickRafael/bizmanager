import 'package:flutter/material.dart';

/// Placeholder — will be fully built in Phase 5.
class CattleBatchDetail extends StatelessWidget {
  final String batchId;
  const CattleBatchDetail({super.key, required this.batchId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('🐄 Detalhe da Manada')),
      body: Center(child: Text('Batch: $batchId — Em desenvolvimento')),
    );
  }
}
