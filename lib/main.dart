import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/data_manager.dart';
import 'screens/dashboard_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) {
            final dm = DataManager();
            dm.init();
            return dm;
          },
        ),
      ],
      child: MaterialApp(
        title: 'BizManager',
        theme: ThemeData(
          // Use a nice color scheme as requested by "Premium Designs"
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF6750A4), // Deep Purple seed
            brightness: Brightness.light,
          ),
          useMaterial3: true,
          fontFamily:
              'Roboto', // Default, but good to be explicit or change if needed
        ),
        home: const DashboardScreen(),
      ),
    );
  }
}
