import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/service_registry.dart';
import '../../providers/auth_provider.dart';
import '../../providers/request_provider.dart';
import '../../models/borrow_request_model.dart';
import '../../utils/helpers.dart';
import '../../app/routes.dart';
import '../../widgets/request_card.dart';
import '../../widgets/empty_state.dart';

class MyRequestsScreen extends StatefulWidget {
  const MyRequestsScreen({super.key});

  @override
  State<MyRequestsScreen> createState() => _MyRequestsScreenState();
}

class _MyRequestsScreenState extends State<MyRequestsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.currentUser != null) {
      Provider.of<RequestProvider>(
        context,
        listen: false,
      ).listenToUserRequests(auth.currentUser!.uid);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showRejectDialog(BorrowRequestModel request, String currentUserId) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Decline Request'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Please provide a brief reason for declining ${request.borrowerName}\'s request for "${request.itemName}".',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                hintText:
                    'e.g. Currently in personal use / Unavailable during that time',
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final reason = reasonController.text.trim().isNotEmpty
                  ? reasonController.text.trim()
                  : 'Item is unavailable during requested schedule.';
              Navigator.pop(ctx);

              final provider = Provider.of<RequestProvider>(
                context,
                listen: false,
              );
              final success = await provider.rejectRequest(
                request,
                reason,
                currentUserId,
              );
              if (mounted) {
                if (success) {
                  AppHelpers.showSnackBar(
                    context,
                    'Request declined.',
                    isSuccess: true,
                  );
                } else {
                  AppHelpers.showSnackBar(
                    context,
                    provider.errorMessage ?? 'Failed to decline request.',
                    isError: true,
                  );
                }
              }
            },
            child: const Text('Decline'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final requestProvider = Provider.of<RequestProvider>(context);
    final currentUserId = authProvider.currentUser?.uid ?? '';

    final sentRequests = requestProvider.myRequests;
    final incomingRequests = requestProvider.incomingRequests;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Borrow Requests'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Theme.of(context).primaryColor,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Theme.of(context).primaryColor,
          tabs: [
            Tab(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Sent Requests'),
                    if (sentRequests.any((r) => r.isApproved)) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: const BoxDecoration(
                          color: Color(0xFF10B981),
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '${sentRequests.where((r) => r.isApproved).length}',
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
              ),
            ),
            Tab(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Incoming Requests'),
                    if (requestProvider.pendingIncomingCount > 0) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: const BoxDecoration(
                          color: Color(0xFFEF4444),
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '${requestProvider.pendingIncomingCount}',
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
              ),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // 1. Sent Requests Tab
          sentRequests.isEmpty
              ? const EmptyState(
                  icon: Icons.outbox_rounded,
                  title: 'No Sent Requests',
                  description:
                      'You haven’t requested any items yet. Explore the campus catalog to borrow what you need!',
                )
              : ListView.builder(
                  padding: const EdgeInsets.only(top: 8, bottom: 24),
                  itemCount: sentRequests.length,
                  itemBuilder: (context, index) {
                    final req = sentRequests[index];
                    return RequestCard(
                      request: req,
                      isIncoming: false,
                      onOpenChat: () async {
                        final chatId = await ServiceRegistry.chatService.ensureChatForRequest(
                          requestId: req.id,
                          currentUserId: currentUserId,
                        ) ?? req.effectiveChatId;
                        if (context.mounted && chatId.isNotEmpty) {
                          Navigator.pushNamed(
                            context,
                            AppRoutes.chat,
                            arguments: chatId,
                          );
                        }
                      },
                      onAcceptHelper: (helperId, helperName) async {
                        final confirm = await AppHelpers.showConfirmDialog(
                          context: context,
                          title: 'Accept Helper?',
                          message:
                              'Accept $helperName as your helper for "${req.itemName}"? This will lock the request to this helper and start a private chat.',
                          confirmLabel: 'Accept Helper',
                        );
                        if (confirm && context.mounted) {
                          final chatId = await requestProvider.acceptHelper(
                            requestId: req.id,
                            requesterId: currentUserId,
                            helperId: helperId,
                            helperName: helperName,
                          );
                          if (context.mounted) {
                            if (chatId != null) {
                              AppHelpers.showSnackBar(
                                context,
                                '$helperName accepted as your helper! Opening chat...',
                                isSuccess: true,
                              );
                              Navigator.pushNamed(
                                context,
                                AppRoutes.chat,
                                arguments: chatId,
                              );
                            } else {
                              AppHelpers.showSnackBar(
                                context,
                                requestProvider.errorMessage ??
                                    'Failed to accept helper.',
                                isError: true,
                              );
                            }
                          }
                        }
                      },
                      onRemoveHelper: (helperId) async {
                        final confirm = await AppHelpers.showConfirmDialog(
                          context: context,
                          title: 'Remove Helper?',
                          message:
                              'Remove this helper? The request will become open again for other campus members to help.',
                          confirmLabel: 'Remove Helper',
                          isDestructive: true,
                        );
                        if (confirm && context.mounted) {
                          final success =
                              await requestProvider.removeAcceptedHelper(
                            requestId: req.id,
                            requesterId: currentUserId,
                            helperId: helperId,
                          );
                          if (context.mounted) {
                            if (success) {
                              AppHelpers.showSnackBar(
                                context,
                                'Helper removed. Request is now open again.',
                                isSuccess: true,
                              );
                            } else {
                              AppHelpers.showSnackBar(
                                context,
                                requestProvider.errorMessage ??
                                    'Failed to remove helper.',
                                isError: true,
                              );
                            }
                          }
                        }
                      },
                      onRejectHelper: (helperId) async {
                        final confirm = await AppHelpers.showConfirmDialog(
                          context: context,
                          title: 'Decline Help Offer?',
                          message:
                              'Decline this help offer? Other campus members can still offer help.',
                          confirmLabel: 'Decline',
                          isDestructive: true,
                        );
                        if (confirm && context.mounted) {
                          final success =
                              await requestProvider.rejectHelperOffer(
                            requestId: req.id,
                            requesterId: currentUserId,
                            helperId: helperId,
                          );
                          if (context.mounted) {
                            if (success) {
                              AppHelpers.showSnackBar(
                                context,
                                'Help offer declined.',
                                isSuccess: true,
                              );
                            } else {
                              AppHelpers.showSnackBar(
                                context,
                                requestProvider.errorMessage ??
                                    'Failed to decline help offer.',
                                isError: true,
                              );
                            }
                          }
                        }
                      },
                      onCancel: () async {
                        final confirm = await AppHelpers.showConfirmDialog(
                          context: context,
                          title: 'Cancel Request?',
                          message:
                              'Are you sure you want to cancel this borrow request?',
                          confirmLabel: 'Cancel Request',
                          isDestructive: true,
                        );
                        if (confirm && context.mounted) {
                          await requestProvider.cancelRequest(
                            req.id,
                            currentUserId,
                          );
                          if (context.mounted) {
                            AppHelpers.showSnackBar(
                              context,
                              'Request cancelled.',
                              isSuccess: true,
                            );
                          }
                        }
                      },
                    );
                  },
                ),

          // 2. Incoming Requests Tab
          incomingRequests.isEmpty
              ? const EmptyState(
                  icon: Icons.inbox_rounded,
                  title: 'No Incoming Requests',
                  description:
                      'When peers request to borrow your listed items, their requests will appear here for your approval.',
                )
              : ListView.builder(
                  padding: const EdgeInsets.only(top: 8, bottom: 24),
                  itemCount: incomingRequests.length,
                  itemBuilder: (context, index) {
                    final req = incomingRequests[index];
                    return RequestCard(
                      request: req,
                      isIncoming: true,
                      onApprove: () async {
                        final confirm = await AppHelpers.showConfirmDialog(
                          context: context,
                          title: 'Approve Borrow Request?',
                          message:
                              'Approve ${req.borrowerName}\'s request for "${req.itemName}"? This will reserve the item and create a pickup transaction.',
                          confirmLabel: 'Approve',
                        );
                        if (confirm && context.mounted) {
                          final success = await requestProvider.approveRequest(
                            req,
                            currentUserId,
                          );
                          if (context.mounted) {
                            if (success) {
                              AppHelpers.showSnackBar(
                                context,
                                'Request approved! Handover transaction created.',
                                isSuccess: true,
                              );
                            } else {
                              AppHelpers.showSnackBar(
                                context,
                                requestProvider.errorMessage ??
                                    'Failed to approve request',
                                isError: true,
                              );
                            }
                          }
                        }
                      },
                      onReject: () => _showRejectDialog(req, currentUserId),
                    );
                  },
                ),
        ],
      ),
    );
  }
}
