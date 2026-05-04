import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

// Providers — will be populated in Phase 3
// import 'features/farms/providers/farm_provider.dart';
// import 'features/clients/providers/client_provider.dart';
// import 'features/partners/providers/partner_provider.dart';
// import 'features/settings/providers/settings_provider.dart';
// import 'features/poultry/providers/poultry_provider.dart';
// import 'features/cattle/providers/cattle_provider.dart';
// import 'features/goats/providers/goat_provider.dart';

/// Temporary bridge: keep the old DataManager running until Phase 3.
import 'services/data_manager.dart';

class FarmaApp extends StatelessWidget {
  const FarmaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Temporary: old DataManager until Phase 3 migration
        ChangeNotifierProvider(
          create: (_) {
            final dm = DataManager();
            dm.init();
            return dm;
          },
        ),
        // Phase 3 providers will replace the above:
        // ChangeNotifierProvider(create: (_) => FarmProvider()..init()),
        // ChangeNotifierProvider(create: (_) => ClientProvider()..init()),
        // ChangeNotifierProvider(create: (_) => PartnerProvider()..init()),
        // ChangeNotifierProvider(create: (_) => SettingsProvider()..init()),
        // ChangeNotifierProvider(create: (_) => PoultryProvider()..init()),
        // ChangeNotifierProvider(create: (_) => CattleProvider()..init()),
        // ChangeNotifierProvider(create: (_) => GoatProvider()..init()),
      ],
      child: MaterialApp.router(
        title: 'Farma',
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: ThemeMode.light,
        routerConfig: AppRouter.router,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
