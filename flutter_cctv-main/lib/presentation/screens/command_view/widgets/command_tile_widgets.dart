import 'dart:async';
import 'package:flutter/material.dart';
import '../widgets/hls_player.dart'; // HlsPlayer
import '../command_view_model.dart';

// =============================================================================
// StreamLoadingTile — แสดง progress + ข้อความขณะ HLS กำลัง start
// =============================================================================

class StreamLoadingTile extends StatefulWidget {
  final String cameraName;
  const StreamLoadingTile({Key? key, required this.cameraName})
      : super(key: key);

  @override
  State<StreamLoadingTile> createState() => _StreamLoadingTileState();
}

class _StreamLoadingTileState extends State<StreamLoadingTile> {
  Timer? _timer;
  bool _isSlow = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(seconds: 10), () {
      if (mounted) setState(() => _isSlow = true);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            widget.cameraName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          const LinearProgressIndicator(
            color: Colors.white54,
            backgroundColor: Colors.white12,
          ),
          const SizedBox(height: 6),
          Text(
            _isSlow ? 'Taking longer than usual…' : 'Starting stream…',
            style: TextStyle(
              color: Colors.white.withOpacity(0.55),
              fontSize: 9,
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// VideoTile — tile หลักของแต่ละช่องกล้อง
// =============================================================================

class VideoTile extends StatefulWidget {
  final int index;
  final CameraInfo? camera;
  final Future<HlsResult>? hlsFuture;
  final bool isEditMode;
  final bool isSelected;

  const VideoTile({
    Key? key,
    required this.index,
    required this.camera,
    required this.hlsFuture,
    this.isEditMode = false,
    this.isSelected = false,
  }) : super(key: key);

  @override
  State<VideoTile> createState() => _VideoTileState();
}

class _VideoTileState extends State<VideoTile> {
  bool _gracePeriodDone = false;
  Timer? _graceTimer;

  @override
  void dispose() {
    _graceTimer?.cancel();
    super.dispose();
  }

  void _startGrace() {
    if (_graceTimer != null) return;
    _graceTimer = Timer(const Duration(seconds: 6), () {
      if (mounted) setState(() => _gracePeriodDone = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final hasCam = widget.camera != null;

    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: Stack(
        children: [
          Positioned.fill(
            child: widget.isEditMode
                ? _editModePlaceholder(
                    widget.camera?.name ?? 'CAM ${widget.index + 1}')
                : hasCam
                    ? (widget.hlsFuture == null
                        ? StreamLoadingTile(
                            cameraName: widget.camera!.name)
                        : FutureBuilder<HlsResult>(
                            key: ValueKey(widget.camera!.id.isNotEmpty
                                ? widget.camera!.id
                                : widget.camera!.name),
                            future: widget.hlsFuture,
                            builder: (context, snap) {
                              if (snap.connectionState ==
                                  ConnectionState.waiting) {
                                return StreamLoadingTile(
                                    cameraName: widget.camera!.name);
                              }
                              final result = snap.data;
                              final hls = result?.url;
                              if (hls == null || hls.isEmpty) {
                                _startGrace();
                                if (!_gracePeriodDone) {
                                  return StreamLoadingTile(
                                      cameraName: widget.camera!.name);
                                }
                                return _ErrorTile(
                                    reason: result?.error ??
                                        'Stream unavailable');
                              }
                              return HlsPlayer(
                                key: ValueKey(
                                  '${widget.camera!.id.isNotEmpty ? widget.camera!.id : widget.camera!.name}_$hls',
                                ),
                                hlsUrl: hls,
                              );
                            },
                          ))
                    : _NoStreamSlot(index: widget.index),
          ),
          // Camera name label
          Positioned(
            left: 4,
            top: 4,
            child: IgnorePointer(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  hasCam
                      ? widget.camera!.name
                      : 'CAM ${widget.index + 1}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _editModePlaceholder(String cameraName) => Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.grey[900]!, Colors.grey[800]!],
          ),
        ),
        alignment: Alignment.center,
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.pause_circle_outline,
                color: Colors.white.withOpacity(0.6), size: 48),
            const SizedBox(height: 12),
            Text(
              cameraName,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Stream paused in edit mode',
                style: TextStyle(
                    color: Colors.white.withOpacity(0.6), fontSize: 9),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      );
}

// =============================================================================
// _ErrorTile — แสดงเมื่อ stream ล้มเหลว
// =============================================================================

class _ErrorTile extends StatelessWidget {
  final String reason;
  const _ErrorTile({required this.reason});

  @override
  Widget build(BuildContext context) {
    IconData icon;
    Color accent;
    if (reason.contains('timed out') || reason.contains('unreachable')) {
      icon = Icons.wifi_off_rounded;
      accent = Colors.orange;
    } else if (reason.contains('No RTSP') ||
        reason.contains('not configured')) {
      icon = Icons.videocam_off_rounded;
      accent = Colors.grey;
    } else if (reason.contains('400') || reason.contains('Bad request')) {
      icon = Icons.error_outline_rounded;
      accent = Colors.amber;
    } else {
      icon = Icons.signal_wifi_statusbar_connected_no_internet_4_rounded;
      accent = Colors.redAccent;
    }

    return Container(
      color: Colors.black,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: accent, size: 26),
          const SizedBox(height: 6),
          Text(
            'Stream Unavailable',
            style: TextStyle(
              color: accent,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 5),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              reason,
              style: const TextStyle(
                  color: Colors.white70, fontSize: 9, height: 1.4),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// _NoStreamSlot — empty slot เมื่อไม่มีกล้อง
// =============================================================================

class _NoStreamSlot extends StatelessWidget {
  final int index;
  const _NoStreamSlot({required this.index});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.video_camera_back_outlined,
              color: Colors.white24, size: 32),
          const SizedBox(height: 8),
          Text(
            'EMPTY SLOT ${index + 1}',
            style: const TextStyle(color: Colors.white54, fontSize: 10),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}