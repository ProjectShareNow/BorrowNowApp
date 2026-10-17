import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/id_generator.dart';
import '../app/app_config.dart';
import '../models/chat_model.dart';
import '../models/message_model.dart';
import '../models/notification_model.dart';
import 'in_memory_store.dart';

class ChatService {
  final FirebaseFirestore? firestore;

  ChatService({this.firestore});

  /// Build deterministic chat ID tied to request, borrower, and accepted lender/helper
  static String buildChatId({
    required String requestId,
    required String borrowerId,
    required String helperId,
  }) {
    final cleanReq = requestId.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    final cleanBorrower = borrowerId.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    final cleanHelper = helperId.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    return 'chat_${cleanReq}_${cleanBorrower}_$cleanHelper';
  }

  /// Real-time stream of a specific chat document
  Stream<ChatModel?> getChatStream(String chatId) async* {
    final firestore = this.firestore;
    if (AppConfig.isFirebaseInitialized && firestore != null) {
      yield* firestore.collection('chats').doc(chatId).snapshots().map((doc) {
        if (!doc.exists) return null;
        return ChatModel.fromFirestore(doc);
      });
    } else {
      yield InMemoryStore.instance.chats[chatId];
      yield* InMemoryStore.instance.chatsStream.map((list) {
        try {
          return list.firstWhere((c) => c.id == chatId);
        } catch (_) {
          return InMemoryStore.instance.chats[chatId];
        }
      });
    }
  }

  /// Get single chat document by ID
  Future<ChatModel?> getChat(String chatId) async {
    final firestore = this.firestore;
    if (AppConfig.isFirebaseInitialized && firestore != null) {
      final doc = await firestore.collection('chats').doc(chatId).get();
      if (!doc.exists) return null;
      return ChatModel.fromFirestore(doc);
    } else {
      return InMemoryStore.instance.chats[chatId];
    }
  }

  /// Stream of user conversations (where user is participant)
  Stream<List<ChatModel>> getUserChatsStream(String userId) async* {
    final firestore = this.firestore;
    if (AppConfig.isFirebaseInitialized && firestore != null) {
      yield* firestore
          .collection('chats')
          .where('participants', arrayContains: userId)
          .snapshots()
          .map(
            (snapshot) => snapshot.docs
                .map((doc) => ChatModel.fromFirestore(doc))
                .toList()
              ..sort((a, b) => b.lastMessageTime.compareTo(a.lastMessageTime)),
          );
    } else {
      yield InMemoryStore.instance.chats.values
          .where((c) => c.isUserParticipant(userId))
          .toList()
        ..sort((a, b) => b.lastMessageTime.compareTo(a.lastMessageTime));
      yield* InMemoryStore.instance.chatsStream.map(
        (list) =>
            list.where((c) => c.isUserParticipant(userId)).toList()
              ..sort((a, b) => b.lastMessageTime.compareTo(a.lastMessageTime)),
      );
    }
  }

  /// Stream of messages in a conversation
  Stream<List<MessageModel>> getMessagesStream(String chatId) {
    final firestore = this.firestore;
    if (AppConfig.isFirebaseInitialized && firestore != null) {
      return firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .orderBy('timestamp', descending: false)
          .snapshots()
          .map(
            (snapshot) => snapshot.docs
                .map((doc) => MessageModel.fromFirestore(doc))
                .toList(),
          );
    } else {
      return InMemoryStore.instance.getChatMessagesStream(chatId);
    }
  }

  /// Create or retrieve private chat for accepted helper
  Future<ChatModel> createOrGetChat({
    required String requestId,
    required String itemId,
    required String itemName,
    String itemPhotoUrl = '',
    required String borrowerId,
    required String borrowerName,
    required String lenderId,
    required String lenderName,
  }) async {
    final chatId = buildChatId(
      requestId: requestId,
      borrowerId: borrowerId,
      helperId: lenderId,
    );
    final now = DateTime.now();

    final firestore = this.firestore;
    if (AppConfig.isFirebaseInitialized && firestore != null) {
      final docRef = firestore.collection('chats').doc(chatId);
      try {
        final doc = await docRef.get();
        if (doc.exists) {
          final existing = ChatModel.fromFirestore(doc);
          if (existing.isClosed) {
            await docRef.update({
              'status': 'active',
              'updatedAt': FieldValue.serverTimestamp(),
            });
            return existing.copyWith(status: 'active', updatedAt: now);
          }
          return existing;
        }
      } catch (e) {
        AppConfig.log('[ChatService] createOrGetChat doc get notice: $e');
      }

      final newChat = ChatModel(
        id: chatId,
        requestId: requestId,
        itemId: itemId,
        itemName: itemName,
        itemPhotoUrl: itemPhotoUrl,
        ownerId: lenderId,
        lenderId: lenderId,
        borrowerId: borrowerId,
        ownerName: lenderName,
        lenderName: lenderName,
        borrowerName: borrowerName,
        participants: [borrowerId, lenderId],
        status: 'active',
        lastMessage: 'Help offer accepted. Coordinate handover here!',
        lastMessageTime: now,
        lastSenderId: borrowerId,
        createdAt: now,
        updatedAt: now,
      );

      await docRef.set(newChat.toMap(), SetOptions(merge: true));
      return newChat;
    } else {
      final existing = InMemoryStore.instance.chats[chatId];
      if (existing != null) {
        if (existing.isClosed) {
          final updated = existing.copyWith(
            status: 'active',
            updatedAt: now,
          );
          InMemoryStore.instance.chats[chatId] = updated;
          InMemoryStore.instance.notifyChats();
          return updated;
        }
        return existing;
      }

      final newChat = ChatModel(
        id: chatId,
        requestId: requestId,
        itemId: itemId,
        itemName: itemName,
        itemPhotoUrl: itemPhotoUrl,
        ownerId: lenderId,
        lenderId: lenderId,
        borrowerId: borrowerId,
        ownerName: lenderName,
        lenderName: lenderName,
        borrowerName: borrowerName,
        participants: [borrowerId, lenderId],
        status: 'active',
        lastMessage: 'Help offer accepted. Coordinate handover here!',
        lastMessageTime: now,
        lastSenderId: borrowerId,
        createdAt: now,
        updatedAt: now,
      );
      InMemoryStore.instance.chats[chatId] = newChat;
      InMemoryStore.instance.notifyChats();
      return newChat;
    }
  }

  /// Close chat when helper is removed/rejected
  Future<void> closeChat({
    required String chatId,
    required String currentUserId,
  }) async {
    final firestore = this.firestore;
    if (AppConfig.isFirebaseInitialized && firestore != null) {
      await firestore.collection('chats').doc(chatId).update({
        'status': 'closed',
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } else {
      final chat = InMemoryStore.instance.chats[chatId];
      if (chat != null) {
        InMemoryStore.instance.chats[chatId] = chat.copyWith(
          status: 'closed',
          updatedAt: DateTime.now(),
        );
        InMemoryStore.instance.notifyChats();
      }
    }
  }

  /// Send message in private chat
  Future<void> sendMessage({
    required String chatId,
    required String senderId,
    required String senderName,
    required String text,
    String? recipientId,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      throw Exception('Message cannot be empty.');
    }

    final chat = await getChat(chatId);
    if (chat == null) {
      throw Exception('Chat conversation not found.');
    }

    if (!chat.isUserParticipant(senderId)) {
      throw Exception('Unauthorized: You are not a participant in this private chat.');
    }

    if (chat.isClosed) {
      throw Exception('This chat is closed. Messages cannot be sent.');
    }

    final effectiveRecipientId = (recipientId != null && recipientId.isNotEmpty)
        ? recipientId
        : (senderId == chat.borrowerId ? chat.lenderId : chat.borrowerId);

    final messageId = FirestoreIdGenerator.generateId('messages');
    final now = DateTime.now();
    final message = MessageModel(
      id: messageId,
      chatId: chatId,
      senderId: senderId,
      senderName: senderName,
      text: trimmed,
      timestamp: now,
      type: 'text',
      isRead: false,
    );

    final firestore = this.firestore;
    if (AppConfig.isFirebaseInitialized && firestore != null) {
      final batch = firestore.batch();
      batch.set(
        firestore
            .collection('chats')
            .doc(chatId)
            .collection('messages')
            .doc(messageId),
        message.toMap(),
      );
      batch.update(firestore.collection('chats').doc(chatId), {
        'lastMessage': trimmed,
        'lastMessageTime': FieldValue.serverTimestamp(),
        'lastMessageAt': FieldValue.serverTimestamp(),
        'lastSenderId': senderId,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Notification for recipient
      if (effectiveRecipientId.isNotEmpty) {
        final notifId = FirestoreIdGenerator.generateId('notifications');
        final notif = NotificationModel(
          id: notifId,
          recipientId: effectiveRecipientId,
          senderId: senderId,
          senderName: senderName,
          type: 'new_chat_message',
          title: 'New message from $senderName',
          message: trimmed,
          relatedId: chatId,
        );
        batch.set(firestore.collection('notifications').doc(notifId), notif.toMap());
      }

      await batch.commit();
    } else {
      if (!InMemoryStore.instance.messages.containsKey(chatId)) {
        InMemoryStore.instance.messages[chatId] = [];
      }
      InMemoryStore.instance.messages[chatId]!.add(message);

      final isOwner = senderId == chat.ownerId || senderId == chat.lenderId;
      InMemoryStore.instance.chats[chatId] = chat.copyWith(
        lastMessage: trimmed,
        lastMessageTime: now,
        lastSenderId: senderId,
        unreadCountBorrower: isOwner
            ? chat.unreadCountBorrower + 1
            : chat.unreadCountBorrower,
        unreadCountOwner: !isOwner
            ? chat.unreadCountOwner + 1
            : chat.unreadCountOwner,
        updatedAt: now,
      );

      if (effectiveRecipientId.isNotEmpty) {
        final notifId = FirestoreIdGenerator.generateId('notifications');
        final notif = NotificationModel(
          id: notifId,
          recipientId: effectiveRecipientId,
          senderId: senderId,
          senderName: senderName,
          type: 'new_chat_message',
          title: 'New message from $senderName',
          message: trimmed,
          relatedId: chatId,
        );
        InMemoryStore.instance.notifications[notifId] = notif;
        InMemoryStore.instance.notifyNotifications();
      }

      InMemoryStore.instance.notifyChatMessages(chatId);
      InMemoryStore.instance.notifyChats();
    }
  }

  /// Ensure chat document exists for a request and return chatId
  Future<String?> ensureChatForRequest({
    required String requestId,
    required String currentUserId,
  }) async {
    final firestore = this.firestore;
    if (AppConfig.isFirebaseInitialized && firestore != null) {
      try {
        final reqDoc = await firestore.collection('borrow_requests').doc(requestId).get();
        if (!reqDoc.exists) return null;
        final data = reqDoc.data() as Map<String, dynamic>;
        final borrowerId = (data['borrowerId'] ?? data['requesterId'] ?? '').toString();
        final helperId = (data['acceptedHelperId'] ?? '').toString();
        if (helperId.isEmpty) return null;

        // Verify current user is borrower or accepted helper
        if (currentUserId != borrowerId && currentUserId != helperId) {
          return null;
        }

        final borrowerName = (data['borrowerName'] ?? data['requesterName'] ?? 'Requester').toString();
        final helperName = (data['acceptedHelperName'] ?? 'Helper').toString();
        final itemId = (data['itemId'] ?? '').toString();
        final itemName = (data['itemName'] ?? 'Item').toString();
        final itemPhotoUrl = (data['itemPhotoUrl'] ?? data['itemImageUrl'] ?? '').toString();

        final chat = await createOrGetChat(
          requestId: requestId,
          itemId: itemId,
          itemName: itemName,
          itemPhotoUrl: itemPhotoUrl,
          borrowerId: borrowerId,
          borrowerName: borrowerName,
          lenderId: helperId,
          lenderName: helperName,
        );

        if ((data['chatId'] ?? '').toString().isEmpty) {
          try {
            await firestore.collection('borrow_requests').doc(requestId).update({
              'chatId': chat.id,
            });
          } catch (updateErr) {
            AppConfig.log('[ChatService] Non-fatal request chatId update notice: $updateErr');
          }
        }

        return chat.id;
      } catch (e) {
        AppConfig.log('[ChatService] Error ensuring chat for request $requestId: $e');
        return null;
      }
    } else {
      final req = InMemoryStore.instance.requests[requestId];
      if (req == null || req.acceptedHelperId == null || req.acceptedHelperId!.isEmpty) return null;
      if (currentUserId != req.borrowerId && currentUserId != req.acceptedHelperId) {
        return null;
      }
      final chat = await createOrGetChat(
        requestId: requestId,
        itemId: req.itemId,
        itemName: req.itemName,
        itemPhotoUrl: req.itemPhotoUrl,
        borrowerId: req.borrowerId,
        borrowerName: req.borrowerName,
        lenderId: req.acceptedHelperId!,
        lenderName: req.acceptedHelperName ?? 'Helper',
      );
      return chat.id;
    }
  }

  /// Resolve notification relatedId or candidate chatId into an authorized existing chatId
  Future<String?> resolveChatId({
    required String relatedIdOrChatId,
    required String currentUserId,
  }) async {
    final trimmed = relatedIdOrChatId.trim();
    if (trimmed.isEmpty) return null;

    try {
      // 1. Direct check if trimmed is already a valid Chat ID
      final existingChat = await getChat(trimmed);
      if (existingChat != null) {
        if (existingChat.isUserParticipant(currentUserId)) {
          return existingChat.id;
        }
        return null; // Unauthorized user trying to access existing chat
      }

      // 2. Check if trimmed is a Transaction ID
      final firestore = this.firestore;
      if (AppConfig.isFirebaseInitialized && firestore != null) {
        try {
          final txnDoc = await firestore.collection('transactions').doc(trimmed).get();
          if (txnDoc.exists) {
            final tData = txnDoc.data() as Map<String, dynamic>;
            final bId = (tData['borrowerId'] ?? '').toString();
            final oId = (tData['ownerId'] ?? tData['lenderId'] ?? '').toString();
            if (currentUserId == bId || currentUserId == oId) {
              final rId = (tData['requestId'] ?? '').toString();
              if (rId.isNotEmpty) {
                final fromTxnReq = await ensureChatForRequest(
                  requestId: rId,
                  currentUserId: currentUserId,
                );
                if (fromTxnReq != null) return fromTxnReq;
              }
              return buildChatId(requestId: rId, borrowerId: bId, helperId: oId);
            }
            return null; // Unauthorized user
          }
        } catch (_) {}
      } else {
        final txn = InMemoryStore.instance.transactions[trimmed];
        if (txn != null) {
          if (currentUserId == txn.borrowerId || currentUserId == txn.ownerId) {
            final fromTxnReq = await ensureChatForRequest(
              requestId: txn.requestId,
              currentUserId: currentUserId,
            );
            if (fromTxnReq != null) return fromTxnReq;
            return buildChatId(
              requestId: txn.requestId,
              borrowerId: txn.borrowerId,
              helperId: txn.ownerId,
            );
          }
          return null; // Unauthorized user
        }
      }

      // 3. Check if trimmed is a Request ID
      final fromReq = await ensureChatForRequest(
        requestId: trimmed,
        currentUserId: currentUserId,
      );
      if (fromReq != null) {
        return fromReq;
      }

      // 4. Check if trimmed has chat_ prefix
      if (trimmed.startsWith('chat_')) {
        final parts = trimmed.split('_');
        if (parts.length >= 4) {
          final reqId = parts[1];
          final bId = parts[2];
          final hId = parts[3];
          if (currentUserId != bId && currentUserId != hId) {
            return null; // Unauthorized user
          }
          final fromDetReq = await ensureChatForRequest(
            requestId: reqId,
            currentUserId: currentUserId,
          );
          if (fromDetReq != null) {
            return fromDetReq;
          }
          final detChat = await getChat(trimmed);
          if (detChat != null && detChat.isUserParticipant(currentUserId)) {
            return detChat.id;
          }
        } else if (parts.length >= 2) {
          final reqId = parts.sublist(1).join('_');
          final fromReq = await ensureChatForRequest(
            requestId: reqId,
            currentUserId: currentUserId,
          );
          if (fromReq != null) return fromReq;
        }
      }
    } catch (e) {
      AppConfig.log('[ChatService] resolveChatId error: $e');
    }

    return null;
  }

  /// Mark messages as read
  Future<void> markMessagesAsRead({
    required String chatId,
    required String currentUserId,
  }) async {
    final firestore = this.firestore;
    if (AppConfig.isFirebaseInitialized && firestore != null) {
      try {
        final docRef = firestore.collection('chats').doc(chatId);
        final doc = await docRef.get();
        if (doc.exists) {
          final data = doc.data() as Map<String, dynamic>;
          final participants = (data['participants'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];
          final borrowerId = (data['borrowerId'] ?? '').toString();
          final lenderId = (data['lenderId'] ?? data['ownerId'] ?? '').toString();

          if (participants.contains(currentUserId) ||
              currentUserId == borrowerId ||
              currentUserId == lenderId) {
            await docRef.update({
              'unreadCount': 0,
            });
          }
        }
      } catch (e) {
        AppConfig.log('[ChatService] markMessagesAsRead non-fatal error: $e');
      }
    } else {
      final chat = InMemoryStore.instance.chats[chatId];
      if (chat != null) {
        final isOwner = currentUserId == chat.ownerId || currentUserId == chat.lenderId;
        InMemoryStore.instance.chats[chatId] = chat.copyWith(
          unreadCountOwner: isOwner ? 0 : chat.unreadCountOwner,
          unreadCountBorrower: !isOwner ? 0 : chat.unreadCountBorrower,
        );
        InMemoryStore.instance.notifyChats();
      }
    }
  }
}
