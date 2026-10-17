import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/id_generator.dart';
import '../utils/helpers.dart';
import '../app/app_config.dart';
import '../models/transaction_model.dart';
import '../models/user_model.dart';
import '../models/notification_model.dart';
import 'in_memory_store.dart';

class TransactionService {
  final FirebaseFirestore? firestore;

  TransactionService({this.firestore});

  static String normalizeRegisterNumber(String input) {
    return input.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
  }

  /// Stream of active borrowings for a user (as borrower or owner)
  Stream<List<TransactionModel>> getActiveTransactions(String userId) {
    final firestore = this.firestore;
    if (AppConfig.isFirebaseInitialized && firestore != null) {
      return firestore
          .collection('transactions')
          .where('status', whereIn: ['scheduled', 'active', 'return_requested'])
          .snapshots()
          .map(
            (snapshot) => snapshot.docs
                .map((doc) => TransactionModel.fromFirestore(doc))
                .where((t) => t.ownerId == userId || t.borrowerId == userId)
                .toList(),
          );
    } else {
      return InMemoryStore.instance.transactionsStream.map(
        (list) =>
            list
                .where(
                  (t) =>
                      (t.ownerId == userId || t.borrowerId == userId) &&
                      [
                        'scheduled',
                        'active',
                        'return_requested',
                      ].contains(t.status),
                )
                .toList()
              ..sort((a, b) => b.createdAt.compareTo(a.createdAt)),
      );
    }
  }

  /// Stream of completed / past transactions history for a user
  Stream<List<TransactionModel>> getTransactionHistory(String userId) {
    final firestore = this.firestore;
    if (AppConfig.isFirebaseInitialized && firestore != null) {
      return firestore
          .collection('transactions')
          .where('status', isEqualTo: 'completed')
          .snapshots()
          .map(
            (snapshot) => snapshot.docs
                .map((doc) => TransactionModel.fromFirestore(doc))
                .where((t) => t.ownerId == userId || t.borrowerId == userId)
                .toList(),
          );
    } else {
      return InMemoryStore.instance.transactionsStream.map(
        (list) =>
            list
                .where(
                  (t) =>
                      (t.ownerId == userId || t.borrowerId == userId) &&
                      t.status == 'completed',
                )
                .toList()
              ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt)),
      );
    }
  }

  /// Get single transaction by ID
  Future<TransactionModel?> getTransactionById(String transactionId) async {
    final firestore = this.firestore;
    if (AppConfig.isFirebaseInitialized && firestore != null) {
      final doc = await firestore
          .collection('transactions')
          .doc(transactionId)
          .get();
      if (doc.exists) {
        return TransactionModel.fromFirestore(doc);
      }
      return null;
    } else {
      return InMemoryStore.instance.transactions[transactionId];
    }
  }

  /// Alias for getTransactionById
  Future<TransactionModel?> getTransaction(String transactionId) =>
      getTransactionById(transactionId);

  /// Stream single transaction by ID
  Stream<TransactionModel?> getTransactionStream(String transactionId) {
    final firestore = this.firestore;
    if (AppConfig.isFirebaseInitialized && firestore != null) {
      return firestore
          .collection('transactions')
          .doc(transactionId)
          .snapshots()
          .map((doc) {
            if (!doc.exists) return null;
            return TransactionModel.fromFirestore(doc);
          });
    } else {
      return InMemoryStore.instance.transactionsStream.map(
        (list) => list.cast<TransactionModel?>().firstWhere(
              (t) => t?.id == transactionId,
              orElse: () => null,
            ),
      );
    }
  }

  /// Stream transaction for a specific chat / request
  Stream<TransactionModel?> getTransactionForChatStream({
    required String requestId,
    required String borrowerId,
    required String lenderId,
  }) async* {
    final firestore = this.firestore;
    final trimmedRequestId = requestId.trim();
    if (AppConfig.isFirebaseInitialized && firestore != null && trimmedRequestId.isNotEmpty) {
      yield* firestore
          .collection('transactions')
          .where('requestId', isEqualTo: trimmedRequestId)
          .snapshots()
          .handleError((error) {
            debugPrint('[BorrowNow] getTransactionForChatStream error: $error');
          })
          .map((snapshot) {
            if (snapshot.docs.isNotEmpty) {
              return TransactionModel.fromFirestore(snapshot.docs.first);
            }
            return null;
          });
    } else {
      TransactionModel? findTxn(List<TransactionModel> list) {
        return list.cast<TransactionModel?>().firstWhere(
              (t) =>
                  t != null &&
                  t.requestId == trimmedRequestId &&
                  ((t.borrowerId == borrowerId && t.ownerId == lenderId) ||
                      (t.borrowerId == lenderId && t.ownerId == borrowerId)),
              orElse: () {
                return list.cast<TransactionModel?>().firstWhere(
                      (t) => t?.requestId == trimmedRequestId,
                      orElse: () => null,
                    );
              },
            );
      }

      yield findTxn(InMemoryStore.instance.transactions.values.toList());
      yield* InMemoryStore.instance.transactionsStream.map((list) => findTxn(list));
    }
  }

  /// Ensure a transaction exists for an active chat
  Future<TransactionModel> getOrCreateTransactionForChat({
    required String requestId,
    required String itemId,
    required String itemName,
    String itemPhotoUrl = '',
    required String borrowerId,
    required String lenderId,
    required String borrowerName,
    required String lenderName,
  }) async {
    final firestore = this.firestore;
    final trimmedRequestId = requestId.trim();

    if (AppConfig.isFirebaseInitialized && firestore != null && trimmedRequestId.isNotEmpty) {
      try {
        final snap = await firestore
            .collection('transactions')
            .where('requestId', isEqualTo: trimmedRequestId)
            .limit(1)
            .get();

        if (snap.docs.isNotEmpty) {
          return TransactionModel.fromFirestore(snap.docs.first);
        }

        // Create new scheduled transaction
        final transactionId = FirestoreIdGenerator.generateId('transactions');
        final newTxn = TransactionModel(
          id: transactionId,
          requestId: trimmedRequestId,
          itemId: itemId,
          itemName: itemName,
          itemPhotoUrl: itemPhotoUrl,
          ownerId: lenderId,
          borrowerId: borrowerId,
          ownerName: lenderName,
          borrowerName: borrowerName,
          status: 'scheduled',
        );

        await firestore
            .collection('transactions')
            .doc(transactionId)
            .set(newTxn.toMap());
        return newTxn;
      } catch (e) {
        debugPrint('[BorrowNow] Firestore getOrCreateTransactionForChat error: $e');
      }
    }

    for (final t in InMemoryStore.instance.transactions.values) {
      if (t.requestId == trimmedRequestId) return t;
    }

    final transactionId = FirestoreIdGenerator.generateId('transactions');
    final newTxn = TransactionModel(
      id: transactionId,
      requestId: trimmedRequestId,
      itemId: itemId,
      itemName: itemName,
      itemPhotoUrl: itemPhotoUrl,
      ownerId: lenderId,
      borrowerId: borrowerId,
      ownerName: lenderName,
      borrowerName: borrowerName,
      status: 'scheduled',
    );
    InMemoryStore.instance.transactions[transactionId] = newTxn;
    InMemoryStore.instance.notifyTransactions();
    return newTxn;
  }

  /// Step 1: Lender verifies borrower identity using registered College ID against Firestore
  Future<bool> verifyBorrowerIdentity({
    required String transactionId,
    required String lenderId,
    String? enteredRegisterNumber,
    String? enteredCollegeId,
    String? requestId,
  }) async {
    final txn = await getTransactionById(transactionId);
    if (txn == null) {
      throw Exception('Transaction record not found in database.');
    }

    if (txn.ownerId != lenderId) {
      throw Exception('You are not authorized to verify this transaction. (Unauthorized: You are not authorized to verify this transaction.)');
    }

    if (txn.status != 'scheduled') {
      throw Exception('Verification failed. Handover verification is only permitted during the scheduled stage.');
    }

    // 1. Get borrowerId (UID) from current borrow request or transaction
    final borrowerId = txn.borrowerId.trim();
    if (borrowerId.isEmpty) {
      throw Exception('Borrower profile ID is missing from transaction.');
    }

    // 2. Direct Firestore fetch of borrower profile from users/{borrowerId}
    UserModel? borrower;
    final fs = firestore;
    if (AppConfig.isFirebaseInitialized && fs != null) {
      try {
        final borrowerDoc = await fs.collection('users').doc(borrowerId).get();
        if (borrowerDoc.exists && borrowerDoc.data() != null) {
          final data = borrowerDoc.data()!;
          borrower = UserModel.fromFirestore(borrowerDoc);
          final docCollegeId = (data['collegeId'] ?? data['registerNumber'] ?? '').toString().trim();
          if (borrower.collegeId.trim().isEmpty && docCollegeId.isNotEmpty) {
            borrower = borrower.copyWith(collegeId: docCollegeId);
          }
        } else {
          throw Exception("Borrower document does not exist in the database. Please contact the administrator.");
        }
      } catch (e) {
        if (e is Exception && e.toString().contains('Borrower document does not exist')) {
          rethrow;
        }
        AppConfig.log('Firestore borrower fetch error during verification: $e');
        if (e.toString().contains('network') || e.toString().contains('unavailable') || e.toString().contains('SocketException')) {
          throw Exception('Unable to verify the College ID right now. Please check your connection and try again.');
        }
        throw Exception('Failed to retrieve borrower profile. Please contact the administrator.');
      }
    } else {
      borrower = InMemoryStore.instance.users[borrowerId];
    }

    if (borrower == null) {
      throw Exception("Borrower document does not exist in the database. Please contact the administrator.");
    }

    // 3. Get borrower's College ID stored in user document
    final borrowerReg = borrower.registerNumber.trim();
    final borrowerCollegeId = borrower.collegeId.trim();
    final registeredCollegeId = borrowerCollegeId.isNotEmpty ? borrowerCollegeId : borrowerReg;
    if (registeredCollegeId.isEmpty) {
      throw Exception("The borrower's College ID is not available. Please contact the administrator. (This borrower’s register number is not available in the database. Please contact the administrator.)");
    }

    // 4. Get borrower's College ID associated with the current borrow request
    final targetRequestId = (requestId != null && requestId.trim().isNotEmpty)
        ? requestId.trim()
        : txn.requestId.trim();

    String requestBorrowerCollegeId = '';
    if (targetRequestId.isNotEmpty) {
      if (AppConfig.isFirebaseInitialized && fs != null) {
        try {
          final reqDoc = await fs.collection('borrow_requests').doc(targetRequestId).get();
          if (reqDoc.exists && reqDoc.data() != null) {
            final reqData = reqDoc.data()!;
            requestBorrowerCollegeId = (reqData['collegeId'] ??
                    reqData['borrowerCollegeId'] ??
                    reqData['registerNumber'] ??
                    reqData['borrowerRegisterNumber'] ??
                    '')
                .toString()
                .trim();
          }
        } catch (e) {
          if (e.toString().contains('network') || e.toString().contains('unavailable') || e.toString().contains('SocketException')) {
            throw Exception('Unable to verify the College ID right now. Please check your connection and try again.');
          }
        }
      } else {
        final req = InMemoryStore.instance.requests[targetRequestId];
        if (req != null) {
          requestBorrowerCollegeId = (req.collegeId.isNotEmpty ? req.collegeId : '').trim();
        }
      }
    }

    final trimmedInput = (enteredCollegeId ?? enteredRegisterNumber ?? '').trim();

    final effectiveRequestCollegeId = trimmedInput.isNotEmpty
        ? trimmedInput
        : requestBorrowerCollegeId;

    if (effectiveRequestCollegeId.isEmpty) {
      throw Exception("Please enter the borrower's College ID. (Please enter the borrower's register number.)");
    }

    // 5. Compare: Borrow request borrower College ID == users collection borrower College ID
    final normalizedBorrowerReg = normalizeRegisterNumber(borrowerReg);
    final normalizedBorrowerCollegeId = normalizeRegisterNumber(borrowerCollegeId);
    final normalizedEffectiveRequestCollegeId = normalizeRegisterNumber(effectiveRequestCollegeId);

    bool isMatch = (borrowerCollegeId.isNotEmpty && effectiveRequestCollegeId.toLowerCase() == borrowerCollegeId.toLowerCase()) ||
        (borrowerReg.isNotEmpty && effectiveRequestCollegeId.toLowerCase() == borrowerReg.toLowerCase()) ||
        (normalizedBorrowerCollegeId.isNotEmpty && normalizedEffectiveRequestCollegeId == normalizedBorrowerCollegeId) ||
        (normalizedBorrowerReg.isNotEmpty && normalizedEffectiveRequestCollegeId == normalizedBorrowerReg);

    if (requestBorrowerCollegeId.isNotEmpty && trimmedInput.isNotEmpty) {
      final normalizedReqStored = normalizeRegisterNumber(requestBorrowerCollegeId);
      final isReqAligned = trimmedInput.toLowerCase() == requestBorrowerCollegeId.toLowerCase() ||
          (normalizedReqStored.isNotEmpty && normalizedEffectiveRequestCollegeId == normalizedReqStored);
      if (!isReqAligned) {
        isMatch = false;
      }
    }

    if (!isMatch) {
      throw Exception("Borrower College ID does not match the registered College ID. (Verification Failed. The register number does not match the borrower’s records.)");
    }

    final now = DateTime.now();
    final effectiveId = borrowerCollegeId.isNotEmpty ? borrowerCollegeId : borrowerReg;
    final maskedBorrowerReg = AppHelpers.maskRegisterNumber(effectiveId);
    final updatedTxn = txn.copyWith(
      handoverIdentityVerified: true,
      handoverVerifiedBy: lenderId,
      handoverVerifiedAt: now,
      maskedBorrowerRegisterNumber: maskedBorrowerReg,
      updatedAt: now,
    );

    final notif = NotificationModel(
      id: FirestoreIdGenerator.generateId('notifications'),
      recipientId: txn.borrowerId,
      senderId: lenderId,
      type: 'identity_verified',
      title: 'Identity Verified ✅',
      message: '${txn.ownerName} has verified your student ID for "${txn.itemName}". Preparing for photo capture.',
      relatedId: transactionId,
    );

    if (AppConfig.isFirebaseInitialized && fs != null) {
      try {
        final batch = fs.batch();
        batch.update(
          fs.collection('transactions').doc(transactionId),
          {
            'handoverIdentityVerified': true,
            'handoverVerifiedBy': lenderId,
            'handoverVerifiedAt': FieldValue.serverTimestamp(),
            'maskedBorrowerRegisterNumber': maskedBorrowerReg,
            'updatedAt': FieldValue.serverTimestamp(),
          },
        );
        batch.set(fs.collection('notifications').doc(notif.id), notif.toMap());
        await batch.commit();
      } catch (e) {
        AppConfig.log('Firestore transaction update error during verification: $e');
        throw Exception('Unable to verify identity right now. Please check your connection and try again.');
      }
    } else {
      InMemoryStore.instance.transactions[transactionId] = updatedTxn;
      InMemoryStore.instance.notifications[notif.id] = notif;
      InMemoryStore.instance.notifyTransactions();
      InMemoryStore.instance.notifyNotifications();
    }

    return true;
  }

  /// Step 2: Lender saves the confirmed handover live photo
  Future<void> confirmHandoverPhoto({
    required String transactionId,
    required String lenderId,
    required String photoUrl,
    required String storagePath,
  }) async {
    final txn = await getTransactionById(transactionId);
    if (txn == null) throw Exception('Transaction not found.');

    if (txn.ownerId != lenderId) {
      throw Exception('Unauthorized: Only the lender can upload handover photo.');
    }

    if (photoUrl.isEmpty) {
      throw Exception('Photo URL cannot be empty.');
    }

    final now = DateTime.now();
    final updatedTxn = txn.copyWith(
      handoverPhotoUrl: photoUrl,
      handoverPhotoStoragePath: storagePath,
      handoverPhotoUploadedAt: now,
      handoverIdentityVerified: true,
      updatedAt: now,
    );

    final firestore = this.firestore;
    if (AppConfig.isFirebaseInitialized && firestore != null) {
      await firestore.collection('transactions').doc(transactionId).update({
        'handoverPhotoUrl': photoUrl,
        'handoverPhotoStoragePath': storagePath,
        'handoverPhotoUploadedAt': FieldValue.serverTimestamp(),
        'handoverIdentityVerified': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } else {
      InMemoryStore.instance.transactions[transactionId] = updatedTxn;
      InMemoryStore.instance.notifyTransactions();
    }
  }

  /// Step 3: Lender confirms physical handover of item
  Future<void> confirmItemHandover({
    required String transactionId,
    required String lenderId,
  }) async {
    final txn = await getTransactionById(transactionId);
    if (txn == null) throw Exception('Transaction not found.');

    if (txn.ownerId != lenderId) {
      throw Exception('Unauthorized: Only the item lender can confirm handover.');
    }

    if (!txn.handoverIdentityVerified) {
      throw Exception('Cannot confirm handover: Borrower identity has not been verified.');
    }

    if (txn.handoverPhotoUrl.isEmpty) {
      throw Exception('Cannot confirm handover: Live handover photo is required.');
    }

    if (txn.status != 'scheduled') {
      throw Exception('Transaction has already been handed over or is not in scheduled stage.');
    }

    final now = DateTime.now();
    final updatedTxn = txn.copyWith(
      handoverConfirmed: true,
      handoverConfirmedAt: now,
      pickupConfirmed: true,
      pickupTime: now,
      status: 'active',
      updatedAt: now,
    );

    final notif = NotificationModel(
      id: FirestoreIdGenerator.generateId('notifications'),
      recipientId: txn.borrowerId,
      senderId: lenderId,
      type: 'handover_confirmed',
      title: 'Item Handed Over! 🚀',
      message: 'Handover confirmed for "${txn.itemName}". Item is now active. Please return it on time.',
      relatedId: transactionId,
    );

    final firestore = this.firestore;
    if (AppConfig.isFirebaseInitialized && firestore != null) {
      final batch = firestore.batch();
      batch.update(firestore.collection('transactions').doc(transactionId), {
        'handoverConfirmed': true,
        'handoverConfirmedAt': FieldValue.serverTimestamp(),
        'pickupConfirmed': true,
        'pickupTime': FieldValue.serverTimestamp(),
        'status': 'active',
        'updatedAt': FieldValue.serverTimestamp(),
      });
      batch.update(firestore.collection('items').doc(txn.itemId), {
        'availability': 'borrowed',
        'updatedAt': FieldValue.serverTimestamp(),
      });
      batch.update(firestore.collection('borrow_requests').doc(txn.requestId), {
        'status': 'active',
        'updatedAt': FieldValue.serverTimestamp(),
      });
      batch.set(firestore.collection('notifications').doc(notif.id), notif.toMap());
      await batch.commit();
    } else {
      InMemoryStore.instance.transactions[transactionId] = updatedTxn;
      final item = InMemoryStore.instance.items[txn.itemId];
      if (item != null) {
        InMemoryStore.instance.items[txn.itemId] = item.copyWith(
          availability: 'borrowed',
        );
      }
      final req = InMemoryStore.instance.requests[txn.requestId];
      if (req != null) {
        InMemoryStore.instance.requests[txn.requestId] = req.copyWith(
          status: 'active',
        );
      }
      InMemoryStore.instance.notifications[notif.id] = notif;
      InMemoryStore.instance.notifyTransactions();
      InMemoryStore.instance.notifyItems();
      InMemoryStore.instance.notifyRequests();
      InMemoryStore.instance.notifyNotifications();
    }
  }

  /// Borrower initiates return of the borrowed item
  Future<void> requestReturn({
    required String transactionId,
    required String currentUserId,
  }) async {
    final txn = await getTransactionById(transactionId);
    if (txn == null) throw Exception('Transaction not found.');

    if (txn.borrowerId != currentUserId) {
      throw Exception('Unauthorized: Only the borrower can initiate return.');
    }

    if (txn.status != 'active') {
      throw Exception('Return can only be initiated while the item is actively borrowed.');
    }

    final now = DateTime.now();
    final updatedTxn = txn.copyWith(
      returnRequestedAt: now,
      status: 'return_requested',
      updatedAt: now,
    );

    final notif = NotificationModel(
      id: FirestoreIdGenerator.generateId('notifications'),
      recipientId: txn.ownerId,
      senderId: currentUserId,
      type: 'return_requested',
      title: 'Return Requested 📦',
      message: '${txn.borrowerName} has requested to return "${txn.itemName}". Open chat to verify identity and inspect condition.',
      relatedId: transactionId,
    );

    final firestore = this.firestore;
    if (AppConfig.isFirebaseInitialized && firestore != null) {
      final batch = firestore.batch();
      batch.update(firestore.collection('transactions').doc(transactionId), {
        'returnRequestedAt': FieldValue.serverTimestamp(),
        'status': 'return_requested',
        'updatedAt': FieldValue.serverTimestamp(),
      });
      batch.update(firestore.collection('borrow_requests').doc(txn.requestId), {
        'status': 'return_requested',
        'updatedAt': FieldValue.serverTimestamp(),
      });
      batch.set(firestore.collection('notifications').doc(notif.id), notif.toMap());
      await batch.commit();
    } else {
      InMemoryStore.instance.transactions[transactionId] = updatedTxn;
      final req = InMemoryStore.instance.requests[txn.requestId];
      if (req != null) {
        InMemoryStore.instance.requests[txn.requestId] = req.copyWith(
          status: 'return_requested',
        );
      }
      InMemoryStore.instance.notifications[notif.id] = notif;
      InMemoryStore.instance.notifyTransactions();
      InMemoryStore.instance.notifyRequests();
      InMemoryStore.instance.notifyNotifications();
    }
  }

  /// Step 4: Verify recipient identity at return against Firestore
  /// At return, the lender is receiving the item back. Borrower verifies lender's College ID.
  Future<bool> verifyLenderIdentityForReturn({
    required String transactionId,
    required String borrowerId,
    required String enteredRegisterNumber,
  }) async {
    final txn = await getTransactionById(transactionId);
    if (txn == null) {
      throw Exception('Unable to verify the College ID right now. Please check your connection and try again.');
    }

    if (txn.borrowerId != borrowerId) {
      throw Exception('You are not authorized to verify this transaction. (Unauthorized: You are not authorized to verify this transaction.)');
    }

    if (txn.status != 'return_requested') {
      throw Exception('Verification failed. Return verification is only permitted during the return_requested stage.');
    }

    final trimmedInput = enteredRegisterNumber.trim();
    if (trimmedInput.isEmpty) {
      throw Exception("Please enter the lender's College ID. (Please enter the lender's register number.)");
    }

    // Direct Firestore fetch of lender profile
    UserModel? lender;
    final fs = firestore;
    if (AppConfig.isFirebaseInitialized && fs != null) {
      try {
        final lenderDoc = await fs.collection('users').doc(txn.ownerId).get();
        if (lenderDoc.exists && lenderDoc.data() != null) {
          final data = lenderDoc.data()!;
          lender = UserModel.fromFirestore(lenderDoc);
          final docCollegeId = (data['collegeId'] ?? data['registerNumber'] ?? '').toString().trim();
          if (lender.collegeId.trim().isEmpty && docCollegeId.isNotEmpty) {
            lender = lender.copyWith(collegeId: docCollegeId);
          }
        }
      } catch (e) {
        AppConfig.log('Firestore lender fetch error during verification: $e');
        throw Exception('Unable to verify the College ID right now. Please check your connection and try again.');
      }
    } else {
      lender = InMemoryStore.instance.users[txn.ownerId];
    }

    if (lender == null ||
        (lender.registerNumber.trim().isEmpty && lender.collegeId.trim().isEmpty)) {
      throw Exception("The lender's College ID is not available. Please contact the administrator. (This lender’s register number is not available in the database. Please contact the administrator.)");
    }

    final lenderReg = lender.registerNumber.trim();
    final lenderCollegeId = lender.collegeId.trim();
    final normalizedLenderReg = normalizeRegisterNumber(lenderReg);
    final normalizedLenderCollegeId = normalizeRegisterNumber(lenderCollegeId);

    final isMatch = (lenderCollegeId.isNotEmpty && trimmedInput.toLowerCase() == lenderCollegeId.toLowerCase()) ||
        (lenderReg.isNotEmpty && trimmedInput.toLowerCase() == lenderReg.toLowerCase()) ||
        (normalizedLenderCollegeId.isNotEmpty && normalizeRegisterNumber(trimmedInput) == normalizedLenderCollegeId) ||
        (normalizedLenderReg.isNotEmpty && normalizeRegisterNumber(trimmedInput) == normalizedLenderReg);

    if (!isMatch) {
      throw Exception("Verification failed. The College ID does not match the lender's registered ID. Please check and try again. (Verification Failed. The register number does not match the lender’s records.)");
    }

    final now = DateTime.now();
    final effectiveId = lenderCollegeId.isNotEmpty ? lenderCollegeId : lenderReg;
    final maskedLenderReg = AppHelpers.maskRegisterNumber(effectiveId);
    final updatedTxn = txn.copyWith(
      returnIdentityVerified: true,
      returnVerifiedBy: borrowerId,
      returnVerifiedAt: now,
      maskedLenderRegisterNumber: maskedLenderReg,
      updatedAt: now,
    );

    final notif = NotificationModel(
      id: FirestoreIdGenerator.generateId('notifications'),
      recipientId: txn.ownerId,
      senderId: borrowerId,
      type: 'return_identity_verified',
      title: 'Return Identity Verified ✅',
      message: '${txn.borrowerName} has verified your identity for receiving "${txn.itemName}".',
      relatedId: transactionId,
    );

    if (AppConfig.isFirebaseInitialized && fs != null) {
      try {
        final batch = fs.batch();
        batch.update(fs.collection('transactions').doc(transactionId), {
          'returnIdentityVerified': true,
          'returnVerifiedBy': borrowerId,
          'returnVerifiedAt': FieldValue.serverTimestamp(),
          'maskedLenderRegisterNumber': maskedLenderReg,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        batch.set(fs.collection('notifications').doc(notif.id), notif.toMap());
        await batch.commit();
      } catch (e) {
        AppConfig.log('Firestore return verification update error: $e');
        throw Exception('Unable to verify identity right now. Please check your connection and try again.');
      }
    } else {
      InMemoryStore.instance.transactions[transactionId] = updatedTxn;
      InMemoryStore.instance.notifications[notif.id] = notif;
      InMemoryStore.instance.notifyTransactions();
      InMemoryStore.instance.notifyNotifications();
    }

    return true;
  }

  /// Step 5: Save confirmed return live photo
  Future<void> confirmReturnPhoto({
    required String transactionId,
    required String currentUserId,
    required String photoUrl,
    required String storagePath,
  }) async {
    final txn = await getTransactionById(transactionId);
    if (txn == null) throw Exception('Transaction not found.');

    if (txn.borrowerId != currentUserId && txn.ownerId != currentUserId) {
      throw Exception('Unauthorized participant.');
    }

    if (photoUrl.isEmpty) {
      throw Exception('Photo URL cannot be empty.');
    }

    if (photoUrl == txn.handoverPhotoUrl && photoUrl.isNotEmpty) {
      throw Exception('A fresh return photo must be captured. Cannot reuse borrowing handover photo.');
    }

    final now = DateTime.now();
    final updatedTxn = txn.copyWith(
      returnPhotoUrl: photoUrl,
      returnPhotoStoragePath: storagePath,
      returnPhotoUploadedAt: now,
      returnIdentityVerified: true,
      updatedAt: now,
    );

    final firestore = this.firestore;
    if (AppConfig.isFirebaseInitialized && firestore != null) {
      await firestore.collection('transactions').doc(transactionId).update({
        'returnPhotoUrl': photoUrl,
        'returnPhotoStoragePath': storagePath,
        'returnPhotoUploadedAt': FieldValue.serverTimestamp(),
        'returnIdentityVerified': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } else {
      InMemoryStore.instance.transactions[transactionId] = updatedTxn;
      InMemoryStore.instance.notifyTransactions();
    }
  }

  /// Step 5b: Borrower confirms item was handed back
  Future<void> confirmBorrowerReturnHandback({
    required String transactionId,
    required String borrowerId,
  }) async {
    final txn = await getTransactionById(transactionId);
    if (txn == null) throw Exception('Transaction not found.');

    if (txn.borrowerId != borrowerId) {
      throw Exception('Unauthorized: Only the borrower can confirm hand-back.');
    }

    if (!txn.returnIdentityVerified) {
      throw Exception('Cannot confirm hand-back: Lender identity verification is required.');
    }

    if (txn.returnPhotoUrl.isEmpty) {
      throw Exception('Cannot confirm hand-back: Return evidence photo is required.');
    }

    final now = DateTime.now();
    final updatedTxn = txn.copyWith(
      borrowerReturnConfirmed: true,
      borrowerReturnConfirmedAt: now,
      updatedAt: now,
    );

    final firestore = this.firestore;
    if (AppConfig.isFirebaseInitialized && firestore != null) {
      await firestore.collection('transactions').doc(transactionId).update({
        'borrowerReturnConfirmed': true,
        'borrowerReturnConfirmedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } else {
      InMemoryStore.instance.transactions[transactionId] = updatedTxn;
      InMemoryStore.instance.notifyTransactions();
    }
  }

  /// Step 6: Final return confirmation & complete transaction
  Future<void> confirmReturnAndComplete({
    required String transactionId,
    required String currentUserId,
    String returnCondition = 'good',
    bool damageReported = false,
    String? damageDetails,
    bool isAdmin = false,
  }) async {
    final txn = await getTransactionById(transactionId);
    if (txn == null) throw Exception('Transaction not found.');

    if (txn.ownerId != currentUserId && !isAdmin) {
      throw Exception('Unauthorized: Only the item lender or admin can confirm receipt and close transaction.');
    }

    if (txn.status != 'return_requested') {
      throw Exception('Transaction is not in return_requested stage.');
    }

    if (!txn.returnIdentityVerified) {
      throw Exception('Cannot complete return: Identity verification is required.');
    }

    if (txn.returnPhotoUrl.isEmpty) {
      throw Exception('Cannot complete return: Return evidence photo is required.');
    }

    final now = DateTime.now();
    final updatedTxn = txn.copyWith(
      returnCondition: returnCondition,
      damageReported: damageReported,
      damageDetails: damageDetails,
      borrowerReturnConfirmed: true,
      borrowerReturnConfirmedAt: txn.borrowerReturnConfirmedAt ?? now,
      lenderReturnConfirmed: true,
      lenderReturnConfirmedAt: now,
      returnedAt: now,
      completedAt: now,
      status: 'completed',
      updatedAt: now,
    );

    final notifBorrower = NotificationModel(
      id: FirestoreIdGenerator.generateId('notifications'),
      recipientId: txn.borrowerId,
      senderId: txn.ownerId,
      senderName: txn.ownerName,
      type: 'feedback_request',
      title: 'Leave Feedback for ${txn.ownerName} ⭐',
      message: 'Item "${txn.itemName}" return complete! Please rate and review your lender.',
      relatedId: transactionId,
    );

    final notifLender = NotificationModel(
      id: FirestoreIdGenerator.generateId('notifications'),
      recipientId: txn.ownerId,
      senderId: txn.borrowerId,
      senderName: txn.borrowerName,
      type: 'feedback_request',
      title: 'Leave Feedback for ${txn.borrowerName} ⭐',
      message: 'Item "${txn.itemName}" return complete! Please rate and review your borrower.',
      relatedId: transactionId,
    );

    final itemAvailability = damageReported ? 'inactive' : 'available';

    final firestore = this.firestore;
    if (AppConfig.isFirebaseInitialized && firestore != null) {
      final batch = firestore.batch();
      batch.update(firestore.collection('transactions').doc(transactionId), {
        'returnCondition': returnCondition,
        'damageReported': damageReported,
        'damageDetails': damageDetails,
        'borrowerReturnConfirmed': true,
        'borrowerReturnConfirmedAt': txn.borrowerReturnConfirmedAt != null
            ? txn.borrowerReturnConfirmedAt!
            : FieldValue.serverTimestamp(),
        'lenderReturnConfirmed': true,
        'lenderReturnConfirmedAt': FieldValue.serverTimestamp(),
        'returnedAt': FieldValue.serverTimestamp(),
        'completedAt': FieldValue.serverTimestamp(),
        'status': 'completed',
        'updatedAt': FieldValue.serverTimestamp(),
      });
      batch.update(firestore.collection('items').doc(txn.itemId), {
        'availability': itemAvailability,
        if (damageReported) 'condition': 'damaged',
        'updatedAt': FieldValue.serverTimestamp(),
      });
      batch.update(firestore.collection('borrow_requests').doc(txn.requestId), {
        'status': 'returned',
        'updatedAt': FieldValue.serverTimestamp(),
      });
      batch.update(firestore.collection('users').doc(txn.borrowerId), {
        'borrowedCount': FieldValue.increment(1),
      });
      batch.set(firestore.collection('notifications').doc(notifBorrower.id), notifBorrower.toMap());
      batch.set(firestore.collection('notifications').doc(notifLender.id), notifLender.toMap());
      await batch.commit();
    } else {
      InMemoryStore.instance.transactions[transactionId] = updatedTxn;
      final item = InMemoryStore.instance.items[txn.itemId];
      if (item != null) {
        InMemoryStore.instance.items[txn.itemId] = item.copyWith(
          availability: itemAvailability,
          condition: damageReported ? 'damaged' : item.condition,
        );
      }
      final req = InMemoryStore.instance.requests[txn.requestId];
      if (req != null) {
        InMemoryStore.instance.requests[txn.requestId] = req.copyWith(
          status: 'returned',
        );
      }
      final borrower = InMemoryStore.instance.users[txn.borrowerId];
      if (borrower != null) {
        InMemoryStore.instance.users[txn.borrowerId] = borrower.copyWith(
          borrowedCount: borrower.borrowedCount + 1,
        );
      }
      InMemoryStore.instance.notifications[notifBorrower.id] = notifBorrower;
      InMemoryStore.instance.notifications[notifLender.id] = notifLender;
      InMemoryStore.instance.notifyTransactions();
      InMemoryStore.instance.notifyItems();
      InMemoryStore.instance.notifyRequests();
      InMemoryStore.instance.notifyUsers();
      InMemoryStore.instance.notifyNotifications();
    }
  }

  /// Backward-compatible wrapper for confirmReturnReceipt
  Future<void> confirmReturnReceipt({
    required String transactionId,
    required String currentUserId,
    bool isAdmin = false,
  }) async {
    return confirmReturnAndComplete(
      transactionId: transactionId,
      currentUserId: currentUserId,
      isAdmin: isAdmin,
    );
  }

  /// Legacy confirm readiness for handover (if both confirm)
  Future<void> confirmHandoverReadiness({
    required String transactionId,
    required String currentUserId,
  }) async {
    final txn = await getTransactionById(transactionId);
    if (txn == null) throw Exception('Transaction not found.');

    final isOwner = txn.ownerId == currentUserId;
    final isBorrower = txn.borrowerId == currentUserId;

    if (!isOwner && !isBorrower) {
      throw Exception('Unauthorized: You are not a participant in this transaction.');
    }

    final newOwnerReady = isOwner ? true : txn.ownerReady;
    final newBorrowerReady = isBorrower ? true : txn.borrowerReady;

    final updatedTxn = txn.copyWith(
      ownerReady: newOwnerReady,
      borrowerReady: newBorrowerReady,
      updatedAt: DateTime.now(),
    );

    final otherUserId = isOwner ? txn.borrowerId : txn.ownerId;
    final otherRole = isOwner ? 'Owner' : 'Borrower';
    final notif = NotificationModel(
      id: FirestoreIdGenerator.generateId('notifications'),
      recipientId: otherUserId,
      senderId: currentUserId,
      type: 'handover_ready',
      title: '$otherRole Ready for Handover',
      message: '$otherRole is ready at the meeting location for "${txn.itemName}".',
      relatedId: txn.id,
    );

    final firestore = this.firestore;
    if (AppConfig.isFirebaseInitialized && firestore != null) {
      final batch = firestore.batch();
      batch.update(
        firestore.collection('transactions').doc(transactionId),
        updatedTxn.toMap(),
      );
      batch.set(
        firestore.collection('notifications').doc(notif.id),
        notif.toMap(),
      );
      await batch.commit();
    } else {
      InMemoryStore.instance.transactions[transactionId] = updatedTxn;
      InMemoryStore.instance.notifications[notif.id] = notif;
      InMemoryStore.instance.notifyTransactions();
      InMemoryStore.instance.notifyNotifications();
    }
  }

  /// Stream of all transactions across campus for administrative management
  Stream<List<TransactionModel>> getAllTransactionsStream() {
    final firestore = this.firestore;
    if (AppConfig.isFirebaseInitialized && firestore != null) {
      return firestore
          .collection('transactions')
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map(
            (snapshot) => snapshot.docs
                .map((doc) => TransactionModel.fromFirestore(doc))
                .toList(),
          );
    } else {
      return InMemoryStore.instance.transactionsStream.map(
        (list) =>
            List<TransactionModel>.from(list)
              ..sort((a, b) => b.createdAt.compareTo(a.createdAt)),
      );
    }
  }
}
