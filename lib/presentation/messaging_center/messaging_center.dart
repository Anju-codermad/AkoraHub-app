import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/app_export.dart';
import '../../widgets/custom_icon_widget.dart';
import './widgets/channel_filter_widget.dart';
import './widgets/conversation_card_widget.dart';
import './widgets/customer_context_widget.dart';
import './widgets/quick_reply_sheet_widget.dart';

/// Messaging Center screen for managing customer communications
/// Consolidates WhatsApp, internal chat, and system messages
class MessagingCenter extends StatefulWidget {
  const MessagingCenter({super.key});

  @override
  State<MessagingCenter> createState() => _MessagingCenterState();
}

class _MessagingCenterState extends State<MessagingCenter> {
  String _selectedChannel = 'all';
  String _searchQuery = '';
  bool _showCustomerContext = false;
  Map<String, dynamic>? _selectedCustomer;
  final TextEditingController _searchController = TextEditingController();

  // Mock data for conversations
  final List<Map<String, dynamic>> _allConversations = [
    {
      'id': '1',
      'customerName': 'Marie Dubois',
      'customerPhoto':
          'https://img.rocket.new/generatedImages/rocket_gen_img_14da91c34-1763294780479.png',
      'customerPhotoLabel':
          'Professional photo of a woman with shoulder-length brown hair wearing a blue blazer',
      'lastMessage':
          'Bonjour, je suis intéressée par vos savons naturels. Avez-vous des échantillons disponibles?',
      'timestamp': '10:30 AM',
      'unreadCount': 2,
      'channel': 'whatsapp',
      'hasAttachment': false,
      'isMuted': false,
    },
    {
      'id': '2',
      'customerName': 'Jean Rakoto',
      'customerPhoto':
          'https://cdn.pixabay.com/photo/2015/03/04/22/35/avatar-659652_640.png',
      'customerPhotoLabel':
          'Headshot of a man with short black hair wearing a white shirt',
      'lastMessage': 'Misaotra tompoko! Ahoana ny vidiny ho an\'ny savony 10?',
      'timestamp': '9:45 AM',
      'unreadCount': 0,
      'channel': 'internal',
      'hasAttachment': false,
      'isMuted': false,
    },
    {
      'id': '3',
      'customerName': 'Sarah Johnson',
      'customerPhoto':
          'https://cdn.pixabay.com/photo/2015/03/04/22/35/avatar-659652_640.png',
      'customerPhotoLabel':
          'Portrait of a woman with curly blonde hair wearing a red top',
      'lastMessage':
          'Can you send me the product catalog? I\'m interested in bulk orders.',
      'timestamp': 'Yesterday',
      'unreadCount': 1,
      'channel': 'whatsapp',
      'hasAttachment': true,
      'isMuted': false,
    },
    {
      'id': '4',
      'customerName': 'Ahmed Hassan',
      'customerPhoto':
          'https://img.rocket.new/generatedImages/rocket_gen_img_1410644f5-1763295214845.png',
      'customerPhotoLabel':
          'Professional headshot of a man with short dark hair and beard wearing a navy suit',
      'lastMessage': 'شكراً لك. متى يمكنني استلام الطلب؟',
      'timestamp': 'Yesterday',
      'unreadCount': 0,
      'channel': 'internal',
      'hasAttachment': false,
      'isMuted': false,
    },
    {
      'id': '5',
      'customerName': 'System Notification',
      'customerPhoto':
          'https://ui-avatars.com/api/?name=System&background=4A90A4&color=fff',
      'customerPhotoLabel': 'System notification icon with blue background',
      'lastMessage':
          'New order #1234 received. Customer requested express delivery.',
      'timestamp': '2 days ago',
      'unreadCount': 0,
      'channel': 'system',
      'hasAttachment': false,
      'isMuted': false,
    },
    {
      'id': '6',
      'customerName': 'Claire Martin',
      'customerPhoto':
          'https://cdn.pixabay.com/photo/2015/03/04/22/35/avatar-659652_640.png',
      'customerPhotoLabel':
          'Photo of a woman with long dark hair wearing glasses and a green sweater',
      'lastMessage':
          'Merci pour votre réponse rapide! Je vais passer commande aujourd\'hui.',
      'timestamp': '3 days ago',
      'unreadCount': 0,
      'channel': 'whatsapp',
      'hasAttachment': false,
      'isMuted': true,
    },
    {
      'id': '7',
      'customerName': 'Rabe Andry',
      'customerPhoto':
          'https://cdn.pixabay.com/photo/2015/03/04/22/35/avatar-659652_640.png',
      'customerPhotoLabel':
          'Portrait of a man with short hair wearing a casual gray t-shirt',
      'lastMessage': 'Azafady, misy ve ny savony ho an\'ny hoditra maina?',
      'timestamp': '1 week ago',
      'unreadCount': 0,
      'channel': 'internal',
      'hasAttachment': false,
      'isMuted': false,
    },
  ];

  // Mock customer data for context sidebar
  final Map<String, dynamic> _mockCustomerData = {
    'name': 'Marie Dubois',
    'email': 'marie.dubois@email.com',
    'phone': '+33 6 12 34 56 78',
    'location': 'Paris, France',
    'photo':
        'https://img.rocket.new/generatedImages/rocket_gen_img_14da91c34-1763294780479.png',
    'photoLabel':
        'Professional photo of a woman with shoulder-length brown hair wearing a blue blazer',
    'totalOrders': 5,
    'totalSpent': 245.50,
    'favoriteProducts': ['Natural Soap', 'Lavender Soap', 'Shea Butter Soap'],
    'recentOrders': [
      {
        'product': 'Natural Soap Set',
        'date': 'Dec 5, 2025',
        'amount': 45.00,
      },
      {
        'product': 'Lavender Soap',
        'date': 'Nov 28, 2025',
        'amount': 15.50,
      },
      {
        'product': 'Shea Butter Soap',
        'date': 'Nov 20, 2025',
        'amount': 18.00,
      },
    ],
    'interactions': [
      {
        'type': 'message',
        'description': 'Inquired about natural soap ingredients',
        'date': 'Dec 8, 2025',
      },
      {
        'type': 'call',
        'description': 'Phone consultation about bulk orders',
        'date': 'Dec 1, 2025',
      },
      {
        'type': 'event',
        'description': 'Attended product demonstration event',
        'date': 'Nov 15, 2025',
      },
    ],
  };

  List<Map<String, dynamic>> get _filteredConversations {
    List<Map<String, dynamic>> filtered = _allConversations;

    // Filter by channel
    if (_selectedChannel != 'all') {
      filtered = filtered
          .where((conv) => conv['channel'] == _selectedChannel)
          .toList();
    }

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((conv) {
        final name = (conv['customerName'] as String).toLowerCase();
        final message = (conv['lastMessage'] as String).toLowerCase();
        final query = _searchQuery.toLowerCase();
        return name.contains(query) || message.contains(query);
      }).toList();
    }

    return filtered;
  }

  Map<String, int> get _channelCounts {
    return {
      'all':
          _allConversations.where((c) => (c['unreadCount'] as int) > 0).length,
      'whatsapp': _allConversations
          .where((c) =>
              c['channel'] == 'whatsapp' && (c['unreadCount'] as int) > 0)
          .length,
      'internal': _allConversations
          .where((c) =>
              c['channel'] == 'internal' && (c['unreadCount'] as int) > 0)
          .length,
      'system': _allConversations
          .where(
              (c) => c['channel'] == 'system' && (c['unreadCount'] as int) > 0)
          .length,
    };
  }

  int get _totalUnreadCount {
    return _allConversations.fold(
        0, (sum, conv) => sum + (conv['unreadCount'] as int));
  }

  void _handleQuickReply(Map<String, dynamic> conversation) {
    HapticFeedback.selectionClick();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => QuickReplySheetWidget(
        onReplySelected: (message) {
          // Send quick reply
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Quick reply sent: ${message.substring(0, 30)}...'),
              duration: const Duration(seconds: 2),
            ),
          );
        },
        businessType: 'soap',
      ),
    );
  }

  void _handleSettings(Map<String, dynamic> conversation) {
    HapticFeedback.selectionClick();
    showModalBottomSheet(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: CustomIconWidget(
                  iconName: 'archive',
                  size: 24,
                  color: theme.colorScheme.onSurface,
                ),
                title: const Text('Archive Conversation'),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Conversation archived')),
                  );
                },
              ),
              ListTile(
                leading: CustomIconWidget(
                  iconName: 'delete',
                  size: 24,
                  color: theme.colorScheme.error,
                ),
                title: Text(
                  'Delete Conversation',
                  style: TextStyle(color: theme.colorScheme.error),
                ),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Conversation deleted')),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _handleMute(Map<String, dynamic> conversation) {
    HapticFeedback.selectionClick();
    setState(() {
      conversation['isMuted'] = !(conversation['isMuted'] as bool);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          conversation['isMuted'] as bool
              ? 'Conversation muted'
              : 'Conversation unmuted',
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _openConversation(Map<String, dynamic> conversation) {
    HapticFeedback.selectionClick();
    // Mark as read
    setState(() {
      conversation['unreadCount'] = 0;
    });
    // Navigate to conversation detail (would be implemented separately)
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
            Text('Opening conversation with ${conversation['customerName']}'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showCustomerContextSidebar(Map<String, dynamic> conversation) {
    setState(() {
      _selectedCustomer = _mockCustomerData;
      _showCustomerContext = true;
    });
  }

  Future<void> _refreshConversations() async {
    HapticFeedback.selectionClick();
    // Simulate network refresh
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Messages synced'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: theme.appBarTheme.elevation,
        leading: IconButton(
          icon: CustomIconWidget(
            iconName: 'arrow_back',
            size: 24,
            color: theme.appBarTheme.foregroundColor ??
                theme.colorScheme.onSurface,
          ),
          onPressed: () {
            HapticFeedback.selectionClick();
            Navigator.pop(context);
          },
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Messages',
              style: theme.appBarTheme.titleTextStyle,
            ),
            if (_totalUnreadCount > 0)
              Text(
                '$_totalUnreadCount unread',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                CustomIconWidget(
                  iconName: 'campaign',
                  size: 24,
                  color: theme.appBarTheme.foregroundColor ??
                      theme.colorScheme.onSurface,
                ),
              ],
            ),
            onPressed: () {
              HapticFeedback.selectionClick();
              Navigator.pushNamed(context, '/campaign-management');
            },
            tooltip: 'Campaigns',
          ),
          IconButton(
            icon: CustomIconWidget(
              iconName: 'more_vert',
              size: 24,
              color: theme.appBarTheme.foregroundColor ??
                  theme.colorScheme.onSurface,
            ),
            onPressed: () {
              HapticFeedback.selectionClick();
              // Show more options
            },
            tooltip: 'More options',
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // Search bar
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  border: Border(
                    bottom: BorderSide(
                      color: theme.colorScheme.outline.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) => setState(() => _searchQuery = value),
                  decoration: InputDecoration(
                    hintText: 'Search conversations...',
                    prefixIcon: Padding(
                      padding: const EdgeInsets.all(12),
                      child: CustomIconWidget(
                        iconName: 'search',
                        size: 20,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: CustomIconWidget(
                              iconName: 'close',
                              size: 20,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: theme.colorScheme.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: theme.colorScheme.outline.withValues(alpha: 0.3),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: theme.colorScheme.outline.withValues(alpha: 0.3),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: theme.colorScheme.primary,
                        width: 2,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                  ),
                ),
              ),
              // Channel filter
              ChannelFilterWidget(
                selectedChannel: _selectedChannel,
                onChannelSelected: (channel) {
                  HapticFeedback.selectionClick();
                  setState(() => _selectedChannel = channel);
                },
                channelCounts: _channelCounts,
              ),
              // Conversations list
              Expanded(
                child: _filteredConversations.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CustomIconWidget(
                              iconName: 'inbox',
                              size: 64,
                              color: theme.colorScheme.onSurfaceVariant
                                  .withValues(alpha: 0.5),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _searchQuery.isNotEmpty
                                  ? 'No conversations found'
                                  : 'No messages yet',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _searchQuery.isNotEmpty
                                  ? 'Try a different search term'
                                  : 'Start a conversation with your customers',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _refreshConversations,
                        child: ListView.builder(
                          itemCount: _filteredConversations.length,
                          itemBuilder: (context, index) {
                            final conversation = _filteredConversations[index];
                            return ConversationCardWidget(
                              conversation: conversation,
                              onTap: () => _openConversation(conversation),
                              onQuickReply: () =>
                                  _handleQuickReply(conversation),
                              onSettings: () => _handleSettings(conversation),
                              onMute: () => _handleMute(conversation),
                            );
                          },
                        ),
                      ),
              ),
            ],
          ),
          // Customer context sidebar
          if (_showCustomerContext && _selectedCustomer != null)
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              child: CustomerContextWidget(
                customerData: _selectedCustomer!,
                onClose: () => setState(() => _showCustomerContext = false),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          HapticFeedback.selectionClick();
          // Start new conversation
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Start new conversation'),
              duration: Duration(seconds: 2),
            ),
          );
        },
        icon: CustomIconWidget(
          iconName: 'add',
          size: 24,
          color:
              theme.floatingActionButtonTheme.foregroundColor ?? Colors.white,
        ),
        label: const Text('New Message'),
      ),
    );
  }
}
