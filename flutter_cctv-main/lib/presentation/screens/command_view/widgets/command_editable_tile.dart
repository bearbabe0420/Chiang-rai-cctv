import 'package:flutter/material.dart';
import '../command_view_model.dart';
import 'command_tile_widgets.dart';

// =============================================================================
// EditableTile — tile ที่ click-to-select / swap ได้ใน edit mode
// =============================================================================

class EditableTile extends StatelessWidget {
  final int index;
  final CameraInfo? camera;
  final Future<HlsResult>? hlsFuture;
  final bool isSelected;

  /// Called when user taps this tile in edit mode.
  /// [fromIndex] is non-null only when a tile is already selected (swap intent).
  final void Function(int tappedIndex) onTap;

  const EditableTile({
    Key? key,
    required this.index,
    required this.camera,
    required this.hlsFuture,
    required this.isSelected,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected
                ? Colors.orange
                : Colors.blue.withOpacity(0.5),
            width: isSelected ? 3 : 1,
          ),
          borderRadius: BorderRadius.circular(6),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.orange.withOpacity(0.6),
                    blurRadius: 12,
                    spreadRadius: 3,
                  ),
                ]
              : null,
        ),
        child: Stack(
          children: [
            // Video tile (paused in edit mode)
            VideoTile(
              index: index,
              camera: camera,
              hlsFuture: hlsFuture,
              isEditMode: true,
              isSelected: isSelected,
            ),

            // Tinted overlay + selection icon
            Positioned.fill(
              child: IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.orange.withOpacity(0.2)
                        : Colors.blue.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Center(
                    child: isSelected
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.check_circle,
                                color: Colors.orange,
                                size: 48,
                                shadows: const [
                                  Shadow(
                                      color: Colors.black, blurRadius: 4),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.orange,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text(
                                  'SELECTED - Click another to swap',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          )
                        : Icon(Icons.touch_app,
                            color: Colors.white.withOpacity(0.3), size: 32),
                  ),
                ),
              ),
            ),

            // Position number badge
            Positioned(
              top: 4,
              left: 4,
              child: IgnorePointer(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.orange
                        : Colors.blue.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),

            // Transparent tap capture layer (must be on top)
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onTap(index),
                child: Container(color: Colors.transparent),
              ),
            ),
          ],
        ),
      ),
    );
  }
}