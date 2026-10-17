import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/id_generator.dart';
import '../app/app_config.dart';
import '../models/borrow_request_model.dart';
import '../models/user_model.dart';
import '../models/transaction_model.dart';
import '../models/chat_model.dart';
import '../models/notification_model.dart';
import 'chat_service.dart';
import 'in_memory_store.dart';

class BorrowRequestService {
  final FirebaseFirestore? firestore;

  BorrowRequestService({this.firestore});

  /// Stream of requests submitted by borrower
  Stream<List<BorrowRequestModel>> getMyBorrowRequests(String borrowerId) {
    final firestore = this.firestore;
    if (AppConfig.isFirebaseInitialized && firestore != null) {
      return firestore
          .collection('borrow_requests')
          .where('borrowerId', isEqualTo: borrowerId)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map(
            (snapshot) => snapshot.docs
                .map((doc) => BorrowRequestModel.fromFirestore(doc))
                .toList(),
          );
    } else {
      return InMemoryStore.instance.requestsStream.map(
        (list) =>
            list.where((r) => r.borrowerId == borrowerId).toList()
              ..sort((a, b) => b.createdAt.compareTo(a.createdAt)),
      );
    }
  }

  /// Stream of incoming requests received by owner
  Stream<List<BorrowRequestModel>> getIncomingBorrowRequests(String ownerId) {
    final firestore = this.firestore;
    if (AppConfig.isFirebaseInitialized && firestore != null) {
      return firestore
          .collection('borrow_requests')
          .where('ownerId', isEqualTo: ownerId)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map(
            (snapshot) => snapshot.docs
                .map((doc) => BorrowRequestModel.fromFirestore(doc))
                .toList(),
          );
    } else {
      return InMemoryStore.instance.requestsStream.map(
        (list) =>
            list.where((r) => r.ownerId == ownerId).toList()
              ..sort((a, b) => b.createdAt.compareTo(a.createdAt)),
      );
    }
  }

  /// Check if user has an active or pending request for this item
  Future<bool> hasActiveOrPendingRequest({
    required String borrowerId,
    required String itemId,
  }) async {
    final firestore = this.firestore;
    if (AppConfig.isFirebaseInitialized && firestore != null) {
      final snapshot = await firestore
          .collection('borrow_requests')
          .where('borrowerId', isEqualTo: borrowerId)
          .where('itemId', isEqualTo: itemId)
          .where('status', whereIn: ['pending', 'approved', 'active'])
          .limit(1)
          .get();
      return snapshot.docs.isNotEmpty;
    } else {
      return InMemoryStore.instance.requests.values.any(
        (r) =>
            r.borrowerId == borrowerId &&
            r.itemId == itemId &&
            ['pending', 'approved', 'active'].contains(r.status),
      );
    }
  }

  /// Create and submit borrow request
  Future<String> submitRequest(BorrowRequestModel request) async {
    // 1. Owner cannot request to borrow their own item
    if (request.ownerId == request.borrowerId) {
      throw Exception('You cannot borrow your own item.');
    }

    // 2. Prevent duplicate active or pending requests
    final hasExisting = await hasActiveOrPendingRequest(
      borrowerId: request.borrowerId,
      itemId: request.itemId,
    );
    if (hasExisting) {
      throw Exception(
        'You already have a pending or active request for this item.',
      );
    }

    final requestId = request.id.isNotEmpty
        ? request.id
        : FirestoreIdGenerator.generateId('borrow_requests');
    final newRequest = request.copyWith(id: requestId);

    final firestore = this.firestore;
    if (AppConfig.isFirebaseInitialized && firestore != null) {
      await firestore
          .collection('borrow_requests')
          .doc(requestId)
          .set(newRequest.toMap());

      // Send in-app notification to item owner
      final notification = NotificationModel(
        id: FirestoreIdGenerator.generateId('notifications'),
        recipientId: request.ownerId,
        senderId: request.borrowerId,
        senderName: request.borrowerName,
        type: 'request_received',
        title: 'New Borrow Request',
        message:
            '${request.borrowerName} requested to borrow "${request.itemName}".',
        relatedId: requestId,
      );
      await firestore
          .collection('notifications')
          .doc(notification.id)
          .set(notification.toMap());
    } else {
      InMemoryStore.instance.requests[requestId] = newRequest;

      // In-memory notification
      final notification = NotificationModel(
        id: FirestoreIdGenerator.generateId('notifications'),
        recipientId: request.ownerId,
        senderId: request.borrowerId,
        senderName: request.borrowerName,
        type: 'request_received',
        title: 'New Borrow Request',
        message:
            '${request.borrowerName} requested to borrow "${request.itemName}".',
        relatedId: requestId,
      );
      InMemoryStore.instance.notifications[notification.id] = notification;
      InMemoryStore.instance.notifyRequests();
      InMemoryStore.instance.notifyNotifications();
    }

    return requestId;
  }

  /// Approve request:
  /// Updates request status to 'approved', item status to 'reserved',
  /// creates transaction, creates chat, and sends notification to borrower.
  Future<void> approveRequest({
    required BorrowRequestModel request,
    required String currentUserId,
  }) async {
    if (request.ownerId != currentUserId) {
      throw Exception(
        'Unauthorized: Only the item owner can approve this request.',
      );
    }

    final firestore = this.firestore;
    // Check if another request was already approved for this item
    if (AppConfig.isFirebaseInitialized && firestore != null) {
      final existingApproved = await firestore
          .collection('borrow_requests')
          .where('itemId', isEqualTo: request.itemId)
          .where('status', isEqualTo: 'approved')
          .get();

      if (existingApproved.docs.isNotEmpty) {
        throw Exception('Another request is already approved for this item.');
      }
    } else {
      final existingApproved = InMemoryStore.instance.requests.values.any(
        (r) =>
            r.itemId == request.itemId &&
            r.status == 'approved' &&
            r.id != request.id,
      );
      if (existingApproved) {
        throw Exception('Another request is already approved for this item.');
      }
    }

    final updatedRequest = request.copyWith(
      status: 'approved',
      updatedAt: DateTime.now(),
    );

    final transactionId = FirestoreIdGenerator.generateId('transactions');
    final newTransaction = TransactionModel(
      id: transactionId,
      requestId: request.id,
      itemId: request.itemId,
      itemName: request.itemName,
      itemPhotoUrl: request.itemPhotoUrl,
      ownerId: request.ownerId,
      borrowerId: request.borrowerId,
      ownerName: 'Owner',
      borrowerName: request.borrowerName,
      status: 'scheduled',
    );

    final chatId = ChatService.buildChatId(
      requestId: request.id,
      borrowerId: request.borrowerId,
      helperId: request.ownerId,
    );
    final newChat = ChatModel(
      id: chatId,
      requestId: request.id,
      itemId: request.itemId,
      itemName: request.itemName,
      itemPhotoUrl: request.itemPhotoUrl,
      ownerId: request.ownerId,
      lenderId: request.ownerId,
      borrowerId: request.borrowerId,
      ownerName: 'Owner',
      lenderName: 'Owner',
      borrowerName: request.borrowerName,
      participants: [request.borrowerId, request.ownerId],
      status: 'active',
      lastMessage:
          'Request approved. Coordinate pickup time and location here.',
      lastMessageTime: DateTime.now(),
    );

    final notif = NotificationModel(
      id: FirestoreIdGenerator.generateId('notifications'),
      recipientId: request.borrowerId,
      senderId: request.ownerId,
      type: 'request_approved',
      title: 'Request Approved! 🎉',
      message:
          'Your request for "${request.itemName}" was approved! Tap to arrange handover.',
      relatedId: transactionId,
    );

    if (AppConfig.isFirebaseInitialized && firestore != null) {
      final batch = firestore.batch();
      batch.update(
        firestore.collection('borrow_requests').doc(request.id),
        updatedRequest.toMap(),
      );
      batch.update(firestore.collection('items').doc(request.itemId), {
        'availability': 'reserved',
        'updatedAt': Timestamp.now(),
      });
      batch.set(
        firestore.collection('transactions').doc(transactionId),
        newTransaction.toMap(),
      );
      batch.set(firestore.collection('chats').doc(chatId), newChat.toMap());
      batch.set(
        firestore.collection('notifications').doc(notif.id),
        notif.toMap(),
      );
      await batch.commit();
    } else {
      InMemoryStore.instance.requests[request.id] = updatedRequest;
      final currentItem = InMemoryStore.instance.items[request.itemId];
      if (currentItem != null) {
        InMemoryStore.instance.items[request.itemId] = currentItem.copyWith(
          availability: 'reserved',
        );
      }
      InMemoryStore.instance.transactions[transactionId] = newTransaction;
      InMemoryStore.instance.chats[chatId] = newChat;
      InMemoryStore.instance.notifications[notif.id] = notif;
      InMemoryStore.instance.notifyRequests();
      InMemoryStore.instance.notifyItems();
      InMemoryStore.instance.notifyTransactions();
      InMemoryStore.instance.notifyChats();
      InMemoryStore.instance.notifyNotifications();
    }
  }

  /// Reject request
  Future<void> rejectRequest({
    required BorrowRequestModel request,
    required String reason,
    required String currentUserId,
  }) async {
    if (request.ownerId != currentUserId) {
      throw Exception('Unauthorized: Only item owner can reject this request.');
    }

    final updated = request.copyWith(
      status: 'rejected',
      rejectionReason: reason.trim(),
      updatedAt: DateTime.now(),
    );

    final notif = NotificationModel(
      id: FirestoreIdGenerator.generateId('notifications'),
      recipientId: request.borrowerId,
      senderId: currentUserId,
      type: 'request_rejected',
      title: 'Request Declined',
      message: 'Your request for "${request.itemName}" was declined: $reason',
      relatedId: request.id,
    );

    final firestore = this.firestore;
    if (AppConfig.isFirebaseInitialized && firestore != null) {
      await firestore
          .collection('borrow_requests')
          .doc(request.id)
          .update(updated.toMap());
      await firestore
          .collection('notifications')
          .doc(notif.id)
          .set(notif.toMap());
    } else {
      InMemoryStore.instance.requests[request.id] = updated;
      InMemoryStore.instance.notifications[notif.id] = notif;
      InMemoryStore.instance.notifyRequests();
      InMemoryStore.instance.notifyNotifications();
    }
  }

  /// Cancel pending request by borrower
  Future<void> cancelRequest({
    required String requestId,
    required String currentUserId,
  }) async {
    final firestore = this.firestore;
    if (AppConfig.isFirebaseInitialized && firestore != null) {
      final doc = await firestore
          .collection('borrow_requests')
          .doc(requestId)
          .get();
      if (!doc.exists) throw Exception('Request not found.');
      final req = BorrowRequestModel.fromFirestore(doc);
      if (req.borrowerId != currentUserId) {
        throw Exception('Unauthorized: Only borrower can cancel this request.');
      }
      if (req.status != 'pending') {
        throw Exception('Only pending requests can be cancelled.');
      }

      await firestore.collection('borrow_requests').doc(requestId).update({
        'status': 'cancelled',
        'updatedAt': Timestamp.now(),
      });
    } else {
      final req = InMemoryStore.instance.requests[requestId];
      if (req == null) throw Exception('Request not found.');
      if (req.borrowerId != currentUserId) {
        throw Exception('Unauthorized: Only borrower can cancel this request.');
      }
      if (req.status != 'pending') {
        throw Exception('Only pending requests can be cancelled.');
      }

      InMemoryStore.instance.requests[requestId] = req.copyWith(
        status: 'cancelled',
        updatedAt: DateTime.now(),
      );
      InMemoryStore.instance.notifyRequests();
    }
  }

  /// Stream of all borrow requests across campus for administrative monitoring
  Stream<List<BorrowRequestModel>> getAllBorrowRequestsStream() {
    final firestore = this.firestore;
    if (AppConfig.isFirebaseInitialized && firestore != null) {
      return firestore
          .collection('borrow_requests')
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map(
            (snapshot) => snapshot.docs
                .map((doc) => BorrowRequestModel.fromFirestore(doc))
                .toList(),
          );
    } else {
      return InMemoryStore.instance.requestsStream.map(
        (list) =>
            List<BorrowRequestModel>.from(list)
              ..sort((a, b) => b.createdAt.compareTo(a.createdAt)),
      );
    }
  }

  /// Stream of active campus requests from other users
  Stream<List<BorrowRequestModel>> getCampusRequestsStream(
    String currentUserId,
  ) {
    final firestore = this.firestore;
    if (AppConfig.isFirebaseInitialized && firestore != null) {
      return firestore
          .collection('borrow_requests')
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map(
            (snapshot) => snapshot.docs
                .map((doc) => BorrowRequestModel.fromFirestore(doc))
                .where((r) {
                  // Exclude current user's own requests
                  if (r.borrowerId == currentUserId) return false;
                  // Only active/open/pending/helper_selected requests
                  final s = r.status.toLowerCase();
                  return s == 'pending' ||
                      s == 'open' ||
                      s == 'matching' ||
                      s == 'campus_broadcast' ||
                      s == 'helper_selected' ||
                      s == 'accepted';
                })
                .toList(),
          );
    } else {
      return InMemoryStore.instance.requestsStream.map(
        (list) => list
            .where((r) {
              if (r.borrowerId == currentUserId) return false;
              final s = r.status.toLowerCase();
              return s == 'pending' ||
                  s == 'open' ||
                  s == 'matching' ||
                  s == 'campus_broadcast' ||
                  s == 'helper_selected' ||
                  s == 'accepted';
            })
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt)),
      );
    }
  }

  /// Offer help on a campus request
  Future<void> offerHelp({
    required String requestId,
    required UserModel helperUser,
  }) async {
    final firestore = this.firestore;
    if (AppConfig.isFirebaseInitialized && firestore != null) {
      final docRef = firestore.collection('borrow_requests').doc(requestId);
      final doc = await docRef.get();
      if (!doc.exists) throw Exception('Request not found.');
      final request = BorrowRequestModel.fromFirestore(doc);

      if (request.borrowerId == helperUser.uid) {
        throw Exception('You cannot offer help on your own request.');
      }
      if (request.acceptedHelperId != null &&
          request.acceptedHelperId != helperUser.uid) {
        throw Exception('Another helper has already been selected for this request.');
      }
      if (request.helperIds.contains(helperUser.uid)) {
        throw Exception('You have already offered help for this request.');
      }

      final helperData = {
        'helperId': helperUser.uid,
        'helperName': helperUser.fullName,
        'helperDepartment': helperUser.department,
        'status': 'pending',
        'offeredAt': Timestamp.now(),
      };

      await docRef.update({
        'helperIds': FieldValue.arrayUnion([helperUser.uid]),
        'helpers': FieldValue.arrayUnion([helperData]),
        'updatedAt': Timestamp.now(),
      });

      // Send in-app notification to requester
      final notification = NotificationModel(
        id: FirestoreIdGenerator.generateId('notifications'),
        recipientId: request.borrowerId,
        senderId: helperUser.uid,
        senderName: helperUser.fullName,
        type: 'help_offered',
        title: 'Someone Can Help! 🤝',
        message:
            '${helperUser.fullName} can help with your "${request.itemName}" request.',
        relatedId: requestId,
      );
      await firestore
          .collection('notifications')
          .doc(notification.id)
          .set(notification.toMap());
    } else {
      final request = InMemoryStore.instance.requests[requestId];
      if (request == null) throw Exception('Request not found.');
      if (request.borrowerId == helperUser.uid) {
        throw Exception('You cannot offer help on your own request.');
      }
      if (request.acceptedHelperId != null &&
          request.acceptedHelperId != helperUser.uid) {
        throw Exception('Another helper has already been selected for this request.');
      }
      if (request.helperIds.contains(helperUser.uid)) {
        throw Exception('You have already offered help for this request.');
      }

      final helperData = {
        'helperId': helperUser.uid,
        'helperName': helperUser.fullName,
        'helperDepartment': helperUser.department,
        'status': 'pending',
        'offeredAt': Timestamp.now(),
      };

      final updatedHelpers =
          List<Map<String, dynamic>>.from(request.helpers)..add(helperData);
      final updatedHelperIds =
          List<String>.from(request.helperIds)..add(helperUser.uid);

      final updatedRequest = request.copyWith(
        helpers: updatedHelpers,
        helperIds: updatedHelperIds,
        updatedAt: DateTime.now(),
      );
      InMemoryStore.instance.requests[requestId] = updatedRequest;

      final notification = NotificationModel(
        id: FirestoreIdGenerator.generateId('notifications'),
        recipientId: request.borrowerId,
        senderId: helperUser.uid,
        senderName: helperUser.fullName,
        type: 'help_offered',
        title: 'Someone Can Help! 🤝',
        message:
            '${helperUser.fullName} can help with your "${request.itemName}" request.',
        relatedId: requestId,
      );
      InMemoryStore.instance.notifications[notification.id] = notification;
      InMemoryStore.instance.notifyRequests();
      InMemoryStore.instance.notifyNotifications();
    }
  }

  /// Atomically accept a single helper for a request.
  /// Locks the request so no other user can be accepted,
  /// creates/activates the private chat for only borrower and helper,
  /// and sends notification to the accepted helper.
  Future<String> acceptHelper({
    required String requestId,
    required String requesterId,
    required String helperId,
    required String helperName,
  }) async {
    final firestore = this.firestore;
    final chatId = ChatService.buildChatId(
      requestId: requestId,
      borrowerId: requesterId,
      helperId: helperId,
    );
    String itemName = 'item';
    String borrowerName = 'Requester';

    if (AppConfig.isFirebaseInitialized && firestore != null) {
      final docRef = firestore.collection('borrow_requests').doc(requestId);
      final chatRef = firestore.collection('chats').doc(chatId);

      await firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(docRef);
        if (!snapshot.exists) {
          throw Exception('Request not found.');
        }

        // Read chat document before any writes (Firestore requires all reads before writes)
        final chatSnapshot = await transaction.get(chatRef);

        final data = snapshot.data() as Map<String, dynamic>;
        final reqBorrowerId = data['borrowerId'] ?? data['requesterId'];
        if (reqBorrowerId != requesterId) {
          throw Exception('Unauthorized: Only the requester can accept a helper.');
        }

        final currentAcceptedId = data['acceptedHelperId'];
        if (currentAcceptedId != null &&
            currentAcceptedId.toString().isNotEmpty &&
            currentAcceptedId != helperId) {
          throw Exception('Another helper has already been selected for this request.');
        }

        itemName = data['itemName'] ?? 'item';
        borrowerName = data['borrowerName'] ?? data['requesterName'] ?? 'Requester';
        final itemId = data['itemId'] ?? '';
        final itemPhotoUrl = data['itemPhotoUrl'] ?? data['itemImageUrl'] ?? '';

        // Update helpers list with status: 'accepted'
        final rawHelpers = data['helpers'] as List<dynamic>? ?? [];
        final updatedHelpers = rawHelpers.map((h) {
          final map = Map<String, dynamic>.from(h as Map);
          if (map['helperId'] == helperId) {
            map['status'] = 'accepted';
          }
          return map;
        }).toList();

        // 1. Update Request
        transaction.update(docRef, {
          'acceptedHelperId': helperId,
          'acceptedHelperName': helperName,
          'acceptedHelperAt': FieldValue.serverTimestamp(),
          'chatId': chatId,
          'status': 'helper_selected',
          'requestStatus': 'helper_selected',
          'helpers': updatedHelpers,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // 2. Create or Reopen Chat Document
        if (chatSnapshot.exists) {
          transaction.update(chatRef, {
            'status': 'active',
            'updatedAt': FieldValue.serverTimestamp(),
          });
        } else {
          final newChat = ChatModel(
            id: chatId,
            requestId: requestId,
            itemId: itemId,
            itemName: itemName,
            itemPhotoUrl: itemPhotoUrl,
            ownerId: helperId,
            lenderId: helperId,
            borrowerId: requesterId,
            ownerName: helperName,
            lenderName: helperName,
            borrowerName: borrowerName,
            participants: [requesterId, helperId],
            status: 'active',
            lastMessage: 'Help offer accepted. Coordinate handover here!',
            lastMessageTime: DateTime.now(),
            lastSenderId: requesterId,
          );
          transaction.set(chatRef, newChat.toMap());
        }

        // 3. Send Notification to accepted helper
        final notifId = FirestoreIdGenerator.generateId('notifications');
        final notification = NotificationModel(
          id: notifId,
          recipientId: helperId,
          senderId: requesterId,
          senderName: borrowerName,
          type: 'helper_accepted',
          title: "You've been selected to help",
          message: 'You have been selected to help with "$itemName". Open the chat to coordinate the handover.',
          relatedId: chatId,
        );
        final notifRef = firestore.collection('notifications').doc(notifId);
        transaction.set(notifRef, notification.toMap());
      });

      return chatId;
    } else {
      final request = InMemoryStore.instance.requests[requestId];
      if (request == null) throw Exception('Request not found.');
      if (request.borrowerId != requesterId) {
        throw Exception('Unauthorized: Only the requester can accept a helper.');
      }
      if (request.acceptedHelperId != null &&
          request.acceptedHelperId!.isNotEmpty &&
          request.acceptedHelperId != helperId) {
        throw Exception('Another helper has already been selected for this request.');
      }

      itemName = request.itemName;
      borrowerName = request.borrowerName;
      final updatedHelpers = request.helpers.map((h) {
        final map = Map<String, dynamic>.from(h);
        if (map['helperId'] == helperId) {
          map['status'] = 'accepted';
        }
        return map;
      }).toList();

      final updatedRequest = request.copyWith(
        acceptedHelperId: helperId,
        acceptedHelperName: helperName,
        acceptedHelperAt: DateTime.now(),
        chatId: chatId,
        status: 'helper_selected',
        helpers: updatedHelpers,
        updatedAt: DateTime.now(),
      );
      InMemoryStore.instance.requests[requestId] = updatedRequest;

      // In-Memory Chat
      final existingChat = InMemoryStore.instance.chats[chatId];
      if (existingChat != null) {
        InMemoryStore.instance.chats[chatId] = existingChat.copyWith(
          status: 'active',
          updatedAt: DateTime.now(),
        );
      } else {
        final newChat = ChatModel(
          id: chatId,
          requestId: requestId,
          itemId: request.itemId,
          itemName: request.itemName,
          itemPhotoUrl: request.itemPhotoUrl,
          ownerId: helperId,
          lenderId: helperId,
          borrowerId: requesterId,
          ownerName: helperName,
          lenderName: helperName,
          borrowerName: borrowerName,
          participants: [requesterId, helperId],
          status: 'active',
          lastMessage: 'Help offer accepted. Coordinate handover here!',
          lastMessageTime: DateTime.now(),
          lastSenderId: requesterId,
        );
        InMemoryStore.instance.chats[chatId] = newChat;
      }
      InMemoryStore.instance.notifyChats();

      // Transaction
      final transactionId = FirestoreIdGenerator.generateId('transactions');
      final newTxn = TransactionModel(
        id: transactionId,
        requestId: requestId,
        itemId: request.itemId,
        itemName: request.itemName,
        itemPhotoUrl: request.itemPhotoUrl,
        ownerId: helperId,
        borrowerId: requesterId,
        ownerName: helperName,
        borrowerName: borrowerName,
        status: 'scheduled',
      );
      InMemoryStore.instance.transactions[transactionId] = newTxn;
      InMemoryStore.instance.notifyTransactions();

      // Notification
      final notifId = FirestoreIdGenerator.generateId('notifications');
      final notification = NotificationModel(
        id: notifId,
        recipientId: helperId,
        senderId: requesterId,
        senderName: borrowerName,
        type: 'helper_accepted',
        title: "You've been selected to help",
        message: 'You have been selected to help with "$itemName". Open the chat to coordinate the handover.',
        relatedId: chatId,
      );
      InMemoryStore.instance.notifications[notifId] = notification;

      InMemoryStore.instance.notifyRequests();
      InMemoryStore.instance.notifyNotifications();
      return chatId;
    }
  }

  /// Remove/reject the previously accepted helper.
  /// Sets request back to 'open', clears acceptedHelperId,
  /// sets chat status to 'closed', and notifies removed helper.
  Future<void> removeAcceptedHelper({
    required String requestId,
    required String requesterId,
    required String helperId,
  }) async {
    final firestore = this.firestore;
    String borrowerName = 'Requester';

    if (AppConfig.isFirebaseInitialized && firestore != null) {
      final docRef = firestore.collection('borrow_requests').doc(requestId);

      await firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(docRef);
        if (!snapshot.exists) throw Exception('Request not found.');

        final data = snapshot.data() as Map<String, dynamic>;
        final reqBorrowerId = data['borrowerId'] ?? data['requesterId'];
        if (reqBorrowerId != requesterId) {
          throw Exception('Unauthorized: Only the requester can remove a helper.');
        }

        borrowerName = data['borrowerName'] ?? data['requesterName'] ?? 'Requester';

        // Close associated chat
        final chatId = data['chatId'] as String? ??
            ChatService.buildChatId(
              requestId: requestId,
              borrowerId: requesterId,
              helperId: helperId,
            );
        final chatRef = firestore.collection('chats').doc(chatId);
        final chatSnapshot = await transaction.get(chatRef);
        if (chatSnapshot.exists) {
          transaction.update(chatRef, {
            'status': 'closed',
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }

        // Update helpers array: mark status as 'rejected'
        final rawHelpers = data['helpers'] as List<dynamic>? ?? [];
        final updatedHelpers = rawHelpers.map((h) {
          final map = Map<String, dynamic>.from(h as Map);
          if (map['helperId'] == helperId) {
            map['status'] = 'rejected';
          }
          return map;
        }).toList();

        transaction.update(docRef, {
          'acceptedHelperId': null,
          'acceptedHelperName': null,
          'acceptedHelperAt': null,
          'chatId': null,
          'status': 'open',
          'requestStatus': 'open',
          'rejectedHelperIds': FieldValue.arrayUnion([helperId]),
          'helpers': updatedHelpers,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // Send notification to the removed helper
        final notifId = FirestoreIdGenerator.generateId('notifications');
        final notification = NotificationModel(
          id: notifId,
          recipientId: helperId,
          senderId: requesterId,
          senderName: borrowerName,
          type: 'helper_removed',
          title: 'Help Offer Update',
          message: 'You are no longer selected for this borrowing request.',
          relatedId: requestId,
        );
        final notifRef = firestore.collection('notifications').doc(notifId);
        transaction.set(notifRef, notification.toMap());
      });
    } else {
      final request = InMemoryStore.instance.requests[requestId];
      if (request == null) throw Exception('Request not found.');
      if (request.borrowerId != requesterId) {
        throw Exception('Unauthorized: Only the requester can remove a helper.');
      }

      borrowerName = request.borrowerName;

      final chatId = request.chatId ??
          ChatService.buildChatId(
            requestId: requestId,
            borrowerId: requesterId,
            helperId: helperId,
          );

      // Close chat in-memory
      final chat = InMemoryStore.instance.chats[chatId];
      if (chat != null) {
        InMemoryStore.instance.chats[chatId] = chat.copyWith(
          status: 'closed',
          updatedAt: DateTime.now(),
        );
        InMemoryStore.instance.notifyChats();
      }

      final updatedHelpers = request.helpers.map((h) {
        final map = Map<String, dynamic>.from(h);
        if (map['helperId'] == helperId) {
          map['status'] = 'rejected';
        }
        return map;
      }).toList();

      final updatedRejected = List<String>.from(request.rejectedHelperIds);
      if (!updatedRejected.contains(helperId)) {
        updatedRejected.add(helperId);
      }

      final updatedRequest = request.copyWith(
        clearAcceptedHelper: true,
        clearChatId: true,
        status: 'open',
        rejectedHelperIds: updatedRejected,
        helpers: updatedHelpers,
        updatedAt: DateTime.now(),
      );
      InMemoryStore.instance.requests[requestId] = updatedRequest;

      final notifId = FirestoreIdGenerator.generateId('notifications');
      final notification = NotificationModel(
        id: notifId,
        recipientId: helperId,
        senderId: requesterId,
        senderName: borrowerName,
        type: 'helper_removed',
        title: 'Help Offer Update',
        message: 'You are no longer selected for this borrowing request.',
        relatedId: requestId,
      );
      InMemoryStore.instance.notifications[notifId] = notification;
      InMemoryStore.instance.notifyRequests();
      InMemoryStore.instance.notifyNotifications();
    }
  }

  /// Reject a pending help offer while request is open
  Future<void> rejectHelperOffer({
    required String requestId,
    required String requesterId,
    required String helperId,
  }) async {
    final firestore = this.firestore;
    String itemName = 'item';
    if (AppConfig.isFirebaseInitialized && firestore != null) {
      final docRef = firestore.collection('borrow_requests').doc(requestId);
      final doc = await docRef.get();
      if (!doc.exists) throw Exception('Request not found.');

      final data = doc.data() as Map<String, dynamic>;
      final reqBorrowerId = data['borrowerId'] ?? data['requesterId'];
      if (reqBorrowerId != requesterId) {
        throw Exception('Unauthorized: Only the requester can reject a helper.');
      }

      itemName = data['itemName'] ?? 'item';

      final rawHelpers = data['helpers'] as List<dynamic>? ?? [];
      final updatedHelpers = rawHelpers.map((h) {
        final map = Map<String, dynamic>.from(h as Map);
        if (map['helperId'] == helperId) {
          map['status'] = 'rejected';
        }
        return map;
      }).toList();

      await docRef.update({
        'rejectedHelperIds': FieldValue.arrayUnion([helperId]),
        'helpers': updatedHelpers,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      final notification = NotificationModel(
        id: FirestoreIdGenerator.generateId('notifications'),
        recipientId: helperId,
        senderId: requesterId,
        senderName: 'Requester',
        type: 'helper_rejected',
        title: 'Help Offer Update',
        message: 'The help offer for "$itemName" was not accepted.',
        relatedId: requestId,
      );
      await firestore
          .collection('notifications')
          .doc(notification.id)
          .set(notification.toMap());
    } else {
      final request = InMemoryStore.instance.requests[requestId];
      if (request == null) throw Exception('Request not found.');
      if (request.borrowerId != requesterId) {
        throw Exception('Unauthorized: Only the requester can reject a helper.');
      }

      itemName = request.itemName;
      final updatedHelpers = request.helpers.map((h) {
        final map = Map<String, dynamic>.from(h);
        if (map['helperId'] == helperId) {
          map['status'] = 'rejected';
        }
        return map;
      }).toList();

      final updatedRejected = List<String>.from(request.rejectedHelperIds);
      if (!updatedRejected.contains(helperId)) {
        updatedRejected.add(helperId);
      }

      final updatedRequest = request.copyWith(
        rejectedHelperIds: updatedRejected,
        helpers: updatedHelpers,
        updatedAt: DateTime.now(),
      );
      InMemoryStore.instance.requests[requestId] = updatedRequest;

      final notification = NotificationModel(
        id: FirestoreIdGenerator.generateId('notifications'),
        recipientId: helperId,
        senderId: requesterId,
        senderName: 'Requester',
        type: 'helper_rejected',
        title: 'Help Offer Update',
        message: 'The help offer for "$itemName" was not accepted.',
        relatedId: requestId,
      );
      InMemoryStore.instance.notifications[notification.id] = notification;
      InMemoryStore.instance.notifyRequests();
      InMemoryStore.instance.notifyNotifications();
    }
  }
}

