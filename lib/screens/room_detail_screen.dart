import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import '../models.dart';
import '../widgets.dart';
import 'item_form_screen.dart';

class RoomDetailScreen extends StatefulWidget {
  final Room room;

  const RoomDetailScreen({super.key, required this.room});

  @override
  State<RoomDetailScreen> createState() => _RoomDetailScreenState();
}

class _RoomDetailScreenState extends State<RoomDetailScreen> {
  String _selectedLocationId = 'all'; // 'all' or specific location ID

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppState>(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final locations = state.getLocationsForRoom(widget.room.id);
    
    // Determine which items to display
    List<InventoryItem> displayItems;
    if (_selectedLocationId == 'all') {
      displayItems = state.getItemsForRoom(widget.room.id);
    } else {
      displayItems = state.getItemsForLocation(_selectedLocationId);
    }

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Text(widget.room.iconEmoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 8),
            Text(widget.room.name),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_home_work_outlined),
            tooltip: '保管場所を追加',
            onPressed: () => _showAddLocationDialog(context, state),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Locations Selector Row
          if (locations.isNotEmpty)
            Container(
              height: 50,
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                physics: const BouncingScrollPhysics(),
                itemCount: locations.length + 1,
                itemBuilder: (context, index) {
                  final isAll = index == 0;
                  final String id = isAll ? 'all' : locations[index - 1].id;
                  final String name = isAll ? 'すべて' : locations[index - 1].name;
                  final String emoji = isAll ? '📦' : locations[index - 1].iconEmoji;
                  
                  final isSelected = _selectedLocationId == id;
                  final itemQty = isAll 
                      ? state.getItemsForRoom(widget.room.id).length
                      : state.getItemsForLocation(id).length;

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: ChoiceChip(
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(emoji),
                          const SizedBox(width: 4),
                          Text(name),
                          const SizedBox(width: 4),
                          Text(
                            '($itemQty)',
                            style: TextStyle(
                              fontSize: 10,
                              color: isSelected 
                                  ? (isDark ? Colors.black54 : Colors.white70) 
                                  : Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _selectedLocationId = id;
                          });
                        }
                      },
                      selectedColor: theme.colorScheme.primary,
                      backgroundColor: isDark ? const Color(0xFF192529) : Colors.grey.shade100,
                      labelStyle: TextStyle(
                        color: isSelected
                            ? theme.colorScheme.onPrimary
                            : theme.colorScheme.onSurface,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color: isSelected ? Colors.transparent : Colors.grey.shade300.withOpacity(0.5),
                        ),
                      ),
                      showCheckmark: false,
                    ),
                  );
                },
              ),
            ),

          // Items List View
          Expanded(
            child: locations.isEmpty
                ? EmptyState(
                    icon: '📦',
                    title: '保管場所がありません',
                    subtitle: '右上のアイコンから、冷蔵庫や棚などの保管場所を追加しましょう！',
                  )
                : displayItems.isEmpty
                    ? EmptyState(
                        icon: '📝',
                        title: '登録されたアイテムがありません',
                        subtitle: '右下の「+」ボタンから新しくアイテムを追加できます。',
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.only(bottom: 80, top: 4),
                        itemCount: displayItems.length,
                        itemBuilder: (context, index) {
                          final item = displayItems[index];
                          final cat = state.getCategoryById(item.categoryId);
                          final loc = state.getLocationById(item.storageLocationId);
                          final itemRoom = loc != null ? state.getRoomForLocation(loc.id) : null;

                          return ItemTile(
                            item: item,
                            category: cat,
                            room: _selectedLocationId == 'all' ? itemRoom : null,
                            location: _selectedLocationId == 'all' ? loc : null,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ItemFormScreen(item: item),
                                ),
                              );
                            },
                            onIncrement: () => state.updateQuantity(item.id, 1),
                            onDecrement: () => state.updateQuantity(item.id, -1),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: locations.isNotEmpty
          ? FloatingActionButton(
              heroTag: 'add_item_room',
              child: const Icon(Icons.add),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ItemFormScreen(
                      initialRoomId: widget.room.id,
                      initialLocationId: _selectedLocationId == 'all' 
                          ? locations.first.id 
                          : _selectedLocationId,
                    ),
                  ),
                );
              },
            )
          : null,
    );
  }

  void _showAddLocationDialog(BuildContext context, AppState state) {
    final nameController = TextEditingController();
    String iconEmoji = '📦';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('保管場所を追加', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: '保管場所の名前',
                      hintText: '例：冷蔵庫、パントリー、棚A',
                    ),
                    autofocus: true,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Text('アイコン (絵文字):'),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: () async {
                          // Quick selection of emojis
                          final selected = await _showEmojiPicker(context);
                          if (selected != null) {
                            setDialogState(() {
                              iconEmoji = selected;
                            });
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade400),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            iconEmoji,
                            style: const TextStyle(fontSize: 20),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('キャンセル'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final name = nameController.text.trim();
                    if (name.isNotEmpty) {
                      state.addLocation(widget.room.id, name, iconEmoji);
                      Navigator.pop(context);
                      // Update selected location if it was the first one
                      if (state.getLocationsForRoom(widget.room.id).length == 1) {
                        setState(() {
                          _selectedLocationId = state.getLocationsForRoom(widget.room.id).first.id;
                        });
                      }
                    }
                  },
                  child: const Text('追加'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<String?> _showEmojiPicker(BuildContext context) {
    final emojis = ['📦', '❄️', '🥫', '🗄️', '🧼', '🚪', '🛏️', '👚', '🧴', '🍷', '🥕', '📚'];
    return showModalBottomSheet<String>(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          height: 180,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('アイコンの絵文字を選択', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 6,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                  ),
                  itemCount: emojis.length,
                  itemBuilder: (context, index) {
                    return InkWell(
                      onTap: () => Navigator.pop(context, emojis[index]),
                      child: Center(
                        child: Text(
                          emojis[index],
                          style: const TextStyle(fontSize: 26),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
