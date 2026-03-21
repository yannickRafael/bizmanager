import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/data_manager.dart';
import '../models/enums.dart';

class BatchDetailScreen extends StatelessWidget {
  final String batchId;

  const BatchDetailScreen({super.key, required this.batchId});

  @override
  Widget build(BuildContext context) {
    return Consumer<DataManager>(
      builder: (context, dataManager, child) {
        final batch = dataManager.getBatchById(batchId);
        
        if (batch == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Lote Não Encontrado')),
            body: const Center(child: Text('Este lote pode ter sido apagado.')),
          );
        }

        final farm = dataManager.getFarmById(batch.farmId);
        final ageInDays = DateTime.now().difference(batch.entryDate).inDays;
        final isMeat = batch.type == BatchType.meat;

        // Collect related data
        final expenses = dataManager.getExpensesByBatchId(batchId);
        final mortalities = dataManager.getMortalityByBatchId(batchId);
        final slaughters = dataManager.getSlaughtersByBatchId(batchId);
        final eggProductions = dataManager.getEggProductionsByBatchId(batchId);
        
        final chickenSales = dataManager.chickenSales.where((s) => s.batchId == batchId).toList();
        final eggSales = dataManager.eggSales.where((s) => s.batchId == batchId).toList();
        final culledSales = dataManager.culledBirdSales.where((s) => s.batchId == batchId).toList();

        double totalExpenses = expenses.fold(0, (sum, e) => sum + e.amount);
        int totalMortality = mortalities.fold(0, (sum, m) => sum + m.quantity);
        double mortalityRate = batch.initialQuantity > 0 
            ? (totalMortality / batch.initialQuantity) * 100 
            : 0;

        return DefaultTabController(
          length: isMeat ? 4 : 5,
          child: Scaffold(
            appBar: AppBar(
              title: Text(batch.name),
              bottom: TabBar(
                isScrollable: true,
                tabs: [
                  const Tab(text: 'Resumo'),
                  const Tab(text: 'Despesas'),
                  const Tab(text: 'Mortalidade'),
                  if (isMeat) const Tab(text: 'Abates'),
                  if (!isMeat) const Tab(text: 'Produção de Ovos'),
                  const Tab(text: 'Vendas'),
                ],
              ),
            ),
            body: TabBarView(
              children: [
                // 1. SUMMARY TAB
                ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.home_work),
                        title: const Text('Exploração'),
                        subtitle: Text(farm?.name ?? 'Desconhecida'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(child: _StatCard(title: 'Idade', value: '$ageInDays dias', icon: Icons.calendar_today)),
                        const SizedBox(width: 8),
                        Expanded(child: _StatCard(title: 'Vivas', value: '${batch.currentQuantity}', icon: Icons.pets)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(child: _StatCard(title: 'Mortalidade', value: '${mortalityRate.toStringAsFixed(1)}%', icon: Icons.warning_amber_rounded)),
                        const SizedBox(width: 8),
                        Expanded(child: _StatCard(title: 'Despesas', value: '${dataManager.currencySymbol}$totalExpenses', icon: Icons.money_off)),
                      ],
                    ),
                  ],
                ),

                // 2. EXPENSES TAB
                expenses.isEmpty
                    ? const Center(child: Text('Sem despesas registadas.'))
                    : ListView.builder(
                        itemCount: expenses.length,
                        itemBuilder: (ctx, i) => ListTile(
                          leading: const Icon(Icons.receipt),
                          title: Text(expenses[i].description),
                          subtitle: Text(expenses[i].date.toString().substring(0, 10)),
                          trailing: Text('${dataManager.currencySymbol}${expenses[i].amount}'),
                        ),
                      ),

                // 3. MORTALITY TAB
                mortalities.isEmpty
                    ? const Center(child: Text('Sem perdas registadas.'))
                    : ListView.builder(
                        itemCount: mortalities.length,
                        itemBuilder: (ctx, i) => ListTile(
                          leading: const Icon(Icons.warning, color: Colors.orange),
                          title: Text('${mortalities[i].quantity} aves mortas'),
                          subtitle: Text(mortalities[i].cause ?? 'Causa não especificada'),
                          trailing: Text(mortalities[i].date.toString().substring(0, 10)),
                        ),
                      ),

                // 4. SLAUGHTERS (Meat) OR EGG PRODUCTION (Layers)
                if (isMeat)
                  slaughters.isEmpty
                      ? const Center(child: Text('Sem abates registados.'))
                      : ListView.builder(
                          itemCount: slaughters.length,
                          itemBuilder: (ctx, i) => ListTile(
                            leading: const Icon(Icons.cut),
                            title: Text('${slaughters[i].slaughteredQuantity} frangos abatidos'),
                            subtitle: Text('Peso Total: ${slaughters[i].totalWeightKg} kg'),
                            trailing: Text(slaughters[i].date.toString().substring(0, 10)),
                          ),
                        )
                else
                  eggProductions.isEmpty
                      ? const Center(child: Text('Sem produção de ovos registada.'))
                      : ListView.builder(
                          itemCount: eggProductions.length,
                          itemBuilder: (ctx, i) => ListTile(
                            leading: const Icon(Icons.egg),
                            title: Text('${eggProductions[i].quantity} ${eggProductions[i].unit.name}'),
                            subtitle: Text('Classe: ${eggProductions[i].size.name}'),
                            trailing: Text(eggProductions[i].date.toString().substring(0, 10)),
                          ),
                        ),

                // 5. SALES TAB (Combines all sale types for this batch)
                ListView(
                  children: [
                    if (isMeat) ...chickenSales.map((s) => ListTile(
                      leading: const Icon(Icons.attach_money, color: Colors.green),
                      title: Text('Venda Frango (${s.saleType.name})'),
                      subtitle: Text(s.date.toString().substring(0, 10)),
                      trailing: Text('${dataManager.currencySymbol}${s.total}'),
                    )),
                    if (!isMeat) ...eggSales.map((s) => ListTile(
                      leading: const Icon(Icons.attach_money, color: Colors.green),
                      title: Text('Venda Ovos (${s.quantity} ${s.unit.name})'),
                      subtitle: Text(s.date.toString().substring(0, 10)),
                      trailing: Text('${dataManager.currencySymbol}${s.total}'),
                    )),
                    if (!isMeat) ...culledSales.map((s) => ListTile(
                      leading: const Icon(Icons.attach_money, color: Colors.green),
                      title: Text('Venda Descarte (${s.quantity} aves)'),
                      subtitle: Text(s.date.toString().substring(0, 10)),
                      trailing: Text('${dataManager.currencySymbol}${s.total}'),
                    )),
                    if (chickenSales.isEmpty && eggSales.isEmpty && culledSales.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(32.0),
                        child: Center(child: Text('Nenhuma venda registada para este lote.')),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _StatCard({required this.title, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(title, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          ],
        ),
      ),
    );
  }
}
