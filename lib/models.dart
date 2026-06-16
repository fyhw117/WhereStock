class Room {
  final String id;
  final String name;
  final String iconEmoji;

  Room({
    required this.id,
    required this.name,
    required this.iconEmoji,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'iconEmoji': iconEmoji,
      };

  factory Room.fromJson(Map<String, dynamic> json) => Room(
        id: json['id'] as String,
        name: json['name'] as String,
        iconEmoji: json['iconEmoji'] as String? ?? '🏠',
      );
}

class StorageLocation {
  final String id;
  final String roomId;
  final String name;
  final String iconEmoji;

  StorageLocation({
    required this.id,
    required this.roomId,
    required this.name,
    required this.iconEmoji,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'roomId': roomId,
        'name': name,
        'iconEmoji': iconEmoji,
      };

  factory StorageLocation.fromJson(Map<String, dynamic> json) => StorageLocation(
        id: json['id'] as String,
        roomId: json['roomId'] as String,
        name: json['name'] as String,
        iconEmoji: json['iconEmoji'] as String? ?? '📦',
      );
}

class Category {
  final String id;
  final String name;
  final String colorHex;
  final String iconEmoji;

  Category({
    required this.id,
    required this.name,
    required this.colorHex,
    required this.iconEmoji,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'colorHex': colorHex,
        'iconEmoji': iconEmoji,
      };

  factory Category.fromJson(Map<String, dynamic> json) => Category(
        id: json['id'] as String,
        name: json['name'] as String,
        colorHex: json['colorHex'] as String,
        iconEmoji: json['iconEmoji'] as String? ?? '🏷️',
      );
}

class InventoryItem {
  final String id;
  final String name;
  final String storageLocationId;
  final String? categoryId;
  final int quantity;
  final int minQuantity;
  final String notes;
  final DateTime updatedAt;

  InventoryItem({
    required this.id,
    required this.name,
    required this.storageLocationId,
    this.categoryId,
    required this.quantity,
    this.minQuantity = 0,
    this.notes = '',
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'storageLocationId': storageLocationId,
        'categoryId': categoryId,
        'quantity': quantity,
        'minQuantity': minQuantity,
        'notes': notes,
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory InventoryItem.fromJson(Map<String, dynamic> json) => InventoryItem(
        id: json['id'] as String,
        name: json['name'] as String,
        storageLocationId: json['storageLocationId'] as String,
        categoryId: json['categoryId'] as String?,
        quantity: json['quantity'] as int? ?? 0,
        minQuantity: json['minQuantity'] as int? ?? 0,
        notes: json['notes'] as String? ?? '',
        updatedAt: json['updatedAt'] != null
            ? DateTime.parse(json['updatedAt'] as String)
            : DateTime.now(),
      );

  InventoryItem copyWith({
    String? name,
    String? storageLocationId,
    String? categoryId,
    int? quantity,
    int? minQuantity,
    String? notes,
    DateTime? updatedAt,
  }) {
    return InventoryItem(
      id: id,
      name: name ?? this.name,
      storageLocationId: storageLocationId ?? this.storageLocationId,
      categoryId: categoryId ?? this.categoryId,
      quantity: quantity ?? this.quantity,
      minQuantity: minQuantity ?? this.minQuantity,
      notes: notes ?? this.notes,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}
