import 'package:flutter/material.dart';

/// Placeholder — will be fully built in Phase 4.
class PoultryBatchDetail extends StatelessWidget {
  final String batchId;
  const PoultryBatchDetail({super.key, required this.batchId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('🐔 Detalhe do Lote')),
      body: Center(child: Text('Batch: $batchId — Em migração')),
    );
  }
}
