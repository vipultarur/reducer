import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';

class CommonBottomNavBar extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const CommonBottomNavBar({
    super.key,
    required this.navigationShell,
  });

  void _onTap(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: navigationShell.currentIndex,
      onDestinationSelected: _onTap,
      destinations: const [
        NavigationDestination(
          icon: Icon(Iconsax.home_1),
          selectedIcon: Icon(Iconsax.home5),
          label: 'Home',
        ),
        NavigationDestination(
          icon: Icon(Iconsax.edit),
          selectedIcon: Icon(Iconsax.edit5),
          label: 'Editor',
        ),
        NavigationDestination(
          icon: Icon(Iconsax.gallery),
          selectedIcon: Icon(Iconsax.gallery5),
          label: 'History',
        ),
        NavigationDestination(
          icon: Icon(Iconsax.crown),
          selectedIcon: Icon(Iconsax.crown5),
          label: 'Premium',
        ),
        NavigationDestination(
          icon: Icon(Iconsax.user),
          selectedIcon: Icon(Iconsax.user),
          label: 'Profile',
        ),
      ],
    );
  }
}
