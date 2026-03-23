// Automatic FlutterFlow imports
import '/utils/flutter_flow/theme.dart';
import '/utils/flutter_flow/util.dart';
import '/utils/flutter_flow/widgets.dart';
import '/core/i18n/i18n.dart';
import '../../widgets/nav/nav_bar_main_widget.dart';
import '../command_view/widgets/hls_player.dart' as custom_widgets;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '/data/services/category_service.dart';
import '/data/services/camera_service.dart';

// ── Sub-widgets ───────────────────────────────────────────────────────────────
import 'command_view_model.dart';
import 'widgets/command_tile_widgets.dart';
import 'widgets/command_overlay_widgets.dart';
import 'widgets/command_toolbar_widgets.dart';
import 'widgets/command_editable_tile.dart';

export 'command_view_model.dart';

// =============================================================================
// CommandViewWidget — page wrapper (NavBar + CommandWidget body)
// =============================================================================

class CommandViewWidget extends StatefulWidget {
  const CommandViewWidget({super.key});

  static String routeName = 'CommandView';
  static String routePath = '/Commandview';

  @override
  State<CommandViewWidget> createState() => _CommandViewWidgetState();
}

class _CommandViewWidgetState extends State<CommandViewWidget> {
  late CommandViewModel _model;
  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => CommandViewModel());
    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      backgroundColor: Colors.white,
      body: NestedScrollView(
        floatHeaderSlivers: false,
        headerSliverBuilder: (context, _) => [
          SliverAppBar(
            pinned: false,
            floating: false,
            toolbarHeight: AppTextStyles.navBarHeight,
            backgroundColor: Colors.white,
            iconTheme: const IconThemeData(color: Color(0xFFD6C6C6)),
            automaticallyImplyLeading: false,
            title: wrapWithModel(
              model: _model.navBarMainModel,
              updateCallback: () => safeSetState(() {}),
              child: NavBarMainWidget(),
            ),
            centerTitle: true,
            elevation: 0.0,
          ),
        ],
        body: Builder(
          builder: (context) => SafeArea(
            top: false,
            child: Container(
              color: Colors.black,
              child: const CommandWidget(
                width: double.infinity,
                height: double.infinity,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// CommandViewModel
// =============================================================================

class CommandViewModel extends FlutterFlowModel<CommandViewWidget> {
  bool? isMenuOpen;
  late NavBarMainModel navBarMainModel;

  @override
  void initState(BuildContext context) {
    navBarMainModel = createModel(context, () => NavBarMainModel());
  }

  @override
  void dispose() {
    navBarMainModel.dispose();
  }
}

// =============================================================================
// CommandWidget — grid หลักแสดง CCTV
// =============================================================================

class CommandWidget extends StatefulWidget {
  const CommandWidget({Key? key, this.width, this.height}) : super(key: key);

  final double? width;
  final double? height;

  @override
  State<CommandWidget> createState() => _CommandWidgetState();
}

class _CommandWidgetState extends State<CommandWidget> {
  static const int _maxHlsStartAttempts = 3;

  // ── Grid state ──────────────────────────────────────────────────────────────
  int gridSize = 2;
  final Map<String, Future<HlsResult>> _hlsCache = {};
  List<CameraInfo> _cameras = [];
  List<dynamic> _categories = [];
  bool _isLoading = true;
  bool _isLoadingCategories = true;
  String? _errorMessage;
  int _fetchSeq = 0;

  // ── Filters & layout ────────────────────────────────────────────────────────
  String? _selectedCategoryId;
  bool _isEditMode = false;
  Map<int, String> _gridPositions = {};
  int? _selectedTileIndex;
  List<CameraInfo?> _currentSlots = [];

  // ── Accident state ───────────────────────────────────────────────────────────
  Map<String, Map<String, dynamic>> _latestAccidents = {};
  Timer? _accidentPollTimer;

  // ── Focus (full-screen) ──────────────────────────────────────────────────────
  CameraInfo? _focusedCamera;
  Future<HlsResult>? _focusedHlsFuture;

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  @override
  void initState() {
    super.initState();
    _fetchCategories();
    _fetchCameras();
    _loadGridLayout();
    _pollAccidents();
    _accidentPollTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _pollAccidents(),
    );
  }

  @override
  void dispose() {
    _accidentPollTimer?.cancel();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Data fetching
  // ---------------------------------------------------------------------------

  Future<void> _fetchCategories() async {
    try {
      final response = await CategoryService().getCategories();
      if (response.succeeded) {
        final List<dynamic> jsonList = response.jsonBody is List
            ? response.jsonBody
            : (response.jsonBody['data'] as List? ?? []);
        setState(() {
          _categories = jsonList;
          _isLoadingCategories = false;
        });
      } else {
        setState(() => _isLoadingCategories = false);
      }
    } catch (e) {
      setState(() => _isLoadingCategories = false);
    }
  }

  Future<void> _fetchCameras() async {
    _fetchSeq++;
    final mySeq = _fetchSeq;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = _selectedCategoryId == null
          ? await CameraService().getCameras(limit: '100')
          : await CameraService()
              .getCamerasByCategoryId(_selectedCategoryId!);

      if (mySeq != _fetchSeq) return;

      if (response.succeeded) {
        final List<dynamic> jsonList = response.jsonBody is List
            ? response.jsonBody
            : (response.jsonBody['data'] as List? ?? []);

        final seenIds = <String>{};
        final parsedCams = <CameraInfo>[];
        for (final e in jsonList) {
          final cam = CameraInfo.fromJson(e as Map<String, dynamic>);
          final key = cam.id.isNotEmpty ? cam.id : cam.name;
          if (seenIds.add(key)) parsedCams.add(cam);
        }

        final validKeys = <String>{
          for (final c in parsedCams) c.id.isNotEmpty ? c.id : c.name,
        };
        _hlsCache.removeWhere((key, _) => !validKeys.contains(key));

        setState(() {
          _cameras = parsedCams;
          _isLoading = false;
          _errorMessage = null;
        });
      } else if (response.statusCode == 404 &&
          _selectedCategoryId != null) {
        _hlsCache.clear();
        setState(() {
          _cameras = [];
          _isLoading = false;
          _errorMessage = null;
        });
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = 'ข้อผิดพลาดจาก API: ${response.statusCode}';
        });
      }
    } catch (e) {
      if (_fetchSeq != mySeq) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'เกิดข้อผิดพลาด: $e';
      });
    }
  }

  Future<void> _loadGridLayout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString('command_grid_layout');
      if (saved != null) {
        final map = jsonDecode(saved) as Map<String, dynamic>;
        setState(() {
          _gridPositions =
              map.map((k, v) => MapEntry(int.parse(k), v.toString()));
        });
      }
    } catch (_) {}
  }

  Future<void> _saveGridLayout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'command_grid_layout',
        jsonEncode(
            _gridPositions.map((k, v) => MapEntry(k.toString(), v))),
      );
    } catch (_) {}
  }

  Future<void> _pollAccidents() async {
    try {
      final resp = await http
          .get(Uri.parse('$kApiBaseUrl/api/accidents?limit=100'))
          .timeout(const Duration(seconds: 10));
      if (resp.statusCode != 200) return;
      final body = jsonDecode(resp.body);
      final List<dynamic> list =
          body is List ? body : (body['data'] as List? ?? []);
      final now = DateTime.now();
      final Map<String, Map<String, dynamic>> fresh = {};
      for (final a in list) {
        if (a is! Map<String, dynamic>) continue;
        final cameraId = a['cameraId']?.toString();
        if (cameraId == null || cameraId.isEmpty) continue;
        final ts = _parseAccidentTimestamp(a);
        if (ts != null && now.difference(ts).inMinutes >= 5) continue;
        final prev = fresh[cameraId];
        if (prev == null) {
          fresh[cameraId] = a;
          continue;
        }
        final prevTs = _parseAccidentTimestamp(prev);
        if (ts != null && (prevTs == null || ts.isAfter(prevTs))) {
          fresh[cameraId] = a;
        }
      }
      if (mounted) setState(() => _latestAccidents = fresh);
    } catch (_) {}
  }

  DateTime? _parseAccidentTimestamp(Map<String, dynamic> accident) {
    final raw = accident['timestamp']?.toString() ?? '';
    return DateTime.tryParse(raw)?.toLocal();
  }

  Map<String, dynamic>? _latestAccidentEvent() {
    Map<String, dynamic>? latest;
    DateTime? latestTs;
    for (final event in _latestAccidents.values) {
      final ts = _parseAccidentTimestamp(event);
      if (latest == null) {
        latest = event;
        latestTs = ts;
        continue;
      }
      if (ts != null && (latestTs == null || ts.isAfter(latestTs))) {
        latest = event;
        latestTs = ts;
      }
    }
    return latest;
  }

  CameraInfo? _findCameraById(String cameraId) {
    for (final cam in _cameras) {
      if (cam.id == cameraId) return cam;
    }
    return null;
  }

  void _openAccidentDialog(Map<String, dynamic> accident) {
    final cameraId = accident['cameraId']?.toString() ?? '';
    final camera = cameraId.isNotEmpty ? _findCameraById(cameraId) : null;
    if (camera == null) return;

    showDialog(
      context: context,
      builder: (_) => AccidentDialog(camera: camera, accident: accident),
    );
  }

  // ---------------------------------------------------------------------------
  // Layout helpers
  // ---------------------------------------------------------------------------

  void _cycleLayout() {
    setState(() {
      gridSize = gridSize == 2 ? 3 : (gridSize == 3 ? 4 : 2);
      _gridPositions = {};
    });
  }

  String _getCategoryName(String categoryId, {bool truncate = true}) {
    try {
      final cat = _categories.firstWhere(
        (c) => c['id']?.toString() == categoryId,
        orElse: () => {'name': 'ไม่ระบุ'},
      );
      final name = cat['name']?.toString() ?? 'ไม่ระบุ';
      if (!truncate) return name;
      return name.length > 9 ? '${name.substring(0, 9)}...' : name;
    } catch (_) {
      return 'ไม่ระบุ';
    }
  }

  bool _mapsEqual(Map<int, String> a, Map<int, String> b) {
    if (a.length != b.length) return false;
    for (final e in a.entries) {
      if (b[e.key] != e.value) return false;
    }
    return true;
  }

  List<CameraInfo?> _buildSlotAssignment(
      List<CameraInfo> cams, int totalTiles) {
    final slots = List<CameraInfo?>.filled(totalTiles, null);
    final placedIds = <String>{};

    final sorted = _gridPositions.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    for (final entry in sorted) {
      final pos = entry.key;
      final cameraId = entry.value;
      if (pos >= totalTiles) continue;
      if (placedIds.contains(cameraId)) continue;
      try {
        final cam = cams.firstWhere(
          (c) => (c.id.isNotEmpty ? c.id : c.name) == cameraId,
        );
        slots[pos] = cam;
        placedIds.add(cam.id.isNotEmpty ? cam.id : cam.name);
      } catch (_) {}
    }

    final unplacedSeen = <String>{};
    final unplaced = <CameraInfo>[];
    for (final cam in cams) {
      final key = cam.id.isNotEmpty ? cam.id : cam.name;
      if (!placedIds.contains(key) && unplacedSeen.add(key)) {
        unplaced.add(cam);
      }
    }

    int ui = 0;
    for (int i = 0; i < totalTiles && ui < unplaced.length; i++) {
      if (slots[i] == null) slots[i] = unplaced[ui++];
    }
    return slots;
  }

  // ---------------------------------------------------------------------------
  // HLS stream management
  // ---------------------------------------------------------------------------

  Future<HlsResult> _ensureHls(CameraInfo cam) {
    final key = cam.id.isNotEmpty ? cam.id : cam.name;
    return _hlsCache[key] ??= _startHls(cam);
  }

  String _tr(
    String key, {
    Map<String, String>? params,
    String? fallback,
  }) {
    return context.tr(key, params: params, fallback: fallback);
  }

  Duration _retryDelayForAttempt(int attempt) {
    final ms = 600 * (1 << (attempt - 1));
    return Duration(milliseconds: ms);
  }

  Future<HlsResult> _startHls(CameraInfo cam) async {
    HlsResult? lastFailure;
    bool lastFailureRetryable = false;

    for (int attempt = 1; attempt <= _maxHlsStartAttempts; attempt++) {
      final attemptResult = await _startHlsOnce(cam);
      if (attemptResult.url != null && attemptResult.url!.isNotEmpty) {
        return attemptResult;
      }

      lastFailure = attemptResult;
      lastFailureRetryable = _isRetryableHlsError(attemptResult.error);
      final hasMoreAttempts = attempt < _maxHlsStartAttempts;

      if (!lastFailureRetryable || !hasMoreAttempts) {
        if (lastFailureRetryable && attempt > 1) {
          return HlsResult(
            error: _tr(
              'command.start_hls_retry_exhausted',
              params: {
                'attempts': attempt.toString(),
                'reason': attemptResult.error ??
                    _tr(
                      'command.stream_unavailable',
                      fallback: 'Stream unavailable',
                    ),
              },
              fallback:
                  'Failed to start stream after $attempt attempts: ${attemptResult.error ?? 'Stream unavailable'}',
            ),
          );
        }
        return attemptResult;
      }

      await Future.delayed(_retryDelayForAttempt(attempt));
    }

    return lastFailure ??
        HlsResult(
          error: _tr(
            'command.stream_unavailable',
            fallback: 'Stream unavailable',
          ),
        );
  }

  bool _isRetryableHlsError(String? error) {
    if (error == null || error.isEmpty) return true;
    final msg = error.toLowerCase();
    if (msg.contains('http 408') ||
        msg.contains('http 429') ||
        msg.contains('http 500') ||
        msg.contains('http 502') ||
        msg.contains('http 503') ||
        msg.contains('http 504')) {
      return true;
    }
    if (msg.contains('timeout') ||
        msg.contains('หมดเวลา') ||
        msg.contains('socketexception') ||
        msg.contains('clientexception') ||
        msg.contains('failed host lookup') ||
        msg.contains('connection closed')) {
      return true;
    }
    return false;
  }

  Future<HlsResult> _startHlsOnce(CameraInfo cam) async {
    final uri = Uri.parse('$kApiBaseUrl/api/stream/hls/start');
    try {
      final resp = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'cameraId': cam.id}),
          )
          .timeout(const Duration(seconds: 15));

      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        final obj = jsonDecode(resp.body);
        String? hlsUrl =
            obj is Map ? obj['hlsUrl'] as String? : null;
        if (hlsUrl == null || hlsUrl.isEmpty) {
          return HlsResult(
            error: _tr(
              'command.start_hls_missing_url',
              fallback: 'Server did not return an HLS URL',
            ),
          );
        }
        final finalUrl =
            hlsUrl.startsWith('http') ? hlsUrl : '$kApiBaseUrl$hlsUrl';
        return HlsResult(url: finalUrl);
      } else if (resp.statusCode == 400) {
        try {
          final err = jsonDecode(resp.body);
          final msg = err['error']?.toString() ?? resp.body;
          if (msg.contains('No RTSP URL configured')) {
            return HlsResult(
              error: _tr(
                'command.start_hls_no_rtsp',
                fallback: 'RTSP URL is not configured for this camera',
              ),
            );
          }
          return HlsResult(
            error: _tr(
              'command.start_hls_bad_request',
              params: {'message': msg},
              fallback: 'Bad request: $msg',
            ),
          );
        } catch (_) {
          final shortBody = resp.body.length > 80
              ? resp.body.substring(0, 80)
              : resp.body;
          return HlsResult(
            error: _tr(
              'command.start_hls_bad_request_short',
              params: {'message': shortBody},
              fallback: 'Bad request (400): $shortBody',
            ),
          );
        }
      } else {
        final shortBody = resp.body.length > 80
            ? resp.body.substring(0, 80)
            : resp.body;
        return HlsResult(
          error: _tr(
            'command.start_hls_http_error',
            params: {
              'statusCode': resp.statusCode.toString(),
              'message': shortBody,
            },
            fallback: 'HTTP ${resp.statusCode}: $shortBody',
          ),
        );
      }
    } catch (e) {
      if (e.toString().contains('TimeoutException')) {
        return HlsResult(
          error: _tr(
            'command.start_hls_timeout',
            fallback: 'Connection timed out - could not contact server',
          ),
        );
      }
      return HlsResult(
        error: _tr(
          'command.start_hls_unexpected',
          params: {'error': e.toString()},
          fallback: 'Unexpected error: $e',
        ),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Accident overlay helpers
  // ---------------------------------------------------------------------------

  Widget _withAccidentOverlay(
      int index, CameraInfo? cam, Widget child) {
    if (cam == null || cam.id.isEmpty) return child;
    final accident = _latestAccidents[cam.id];
    if (accident == null) return child;
    return Stack(
      children: [
        child,
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () => _openAccidentDialog(accident),
            child: AccidentOverlay(
                timestamp: accident['timestamp']?.toString()),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final totalTiles = gridSize * gridSize;
    final latestAccident = _latestAccidentEvent();
    final latestCameraId = latestAccident?['cameraId']?.toString() ?? '';
    final latestCamera =
        latestCameraId.isNotEmpty ? _findCameraById(latestCameraId) : null;

    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: Container(
        color: Colors.black,
        child: SafeArea(
          child: Stack(
            children: [
              // ── Camera grid area ─────────────────────────────────────────
              Builder(builder: (context) {
                if (_isLoading) {
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  );
                }

                if (_errorMessage != null) {
                  return ApiErrorState(
                    message: _errorMessage!,
                    onRetry: () {
                      _hlsCache.clear();
                      _fetchCameras();
                      _fetchCategories();
                    },
                  );
                }

                final cams = _cameras;

                if (cams.isEmpty) {
                  return _selectedCategoryId != null
                      ? CategoryEmptyState(
                          categoryName: _getCategoryName(
                              _selectedCategoryId!,
                              truncate: false))
                      : NoCamerasState(
                          onRefresh: () {
                            _hlsCache.clear();
                            _fetchCameras();
                            _fetchCategories();
                          },
                        );
                }

                final slots = _buildSlotAssignment(cams, totalTiles);
                _currentSlots = slots;

                // Sync _gridPositions post-frame
                final synced = <int, String>{};
                for (int i = 0; i < slots.length; i++) {
                  final c = slots[i];
                  if (c != null) {
                    synced[i] = c.id.isNotEmpty ? c.id : c.name;
                  }
                }
                if (!_mapsEqual(_gridPositions, synced)) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) setState(() => _gridPositions = synced);
                  });
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(4.0),
                  itemCount: totalTiles,
                  gridDelegate:
                      SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: gridSize,
                    crossAxisSpacing: 4,
                    mainAxisSpacing: 4,
                    childAspectRatio: 16 / 9,
                  ),
                  itemBuilder: (context, index) {
                    final cam = slots[index];
                    final isFocused = _focusedCamera != null &&
                        cam != null &&
                        (cam.id.isNotEmpty
                            ? cam.id == _focusedCamera!.id
                            : cam.name == _focusedCamera!.name);
                    final Future<HlsResult>? fut =
                        (cam != null && !isFocused)
                            ? _ensureHls(cam)
                            : null;

                    if (_isEditMode) {
                      return _withAccidentOverlay(
                        index,
                        cam,
                        EditableTile(
                          index: index,
                          camera: cam,
                          hlsFuture: fut,
                          isSelected: _selectedTileIndex == index,
                          onTap: _handleTileEditTap,
                        ),
                      );
                    }

                    final tile = VideoTile(
                      key: cam != null
                          ? ValueKey(
                              'tile_${index}_${cam.id}_$gridSize')
                          : ValueKey('empty_$index'),
                      index: index,
                      camera: cam,
                      hlsFuture: fut,
                    );

                    return _withAccidentOverlay(
                      index,
                      cam,
                      GestureDetector(
                        behavior: HitTestBehavior.translucent,
                        onDoubleTap: cam != null
                            ? () => setState(() {
                                  _focusedCamera = cam;
                                  _focusedHlsFuture = fut;
                                })
                            : null,
                        child: tile,
                      ),
                    );
                  },
                );
              }),

              // ── Top-left toolbar ─────────────────────────────────────────
              GridToolbar(
                gridSize: gridSize,
                isEditMode: _isEditMode,
                onCycleLayout: _cycleLayout,
                onToggleEdit: () {
                  setState(() {
                    _isEditMode = !_isEditMode;
                    if (!_isEditMode) {
                      _saveGridLayout();
                    }
                    _selectedTileIndex = null;
                  });
                },
              ),

              // ── Top-right category filter ─────────────────────────────────
              CategoryFilter(
                isLoadingCategories: _isLoadingCategories,
                categories: _categories,
                selectedCategoryId: _selectedCategoryId,
                gridSize: gridSize,
                cameraCount: _cameras.length,
                getCategoryName: _getCategoryName,
                onSelected: (value) {
                  if (_selectedCategoryId != value) {
                    setState(() => _selectedCategoryId = value);
                    _hlsCache.clear();
                    _fetchCameras();
                  }
                },
              ),

              // ── Top incident strip ───────────────────────────────────────
              if (latestAccident != null && _focusedCamera == null)
                Positioned(
                  top: 58,
                  left: 0,
                  right: 0,
                  child: AccidentIncidentBanner(
                    count: _latestAccidents.length,
                    cameraName: latestCamera?.name ?? latestCameraId,
                    timestamp: latestAccident['timestamp']?.toString(),
                    onOpen: () => _openAccidentDialog(latestAccident),
                  ),
                ),

              // ── Edit mode banner ─────────────────────────────────────────
              if (_isEditMode) const EditModeBanner(),

              // ── Full-screen focus overlay ─────────────────────────────────
              if (_focusedCamera != null)
                Positioned.fill(
                  child: FocusOverlay(
                    camera: _focusedCamera!,
                    hlsFuture: _focusedHlsFuture,
                    onExit: () =>
                        setState(() => _focusedCamera = null),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Edit mode tile tap handler
  // ---------------------------------------------------------------------------

  void _handleTileEditTap(int index) {
    if (_selectedTileIndex == null) {
      setState(() => _selectedTileIndex = index);
    } else if (_selectedTileIndex == index) {
      setState(() => _selectedTileIndex = null);
    } else {
      final from = _selectedTileIndex!;
      final to = index;

      String? _camKey(int idx) {
        final cam =
            idx < _currentSlots.length ? _currentSlots[idx] : null;
        if (cam == null) return null;
        return cam.id.isNotEmpty ? cam.id : cam.name;
      }

      final fromId = _camKey(from);
      final toId = _camKey(to);

      setState(() {
        if (fromId != null) {
          _gridPositions[to] = fromId;
        } else {
          _gridPositions.remove(to);
        }
        if (toId != null) {
          _gridPositions[from] = toId;
        } else {
          _gridPositions.remove(from);
        }
        _selectedTileIndex = null;
      });
    }
  }
}