import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/id_generator.dart';
import '../app/app_config.dart';
import '../models/item_model.dart';
import '../models/notification_model.dart';
import 'in_memory_store.dart';

class ItemService {
  final FirebaseFirestore? firestore;

  ItemService({this.firestore});

  /// Stream of all available items for the public catalog
  Stream<List<ItemModel>> getAvailableItemsStream() {
    final firestore = this.firestore;
    if (AppConfig.isFirebaseInitialized && firestore != null) {
      return firestore
          .collection('items')
          .where('availability', isEqualTo: 'available')
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map(
            (snapshot) => snapshot.docs
                .map((doc) => ItemModel.fromFirestore(doc))
                .toList(),
          );
    } else {
      return InMemoryStore.instance.itemsStream.map(
        (list) =>
            list.where((item) => item.availability == 'available').toList()
              ..sort((a, b) => b.createdAt.compareTo(a.createdAt)),
      );
    }
  }

  /// Stream of recently added items
  Stream<List<ItemModel>> getRecentItemsStream({int limit = 5}) {
    final firestore = this.firestore;
    if (AppConfig.isFirebaseInitialized && firestore != null) {
      return firestore
          .collection('items')
          .where('availability', isEqualTo: 'available')
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .snapshots()
          .map(
            (snapshot) => snapshot.docs
                .map((doc) => ItemModel.fromFirestore(doc))
                .toList(),
          );
    } else {
      return InMemoryStore.instance.itemsStream.map(
        (list) =>
            list.where((item) => item.availability == 'available').toList()
              ..sort((a, b) => b.createdAt.compareTo(a.createdAt)),
      );
    }
  }

  /// Stream of items listed by a specific student
  Stream<List<ItemModel>> getMyItemsStream(String userId) {
    final firestore = this.firestore;
    if (AppConfig.isFirebaseInitialized && firestore != null) {
      return firestore
          .collection('items')
          .where('ownerId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map(
            (snapshot) => snapshot.docs
                .map((doc) => ItemModel.fromFirestore(doc))
                .toList(),
          );
    } else {
      return InMemoryStore.instance.itemsStream.map(
        (list) =>
            list.where((item) => item.ownerId == userId).toList()
              ..sort((a, b) => b.createdAt.compareTo(a.createdAt)),
      );
    }
  }

  /// Get single item details by ID
  Future<ItemModel?> getItemById(String itemId) async {
    final firestore = this.firestore;
    if (AppConfig.isFirebaseInitialized && firestore != null) {
      final doc = await firestore.collection('items').doc(itemId).get();
      if (doc.exists) {
        return ItemModel.fromFirestore(doc);
      }
      return null;
    } else {
      return InMemoryStore.instance.items[itemId];
    }
  }

  /// Create a new item listing
  Future<String> createItem(ItemModel item) async {
    final itemId = item.id.isNotEmpty
        ? item.id
        : FirestoreIdGenerator.generateId('items');
    final newItem = item.copyWith(id: itemId);

    final firestore = this.firestore;
    if (AppConfig.isFirebaseInitialized && firestore != null) {
      await firestore.collection('items').doc(itemId).set(newItem.toMap());
      // Increment user's item count
      await firestore.collection('users').doc(item.ownerId).update({
        'itemsListedCount': FieldValue.increment(1),
      });
    } else {
      InMemoryStore.instance.items[itemId] = newItem;
      final owner = InMemoryStore.instance.users[item.ownerId];
      if (owner != null) {
        InMemoryStore.instance.users[item.ownerId] = owner.copyWith(
          itemsListedCount: owner.itemsListedCount + 1,
        );
      }
      InMemoryStore.instance.notifyItems();
      InMemoryStore.instance.notifyUsers();
    }

    return itemId;
  }

  /// Update item details (Only owner can edit)
  Future<void> updateItem({
    required ItemModel item,
    required String currentUserId,
  }) async {
    if (item.ownerId != currentUserId) {
      throw Exception('Unauthorized: You can only edit your own items.');
    }

    final updated = item.copyWith(updatedAt: DateTime.now());

    final firestore = this.firestore;
    if (AppConfig.isFirebaseInitialized && firestore != null) {
      await firestore.collection('items').doc(item.id).update(updated.toMap());
    } else {
      InMemoryStore.instance.items[item.id] = updated;
      InMemoryStore.instance.notifyItems();
    }
  }

  /// Update item availability status (available, reserved, borrowed, inactive)
  Future<void> updateItemAvailability({
    required String itemId,
    required String availability,
    required String currentUserId,
    bool isAdmin = false,
  }) async {
    final item = await getItemById(itemId);
    if (item == null) throw Exception('Item not found.');

    if (item.ownerId != currentUserId && !isAdmin) {
      throw Exception(
        'Unauthorized: Only item owner or admin can update status.',
      );
    }

    final updated = item.copyWith(
      availability: availability,
      updatedAt: DateTime.now(),
    );

    final firestore = this.firestore;
    if (AppConfig.isFirebaseInitialized && firestore != null) {
      await firestore.collection('items').doc(itemId).update({
        'availability': availability,
        'updatedAt': Timestamp.now(),
      });
    } else {
      InMemoryStore.instance.items[itemId] = updated;
      InMemoryStore.instance.notifyItems();
    }
  }

  /// Delete / Deactivate item
  Future<void> deleteItem({
    required String itemId,
    required String currentUserId,
    bool isAdmin = false,
  }) async {
    final item = await getItemById(itemId);
    if (item == null) throw Exception('Item not found.');

    if (item.ownerId != currentUserId && !isAdmin) {
      throw Exception('Unauthorized: Only item owner or admin can delete.');
    }

    final firestore = this.firestore;
    if (AppConfig.isFirebaseInitialized && firestore != null) {
      await firestore.collection('items').doc(itemId).delete();
      await firestore.collection('users').doc(item.ownerId).update({
        'itemsListedCount': FieldValue.increment(-1),
      });
    } else {
      InMemoryStore.instance.items.remove(itemId);
      final owner = InMemoryStore.instance.users[item.ownerId];
      if (owner != null && owner.itemsListedCount > 0) {
        InMemoryStore.instance.users[item.ownerId] = owner.copyWith(
          itemsListedCount: owner.itemsListedCount - 1,
        );
      }
      InMemoryStore.instance.notifyItems();
      InMemoryStore.instance.notifyUsers();
    }
  }

  /// Search and filter items
  List<ItemModel> filterItems({
    required List<ItemModel> allItems,
    String? query,
    String? category,
    String? department,
    String? availability,
    String? sortBy, // 'recent', 'name', 'condition'
  }) {
    var result = List<ItemModel>.from(allItems);

    // Filter by availability
    if (availability != null && availability != 'All') {
      result = result
          .where(
            (item) =>
                item.availability.toLowerCase() == availability.toLowerCase(),
          )
          .toList();
    }

    // Filter by category
    if (category != null && category != 'All') {
      result = result
          .where(
            (item) => item.category.toLowerCase() == category.toLowerCase(),
          )
          .toList();
    }

    // Filter by department
    if (department != null && department.isNotEmpty && department != 'All') {
      result = result
          .where(
            (item) =>
                item.ownerDepartment.toLowerCase() == department.toLowerCase(),
          )
          .toList();
    }

    // Search query
    if (query != null && query.trim().isNotEmpty) {
      final q = query.trim().toLowerCase();
      result = result.where((item) {
        return item.name.toLowerCase().contains(q) ||
            item.description.toLowerCase().contains(q) ||
            item.pickupLocation.toLowerCase().contains(q);
      }).toList();
    }

    // Sorting
    if (sortBy == 'name') {
      result.sort(
        (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      );
    } else {
      // Default recent
      result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }

    return result;
  }

  /// Stream of all items across campus (for administrative management)
  Stream<List<ItemModel>> getAllItemsStream() {
    final firestore = this.firestore;
    if (AppConfig.isFirebaseInitialized && firestore != null) {
      return firestore
          .collection('items')
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map(
            (snapshot) => snapshot.docs
                .map((doc) => ItemModel.fromFirestore(doc))
                .toList(),
          );
    } else {
      return InMemoryStore.instance.itemsStream.map(
        (list) =>
            List<ItemModel>.from(list)
              ..sort((a, b) => b.createdAt.compareTo(a.createdAt)),
      );
    }
  }

  /// Deactivate an inappropriate item with justification and owner notice
  Future<void> adminDeactivateItem({
    required String itemId,
    required String reason,
    required String adminUid,
    String adminName = 'Campus Administrator',
  }) async {
    final item = await getItemById(itemId);
    if (item == null) throw Exception('Item not found.');

    final notifId = FirestoreIdGenerator.generateId('notifications');

    final firestore = this.firestore;
    if (AppConfig.isFirebaseInitialized && firestore != null) {
      final notif = NotificationModel(
        id: notifId,
        recipientId: item.ownerId,
        senderId: adminUid,
        senderName: adminName,
        type: 'admin_notice',
        title: 'Listing Deactivated by Admin',
        message:
            'Your listed item "${item.name}" was deactivated by campus admin: $reason',
        relatedId: itemId,
      );

      final batch = firestore.batch();
      batch.update(firestore.collection('items').doc(itemId), {
        'availability': 'inactive',
        'updatedAt': Timestamp.now(),
      });
      batch.set(
        firestore.collection('notifications').doc(notifId),
        notif.toMap(),
      );
      await batch.commit();
    } else {
      final updated = item.copyWith(
        availability: 'inactive',
        updatedAt: DateTime.now(),
      );
      InMemoryStore.instance.items[itemId] = updated;
      final notif = NotificationModel(
        id: notifId,
        recipientId: item.ownerId,
        senderId: adminUid,
        senderName: adminName,
        type: 'admin_notice',
        title: 'Listing Deactivated by Admin',
        message:
            'Your listed item "${item.name}" was deactivated by campus admin: $reason',
        relatedId: itemId,
      );
      InMemoryStore.instance.notifications[notifId] = notif;
      InMemoryStore.instance.notifyItems();
      InMemoryStore.instance.notifyNotifications();
    }
  }
}
