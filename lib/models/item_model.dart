import 'package:cloud_firestore/cloud_firestore.dart';

class ItemModel {
  final String id;
  final String name;
  final String category;
  final String description;
  final String condition;
  final String photoUrl;
  final String pickupLocation;
  final String availability; // 'available', 'reserved', 'borrowed', 'inactive'
  final String ownerId;
  final String ownerName;
  final String ownerDepartment;
  final String ownerPhotoUrl;
  final double ownerRating;
  final DateTime createdAt;
  final DateTime updatedAt;

  ItemModel({
    required this.id,
    required this.name,
    required this.category,
    required this.description,
    required this.condition,
    this.photoUrl = '',
    required this.pickupLocation,
    this.availability = 'available',
    required this.ownerId,
    required this.ownerName,
    this.ownerDepartment = '',
    this.ownerPhotoUrl = '',
    this.ownerRating = 0.0,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  bool get isAvailable => availability == 'available';
  bool get isReserved => availability == 'reserved';
  bool get isBorrowed => availability == 'borrowed';
  bool get isInactive => availability == 'inactive';

  ItemModel copyWith({
    String? id,
    String? name,
    String? category,
    String? description,
    String? condition,
    String? photoUrl,
    String? pickupLocation,
    String? availability,
    String? ownerId,
    String? ownerName,
    String? ownerDepartment,
    String? ownerPhotoUrl,
    double? ownerRating,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ItemModel(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      description: description ?? this.description,
      condition: condition ?? this.condition,
      photoUrl: photoUrl ?? this.photoUrl,
      pickupLocation: pickupLocation ?? this.pickupLocation,
      availability: availability ?? this.availability,
      ownerId: ownerId ?? this.ownerId,
      ownerName: ownerName ?? this.ownerName,
      ownerDepartment: ownerDepartment ?? this.ownerDepartment,
      ownerPhotoUrl: ownerPhotoUrl ?? this.ownerPhotoUrl,
      ownerRating: ownerRating ?? this.ownerRating,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'itemId': id,
      'name': name,
      'itemName': name,
      'category': category,
      'description': description,
      'condition': condition,
      'photoUrl': photoUrl,
      'imageUrl': photoUrl.isNotEmpty ? photoUrl : null,
      'pickupLocation': pickupLocation,
      'availability': availability,
      'ownerId': ownerId,
      'ownerName': ownerName,
      'ownerDepartment': ownerDepartment,
      'ownerPhotoUrl': ownerPhotoUrl,
      'ownerRating': ownerRating,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory ItemModel.fromMap(Map<String, dynamic> map, {String? docId}) {
    DateTime parseDate(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
      return DateTime.now();
    }

    return ItemModel(
      id: docId ?? map['itemId'] ?? map['id'] ?? '',
      name: map['itemName'] ?? map['name'] ?? '',
      category: map['category'] ?? 'Other',
      description: map['description'] ?? '',
      condition: map['condition'] ?? 'Good',
      photoUrl: map['imageUrl'] ?? map['photoUrl'] ?? '',
      pickupLocation: map['pickupLocation'] ?? '',
      availability: map['availability'] ?? 'available',
      ownerId: map['ownerId'] ?? '',
      ownerName: map['ownerName'] ?? 'Student',
      ownerDepartment: map['ownerDepartment'] ?? '',
      ownerPhotoUrl: map['ownerPhotoUrl'] ?? '',
      ownerRating:
          ((map['ownerRating'] ?? map['rating']) as num?)?.toDouble().clamp(0.0, 5.0) ??
          0.0,
      createdAt: parseDate(map['createdAt']),
      updatedAt: parseDate(map['updatedAt']),
    );
  }

  factory ItemModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return ItemModel.fromMap(data, docId: doc.id);
  }
}
