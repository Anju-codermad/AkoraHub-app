import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Navigation item configuration for the bottom navigation bar
class CustomBottomBarItem {
  final String route;
  final IconData icon;
  final IconData? activeIcon;
  final String label;
  final int? badgeCount;

  const CustomBottomBarItem({
    required this.route,
    required this.icon,
    this.activeIcon,
    required this.label,
    this.badgeCount,
  });
}

/// Custom bottom navigation bar widget for professional multi-business super-app
/// Implements thumb-accessible navigation with contextual overflow
///
/// Features:
/// - Material 3 design with adaptive platform behavior
/// - Badge notifications for important updates
/// - Haptic feedback on navigation
/// - Smooth transitions with 200ms animations
/// - Minimum 48dp touch targets for accessibility
class CustomBottomBar extends StatefulWidget {
  /// Current active route path
  final String currentRoute;

  /// Callback when navigation item is tapped
  final Function(String route) onNavigate;

  /// Optional badge counts for navigation items
  final Map<String, int>? badgeCounts;

  /// Whether to show labels for all items (default: true)
  final bool showLabels;

  /// Custom elevation (default: 4.0)
  final double elevation;

  const CustomBottomBar({
    super.key,
    required this.currentRoute,
    required this.onNavigate,
    this.badgeCounts,
    this.showLabels = true,
    this.elevation = 4.0,
  });

  @override
  State<CustomBottomBar> createState() => _CustomBottomBarState();
}

class _CustomBottomBarState extends State<CustomBottomBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  // Primary navigation items based on Mobile Navigation Hierarchy
  static const List<CustomBottomBarItem> _navigationItems = [
    CustomBottomBarItem(
      route: '/business-dashboard',
      icon: Icons.dashboard_outlined,
      activeIcon: Icons.dashboard,
      label: 'Dashboard',
    ),
    CustomBottomBarItem(
      route: '/product-catalog-management',
      icon: Icons.inventory_2_outlined,
      activeIcon: Icons.inventory_2,
      label: 'Products',
    ),
    CustomBottomBarItem(
      route: '/customer-management',
      icon: Icons.people_outline,
      activeIcon: Icons.people,
      label: 'Customers',
    ),
    CustomBottomBarItem(
      route: '/analytics-dashboard',
      icon: Icons.analytics_outlined,
      activeIcon: Icons.analytics,
      label: 'Analytics',
    ),
    CustomBottomBarItem(
      route: '/business-profile-settings',
      icon: Icons.more_horiz,
      activeIcon: Icons.more_horiz,
      label: 'More',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  int _getCurrentIndex() {
    for (int i = 0; i < _navigationItems.length; i++) {
      if (_navigationItems[i].route == widget.currentRoute) {
        return i;
      }
    }
    return 0;
  }

  void _handleNavigation(int index) {
    if (index == _getCurrentIndex()) return;

    // Haptic feedback for navigation
    HapticFeedback.selectionClick();

    // Trigger scale animation
    _animationController.forward(from: 0.0);

    // Navigate to selected route
    widget.onNavigate(_navigationItems[index].route);
  }

  Widget _buildBadge(int count) {
    return Positioned(
      right: 0,
      top: 0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.error,
          borderRadius: BorderRadius.circular(10),
        ),
        constraints: const BoxConstraints(
          minWidth: 18,
          minHeight: 18,
        ),
        child: Text(
          count > 99 ? '99+' : count.toString(),
          style: TextStyle(
            color: Theme.of(context).colorScheme.onError,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentIndex = _getCurrentIndex();

    return Container(
      decoration: BoxDecoration(
        color: theme.navigationBarTheme.backgroundColor ??
            theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.1),
            blurRadius: widget.elevation * 2,
            offset: Offset(0, -widget.elevation / 2),
          ),
        ],
      ),
      child: SafeArea(
        child: Container(
          height: 80,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(_navigationItems.length, (index) {
              final item = _navigationItems[index];
              final isSelected = index == currentIndex;
              final badgeCount = widget.badgeCounts?[item.route];

              return Expanded(
                child: ScaleTransition(
                  scale: isSelected
                      ? _scaleAnimation
                      : const AlwaysStoppedAnimation(1.0),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _handleNavigation(index),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Icon with badge
                            SizedBox(
                              height: 32,
                              child: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    curve: Curves.easeOut,
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? theme.colorScheme.primary
                                              .withValues(alpha: 0.12)
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      isSelected && item.activeIcon != null
                                          ? item.activeIcon
                                          : item.icon,
                                      size: 24,
                                      color: isSelected
                                          ? theme.colorScheme.primary
                                          : theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  if (badgeCount != null && badgeCount > 0)
                                    _buildBadge(badgeCount),
                                ],
                              ),
                            ),

                            // Label
                            if (widget.showLabels) ...[
                              const SizedBox(height: 4),
                              AnimatedDefaultTextStyle(
                                duration: const Duration(milliseconds: 200),
                                style: (isSelected
                                        ? theme
                                            .navigationBarTheme.labelTextStyle
                                            ?.resolve({WidgetState.selected})
                                        : theme
                                            .navigationBarTheme.labelTextStyle
                                            ?.resolve({})) ??
                                    TextStyle(
                                      fontSize: 12,
                                      fontWeight: isSelected
                                          ? FontWeight.w500
                                          : FontWeight.w400,
                                      color: isSelected
                                          ? theme.colorScheme.primary
                                          : theme.colorScheme.onSurfaceVariant,
                                      letterSpacing: 0.4,
                                    ),
                                child: Text(
                                  item.label,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
