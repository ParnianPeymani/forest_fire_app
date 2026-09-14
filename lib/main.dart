import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'screens/dashboard_screen.dart';
import 'screens/map_screen.dart';
import 'services/fire_data_provider.dart';
import 'services/fire_service.dart';
import 'theme/app_theme.dart';

/// Pass your free NASA FIRMS key at build/run time, e.g.:
///   flutter run --dart-define=FIRMS_MAP_KEY=your_key_here
/// Get a key at https://firms.modaps.eosdis.nasa.gov/api/area/
const String _firmsMapKey =
    String.fromEnvironment('FIRMS_MAP_KEY', defaultValue: '');

void main() {
  runApp(const RiskMapApp());
}

class RiskMapApp extends StatelessWidget {
  const RiskMapApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => FireDataProvider(FireService(mapKey: _firmsMapKey))
        ..load(),
      child: MaterialApp(
        title: 'RiskMap',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark,
        locale: const Locale('fa'),
        home: const _RootShell(),
      ),
    );
  }
}

class _RootShell extends StatefulWidget {
  const _RootShell();

  @override
  State<_RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<_RootShell> {
  int _index = 0;

  static const _screens = [MapScreen(), DashboardScreen()];

  @override
  Widget build(BuildContext context) {
    if (_firmsMapKey.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'FIRMS_MAP_KEY تنظیم نشده — بدون کلید، دریافت داده ممکن نیست. '
              'به README مراجعه کن.',
            ),
            duration: Duration(seconds: 6),
          ),
        );
      });
    }

    return Scaffold(
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map),
            label: 'نقشه',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart),
            label: 'داشبورد',
          ),
        ],
      ),
    );
  }
}
