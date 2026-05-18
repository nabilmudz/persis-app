import 'package:flutter/material.dart';
import 'package:persis_app/app/routes.dart';

class RoleBottomNavigationBar extends StatelessWidget {
  final String currentRoute;
  final String? activeRoute;
  final String homeRoute;
  final String profileRoute;
  final String homeLabel;
  final String profileLabel;
  final IconData homeIcon;
  final IconData profileIcon;

  const RoleBottomNavigationBar({
    super.key,
    required this.currentRoute,
    this.activeRoute,
    required this.homeRoute,
    this.profileRoute = AppRoutes.profile,
    this.homeLabel = 'Beranda',
    this.profileLabel = 'Profil',
    this.homeIcon = Icons.home_rounded,
    this.profileIcon = Icons.person_rounded,
  });

  String get _selectedRoute => activeRoute ?? currentRoute;

  bool get _isHomeSelected => _selectedRoute == homeRoute;

  bool get _isProfileSelected => _selectedRoute == profileRoute;

  void _navigateTo(BuildContext context, String route) {
    if (route == currentRoute) {
      return;
    }

    Navigator.of(context).pushNamedAndRemoveUntil(route, (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final width = size.width;
    final barHeight = (width * 0.20).clamp(72.0, 92.0).toDouble();
    final iconSize = (width * 0.075).clamp(24.0, 30.0).toDouble();
    final labelSize = (width * 0.028).clamp(11.0, 13.0).toDouble();

    return SafeArea(
      top: false,
      child: Container(
        height: barHeight,
        width: double.infinity,
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Color(0x19000000),
              blurRadius: 15,
              offset: Offset(0, -2),
              spreadRadius: 0,
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: _NavItem(
                label: homeLabel,
                icon: homeIcon,
                isSelected: _isHomeSelected,
                selectedColor: const Color(0xFF189D4A),
                unselectedColor: const Color(0xFFACACAC),
                iconSize: iconSize,
                labelSize: labelSize,
                onTap: () => _navigateTo(context, homeRoute),
              ),
            ),
            Expanded(
              child: _NavItem(
                label: profileLabel,
                icon: profileIcon,
                isSelected: _isProfileSelected,
                selectedColor: const Color(0xFF189D4A),
                unselectedColor: const Color(0xFFACACAC),
                iconSize: iconSize,
                labelSize: labelSize,
                onTap: () => _navigateTo(context, profileRoute),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final Color selectedColor;
  final Color unselectedColor;
  final double iconSize;
  final double labelSize;
  final VoidCallback onTap;

  const _NavItem({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.selectedColor,
    required this.unselectedColor,
    required this.iconSize,
    required this.labelSize,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isSelected ? selectedColor : unselectedColor;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                width: iconSize + 12,
                height: iconSize + 12,
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFFE8F7EE)
                      : Colors.transparent,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: iconSize, color: color),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: color,
                  fontSize: labelSize,
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
