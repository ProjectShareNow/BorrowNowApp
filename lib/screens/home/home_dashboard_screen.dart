import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/service_registry.dart';
import '../../providers/auth_provider.dart';
import '../../providers/request_provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/chat_provider.dart';
import '../../models/borrow_request_model.dart';
import '../../models/chat_model.dart';
import '../../app/app_config.dart';
import '../../app/routes.dart';
import '../../utils/helpers.dart';
import '../../widgets/user_avatar.dart';
import '../../widgets/status_chip.dart';

class HomeDashboardScreen extends StatefulWidget {
  final Function(int) onNavigateTab;

  const HomeDashboardScreen({super.key, required this.onNavigateTab});

  @override
  State<HomeDashboardScreen> createState() => _HomeDashboardScreenState();
}

class _HomeDashboardScreenState extends State<HomeDashboardScreen> {
  final Set<String> _helpingRequestIds = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      if (auth.currentUser != null) {
        final uid = auth.currentUser!.uid;
        Provider.of<RequestProvider>(context, listen: false)
            .listenToCampusRequests(uid);
        Provider.of<RequestProvider>(context, listen: false)
            .listenToUserRequests(uid);
        Provider.of<ChatProvider>(context, listen: false)
            .listenToUserChats(uid);
      }
    });
  }

  String _getGreeting(String? fullName) {
    final hour = DateTime.now().hour;
    final timeGreeting = hour < 12
        ? 'Good morning'
        : (hour < 17 ? 'Good afternoon' : 'Good evening');

    final firstName = (fullName != null && fullName.trim().isNotEmpty)
        ? fullName.trim().split(' ').first
        : 'Student';

    return '$timeGreeting, $firstName';
  }

  Future<void> _handleOfferHelp(BorrowRequestModel request) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.currentUser;
    if (user == null) {
      AppHelpers.showSnackBar(
        context,
        'Please sign in to offer help.',
        isError: true,
      );
      return;
    }

    if (request.isCompleted ||
        request.status == 'closed' ||
        request.status == 'cancelled') {
      AppHelpers.showSnackBar(
        context,
        'This request is no longer active.',
        isError: true,
      );
      return;
    }

    if (request.borrowerId == user.uid) {
      AppHelpers.showSnackBar(
        context,
        'You cannot offer help on your own request.',
        isError: true,
      );
      return;
    }

    if (request.acceptedHelperId != null &&
        request.acceptedHelperId != user.uid) {
      AppHelpers.showSnackBar(
        context,
        'Another helper has already been selected for this request.',
        isError: true,
      );
      return;
    }

    if (request.helperIds.contains(user.uid)) {
      AppHelpers.showSnackBar(
        context,
        'You have already offered help for this request.',
      );
      return;
    }

    if (request.rejectedHelperIds.contains(user.uid)) {
      AppHelpers.showSnackBar(
        context,
        'Your offer for this request was not accepted.',
        isError: true,
      );
      return;
    }

    if (_helpingRequestIds.contains(request.id)) {
      return;
    }

    final confirm = await AppHelpers.showConfirmDialog(
      context: context,
      title: 'Offer Help',
      message:
          'Do you have "${request.itemName}" available to lend to ${request.borrowerName}?',
      confirmLabel: 'I Can Help',
    );

    if (!confirm || !mounted) return;

    setState(() {
      _helpingRequestIds.add(request.id);
    });

    final requestProvider = Provider.of<RequestProvider>(
      context,
      listen: false,
    );
    final success = await requestProvider.offerHelp(
      requestId: request.id,
      helperUser: user,
    );

    if (!mounted) return;

    setState(() {
      _helpingRequestIds.remove(request.id);
    });

    if (success) {
      AppHelpers.showSnackBar(
        context,
        'Your offer to help has been sent to ${request.borrowerName}!',
        isSuccess: true,
      );
      Navigator.pushNamed(context, AppRoutes.myRequests);
    } else {
      AppHelpers.showSnackBar(
        context,
        requestProvider.errorMessage ?? 'Unable to send help offer.',
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final requestProvider = Provider.of<RequestProvider>(context);
    final notifProvider = Provider.of<NotificationProvider>(context);
    final chatProvider = Provider.of<ChatProvider>(context);

    final user = authProvider.currentUser;
    final currentUserId = user?.uid ?? '';

    // Filter campus requests: exclude own requests and only show active
    final campusRequests = requestProvider.campusRequests.where((req) {
      final isOwn = req.borrowerId == currentUserId;
      final isActive = req.status.toLowerCase() != 'cancelled' &&
          req.status.toLowerCase() != 'returned' &&
          req.status.toLowerCase() != 'completed';
      return !isOwn && isActive;
    }).toList();

    final activeCount = campusRequests.length;

    // Filter user chats: only accepted requests / conversations where current user is participant
    final eligibleChats = chatProvider.chats.where((chat) {
      final isParticipant = chat.isUserParticipant(currentUserId);
      final isNotClosed = !chat.isClosed;
      return isParticipant && isNotClosed;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      body: SafeArea(
        child: RefreshIndicator(
          color: const Color(0xFF2563EB),
          backgroundColor: Colors.white,
          onRefresh: () async {
            if (user != null) {
              requestProvider.listenToCampusRequests(user.uid);
              requestProvider.listenToUserRequests(user.uid);
              notifProvider.listenToUserNotifications(user.uid);
              chatProvider.listenToUserChats(user.uid);
            }
            await Future.delayed(const Duration(milliseconds: 500));
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. TOP APP BAR / BRANDING
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'BorrowNow',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.3,
                            color: Color(0xFF111827),
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Campus Item Borrowing',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        // Notification Icon with unread badge
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            IconButton(
                              onPressed: () {
                                AppConfig.log('[BorrowNow] Notification icon tapped');
                                widget.onNavigateTab(3);
                              },
                              icon: const Icon(
                                Icons.notifications_outlined,
                                color: Color(0xFF1E293B),
                                size: 24,
                              ),
                              tooltip: 'Notifications',
                            ),
                            if (notifProvider.unreadCount > 0)
                              Positioned(
                                top: 6,
                                right: 6,
                                child: Container(
                                  padding: const EdgeInsets.all(3),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFDC2626),
                                    shape: BoxShape.circle,
                                  ),
                                  constraints: const BoxConstraints(
                                    minWidth: 14,
                                    minHeight: 14,
                                  ),
                                  child: Text(
                                    notifProvider.unreadCount > 9
                                        ? '9+'
                                        : '${notifProvider.unreadCount}',
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
                        const SizedBox(width: 4),
                        // Profile Avatar
                        InkWell(
                          onTap: () {
                            AppConfig.log('[BorrowNow] Profile avatar tapped');
                            Navigator.pushNamed(context, AppRoutes.profile);
                          },
                          borderRadius: BorderRadius.circular(20),
                          child: UserAvatar(
                            name: user?.fullName ?? 'Student',
                            radius: 18,
                            rating: user?.ratingAverage,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Greeting & Subtitle (Dynamic based on time, NO emojis)
                Text(
                  _getGreeting(user?.fullName),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Find what you need from your campus community.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 20),

                // 2. REQUEST HERO CARD (Light Themed)
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFFE2E8F0),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEFF6FF),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.search_rounded,
                                color: Color(0xFF2563EB),
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Text(
                              'Need an Item?',
                              style: TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF111827),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Can\'t find what you need? Post a request and let other verified campus members help.',
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.45,
                            color: Color(0xFF475569),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Container(
                          width: double.infinity,
                          height: 48,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFF2563EB),
                                Color(0xFF4F46E5),
                              ],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF2563EB).withValues(alpha: 0.25),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                AppConfig.log('[BorrowNow] Request button tapped');
                                Navigator.pushNamed(
                                  context,
                                  AppRoutes.borrowRequestForm,
                                );
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: Center(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: const [
                                    Icon(
                                      Icons.add_rounded,
                                      size: 20,
                                      color: Colors.white,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      '+ Request an Item',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 26),

                // 3. CAMPUS REQUESTS SECTION HEADER
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Campus Requests',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF111827),
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Students looking for items on campus',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (activeCount > 0) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFFBFDBFE),
                          ),
                        ),
                        child: Text(
                          '$activeCount Active ${activeCount == 1 ? 'Request' : 'Requests'}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2563EB),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 14),

                // Campus requests feed from Firestore
                if (requestProvider.errorMessage != null && campusRequests.isEmpty) ...[
                  _buildErrorState(context, requestProvider, currentUserId),
                ] else if (requestProvider.isLoading && campusRequests.isEmpty) ...[
                  _buildLoadingSkeleton(),
                ] else if (campusRequests.isEmpty) ...[
                  _buildEmptyCampusRequests(context),
                ] else ...[
                  ...campusRequests.map((req) {
                    return _buildCampusRequestCard(
                      context,
                      request: req,
                      currentUserId: currentUserId,
                    );
                  }),
                ],
                const SizedBox(height: 28),

                // 4. CHATS SECTION
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Chats',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF111827),
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Accepted requests and active conversations',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (eligibleChats.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFFBFDBFE),
                          ),
                        ),
                        child: Text(
                          '${eligibleChats.length} Active',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2563EB),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 14),

                // Chats list or empty state
                if (eligibleChats.isEmpty) ...[
                  _buildEmptyHomeChats(context),
                ] else ...[
                  ...eligibleChats.map((chat) {
                    return _buildHomeChatCard(
                      context,
                      chat: chat,
                      currentUserId: currentUserId,
                    );
                  }),
                ],
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCampusRequestCard(
    BuildContext context, {
    required BorrowRequestModel request,
    required String currentUserId,
  }) {
    final status = request.status;
    final needUntilText = AppHelpers.formatNeedUntil(
      request.requiredDate,
      request.requiredTime.isNotEmpty ? request.requiredTime : null,
    );
    final isOfferingThis = _helpingRequestIds.contains(request.id);
    final hasImage = request.itemPhotoUrl.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Requester Name, Department/ID, Status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      UserAvatar(
                        name: request.borrowerName,
                        imageUrl: request.borrowerPhotoUrl,
                        radius: 18,
                        rating: request.borrowerRating,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              request.borrowerName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF111827),
                              ),
                            ),
                            if (request.borrowerDepartment.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                request.borrowerDepartment,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                StatusChip(status: status),
              ],
            ),
            const SizedBox(height: 14),

            // Item Image (if available) with rounded corners & fallback placeholder
            if (hasImage) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  height: 160,
                  width: double.infinity,
                  child: Image.network(
                    request.itemPhotoUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 120,
                        color: const Color(0xFFF1F5F9),
                        child: const Center(
                          child: Icon(
                            Icons.inventory_2_outlined,
                            size: 40,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                      );
                    },
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        height: 140,
                        color: const Color(0xFFF1F5F9),
                        child: const Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFF2563EB),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Requesting Item Label & Item Name
            const Text(
              'Requesting Item:',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFF64748B),
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              request.itemName,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 10),

            // Details: Pickup Location & Need Until
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.place_outlined,
                        size: 16,
                        color: Color(0xFF2563EB),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Pickup: ',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          request.pickupLocation.isNotEmpty
                              ? request.pickupLocation
                              : 'College Library',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF111827),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (needUntilText.isNotEmpty && needUntilText != 'N/A') ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.access_time_rounded,
                          size: 16,
                          color: Color(0xFF2563EB),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Need Until: ',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            needUntilText,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF111827),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            // Note (if present)
            if (request.message != null && request.message!.trim().isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFFDBEAFE),
                  ),
                ),
                child: Text(
                  '"${request.message!.trim()}"',
                  style: const TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: Color(0xFF1E40AF),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 14),
            const Divider(color: Color(0xFFE2E8F0), height: 1),
            const SizedBox(height: 12),

            // Bottom Action with Single Accepted Helper Locking
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  AppHelpers.formatRelativeTime(request.createdAt),
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF94A3B8),
                  ),
                ),
                _buildHelperActionButton(
                  request: request,
                  currentUserId: currentUserId,
                  isOfferingThis: isOfferingThis,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHelperActionButton({
    required BorrowRequestModel request,
    required String currentUserId,
    required bool isOfferingThis,
  }) {
    if (request.isCompleted) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: const Text(
          'Request Completed',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Color(0xFF94A3B8),
          ),
        ),
      );
    }

    // STATE: CURRENT USER IS THE BORROWER / REQUESTER
    if (request.borrowerId == currentUserId) {
      if (request.acceptedHelperId != null &&
          request.acceptedHelperId!.isNotEmpty) {
        return ElevatedButton.icon(
          onPressed: () async {
            final chatId = await ServiceRegistry.chatService.ensureChatForRequest(
              requestId: request.id,
              currentUserId: currentUserId,
            ) ?? request.effectiveChatId;
            if (mounted && chatId.isNotEmpty) {
              Navigator.pushNamed(context, AppRoutes.chat, arguments: chatId);
            }
          },
          icon: const Icon(Icons.chat_bubble_outline_rounded, size: 16),
          label: const Text(
            'Open Chat',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2563EB),
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
      return OutlinedButton.icon(
        onPressed: () => Navigator.pushNamed(context, AppRoutes.myRequests),
        icon: const Icon(Icons.person_outline_rounded, size: 16),
        label: Text(
          request.helpers.isNotEmpty
              ? 'Your Request (${request.helpers.length} offers)'
              : 'Your Request',
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF2563EB),
          side: const BorderSide(color: Color(0xFF93C5FD)),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }

    // STATE C: CURRENT USER IS ACCEPTED HELPER
    if (request.acceptedHelperId == currentUserId) {
      return ElevatedButton.icon(
        onPressed: () async {
          final chatId = await ServiceRegistry.chatService.ensureChatForRequest(
            requestId: request.id,
            currentUserId: currentUserId,
          ) ?? request.effectiveChatId;
          if (mounted && chatId.isNotEmpty) {
            Navigator.pushNamed(context, AppRoutes.chat, arguments: chatId);
          }
        },
        icon: const Icon(Icons.chat_bubble_outline_rounded, size: 16),
        label: const Text(
          'Selected Helper • Open Chat',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF16A34A),
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }

    // STATE D: SOMEONE ELSE IS ACCEPTED
    if (request.acceptedHelperId != null &&
        request.acceptedHelperId!.isNotEmpty &&
        request.acceptedHelperId != currentUserId) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.lock_outline_rounded, size: 14, color: Color(0xFF94A3B8)),
                SizedBox(width: 4),
                Text(
                  'Help Unavailable',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            'Another helper has been selected.',
            style: TextStyle(
              fontSize: 10,
              color: Color(0xFF94A3B8),
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      );
    }

    // STATE F: CURRENT USER WAS REJECTED
    if (request.rejectedHelperIds.contains(currentUserId)) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFFEE2E2),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFFCA5A5)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.cancel_outlined, size: 16, color: Color(0xFFDC2626)),
            SizedBox(width: 6),
            Text(
              'Offer Rejected',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Color(0xFFDC2626),
              ),
            ),
          ],
        ),
      );
    }

    // STATE B: CURRENT USER HAS OFFERED HELP
    if (request.helperIds.contains(currentUserId)) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFEFF6FF),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFBFDBFE)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.check_circle_outline_rounded, size: 16, color: Color(0xFF2563EB)),
            SizedBox(width: 6),
            Text(
              'Help Offered',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2563EB),
              ),
            ),
          ],
        ),
      );
    }

    // STATE A: AVAILABLE
    return ElevatedButton.icon(
      onPressed: isOfferingThis
          ? null
          : () {
              AppConfig.log('[BorrowNow] I Can Help tapped: ${request.id}');
              _handleOfferHelp(request);
            },
      icon: isOfferingThis
          ? const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : const Icon(Icons.volunteer_activism_rounded, size: 16),
      label: const Text(
        'I Can Help',
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        elevation: 0,
        minimumSize: const Size(110, 38),
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  Widget _buildEmptyCampusRequests(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.group_outlined,
              size: 32,
              color: Color(0xFF2563EB),
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'No Campus Requests',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'There are no active requests from other students right now.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pushNamed(context, AppRoutes.borrowRequestForm);
            },
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Request an Item'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingSkeleton() {
    return Column(
      children: List.generate(2, (index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          height: 140,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: const Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Color(0xFF2563EB),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildErrorState(
    BuildContext context,
    RequestProvider requestProvider,
    String currentUserId,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFCA5A5)),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: Color(0xFFDC2626),
            size: 32,
          ),
          const SizedBox(height: 10),
          const Text(
            'Unable to load campus requests.',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 14),
          ElevatedButton(
            onPressed: () {
              if (currentUserId.isNotEmpty) {
                requestProvider.listenToCampusRequests(currentUserId);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyHomeChats(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: Color(0xFFEFF6FF),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.chat_bubble_outline_rounded,
              size: 26,
              color: Color(0xFF2563EB),
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'No chats yet',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Your accepted borrowing conversations will appear here.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF64748B),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHomeChatCard(
    BuildContext context, {
    required ChatModel chat,
    required String currentUserId,
  }) {
    final isBorrower = chat.borrowerId == currentUserId;
    final otherUserName = chat.getOtherUserName(currentUserId);
    final otherUserRole = isBorrower ? 'Lender' : 'Borrower';
    final unread = chat.getUnreadCount(currentUserId);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: unread > 0 ? const Color(0xFFBFDBFE) : const Color(0xFFE2E8F0),
          width: unread > 0 ? 1.4 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: unread > 0
                ? const Color(0xFF2563EB).withValues(alpha: 0.05)
                : Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () {
            AppConfig.log('[BorrowNow] Home chat tapped: ${chat.id}');
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
                // Avatar with unread indicator dot
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
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 12),

                // Conversation Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name, Role & Timestamp
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                                      color: const Color(0xFF0F172A),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isBorrower
                                        ? const Color(0xFFEFF6FF)
                                        : const Color(0xFFF0FDF4),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                      color: isBorrower
                                          ? const Color(0xFFBFDBFE)
                                          : const Color(0xFFBBF7D0),
                                    ),
                                  ),
                                  child: Text(
                                    otherUserRole,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: isBorrower
                                          ? const Color(0xFF1E40AF)
                                          : const Color(0xFF166534),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            AppHelpers.formatRelativeTime(chat.lastMessageTime),
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

                      // Item name pill
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

                      // Latest Message preview and unread count badge
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
                                borderRadius: BorderRadius.circular(10),
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
  }
}
