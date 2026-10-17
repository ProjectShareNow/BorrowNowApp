import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/app_config.dart';
import '../../providers/auth_provider.dart';
import '../../services/service_registry.dart';
import '../../models/chat_model.dart';
import '../../models/message_model.dart';
import '../../models/transaction_model.dart';
import '../../utils/helpers.dart';
import '../../widgets/user_avatar.dart';
import '../../widgets/chat/chat_workflow_panel.dart';
import '../../widgets/chat/chat_identity_verification_panel.dart';

class ChatScreen extends StatefulWidget {
  final String chatId;

  const ChatScreen({super.key, required this.chatId});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  bool _isSending = false;
  bool _isEnsuringTransaction = false;
  late String _effectiveChatId;

  @override
  void initState() {
    super.initState();
    _effectiveChatId = widget.chatId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _resolveChat();
    });
  }

  @override
  void didUpdateWidget(covariant ChatScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.chatId != widget.chatId) {
      _messageController.clear();
      _isEnsuringTransaction = false;
      _effectiveChatId = widget.chatId;
      _resolveChat();
    }
  }

  Future<void> _resolveChat() async {
    if (!mounted) return;
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final uid = auth.currentUser?.uid ?? '';
    if (uid.isNotEmpty) {
      final resolved = await ServiceRegistry.chatService.resolveChatId(
        relatedIdOrChatId: widget.chatId,
        currentUserId: uid,
      );
      if (mounted && resolved != null && resolved.isNotEmpty && resolved != _effectiveChatId) {
        setState(() {
          _effectiveChatId = resolved;
        });
      }
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 80,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _handleSend(ChatModel chat, String currentUserId, String currentUserName) async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    if (!chat.isUserParticipant(currentUserId)) {
      AppHelpers.showSnackBar(
        context,
        'You are not authorized to send messages in this chat.',
        isError: true,
      );
      return;
    }

    if (chat.isClosed) {
      AppHelpers.showSnackBar(
        context,
        'This chat is closed. Messages cannot be sent.',
        isError: true,
      );
      return;
    }

    setState(() {
      _isSending = true;
    });

    _messageController.clear();

    try {
      final recipientId = currentUserId == chat.borrowerId
          ? (chat.lenderId.isNotEmpty ? chat.lenderId : chat.ownerId)
          : chat.borrowerId;

      await ServiceRegistry.chatService.sendMessage(
        chatId: chat.id,
        senderId: currentUserId,
        senderName: currentUserName,
        text: text,
        recipientId: recipientId,
      );

      Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
    } catch (e) {
      if (mounted) {
        AppHelpers.showSnackBar(
          context,
          e.toString().replaceAll('Exception: ', ''),
          isError: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final currentUser = authProvider.currentUser;
    final currentUserId = currentUser?.uid ?? '';
    final currentUserName = currentUser?.fullName ?? 'Student';

    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Chat')),
        body: const Center(
          child: Text('Please sign in again to access this chat.'),
        ),
      );
    }

    AppConfig.log('[ChatDebug] Current UID: $currentUserId');
    AppConfig.log('[ChatDebug] Chat ID: ${widget.chatId}');

    return StreamBuilder<ChatModel?>(
      stream: ServiceRegistry.chatService.getChatStream(_effectiveChatId),
      builder: (context, chatSnapshot) {
        if (chatSnapshot.connectionState == ConnectionState.waiting &&
            !chatSnapshot.hasData) {
          return Scaffold(
            appBar: AppBar(title: const Text('Loading chat...')),
            body: const Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (chatSnapshot.hasError) {
          final errStr = chatSnapshot.error.toString();
          AppConfig.log('[ChatDebug] Stream error: $errStr');
          final isPermissionDenied = errStr.contains('permission-denied');
          return Scaffold(
            appBar: AppBar(title: const Text('Chat Error')),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isPermissionDenied ? Icons.lock_outline_rounded : Icons.error_outline_rounded,
                      size: 54,
                      color: const Color(0xFFDC2626),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      isPermissionDenied
                          ? "You don't have permission to access this chat."
                          : 'Failed to load chat: ${chatSnapshot.error}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF111827)),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isPermissionDenied
                          ? 'This is a private conversation for accepted participants only.'
                          : 'Please check your connection and try again.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Go Back'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final chat = chatSnapshot.data;
        if (chat == null) {
          ServiceRegistry.chatService.resolveChatId(
            relatedIdOrChatId: widget.chatId,
            currentUserId: currentUserId,
          );
          return Scaffold(
            appBar: AppBar(title: const Text('Opening Chat...')),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 18),
                    const Text(
                      'Connecting to conversation...',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Setting up your private channel with the other student.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 20),
                    OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        AppConfig.log('[ChatDebug] Request ID: ${chat.requestId}');
        AppConfig.log('[ChatDebug] Borrower ID: ${chat.borrowerId}');
        AppConfig.log('[ChatDebug] Lender ID: ${chat.lenderId}');
        AppConfig.log('[ChatDebug] Participants: ${chat.participants}');
        AppConfig.log('[ChatDebug] Chat status: ${chat.status}');

        // Mark messages as read safely after verifying participant
        if (chat.isUserParticipant(currentUserId)) {
          ServiceRegistry.chatService.markMessagesAsRead(
            chatId: chat.id,
            currentUserId: currentUserId,
          );
        }

        // Access Control: Only borrower and accepted helper/lender
        if (!chat.isUserParticipant(currentUserId)) {
          return Scaffold(
            appBar: AppBar(title: const Text('Access Restricted')),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.lock_rounded, size: 54, color: Color(0xFFDC2626)),
                    const SizedBox(height: 14),
                    const Text(
                      'Access Denied',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'This is a private conversation between the borrower and the accepted lender for "${chat.itemName}". Other students cannot view or send messages here.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Return to Safety'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final peerName = chat.getOtherUserName(currentUserId);
        final isClosed = chat.isClosed;

        return Scaffold(
          appBar: AppBar(
            titleSpacing: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.pop(context),
            ),
            title: Row(
              children: [
                UserAvatar(name: peerName, radius: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              peerName,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isClosed) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEE2E2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'Closed',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFDC2626),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      Text(
                        'Re: ${chat.itemName}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          body: SafeArea(
            child: Column(
              children: [
                // Closed Banner
                if (isClosed)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    color: const Color(0xFFFEE2E2),
                    child: Row(
                      children: const [
                        Icon(Icons.info_outline_rounded,
                            size: 18, color: Color(0xFFDC2626)),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'This chat is closed because the helper was removed or the request was reopened. New messages cannot be sent.',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF991B1B),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  // Safe Campus Exchange Notice Banner
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    color: const Color(0xFFF1F5F9),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.shield_outlined,
                          size: 16,
                          color: Color(0xFF0F766E),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Coordinate handover for "${chat.itemName}". Meet in open campus areas (Library, Canteen).',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Real-Time Transaction Workflow Stream (Identity Verification, Live Photo, Handover, Return)
                if (!isClosed)
                  StreamBuilder<TransactionModel?>(
                    stream: ServiceRegistry.transactionService
                        .getTransactionForChatStream(
                      requestId: chat.requestId,
                      borrowerId: chat.borrowerId,
                      lenderId: chat.lenderId.isNotEmpty
                          ? chat.lenderId
                          : chat.ownerId,
                    ),
                    builder: (context, txnSnapshot) {
                      final txn = txnSnapshot.data;
                      if (txn != null) {
                        _isEnsuringTransaction = false;
                      } else if (!isClosed && !_isEnsuringTransaction && chat.requestId.trim().isNotEmpty) {
                        _isEnsuringTransaction = true;
                        WidgetsBinding.instance.addPostFrameCallback((_) async {
                          if (!mounted) return;
                          try {
                            await ServiceRegistry.transactionService
                                .getOrCreateTransactionForChat(
                              requestId: chat.requestId,
                              itemId: chat.itemId,
                              itemName: chat.itemName,
                              itemPhotoUrl: chat.itemPhotoUrl,
                              borrowerId: chat.borrowerId,
                              lenderId: chat.lenderId.isNotEmpty
                                  ? chat.lenderId
                                  : chat.ownerId,
                              borrowerName: chat.borrowerName,
                              lenderName: chat.lenderName.isNotEmpty
                                  ? chat.lenderName
                                  : chat.ownerName,
                            );
                          } catch (e) {
                            debugPrint('[BorrowNow] Failed to get/create transaction: $e');
                          }
                        });
                      }
                      if (txn == null) {
                        return const SizedBox.shrink();
                      }
                      return ChatWorkflowPanel(
                        chat: chat,
                        transaction: txn,
                        currentUser: currentUser,
                        onRefresh: () {
                          setState(() {});
                        },
                      );
                    },
                  ),

                // Real-Time Messages Stream
                Expanded(
                  child: StreamBuilder<List<MessageModel>>(
                    stream: ServiceRegistry.chatService.getMessagesStream(chat.id),
                    builder: (context, msgSnapshot) {
                      if (msgSnapshot.connectionState == ConnectionState.waiting &&
                          !msgSnapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (msgSnapshot.hasError) {
                        final msgErrStr = msgSnapshot.error.toString();
                        AppConfig.log('[ChatDebug] Messages stream error: $msgErrStr');
                        final isPermissionDenied = msgErrStr.contains('permission-denied');
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Text(
                              isPermissionDenied
                                  ? "You don't have permission to view messages."
                                  : 'Error loading messages: ${msgSnapshot.error}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.red, fontSize: 13),
                            ),
                          ),
                        );
                      }

                      final messages = msgSnapshot.data ?? [];

                      if (messages.isEmpty) {
                        return Center(
                          child: SingleChildScrollView(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.chat_bubble_outline_rounded,
                                  size: 48,
                                  color: Colors.grey.shade300,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Say hi to $peerName!',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade600,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Coordinate your meeting location and exact pickup time.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade400,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      return ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final msg = messages[index];
                          final isMe = msg.senderId == currentUserId;

                          return Align(
                            alignment: isMe
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                              constraints: BoxConstraints(
                                maxWidth: MediaQuery.of(context).size.width * 0.75,
                              ),
                              decoration: BoxDecoration(
                                color: isMe
                                    ? theme.primaryColor
                                    : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.only(
                                  topLeft: const Radius.circular(14),
                                  topRight: const Radius.circular(14),
                                  bottomLeft: isMe
                                      ? const Radius.circular(14)
                                      : Radius.zero,
                                  bottomRight: isMe
                                      ? Radius.zero
                                      : const Radius.circular(14),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: isMe
                                    ? CrossAxisAlignment.end
                                    : CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    msg.text,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: isMe
                                          ? Colors.white
                                          : const Color(0xFF0F172A),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        AppHelpers.formatTime(msg.timestamp),
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: isMe
                                              ? Colors.white70
                                              : Colors.grey.shade500,
                                        ),
                                      ),
                                      if (isMe) ...[
                                        const SizedBox(width: 4),
                                        Icon(
                                          msg.isRead
                                              ? Icons.done_all_rounded
                                              : Icons.done_rounded,
                                          size: 12,
                                          color: Colors.white70,
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),

                // Photo Evidence / Camera Capture Card
                if (!isClosed)
                  StreamBuilder<TransactionModel?>(
                    stream: ServiceRegistry.transactionService
                        .getTransactionForChatStream(
                      requestId: chat.requestId,
                      borrowerId: chat.borrowerId,
                      lenderId: chat.lenderId.isNotEmpty
                          ? chat.lenderId
                          : chat.ownerId,
                    ),
                    builder: (context, txnSnapshot) {
                      return ChatPhotoEvidenceCard(
                        chat: chat,
                        transaction: txnSnapshot.data,
                        currentUser: currentUser,
                        onRefresh: () {
                          setState(() {});
                        },
                      );
                    },
                  ),

                // Message Input Bar or Closed State
                if (isClosed)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    color: const Color(0xFFF8FAFC),
                    child: Center(
                      child: Text(
                        'This conversation has been closed.',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          offset: const Offset(0, -2),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _messageController,
                            textCapitalization: TextCapitalization.sentences,
                            decoration: InputDecoration(
                              hintText: 'Type a message...',
                              hintStyle: TextStyle(
                                color: Colors.grey.shade400,
                                fontSize: 14,
                              ),
                              filled: true,
                              fillColor: const Color(0xFFF8FAFC),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(24),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            onSubmitted: (_) =>
                                _handleSend(chat, currentUserId, currentUserName),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton.filled(
                          onPressed: _isSending
                              ? null
                              : () => _handleSend(
                                    chat,
                                    currentUserId,
                                    currentUserName,
                                  ),
                          icon: _isSending
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.send_rounded, size: 18),
                          style: IconButton.styleFrom(
                            backgroundColor: theme.primaryColor,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
