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
    return Scaffold(
      appBar: CommonAppBar(navigationShell: navigationShell),
      body: navigationShell,
      bottomNavigationBar: CommonBottomNavBar(navigationShell: navigationShell),
    );
  }
}
