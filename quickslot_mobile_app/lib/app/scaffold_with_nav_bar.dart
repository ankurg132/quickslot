import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/theme/app_theme.dart';

class ScaffoldWithNavBar extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const ScaffoldWithNavBar({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
          border: const Border(
            top: BorderSide(color: AppTheme.borderColor, width: 1.0),
          ),
        ),
        child: SafeArea(
          top: false,
          child: Container(
            height: 80,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavBarItem(
                  icon: Icons.explore_outlined,
                  activeIcon: Icons.explore_rounded,
                  label: 'Explore',
                  isActive: navigationShell.currentIndex == 0,
                  onTap: () => _onTabSelected(0),
                ),
                _NavBarItem(
                  icon: Icons.calendar_today_rounded,
                  activeIcon: Icons.calendar_month_rounded,
                  label: 'Bookings',
                  isActive: navigationShell.currentIndex == 1,
                  onTap: () => _onTabSelected(1),
                ),
                _NavBarItem(
                  icon: Icons.person_outline_rounded,
                  activeIcon: Icons.person_rounded,
                  label: 'Profile',
                  isActive: navigationShell.currentIndex == 2,
                  onTap: () => _onTabSelected(2),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _onTabSelected(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }
}

class _NavBarItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavBarItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Colors matching user screenshot and AppTheme
    const activeGreenPill = Color(0xFF10B981); // Emerald Green
    const activeTextAndIcon = Color(0xFF006C49); // Lush Deep Green
    const inactiveTextAndIcon = Color(0xFF565E74); // Slate Gray

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Active pill container around the icon
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
              decoration: BoxDecoration(
                color: isActive ? activeGreenPill : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                isActive ? activeIcon : icon,
                color: isActive ? activeTextAndIcon : inactiveTextAndIcon,
                size: 24,
              ),
            ),
            const SizedBox(height: 4),
            // Text label below the icon
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                color: isActive ? activeTextAndIcon : inactiveTextAndIcon,
                fontFamily: 'Inter',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
