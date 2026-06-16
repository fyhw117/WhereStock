import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'models.dart';

class AppState extends ChangeNotifier {
  List<Room> _rooms = [];
  List<StorageLocation> _locations = [];
  List<Category> _categories = [];
  List<InventoryItem> _items = [];
  bool _isLoading = true;

  List<Room> get rooms => _rooms;
  List<StorageLocation> get locations => _locations;
  List<Category> get categories => _categories;
  List<InventoryItem> get items => _items;
  bool get isLoading => _isLoading;

  final _uuid = const Uuid();

  AppState() {
    _loadData();
  }

  // File keys
  static const _keyRooms = 'wherestock_rooms';
  static const _keyLocations = 'wherestock_locations';
  static const _keyCategories = 'wherestock_categories';
  static const _keyItems = 'wherestock_items';

  Future<void> _loadData() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      
      final roomsJson = prefs.getString(_keyRooms);
      final locationsJson = prefs.getString(_keyLocations);
      final categoriesJson = prefs.getString(_keyCategories);
      final itemsJson = prefs.getString(_keyItems);

      if (roomsJson == null || locationsJson == null || categoriesJson == null || itemsJson == null) {
        // First run: load initial data
        _initDefaultData();
        await _saveAll();
      } else {
        _rooms = (json.decode(roomsJson) as List)
            .map((e) => Room.fromJson(e as Map<String, dynamic>))
            .toList();
        _locations = (json.decode(locationsJson) as List)
            .map((e) => StorageLocation.fromJson(e as Map<String, dynamic>))
            .toList();
        _categories = (json.decode(categoriesJson) as List)
            .map((e) => Category.fromJson(e as Map<String, dynamic>))
            .toList();
        _items = (json.decode(itemsJson) as List)
            .map((e) => InventoryItem.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      debugPrint("Error loading data: $e");
      // Fallback to defaults if load fails
      _initDefaultData();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _initDefaultData() {
    // Rooms
    final kitchenId = _uuid.v4();
    final livingId = _uuid.v4();
    final bathId = _uuid.v4();

    _rooms = [
      Room(id: kitchenId, name: 'キッチン', iconEmoji: '🍳'),
      Room(id: livingId, name: 'リビング', iconEmoji: '🛋️'),
      Room(id: bathId, name: '洗面所', iconEmoji: '🛁'),
    ];

    // Storage Locations
    final fridgeId = _uuid.v4();
    final pantryId = _uuid.v4();
    final cabinetId = _uuid.v4();
    final sinkId = _uuid.v4();

    _locations = [
      StorageLocation(id: fridgeId, roomId: kitchenId, name: '冷蔵庫', iconEmoji: '❄️'),
      StorageLocation(id: pantryId, roomId: kitchenId, name: 'パントリー', iconEmoji: '🥫'),
      StorageLocation(id: cabinetId, roomId: livingId, name: '棚A', iconEmoji: '🗄️'),
      StorageLocation(id: sinkId, roomId: bathId, name: '洗面台下', iconEmoji: '🧼'),
    ];

    // Categories
    final foodCatId = _uuid.v4();
    final dailyCatId = _uuid.v4();
    final cleanCatId = _uuid.v4();
    final medCatId = _uuid.v4();

    _categories = [
      Category(id: foodCatId, name: '食材', colorHex: '#4CAF50', iconEmoji: '🍏'),
      Category(id: dailyCatId, name: '日用品', colorHex: '#FF9800', iconEmoji: '🧻'),
      Category(id: cleanCatId, name: '掃除用具', colorHex: '#2196F3', iconEmoji: '🧹'),
      Category(id: medCatId, name: '常備薬', colorHex: '#E91E63', iconEmoji: '💊'),
    ];

    // Items
    _items = [
      InventoryItem(
        id: _uuid.v4(),
        name: '牛乳',
        storageLocationId: fridgeId,
        categoryId: foodCatId,
        quantity: 2,
        minQuantity: 1,
        notes: '賞味期限に注意',
        updatedAt: DateTime.now(),
      ),
      InventoryItem(
        id: _uuid.v4(),
        name: 'キャベツ',
        storageLocationId: fridgeId,
        categoryId: foodCatId,
        quantity: 1,
        minQuantity: 2,
        notes: '早めに消費する',
        updatedAt: DateTime.now(),
      ),
      InventoryItem(
        id: _uuid.v4(),
        name: 'カップ麺',
        storageLocationId: pantryId,
        categoryId: foodCatId,
        quantity: 5,
        minQuantity: 3,
        notes: '非常食兼用',
        updatedAt: DateTime.now(),
      ),
      InventoryItem(
        id: _uuid.v4(),
        name: '乾電池',
        storageLocationId: cabinetId,
        categoryId: dailyCatId,
        quantity: 8,
        minQuantity: 4,
        notes: '単3・単4',
        updatedAt: DateTime.now(),
      ),
      InventoryItem(
        id: _uuid.v4(),
        name: '洗濯洗剤',
        storageLocationId: sinkId,
        categoryId: cleanCatId,
        quantity: 0,
        minQuantity: 1,
        notes: '詰め替え用も切らし中',
        updatedAt: DateTime.now(),
      ),
    ];
  }

  // Save methods
  Future<void> _saveAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyRooms, json.encode(_rooms.map((e) => e.toJson()).toList()));
      await prefs.setString(_keyLocations, json.encode(_locations.map((e) => e.toJson()).toList()));
      await prefs.setString(_keyCategories, json.encode(_categories.map((e) => e.toJson()).toList()));
      await prefs.setString(_keyItems, json.encode(_items.map((e) => e.toJson()).toList()));
    } catch (e) {
      debugPrint("Error saving data: $e");
    }
  }

  // Room methods
  void addRoom(String name, String iconEmoji) {
    final room = Room(id: _uuid.v4(), name: name, iconEmoji: iconEmoji);
    _rooms.add(room);
    _saveAll();
    notifyListeners();
  }

  void editRoom(String id, String name, String iconEmoji) {
    final index = _rooms.indexWhere((r) => r.id == id);
    if (index != -1) {
      _rooms[index] = Room(id: id, name: name, iconEmoji: iconEmoji);
      _saveAll();
      notifyListeners();
    }
  }

  void deleteRoom(String id) {
    _rooms.removeWhere((r) => r.id == id);
    // Cascade delete locations
    final locsToDelete = _locations.where((l) => l.roomId == id).map((l) => l.id).toList();
    _locations.removeWhere((l) => l.roomId == id);
    // Cascade delete items in those locations
    _items.removeWhere((item) => locsToDelete.contains(item.storageLocationId));
    _saveAll();
    notifyListeners();
  }

  // Location methods
  void addLocation(String roomId, String name, String iconEmoji) {
    final loc = StorageLocation(id: _uuid.v4(), roomId: roomId, name: name, iconEmoji: iconEmoji);
    _locations.add(loc);
    _saveAll();
    notifyListeners();
  }

  void editLocation(String id, String name, String iconEmoji) {
    final index = _locations.indexWhere((l) => l.id == id);
    if (index != -1) {
      final old = _locations[index];
      _locations[index] = StorageLocation(id: id, roomId: old.roomId, name: name, iconEmoji: iconEmoji);
      _saveAll();
      notifyListeners();
    }
  }

  void deleteLocation(String id) {
    _locations.removeWhere((l) => l.id == id);
    // Cascade delete items in this location
    _items.removeWhere((item) => item.storageLocationId == id);
    _saveAll();
    notifyListeners();
  }

  // Category methods
  void addCategory(String name, String colorHex, String iconEmoji) {
    final cat = Category(id: _uuid.v4(), name: name, colorHex: colorHex, iconEmoji: iconEmoji);
    _categories.add(cat);
    _saveAll();
    notifyListeners();
  }

  void editCategory(String id, String name, String colorHex, String iconEmoji) {
    final index = _categories.indexWhere((c) => c.id == id);
    if (index != -1) {
      _categories[index] = Category(id: id, name: name, colorHex: colorHex, iconEmoji: iconEmoji);
      _saveAll();
      notifyListeners();
    }
  }

  void deleteCategory(String id) {
    _categories.removeWhere((c) => c.id == id);
    // Nullify categoryId for items using this category
    for (int i = 0; i < _items.length; i++) {
      if (_items[i].categoryId == id) {
        _items[i] = _items[i].copyWith(categoryId: null);
      }
    }
    _saveAll();
    notifyListeners();
  }

  // Item methods
  void addItem({
    required String name,
    required String storageLocationId,
    String? categoryId,
    required int quantity,
    required int minQuantity,
    required String notes,
  }) {
    final item = InventoryItem(
      id: _uuid.v4(),
      name: name,
      storageLocationId: storageLocationId,
      categoryId: categoryId,
      quantity: quantity,
      minQuantity: minQuantity,
      notes: notes,
      updatedAt: DateTime.now(),
    );
    _items.add(item);
    _saveAll();
    notifyListeners();
  }

  void editItem({
    required String id,
    required String name,
    required String storageLocationId,
    String? categoryId,
    required int quantity,
    required int minQuantity,
    required String notes,
  }) {
    final index = _items.indexWhere((item) => item.id == id);
    if (index != -1) {
      _items[index] = InventoryItem(
        id: id,
        name: name,
        storageLocationId: storageLocationId,
        categoryId: categoryId,
        quantity: quantity,
        minQuantity: minQuantity,
        notes: notes,
        updatedAt: DateTime.now(),
      );
      _saveAll();
      notifyListeners();
    }
  }

  void updateQuantity(String id, int delta) {
    final index = _items.indexWhere((item) => item.id == id);
    if (index != -1) {
      final currentQty = _items[index].quantity;
      final newQty = (currentQty + delta).clamp(0, 9999);
      _items[index] = _items[index].copyWith(
        quantity: newQty,
        updatedAt: DateTime.now(),
      );
      _saveAll();
      notifyListeners();
    }
  }

  void deleteItem(String id) {
    _items.removeWhere((item) => item.id == id);
    _saveAll();
    notifyListeners();
  }

  // Helper methods to get relationships
  Room? getRoomForLocation(String locationId) {
    final loc = _locations.firstWhere((l) => l.id == locationId, orElse: () => StorageLocation(id: '', roomId: '', name: '', iconEmoji: ''));
    if (loc.id.isEmpty) return null;
    return _rooms.firstWhere((r) => r.id == loc.roomId, orElse: () => Room(id: '', name: '', iconEmoji: ''));
  }

  StorageLocation? getLocationById(String id) {
    final index = _locations.indexWhere((l) => l.id == id);
    return index != -1 ? _locations[index] : null;
  }

  Category? getCategoryById(String? id) {
    if (id == null) return null;
    final index = _categories.indexWhere((c) => c.id == id);
    return index != -1 ? _categories[index] : null;
  }

  List<StorageLocation> getLocationsForRoom(String roomId) {
    return _locations.where((l) => l.roomId == roomId).toList();
  }

  List<InventoryItem> getItemsForLocation(String locationId) {
    return _items.where((i) => i.storageLocationId == locationId).toList();
  }

  List<InventoryItem> getItemsForRoom(String roomId) {
    final locIds = getLocationsForRoom(roomId).map((l) => l.id).toSet();
    return _items.where((i) => locIds.contains(i.storageLocationId)).toList();
  }

  List<InventoryItem> getAlertItems() {
    return _items.where((i) => i.quantity <= i.minQuantity).toList();
  }
}
