import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import '../models.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('マスタデータ管理'),
          bottom: TabBar(
            labelColor: theme.colorScheme.primary,
            unselectedLabelColor: Colors.grey.shade500,
            indicatorColor: theme.colorScheme.primary,
            indicatorSize: TabBarIndicatorSize.tab,
            tabs: const [
              Tab(text: '部屋'),
              Tab(text: '保管場所'),
              Tab(text: 'カテゴリー'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            RoomsSettingsTab(),
            LocationsSettingsTab(),
            CategoriesSettingsTab(),
          ],
        ),
      ),
    );
  }
}

// ----------------------------------------------------
// 1. Rooms Settings Tab
// ----------------------------------------------------
class RoomsSettingsTab extends StatelessWidget {
  const RoomsSettingsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppState>(context);
    final theme = Theme.of(context);

    return Scaffold(
      body: state.rooms.isEmpty
          ? const Center(child: Text('部屋が登録されていません。'))
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: state.rooms.length,
              itemBuilder: (context, index) {
                final room = state.rooms[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                    child: Text(room.iconEmoji, style: const TextStyle(fontSize: 20)),
                  ),
                  title: Text(room.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 20),
                        onPressed: () => _showRoomDialog(context, state, room: room),
                      ),
                      IconButton(
                        icon: Icon(Icons.delete_outline, size: 20, color: theme.colorScheme.error),
                        onPressed: () => _confirmDeleteRoom(context, state, room),
                      ),
                    ],
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'add_room_settings',
        onPressed: () => _showRoomDialog(context, state),
        label: const Text('部屋を追加'),
        icon: const Icon(Icons.add),
      ),
    );
  }

  void _showRoomDialog(BuildContext context, AppState state, {Room? room}) {
    final nameController = TextEditingController(text: room?.name ?? '');
    String iconEmoji = room?.iconEmoji ?? '🏠';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(room == null ? '部屋を追加' : '部屋を編集', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: '部屋の名前',
                      hintText: '例：キッチン、リビング、書斎',
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
                          final selected = await _showEmojiPicker(context, ['🏠', '🍳', '🛋️', '🛁', '🛏️', '🚪', '🪴', '🚗', '🧸', '📦']);
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
                      if (room == null) {
                        state.addRoom(name, iconEmoji);
                      } else {
                        state.editRoom(room.id, name, iconEmoji);
                      }
                      Navigator.pop(context);
                    }
                  },
                  child: Text(room == null ? '追加' : '保存'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _confirmDeleteRoom(BuildContext context, AppState state, Room room) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('部屋を削除しますか？', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          content: Text('「${room.name}」を削除すると、この部屋に属するすべての保管場所およびその中のすべてのアイテムも削除されます。よろしいですか？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('キャンセル'),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              onPressed: () {
                state.deleteRoom(room.id);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${room.name}を削除しました')),
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

// ----------------------------------------------------
// 2. Locations Settings Tab
// ----------------------------------------------------
class LocationsSettingsTab extends StatelessWidget {
  const LocationsSettingsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppState>(context);
    final theme = Theme.of(context);

    // Group locations by room
    final Map<Room, List<StorageLocation>> grouped = {};
    for (var room in state.rooms) {
      grouped[room] = state.getLocationsForRoom(room.id);
    }

    return Scaffold(
      body: state.rooms.isEmpty
          ? const Center(child: Text('先に「部屋」を登録してください。'))
          : ListView(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
              children: grouped.entries.map((entry) {
                final room = entry.key;
                final locs = entry.value;
                return Card(
                  child: ExpansionTile(
                    initiallyExpanded: true,
                    leading: Text(room.iconEmoji, style: const TextStyle(fontSize: 22)),
                    title: Text('${room.name} (${locs.length})', style: const TextStyle(fontWeight: FontWeight.bold)),
                    children: locs.isEmpty
                        ? [
                            const Padding(
                              padding: EdgeInsets.all(16),
                              child: Text('保管場所がありません。', style: TextStyle(fontSize: 12, color: Colors.grey)),
                            )
                          ]
                        : locs.map((loc) {
                            return ListTile(
                              leading: Text(loc.iconEmoji, style: const TextStyle(fontSize: 20)),
                              title: Text(loc.name),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit_outlined, size: 20),
                                    onPressed: () => _showLocationDialog(context, state, room, location: loc),
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.delete_outline, size: 20, color: theme.colorScheme.error),
                                    onPressed: () => _confirmDeleteLocation(context, state, loc),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                  ),
                );
              }).toList(),
            ),
      floatingActionButton: state.rooms.isEmpty
          ? null
          : FloatingActionButton.extended(
              heroTag: 'add_loc_settings',
              onPressed: () => _showLocationDialog(context, state, state.rooms.first),
              label: const Text('保管場所を追加'),
              icon: const Icon(Icons.add),
            ),
    );
  }

  void _showLocationDialog(BuildContext context, AppState state, Room defaultRoom, {StorageLocation? location}) {
    final nameController = TextEditingController(text: location?.name ?? '');
    String iconEmoji = location?.iconEmoji ?? '📦';
    String selectedRoomId = location?.roomId ?? defaultRoom.id;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(location == null ? '保管場所を追加' : '保管場所を編集', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: selectedRoomId,
                    decoration: const InputDecoration(labelText: '部屋'),
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
                    onChanged: location != null ? null : (val) { // Prevent moving rooms during edit for simplicity
                      if (val != null) {
                        setDialogState(() {
                          selectedRoomId = val;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 12),
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
                          final selected = await _showEmojiPicker(context, ['📦', '❄️', '🥫', '🗄️', '🧼', '🚪', '🛏️', '🧴', '🛍️', '📚', '🗃️']);
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
                      if (location == null) {
                        state.addLocation(selectedRoomId, name, iconEmoji);
                      } else {
                        state.editLocation(location.id, name, iconEmoji);
                      }
                      Navigator.pop(context);
                    }
                  },
                  child: Text(location == null ? '追加' : '保存'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _confirmDeleteLocation(BuildContext context, AppState state, StorageLocation loc) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('保管場所を削除しますか？', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          content: Text('「${loc.name}」を削除すると、この場所の中にあるすべてのアイテムも削除されます。よろしいですか？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('キャンセル'),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              onPressed: () {
                state.deleteLocation(loc.id);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${loc.name}を削除しました')),
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

// ----------------------------------------------------
// 3. Categories Settings Tab
// ----------------------------------------------------
class CategoriesSettingsTab extends StatelessWidget {
  const CategoriesSettingsTab({super.key});

  // Predefined beautiful design palette for category tag colors
  static const List<String> tagColors = [
    '#4CAF50', // Green
    '#2196F3', // Blue
    '#FF9800', // Orange
    '#E91E63', // Pink
    '#9C27B0', // Purple
    '#F44336', // Red
    '#00BCD4', // Cyan
    '#795548', // Brown
  ];

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppState>(context);
    final theme = Theme.of(context);

    return Scaffold(
      body: state.categories.isEmpty
          ? const Center(child: Text('カテゴリーが登録されていません。'))
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: state.categories.length,
              itemBuilder: (context, index) {
                final cat = state.categories[index];
                
                Color color = Colors.grey;
                try {
                  color = Color(int.parse('FF${cat.colorHex.replaceFirst('#', '')}', radix: 16));
                } catch (_) {}

                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: color.withOpacity(0.15),
                    child: Text(cat.iconEmoji, style: const TextStyle(fontSize: 20)),
                  ),
                  title: Row(
                    children: [
                      Text(cat.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(width: 8),
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 20),
                        onPressed: () => _showCategoryDialog(context, state, category: cat),
                      ),
                      IconButton(
                        icon: Icon(Icons.delete_outline, size: 20, color: theme.colorScheme.error),
                        onPressed: () => _confirmDeleteCategory(context, state, cat),
                      ),
                    ],
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'add_cat_settings',
        onPressed: () => _showCategoryDialog(context, state),
        label: const Text('カテゴリーを追加'),
        icon: const Icon(Icons.add),
      ),
    );
  }

  void _showCategoryDialog(BuildContext context, AppState state, {Category? category}) {
    final nameController = TextEditingController(text: category?.name ?? '');
    String iconEmoji = category?.iconEmoji ?? '🏷️';
    String selectedColorHex = category?.colorHex ?? tagColors.first;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(category == null ? 'カテゴリーを追加' : 'カテゴリーを編集', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'カテゴリー名',
                        hintText: '例：日用品、食材、掃除用具',
                      ),
                      autofocus: true,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Text('アイコン:'),
                        const SizedBox(width: 12),
                        GestureDetector(
                          onTap: () async {
                            final selected = await _showEmojiPicker(context, ['🍏', '🧻', '🧹', '💊', '🥩', '🧴', '🍼', '🥫', '🧊', '🔌', '🛠️', '📝']);
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
                    const SizedBox(height: 16),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text('タグカラー:'),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: tagColors.map((colorHex) {
                        Color cellColor = Colors.grey;
                        try {
                          cellColor = Color(int.parse('FF${colorHex.replaceFirst('#', '')}', radix: 16));
                        } catch (_) {}

                        final isSelected = selectedColorHex == colorHex;

                        return GestureDetector(
                          onTap: () {
                            setDialogState(() {
                              selectedColorHex = colorHex;
                            });
                          },
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: cellColor,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected ? Colors.black : Colors.transparent,
                                width: 2.5,
                              ),
                              boxShadow: isSelected
                                  ? [const BoxShadow(color: Colors.black26, blurRadius: 4, spreadRadius: 1)]
                                  : null,
                            ),
                            child: isSelected
                                ? const Icon(Icons.check, color: Colors.white, size: 18)
                                : null,
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
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
                      if (category == null) {
                        state.addCategory(name, selectedColorHex, iconEmoji);
                      } else {
                        state.editCategory(category.id, name, selectedColorHex, iconEmoji);
                      }
                      Navigator.pop(context);
                    }
                  },
                  child: Text(category == null ? '追加' : '保存'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _confirmDeleteCategory(BuildContext context, AppState state, Category cat) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('カテゴリーを削除しますか？', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          content: Text('「${cat.name}」を削除してもよろしいですか？このカテゴリーが割り当てられているアイテムは「未分類」になります。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('キャンセル'),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              onPressed: () {
                state.deleteCategory(cat.id);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${cat.name}を削除しました')),
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

// ----------------------------------------------------
// Emoji Picker Helper Dialog
// ----------------------------------------------------
Future<String?> _showEmojiPicker(BuildContext context, List<String> emojis) {
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
