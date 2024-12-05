import 'package:flutter/material.dart';
import 'dart:ui';

/// Entrypoint of the application.
void main() {
  runApp(const MyApp());
}

/// [Widget] building the [MaterialApp].
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Dock(
            items: const [
              Icons.person,
              Icons.message,
              Icons.call,
              Icons.camera,
              Icons.photo,
            ],
            builder: (e) {
              return Container(
                constraints: const BoxConstraints(minWidth: 48),
                height: 48,
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.primaries[e.hashCode % Colors.primaries.length],
                ),
                child: Center(child: Icon(e, color: Colors.white)),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Dock of the reorderable [items].
class Dock<T extends Object> extends StatefulWidget {
  const Dock({
    super.key,
    this.items = const [],
    required this.builder,
  });

  /// Initial [T] items to put in this [Dock].
  final List<T> items;

  /// Builder building the provided [T] item.
  final Widget Function(T) builder;

  @override
  State<Dock<T>> createState() => _DockState<T>();
}

/// State of the [Dock] used to manipulate the [_items].
class _DockState<T extends Object> extends State<Dock<T>> {
  /// [T] items being manipulated.
  late final List<T> _items = widget.items.toList();

  // Track the item being dragged
  T? _draggedItem;

  // Track the position where item will be inserted
  int? _insertIndex;

  // Track hover states for each item
  final Map<T, bool> _hoveredItems = {};

  // Constants for layout
  static const double itemWidth = 48.0;
  static const double itemSpacing = 4.0;
  static const double animationDuration = 200;

  Widget _buildDraggableItem(T item, int index) {
    final isBeingDragged = _draggedItem == item;
    final isHovered = _hoveredItems[item] ?? false;

    // Calculate position based on index and dragged state
    double calculateX(int index) {
      if (_draggedItem != null) {
        if (item == _draggedItem) return index * (itemWidth + itemSpacing);

        final draggedIndex = _items.indexOf(_draggedItem!);
        if (_insertIndex != null) {
          if (index > draggedIndex && index <= _insertIndex!) {
            return (index - 1) * (itemWidth + itemSpacing);
          } else if (index < draggedIndex && index >= _insertIndex!) {
            return (index + 1) * (itemWidth + itemSpacing);
          }
        }
      }
      return index * (itemWidth + itemSpacing);
    }

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      left: calculateX(index),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hoveredItems[item] = true),
        onExit: (_) => setState(() => _hoveredItems[item] = false),
        child: AnimatedScale(
          scale: isHovered ? 1.1 : 1.0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          child: Draggable<T>(
            data: item,
            feedback: SizedBox(
              width: itemWidth,
              height: itemWidth,
              child: widget.builder(item),
            ),
            childWhenDragging: Opacity(
              opacity: 0.2,
              child: SizedBox(
                width: itemWidth,
                height: itemWidth,
                child: widget.builder(item),
              ),
            ),
            onDragStarted: () {
              setState(() => _draggedItem = item);
            },
            onDragEnd: (_) {
              setState(() => _draggedItem = null);
            },
            child: DragTarget<T>(
              onWillAccept: (data) => data != null,
              onAccept: (data) {
                final draggedIndex = _items.indexOf(data);
                setState(() {
                  _items.removeAt(draggedIndex);
                  _items.insert(index, data);
                  _draggedItem = null;
                  _insertIndex = null;
                });
              },
              onMove: (details) {
                setState(() => _insertIndex = index);
              },
              onLeave: (data) {
                setState(() => _insertIndex = null);
              },
              builder: (context, candidateData, rejectedData) {
                return SizedBox(
                  width: itemWidth,
                  height: itemWidth,
                  child: widget.builder(item),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.black.withOpacity(0.2),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: SizedBox(
            height: itemWidth,
            width: (_items.length * (itemWidth + itemSpacing)) - itemSpacing,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                for (int i = 0; i < _items.length; i++)
                  _buildDraggableItem(_items[i], i),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
