import 'package:flutter/material.dart';
import '/core/i18n/i18n.dart';
import '../widgets/hls_player.dart'; // HlsPlayer
import '../command_view_model.dart';
import 'command_tile_widgets.dart';

// =============================================================================
// AccidentOverlay — pulsing red border + badge บน tile
// =============================================================================

class AccidentOverlay extends StatefulWidget {
  final String? timestamp;
  const AccidentOverlay({Key? key, this.timestamp}) : super(key: key);

  @override
  State<AccidentOverlay> createState() => _AccidentOverlayState();
}

class _AccidentOverlayState extends State<AccidentOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..repeat(reverse: true);
    _opacity = Tween<double>(begin: 1.0, end: 0.25).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _formatTs(String? raw) {
    if (raw == null || raw.isEmpty) return '';
    final dt = DateTime.tryParse(raw);
    if (dt == null) return raw;
    final local = dt.toLocal();
    return '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}:'
        '${local.second.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _opacity,
      builder: (context, _) => Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: Colors.red.withOpacity(_opacity.value),
            width: 3,
          ),
          color: Colors.red.withOpacity(0.07 * _opacity.value),
        ),
        child: Stack(
          children: [
            Positioned(
              top: 4,
              right: 4,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.88),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.warning_amber_rounded,
                        color: Colors.white, size: 10),
                    const SizedBox(width: 3),
                    Text(
                      context.tr(
                        'command.accident_badge',
                        params: {'time': _formatTs(widget.timestamp)},
                        fallback: 'อุบัติเหตุ  ${_formatTs(widget.timestamp)}',
                      ),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// AccidentDialog — full-screen dialog แสดงรายละเอียดอุบัติเหตุ
// =============================================================================

class AccidentDialog extends StatelessWidget {
  final CameraInfo camera;
  final Map<String, dynamic> accident;

  const AccidentDialog({
    Key? key,
    required this.camera,
    required this.accident,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final imageUrl = accident['imageUrl']?.toString() ?? '';
    final timestamp = accident['timestamp']?.toString() ?? '';

    return Dialog(
      backgroundColor: const Color(0xFF1A1A1A),
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
            child: Row(
              children: [
                const Icon(Icons.warning_amber_rounded,
                    color: Colors.red, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    context.tr(
                      'command.accident_dialog_title',
                      params: {'camera': camera.name},
                      fallback: 'ตรวจพบอุบัติเหตุ - ${camera.name}',
                    ),
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white54),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(color: Colors.white12, height: 1),

          // Image
          if (imageUrl.isNotEmpty)
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 400),
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
                loadingBuilder: (_, child, progress) => progress == null
                    ? child
                    : const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32),
                          child: CircularProgressIndicator(
                              color: Colors.white54),
                        )),
                errorBuilder: (_, __, ___) => const Padding(
                  padding: EdgeInsets.all(24),
                  child: Icon(Icons.broken_image,
                      color: Colors.white24, size: 64),
                ),
              ),
            )
          else
            const Padding(
              padding: EdgeInsets.all(24),
              child: Icon(Icons.image_not_supported,
                  color: Colors.white24, size: 64),
            ),

          // Timestamp
          if (timestamp.isNotEmpty)
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                context.tr(
                  'command.accident_detected_at',
                  params: {'time': timestamp},
                  fallback: 'ตรวจพบเมื่อ: $timestamp',
                ),
                style: const TextStyle(color: Colors.white54, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ),

          // Dismiss button
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: Text(context.tr('common.close', fallback: 'ปิด')),
            ),
          ),
        ],
      ),
    );
  }
}

class AccidentIncidentBanner extends StatelessWidget {
  final int count;
  final String cameraName;
  final String? timestamp;
  final VoidCallback onOpen;

  const AccidentIncidentBanner({
    Key? key,
    required this.count,
    required this.cameraName,
    required this.timestamp,
    required this.onOpen,
  }) : super(key: key);

  String _formatTs(String? raw) {
    if (raw == null || raw.isEmpty) return '-';
    final dt = DateTime.tryParse(raw);
    if (dt == null) return raw;
    final local = dt.toLocal();
    return '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}:'
        '${local.second.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onOpen,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 640),
            margin: const EdgeInsets.symmetric(horizontal: 12),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFB91C1C).withOpacity(0.93),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white24),
            ),
            child: Row(
              children: [
                const Icon(Icons.notification_important_rounded,
                    color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    context.tr(
                      'command.accident_banner_summary',
                      params: {
                        'count': count.toString(),
                        'camera': cameraName,
                        'time': _formatTs(timestamp),
                      },
                      fallback:
                          'พบอุบัติเหตุ $count จุด | ล่าสุด: $cameraName เวลา ${_formatTs(timestamp)}',
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  context.tr(
                    'command.accident_banner_action',
                    fallback: 'ดูรายละเอียด',
                  ),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// FocusOverlay — full-screen stream เมื่อ double-tap tile
// =============================================================================

class FocusOverlay extends StatelessWidget {
  final CameraInfo camera;
  final Future<HlsResult>? hlsFuture;
  final VoidCallback onExit;

  const FocusOverlay({
    Key? key,
    required this.camera,
    required this.hlsFuture,
    required this.onExit,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: Stack(
        children: [
          // Full-screen stream
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onDoubleTap: onExit,
              child: FutureBuilder<HlsResult>(
                key: ValueKey('focus_${camera.id}'),
                future: hlsFuture,
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return StreamLoadingTile(cameraName: camera.name);
                  }
                  final hls = snap.data?.url;
                  if (hls == null || hls.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.signal_wifi_statusbar_connected_no_internet_4_rounded,
                            color: Colors.redAccent,
                            size: 48,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            snap.data?.error ?? 'สตรีมไม่พร้อมใช้งาน',
                            style: const TextStyle(
                                color: Colors.white60, fontSize: 14),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                              const Text(
                                'แตะสองครั้งเพื่อออกจากโหมดเต็มจอ',
                                style: TextStyle(
                                    color: Colors.white30, fontSize: 11),
                              ),
                        ],
                      ),
                    );
                  }
                  return HlsPlayer(
                    key: ValueKey('focus_${camera.id}_$hls'),
                    hlsUrl: hls,
                  );
                },
              ),
            ),
          ),

          // Camera name badge (top-left)
          Positioned(
            top: 12,
            left: 12,
            child: IgnorePointer(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  camera.name,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ),

          // Exit button (top-right)
          Positioned(
            top: 8,
            right: 8,
            child: GestureDetector(
              onTap: onExit,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.75),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.fullscreen_exit,
                    color: Colors.white, size: 20),
              ),
            ),
          ),

          // Double-tap hint (bottom-centre)
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Center(
              child: IgnorePointer(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Text(
                    'แตะสองครั้งเพื่อขยาย · แตะ ✕ เพื่อออก',
                    style:
                        TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// EditModeBanner — banner ด้านล่างเมื่ออยู่ใน edit mode
// =============================================================================

class EditModeBanner extends StatelessWidget {
  const EditModeBanner({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 12,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.9),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
                  const Icon(Icons.touch_app, color: Colors.white, size: 14),
                  const SizedBox(width: 6),
                  Text(
                    'แตะเพื่อเลือก · แตะอีกช่องเพื่อสลับตำแหน่ง',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}