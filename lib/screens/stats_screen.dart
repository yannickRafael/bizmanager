import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/data_manager.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Estatísticas')),
      body: Consumer<DataManager>(
        builder: (context, data, child) {
          final requests = data.requests;
          if (requests.isEmpty) {
            return const Center(child: Text('Sem dados suficientes.'));
          }

          // Financials
          double totalRevenue = 0;
          double totalPaid = 0;
          for (var r in requests) {
            totalRevenue += r.totalPrice;
            totalPaid += r.amountPaid;
          }
          double totalDebt = totalRevenue - totalPaid;

          // Product Stats
          final Map<String, double> productRevenue = {};
          final Map<String, double> productQty = {};

          for (var r in requests) {
            final name = r.productName.toUpperCase();
            productRevenue[name] = (productRevenue[name] ?? 0) + r.totalPrice;
            productQty[name] = (productQty[name] ?? 0) + r.amount;
          }

          // Client Stats
          final Map<String, double> clientSpending = {};
          for (var r in requests) {
            clientSpending[r.clientId] =
                (clientSpending[r.clientId] ?? 0) + r.totalPrice;
          }

          // Sort Clients
          final sortedClients = clientSpending.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));
          final topClients = sortedClients.take(5).toList();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Visão Geral Financeira',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        context,
                        'Receita Total',
                        totalRevenue,
                        Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        context,
                        'Cobrado',
                        totalPaid,
                        Colors.green,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildStatCard(
                  context,
                  'Dívida Pendente',
                  totalDebt,
                  Colors.red,
                ),

                const SizedBox(height: 32),
                Text(
                  'Desempenho por Produto',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: productRevenue.entries.map((e) {
                        final name = e.key;
                        final revenue = e.value;
                        final qty = productQty[name] ?? 0;
                        final percent = totalRevenue > 0
                            ? (revenue / totalRevenue)
                            : 0.0;

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '$name (${qty.toStringAsFixed(0)})',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text('\$${revenue.toStringAsFixed(2)}'),
                                ],
                              ),
                              const SizedBox(height: 4),
                              LinearProgressIndicator(
                                value: percent,
                                backgroundColor: Colors.grey[200],
                                color: Colors.blueAccent,
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),

                const SizedBox(height: 32),
                Text(
                  'Melhores Clientes',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Card(
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: topClients.length,
                    separatorBuilder: (_, _) => const Divider(),
                    itemBuilder: (ctx, index) {
                      final entry = topClients[index];
                      final client = data.getClientById(entry.key);
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: index == 0
                              ? Colors.amber
                              : Colors.grey[300],
                          foregroundColor: index == 0
                              ? Colors.black
                              : Colors.black87,
                          child: Text('${index + 1}'),
                        ),
                        title: Text(
                          client?.name ?? 'Desconhecido',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        trailing: Text(
                          '\$${entry.value.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    double value,
    Color color,
  ) {
    return Card(
      color: color.withValues(alpha: 0.1),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: color.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(color: color, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              '\$${value.toStringAsFixed(2)}',
              style: TextStyle(
                color: color,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
