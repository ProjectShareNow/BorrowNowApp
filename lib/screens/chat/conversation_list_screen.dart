import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../app/routes.dart';
import '../../app/app_config.dart';
import '../../utils/helpers.dart';
import '../../widgets/user_avatar.dart';
import '../../widgets/empty_state.dart';

class ConversationListScreen extends StatefulWidget {
  const ConversationListScreen({super.key});

  @override
  State<ConversationListScreen> createState() => _ConversationListScreenState();
}

class _ConversationListScreenState extends State<ConversationListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadChats();
    });
  }

  void _loadChats() {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.currentUser != null) {
      Provider.of<ChatProvider>(
        context,
        listen: false,
      ).listenToUserChats(auth.currentUser!.uid);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final chatProvider = Provider.of<ChatProvider>(context);
    final currentUserId = authProvider.currentUser?.uid ?? '';

    // Filter accepted conversations where current user is an active participant
    final chats = chatProvider.chats.where((chat) {
      return chat.isUserParticipant(currentUserId) && !chat.isClosed;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Chats',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
          ),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline_rounded, color: Color(0xFF1E293B)),
            tooltip: 'My Profile',
            onPressed: () {
              AppConfig.log('[BorrowNow] Profile icon tapped from Chats tab');
              Navigator.pushNamed(context, AppRoutes.profile);
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          _loadChats();
        },
        child: chats.isEmpty
            ? const Center(
                child: SingleChildScrollView(
                  physics: AlwaysScrollableScrollPhysics(),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                    child: EmptyState(
                      icon: Icons.chat_bubble_outline_rounded,
                      title: 'No chats yet',
                      description:
                          'Your accepted borrowing conversations will appear here.',
                    ),
                  ),
                ),
              )
            : ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                itemCount: chats.length,
                separatorBuilder: (ctx, i) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final chat = chats[index];
                  final isBorrower = chat.borrowerId == currentUserId;
                  final otherUserName = chat.getOtherUserName(currentUserId);
                  final otherUserRole = isBorrower ? 'Lender' : 'Borrower';
                  final unread = chat.getUnreadCount(currentUserId);

                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: unread > 0
                            ? const Color(0xFFBFDBFE)
                            : const Color(0xFFE2E8F0),
                        width: unread > 0 ? 1.4 : 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: unread > 0
                              ? const Color(0xFF2563EB).withValues(alpha: 0.05)
                              : Colors.black.withValues(alpha: 0.03),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                      child: InkWell(
                        onTap: () {
                          AppConfig.log('[BorrowNow] Chat tapped: ${chat.id}');
                          Navigator.pushNamed(
                            context,
                            AppRoutes.chat,
                            arguments: chat.id,
                          );
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Avatar with unread badge dot
                              Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  UserAvatar(
                                    name: otherUserName,
                                    radius: 24,
                                  ),
                                  if (unread > 0)
                                    Positioned(
                                      top: -2,
                                      right: -2,
                                      child: Container(
                                        width: 12,
                                        height: 12,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF2563EB),
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: Colors.white,
                                            width: 2,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(width: 12),

                              // Chat details
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Row: Name, Role Pill & Timestamp
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Row(
                                            children: [
                                              Flexible(
                                                child: Text(
                                                  otherUserName,
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                    fontWeight: unread > 0
                                                        ? FontWeight.bold
                                                        : FontWeight.w600,
                                                    fontSize: 14,
                                                    color:
                                                        const Color(0xFF0F172A),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 6),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 6,
                                                  vertical: 2,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: isBorrower
                                                      ? const Color(0xFFEFF6FF)
                                                      : const Color(0xFFF0FDF4),
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                  border: Border.all(
                                                    color: isBorrower
                                                        ? const Color(
                                                            0xFFBFDBFE)
                                                        : const Color(
                                                            0xFFBBF7D0),
                                                  ),
                                                ),
                                                child: Text(
                                                  otherUserRole,
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w600,
                                                    color: isBorrower
                                                        ? const Color(
                                                            0xFF1E40AF)
                                                        : const Color(
                                                            0xFF166534),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          AppHelpers.formatRelativeTime(
                                            chat.lastMessageTime,
                                          ),
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: unread > 0
                                                ? const Color(0xFF2563EB)
                                                : const Color(0xFF94A3B8),
                                            fontWeight: unread > 0
                                                ? FontWeight.w600
                                                : FontWeight.normal,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),

                                    // Item pill
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.inventory_2_outlined,
                                          size: 12,
                                          color: Colors.grey.shade500,
                                        ),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            chat.itemName,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w500,
                                              color: Colors.blue.shade700,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),

                                    // Latest message snippet + unread count badge
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            chat.lastMessage.isNotEmpty
                                                ? chat.lastMessage
                                                : 'Tap to coordinate handover',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: unread > 0
                                                  ? const Color(0xFF0F172A)
                                                  : const Color(0xFF64748B),
                                              fontWeight: unread > 0
                                                  ? FontWeight.w600
                                                  : FontWeight.normal,
                                            ),
                                          ),
                                        ),
                                        if (unread > 0) ...[
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 7,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF2563EB),
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            child: Text(
                                              '$unread',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
