import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:reducer/shared/widgets/common_app_bar.dart';
import 'package:reducer/shared/widgets/common_bottom_nav_bar.dart';

class MainScreen extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const MainScreen({
    super.key,
    required this.navigationShell,
  });

  @override
  Widget build(BuildContext context) {
    // Branch 3 is Premium
    final showAppBar = navigationShell.currentIndex != 3;

    return Scaffold(
      appBar: showAppBar ? CommonAppBar(navigationShell: navigationShell) : null,
      body: navigationShell,
      bottomNavigationBar: CommonBottomNavBar(navigationShell: navigationShell),
    );
  }
}
