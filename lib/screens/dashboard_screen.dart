import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import '../models.dart';
import '../widgets.dart';
import 'room_detail_screen.dart';
import 'item_form_screen.dart';
import 'settings_screen.dart';

class MainNavigationShell extends StatefulWidget {
  const MainNavigationShell({super.key});

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const DashboardScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          selectedItemColor: theme.colorScheme.primary,
          unselectedItemColor: Colors.grey.shade400,
          backgroundColor: theme.colorScheme.surface,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'ホーム',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings_outlined),
              activeIcon: Icon(Icons.settings),
              label: 'マスタ管理',
            ),
          ],
        ),
      ),
    );
  }
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppState>(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (state.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Filter items based on search query
    final filteredItems = state.items.where((item) {
      final nameMatches = item.name.toLowerCase().contains(_searchQuery.toLowerCase());
      final category = state.getCategoryById(item.categoryId);
      final categoryMatches = category?.name.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false;
      return nameMatches || categoryMatches;
    }).toList();

    final alertItems = state.getAlertItems();

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'WhereStock',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '家のなかの「どこに」「何があるか」を管理',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),

            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: TextField(
                controller: _searchController,
                onChanged: (val) {
                  setState(() {
                    _searchQuery = val;
                  });
                },
                decoration: InputDecoration(
                  hintText: 'アイテムやカテゴリーを検索...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchQuery = '';
                            });
                          },
                        )
                      : null,
                ),
              ),
            ),

            // Main Content Area
            Expanded(
              child: _searchQuery.isNotEmpty
                  ? _buildSearchResults(filteredItems, state)
                  : _buildMainDashboard(alertItems, state, theme, isDark),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'add_item_dashboard',
        child: const Icon(Icons.add),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const ItemFormScreen(),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSearchResults(List<InventoryItem> items, AppState state) {
    if (items.isEmpty) {
      return const EmptyState(
        icon: '🔍',
        title: '検索結果が見つかりません',
        subtitle: '名前を変えてもう一度お試しください。',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 80, top: 8),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final cat = state.getCategoryById(item.categoryId);
        final loc = state.getLocationById(item.storageLocationId);
        final room = loc != null ? state.getRoomForLocation(loc.id) : null;

        return ItemTile(
          item: item,
          category: cat,
          room: room,
          location: loc,
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
    );
  }

  Widget _buildMainDashboard(
      List<InventoryItem> alertItems, AppState state, ThemeData theme, bool isDark) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 80),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Alerts Section
          if (alertItems.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: theme.colorScheme.error, size: 20),
                  const SizedBox(width: 6),
                  Text(
                    '要補充アラート (${alertItems.length})',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.error,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                physics: const BouncingScrollPhysics(),
                itemCount: alertItems.length,
                itemBuilder: (context, index) {
                  final item = alertItems[index];
                  final cat = state.getCategoryById(item.categoryId);
                  final loc = state.getLocationById(item.storageLocationId);
                  final room = loc != null ? state.getRoomForLocation(loc.id) : null;

                  Color catColor = Colors.grey;
                  if (cat != null) {
                    try {
                      catColor = Color(int.parse('FF${cat.colorHex.replaceFirst('#', '')}', radix: 16));
                    } catch (_) {}
                  }

                  return Container(
                    width: 180,
                    margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                    child: Card(
                      elevation: 0,
                      margin: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: theme.colorScheme.error.withOpacity(0.4),
                          width: 1,
                        ),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ItemFormScreen(item: item),
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    room != null && loc != null
                                        ? '${room.iconEmoji}${loc.name}'
                                        : '保管場所不明',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey.shade500,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: catColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      cat?.name ?? '未分類',
                                      style: TextStyle(
                                        fontSize: 9,
                                        color: catColor,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      Text(
                                        '${item.quantity}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: theme.colorScheme.error,
                                        ),
                                      ),
                                      Text(
                                        ' / 最低${item.minQuantity}',
                                        style: TextStyle(
                                          fontSize: 9,
                                          color: Colors.grey.shade500,
                                        ),
                                      ),
                                    ],
                                  )
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],

          // Rooms Section Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
            child: Text(
              '部屋一覧',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
          ),

          // Rooms Grid
          if (state.rooms.isEmpty)
            const EmptyState(
              icon: '🏠',
              title: '部屋が登録されていません',
              subtitle: '「マスタ管理」タブから部屋を追加してください。',
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: state.rooms.length,
              itemBuilder: (context, index) {
                final room = state.rooms[index];
                final locCount = state.getLocationsForRoom(room.id).length;
                final itemCount = state.getItemsForRoom(room.id).length;

                return Card(
                  margin: EdgeInsets.zero,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => RoomDetailScreen(room: room),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withOpacity(0.08),
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              room.iconEmoji,
                              style: const TextStyle(fontSize: 20),
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                room.name,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '$locCount 箇所・$itemCount 点の在庫',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
