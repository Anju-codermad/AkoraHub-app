import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// App bar variant types for different screen contexts
enum CustomAppBarVariant {
  /// Standard app bar with back button and title
  standard,

  /// Search-focused app bar with expandable search field
  search,

  /// Dashboard app bar with profile and notifications
  dashboard,

  /// Detail screen app bar with share and favorite actions
  detail,

  /// Settings app bar with minimal actions
  settings,
}

/// Custom app bar widget for professional multi-business super-app
/// Implements Material 3 design with contextual actions
///
/// Features:
/// - Multiple variants for different screen contexts
/// - Smooth transitions and animations
/// - Badge notifications for action items
/// - Haptic feedback on interactions
/// - Accessibility support with semantic labels
class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  /// App bar variant type
  final CustomAppBarVariant variant;

  /// Title text (optional for some variants)
  final String? title;

  /// Subtitle text (optional)
  final String? subtitle;

  /// Leading widget override (replaces default back button)
  final Widget? leading;

  /// Custom actions (variant-specific defaults if null)
  final List<Widget>? actions;

  /// Whether to show back button (default: true)
  final bool showBackButton;

  /// Callback for back button press
  final VoidCallback? onBackPressed;

  /// Search query callback (for search variant)
  final Function(String)? onSearch;

  /// Search hint text (for search variant)
  final String? searchHint;

  /// Badge count for notification icon
  final int? notificationBadgeCount;

  /// Custom elevation (default: 1.0)
  final double elevation;

  /// Whether to center the title (default: false)
  final bool centerTitle;

  const CustomAppBar({
    super.key,
    this.variant = CustomAppBarVariant.standard,
    this.title,
    this.subtitle,
    this.leading,
    this.actions,
    this.showBackButton = true,
    this.onBackPressed,
    this.onSearch,
    this.searchHint,
    this.notificationBadgeCount,
    this.elevation = 1.0,
    this.centerTitle = false,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  Widget _buildLeading(BuildContext context) {
    if (leading != null) return leading!;

    if (showBackButton && Navigator.of(context).canPop()) {
      return IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () {
          HapticFeedback.selectionClick();
          if (onBackPressed != null) {
            onBackPressed!();
          } else {
            Navigator.of(context).pop();
          }
        },
        tooltip: 'Back',
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildTitle(BuildContext context) {
    if (title == null) return const SizedBox.shrink();

    final theme = Theme.of(context);

    if (subtitle != null) {
      return Column(
        crossAxisAlignment:
            centerTitle ? CrossAxisAlignment.center : CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title!,
            style: theme.appBarTheme.titleTextStyle,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            subtitle!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      );
    }

    return Text(
      title!,
      style: theme.appBarTheme.titleTextStyle,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildBadge(BuildContext context, int count) {
    return Positioned(
      right: 8,
      top: 8,
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

  List<Widget> _buildActions(BuildContext context) {
    if (actions != null) return actions!;

    switch (variant) {
      case CustomAppBarVariant.dashboard:
        return [
          IconButton(
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.notifications_outlined),
                if (notificationBadgeCount != null &&
                    notificationBadgeCount! > 0)
                  _buildBadge(context, notificationBadgeCount!),
              ],
            ),
            onPressed: () {
              HapticFeedback.selectionClick();
              Navigator.pushNamed(context, '/messaging-center');
            },
            tooltip: 'Notifications',
          ),
          IconButton(
            icon: const Icon(Icons.account_circle_outlined),
            onPressed: () {
              HapticFeedback.selectionClick();
              Navigator.pushNamed(context, '/business-profile-settings');
            },
            tooltip: 'Profile',
          ),
        ];

      case CustomAppBarVariant.detail:
        return [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () {
              HapticFeedback.selectionClick();
              // Share functionality
            },
            tooltip: 'Share',
          ),
          IconButton(
            icon: const Icon(Icons.favorite_border),
            onPressed: () {
              HapticFeedback.selectionClick();
              // Favorite functionality
            },
            tooltip: 'Favorite',
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              HapticFeedback.selectionClick();
              // More options
            },
            tooltip: 'More options',
          ),
        ];

      case CustomAppBarVariant.search:
        return [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              HapticFeedback.selectionClick();
              // Filter functionality
            },
            tooltip: 'Filter',
          ),
        ];

      case CustomAppBarVariant.settings:
        return [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () {
              HapticFeedback.selectionClick();
              // Help functionality
            },
            tooltip: 'Help',
          ),
        ];

      default:
        return [];
    }
  }

  Widget _buildSearchBar(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      height: 48,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: TextField(
        onChanged: onSearch,
        decoration: InputDecoration(
          hintText: searchHint ?? 'Search...',
          prefixIcon: const Icon(Icons.search, size: 20),
          suffixIcon: IconButton(
            icon: const Icon(Icons.mic_outlined, size: 20),
            onPressed: () {
              HapticFeedback.selectionClick();
              // Voice search functionality
            },
            tooltip: 'Voice search',
          ),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        style: theme.textTheme.bodyMedium,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (variant == CustomAppBarVariant.search) {
      return AppBar(
        backgroundColor: theme.appBarTheme.backgroundColor,
        foregroundColor: theme.appBarTheme.foregroundColor,
        elevation: elevation,
        shadowColor: theme.appBarTheme.shadowColor,
        leading: _buildLeading(context),
        title: _buildSearchBar(context),
        actions: _buildActions(context),
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: theme.brightness == Brightness.light
              ? Brightness.dark
              : Brightness.light,
        ),
      );
    }

    return AppBar(
      backgroundColor: theme.appBarTheme.backgroundColor,
      foregroundColor: theme.appBarTheme.foregroundColor,
      elevation: elevation,
      shadowColor: theme.appBarTheme.shadowColor,
      centerTitle: centerTitle,
      leading: _buildLeading(context),
      title: _buildTitle(context),
      actions: _buildActions(context),
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: theme.brightness == Brightness.light
            ? Brightness.dark
            : Brightness.light,
      ),
    );
  }
}
