import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import '../models.dart';

class ItemFormScreen extends StatefulWidget {
  final InventoryItem? item;
  final String? initialRoomId;
  final String? initialLocationId;

  const ItemFormScreen({
    super.key,
    this.item,
    this.initialRoomId,
    this.initialLocationId,
  });

  @override
  State<ItemFormScreen> createState() => _ItemFormScreenState();
}

class _ItemFormScreenState extends State<ItemFormScreen> {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _nameController;
  late TextEditingController _notesController;
  
  String? _selectedCategoryId;
  String? _selectedRoomId;
  String? _selectedLocationId;
  
  int _quantity = 1;
  int _minQuantity = 0;

  @override
  void initState() {
    super.initState();
    final isEditing = widget.item != null;
    
    _nameController = TextEditingController(text: isEditing ? widget.item!.name : '');
    _notesController = TextEditingController(text: isEditing ? widget.item!.notes : '');
    
    _quantity = isEditing ? widget.item!.quantity : 1;
    _minQuantity = isEditing ? widget.item!.minQuantity : 0;
    _selectedCategoryId = isEditing ? widget.item!.categoryId : null;

    // Set initial Room & Location values based on context
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = Provider.of<AppState>(context, listen: false);
      if (isEditing) {
        final loc = state.getLocationById(widget.item!.storageLocationId);
        setState(() {
          _selectedLocationId = widget.item!.storageLocationId;
          _selectedRoomId = loc?.roomId;
        });
      } else {
        // Adding new item
        setState(() {
          // Priority 1: initial values passed to constructor
          // Priority 2: first room / first location available
          if (widget.initialRoomId != null) {
            _selectedRoomId = widget.initialRoomId;
            _selectedLocationId = widget.initialLocationId;
          } else if (state.rooms.isNotEmpty) {
            _selectedRoomId = state.rooms.first.id;
            final locs = state.getLocationsForRoom(_selectedRoomId!);
            if (locs.isNotEmpty) {
              _selectedLocationId = locs.first.id;
            }
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppState>(context);
    final theme = Theme.of(context);
    final isEditing = widget.item != null;

    final locationsInSelectedRoom = _selectedRoomId != null 
        ? state.getLocationsForRoom(_selectedRoomId!) 
        : <StorageLocation>[];

    // Ensure _selectedLocationId is valid in the filtered locations list
    if (_selectedLocationId != null && 
        locationsInSelectedRoom.isNotEmpty && 
        !locationsInSelectedRoom.any((l) => l.id == _selectedLocationId)) {
      _selectedLocationId = locationsInSelectedRoom.first.id;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'アイテムを編集' : 'アイテムを追加'),
        actions: [
          if (isEditing)
            IconButton(
              icon: Icon(Icons.delete_outline, color: theme.colorScheme.error),
              onPressed: () => _confirmDelete(context, state),
            ),
        ],
      ),
      body: state.rooms.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  '先に「マスタ管理」から部屋を登録してください。',
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : Form(
              key: _formKey,
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                children: [
                  // Item Name Field
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'アイテム名',
                      hintText: '例：洗剤、キャベツ、単3電池',
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'アイテム名を入力してください';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Category Selector Dropdown
                  DropdownButtonFormField<String?>(
                    initialValue: _selectedCategoryId,
                    decoration: const InputDecoration(
                      labelText: 'カテゴリー',
                    ),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('未分類'),
                      ),
                      ...state.categories.map((cat) {
                        return DropdownMenuItem<String?>(
                          value: cat.id,
                          child: Row(
                            children: [
                              Text(cat.iconEmoji),
                              const SizedBox(width: 8),
                              Text(cat.name),
                            ],
                          ),
                        );
                      }),
                    ],
                    onChanged: (val) {
                      setState(() {
                        _selectedCategoryId = val;
                      });
                    },
                  ),
                  const SizedBox(height: 16),

                  // Room Selector Dropdown
                  DropdownButtonFormField<String>(
                    initialValue: _selectedRoomId,
                    decoration: const InputDecoration(
                      labelText: '部屋',
                    ),
                    items: state.rooms.map((room) {
                      return DropdownMenuItem<String>(
                        value: room.id,
                        child: Row(
                          children: [
                            Text(room.iconEmoji),
                            const SizedBox(width: 8),
                            Text(room.name),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _selectedRoomId = val;
                          final locs = state.getLocationsForRoom(val);
                          _selectedLocationId = locs.isNotEmpty ? locs.first.id : null;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),

                  // Location Selector Dropdown
                  DropdownButtonFormField<String>(
                    initialValue: _selectedLocationId,
                    decoration: const InputDecoration(
                      labelText: '保管場所',
                    ),
                    items: locationsInSelectedRoom.isEmpty
                        ? [
                            const DropdownMenuItem<String>(
                              value: '',
                              child: Text('保管場所がありません（追加してください）', style: TextStyle(color: Colors.red)),
                            )
                          ]
                        : locationsInSelectedRoom.map((loc) {
                            return DropdownMenuItem<String>(
                              value: loc.id,
                              child: Row(
                                children: [
                                  Text(loc.iconEmoji),
                                  const SizedBox(width: 8),
                                  Text(loc.name),
                                ],
                              ),
                            );
                          }).toList(),
                    onChanged: locationsInSelectedRoom.isEmpty
                        ? null
                        : (val) {
                            if (val != null && val.isNotEmpty) {
                              setState(() {
                                _selectedLocationId = val;
                              });
                            }
                          },
                    validator: (val) {
                      if (val == null || val.isEmpty) {
                        return '保管場所を選択してください';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // Quantities Section
                  Card(
                    margin: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: Colors.grey.shade300.withOpacity(0.5), width: 1),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          // Quantity Slider / Selector
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                '現在の数量',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.remove_circle_outline),
                                    onPressed: () {
                                      if (_quantity > 0) {
                                        setState(() => _quantity--);
                                      }
                                    },
                                  ),
                                  Container(
                                    width: 48,
                                    alignment: Alignment.center,
                                    child: Text(
                                      '$_quantity',
                                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.add_circle_outline),
                                    onPressed: () {
                                      setState(() => _quantity++);
                                    },
                                  ),
                                ],
                              )
                            ],
                          ),
                          const Divider(),
                          // Min Quantity / Alert Level
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '最低在庫数',
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    'この数以下になるとアラート表示します',
                                    style: TextStyle(fontSize: 10, color: Colors.grey),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.remove_circle_outline),
                                    onPressed: () {
                                      if (_minQuantity > 0) {
                                        setState(() => _minQuantity--);
                                      }
                                    },
                                  ),
                                  Container(
                                    width: 48,
                                    alignment: Alignment.center,
                                    child: Text(
                                      '$_minQuantity',
                                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.add_circle_outline),
                                    onPressed: () {
                                      setState(() => _minQuantity++);
                                    },
                                  ),
                                ],
                              )
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Notes Field
                  TextFormField(
                    controller: _notesController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'メモ（買い出し時の注意や賞味期限など）',
                      hintText: '例：特売は水曜日、賞味期限6ヶ月など',
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Save Button
                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: theme.colorScheme.onPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        if (_formKey.currentState!.validate() && 
                            _selectedLocationId != null && 
                            _selectedLocationId!.isNotEmpty) {
                          if (isEditing) {
                            state.editItem(
                              id: widget.item!.id,
                              name: _nameController.text.trim(),
                              storageLocationId: _selectedLocationId!,
                              categoryId: _selectedCategoryId,
                              quantity: _quantity,
                              minQuantity: _minQuantity,
                              notes: _notesController.text.trim(),
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('アイテムを更新しました')),
                            );
                          } else {
                            state.addItem(
                              name: _nameController.text.trim(),
                              storageLocationId: _selectedLocationId!,
                              categoryId: _selectedCategoryId,
                              quantity: _quantity,
                              minQuantity: _minQuantity,
                              notes: _notesController.text.trim(),
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('アイテムを追加しました')),
                            );
                          }
                          Navigator.pop(context);
                        }
                      },
                      child: Text(
                        isEditing ? '更新する' : '追加する',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  void _confirmDelete(BuildContext context, AppState state) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('アイテムを削除しますか？', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          content: Text('「${widget.item!.name}」を削除してもよろしいですか？この操作は戻せません。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('キャンセル'),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              onPressed: () {
                state.deleteItem(widget.item!.id);
                Navigator.pop(context); // Dialog
                Navigator.pop(context); // ItemFormScreen
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('アイテムを削除しました')),
                );
              },
              child: const Text('削除'),
            ),
          ],
        );
      },
    );
  }
}
