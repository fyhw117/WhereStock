import 'package:flutter/material.dart';
import 'models.dart';

class CategoryBadge extends StatelessWidget {
  final Category? category;

  const CategoryBadge({super.key, this.category});

  @override
  Widget build(BuildContext context) {
    final name = category?.name ?? '未分類';
    final emoji = category?.iconEmoji ?? '🏷️';
    
    // Parse color or fallback to gray
    Color color = Colors.grey;
    if (category != null) {
      try {
        final hexColor = category!.colorHex.replaceFirst('#', '');
        color = Color(int.parse('FF$hexColor', radix: 16));
      } catch (_) {}
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 4),
          Text(
            name,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: color.withAlpha(255),
            ),
          ),
        ],
      ),
    );
  }
}

class QuantityCounter extends StatelessWidget {
  final int quantity;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  const QuantityCounter({
    super.key,
    required this.quantity,
    required this.onIncrement,
    required this.onDecrement,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF212E35) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            padding: EdgeInsets.zero,
            icon: Icon(Icons.remove, size: 16, color: theme.colorScheme.primary),
            onPressed: onDecrement,
          ),
          Container(
            constraints: const BoxConstraints(minWidth: 28),
            alignment: Alignment.center,
            child: Text(
              '$quantity',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
          IconButton(
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            padding: EdgeInsets.zero,
            icon: Icon(Icons.add, size: 16, color: theme.colorScheme.primary),
            onPressed: onIncrement,
          ),
        ],
      ),
    );
  }
}

class ItemTile extends StatelessWidget {
  final InventoryItem item;
  final Category? category;
  final Room? room;
  final StorageLocation? location;
  final VoidCallback onTap;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  const ItemTile({
    super.key,
    required this.item,
    this.category,
    this.room,
    this.location,
    required this.onTap,
    required this.onIncrement,
    required this.onDecrement,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLowStock = item.quantity <= item.minQuantity;

    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isLowStock 
              ? theme.colorScheme.error.withOpacity(0.6) 
              : theme.cardTheme.shape!.adaptiveBorder(context),
          width: isLowStock ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              // Low stock alert indicator
              if (isLowStock)
                Container(
                  width: 8,
                  height: 38,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.error,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              if (isLowStock) const SizedBox(width: 8),
              
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        CategoryBadge(category: category),
                        if (room != null && location != null) ...[
                          const SizedBox(width: 8),
                          Icon(Icons.location_on_outlined, size: 12, color: Colors.grey.shade500),
                          const SizedBox(width: 2),
                          Expanded(
                            child: Text(
                              '${room!.iconEmoji} ${room!.name} > ${location!.iconEmoji} ${location!.name}',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ]
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              QuantityCounter(
                quantity: item.quantity,
                onIncrement: onIncrement,
                onDecrement: onDecrement,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Helper extension for parsing card border
extension on ShapeBorder {
  Color adaptiveBorder(BuildContext context) {
    if (this is RoundedRectangleBorder) {
      final side = (this as RoundedRectangleBorder).side;
      return side.color;
    }
    return Colors.transparent;
  }
}

class EmptyState extends StatelessWidget {
  final String icon;
  final String title;
  final String subtitle;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              icon,
              style: const TextStyle(fontSize: 48),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
