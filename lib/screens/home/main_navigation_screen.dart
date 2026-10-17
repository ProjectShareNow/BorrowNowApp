import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/app_config.dart';
import '../../providers/auth_provider.dart';
import '../../providers/request_provider.dart';
import '../../providers/item_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/chat_provider.dart';
import 'home_dashboard_screen.dart';
import '../items/my_listed_items_screen.dart';
import '../history/history_screen.dart';
import '../notifications/notifications_screen.dart';
import '../chat/conversation_list_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  final int initialIndex;

  const MainNavigationScreen({super.key, this.initialIndex = 0});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initUserStreams();
    });
  }

  void _initUserStreams() {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final user = auth.currentUser;
    if (user != null) {
      final uid = user.uid;
      Provider.of<RequestProvider>(context, listen: false)
          .listenToUserRequests(uid);
      Provider.of<RequestProvider>(context, listen: false)
          .listenToCampusRequests(uid);
      Provider.of<ItemProvider>(context, listen: false).listenToUserItems(uid);
      Provider.of<TransactionProvider>(context, listen: false)
          .listenToUserTransactions(uid);
      Provider.of<NotificationProvider>(context, listen: false)
          .listenToUserNotifications(uid);
      Provider.of<ChatProvider>(context, listen: false)
          .listenToUserChats(uid);
    }
  }

  void _onTabSelected(int index) {
    if (index >= 0 && index < 5) {
      const tabNames = ['Home', 'My Items', 'History', 'Notifications', 'Chat'];
      AppConfig.log('[BorrowNow] Bottom navigation tapped: ${tabNames[index]}');
      setState(() => _currentIndex = index);
    }
  }

  @override
  Widget build(BuildContext context) {
    final notifProvider = Provider.of<NotificationProvider>(context);
    final unreadCount = notifProvider.unreadCount;

    final authProvider = Provider.of<AuthProvider>(context);
    final chatProvider = Provider.of<ChatProvider>(context);
    final currentUserId = authProvider.currentUser?.uid ?? '';
    final chatUnreadCount = chatProvider.chats
        .where((c) => c.isUserParticipant(currentUserId) && !c.isClosed)
        .fold<int>(0, (acc, c) => acc + c.getUnreadCount(currentUserId));

    final List<Widget> pages = [
      HomeDashboardScreen(onNavigateTab: _onTabSelected),
      const MyListedItemsScreen(),
      const HistoryScreen(),
      const NotificationsScreen(),
      const ConversationListScreen(),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      bottomNavigationBar: Material(
        color: Colors.white,
        child: Container(
          decoration: const BoxDecoration(
            border: Border(
              top: BorderSide(
                color: Color(0xFFE2E8F0),
                width: 1,
              ),
            ),
          ),
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: 64,
              child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(
                  index: 0,
                  label: 'Home',
                  icon: Icons.home_outlined,
                  activeIcon: Icons.home_rounded,
                ),
                _buildNavItem(
                  index: 1,
                  label: 'My Items',
                  icon: Icons.inventory_2_outlined,
                  activeIcon: Icons.inventory_2_rounded,
                ),
                _buildNavItem(
                  index: 2,
                  label: 'History',
                  icon: Icons.history_rounded,
                  activeIcon: Icons.history_rounded,
                ),
                _buildNavItem(
                  index: 3,
                  label: 'Notifications',
                  icon: Icons.notifications_outlined,
                  activeIcon: Icons.notifications_rounded,
                  badgeCount: unreadCount,
                ),
                _buildNavItem(
                  index: 4,
                  label: 'Chat',
                  icon: Icons.chat_bubble_outline_rounded,
                  activeIcon: Icons.chat_bubble_rounded,
                  badgeCount: chatUnreadCount,
                ),
              ],
            ),
          ),
        ),
      ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required String label,
    required IconData icon,
    required IconData activeIcon,
    int badgeCount = 0,
  }) {
    final isSelected = _currentIndex == index;
    const activeColor = Color(0xFF2563EB); // Primary blue
    const inactiveColor = Color(0xFF64748B);

    return Expanded(
      child: InkWell(
        onTap: () => _onTabSelected(index),
        splashColor: activeColor.withValues(alpha: 0.1),
        highlightColor: Colors.transparent,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  isSelected ? activeIcon : icon,
                  color: isSelected ? activeColor : inactiveColor,
                  size: 24,
                ),
                if (badgeCount > 0)
                  Positioned(
                    top: -4,
                    right: -6,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        color: Color(0xFFEF4444),
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 15,
                        minHeight: 15,
                      ),
                      child: Text(
                        badgeCount > 9 ? '9+' : '$badgeCount',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? activeColor : inactiveColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
