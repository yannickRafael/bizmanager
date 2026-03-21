import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/data_manager.dart';
import '../models/enums.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Relatórios de Lucro'),
      ),
      body: Consumer<DataManager>(
        builder: (context, dataManager, child) {
          final batches = dataManager.batches.toList();
          if (batches.isEmpty) {
            return const Center(child: Text('Nenhum lote registado.'));
          }

          final currency = dataManager.currencySymbol;

          // Sort by date descending
          batches.sort((a, b) => b.entryDate.compareTo(a.entryDate));

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: batches.length,
            itemBuilder: (context, index) {
              final batch = batches[index];
              final isMeat = batch.type == BatchType.meat;

              // Expenses
              final expenses = dataManager.getExpensesByBatchId(batch.id);
              double totalExpenses = expenses.fold(0.0, (s, e) => s + e.amount) + batch.acquisitionCost;

              // Revenues
              double totalRevenue = 0;
              if (isMeat) {
                totalRevenue += dataManager.chickenSales.where((s) => s.batchId == batch.id).fold(0, (s,x) => s + x.total);
              } else {
                totalRevenue += dataManager.eggSales.where((s) => s.batchId == batch.id).fold(0, (s,x) => s + x.total);
                totalRevenue += dataManager.culledBirdSales.where((s) => s.batchId == batch.id).fold(0, (s,x) => s + x.total);
              }

              // Profit
              double profit = totalRevenue - totalExpenses;
              bool isProfitable = profit >= 0;

              // Mortality
              final mortalities = dataManager.getMortalityByBatchId(batch.id);
              int totalMortality = mortalities.fold(0, (s, m) => s + m.quantity);
              double mortalityRate = batch.initialQuantity > 0 ? (totalMortality / batch.initialQuantity) * 100 : 0.0;

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              batch.name,
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: batch.status == BatchStatus.active ? Colors.green.shade100 : Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              batch.status == BatchStatus.active ? 'ATIVO' : 'FECHADO',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: batch.status == BatchStatus.active ? Colors.green.shade800 : Colors.grey.shade800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Receita', style: TextStyle(color: Colors.grey)),
                                Text('$currency${totalRevenue.toStringAsFixed(2)}', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Despesa', style: TextStyle(color: Colors.grey)),
                                Text('$currency${totalExpenses.toStringAsFixed(2)}', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Lucro Neto', style: TextStyle(color: Colors.grey)),
                                Text(
                                  '$currency${profit.toStringAsFixed(2)}', 
                                  style: TextStyle(color: isProfitable ? Colors.indigo : Colors.red, fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.pets, size: 16, color: Colors.grey),
                              const SizedBox(width: 4),
                              Text('${batch.initialQuantity} Iniciais', style: const TextStyle(color: Colors.grey)),
                            ],
                          ),
                          Row(
                            children: [
                              const Icon(Icons.warning, size: 16, color: Colors.orange),
                              const SizedBox(width: 4),
                              Text('${mortalityRate.toStringAsFixed(1)}% Mortalidade', style: const TextStyle(color: Colors.grey)),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
