import 'package:central_command/presentation/screens/list_camera_page/widgets/stat_row.dart';
import 'package:central_command/presentation/screens/list_camera_page/widgets/table_card.dart';
import 'package:central_command/presentation/screens/list_camera_page/widgets/table_cells.dart';
import '/data/services/index.dart';
import '/presentation/screens/list_camera_page/widgets/views/addnewcamera_widget.dart';
import '/presentation/screens/list_camera_page/widgets/views/detailscamera_widget.dart';
import '/presentation/screens/list_camera_page/widgets/views/editdatacamera_widget.dart';
import '/presentation/widgets/nav/views/nav_bar_main_widget.dart';
import '../collection/widgets/category_chip.dart';
import 'widgets/status_chip.dart';
import '/utils/flutter_flow/theme.dart';
import '/utils/flutter_flow/util.dart';
import 'package:easy_debounce/easy_debounce.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'list_camera_page_model.dart';
export 'list_camera_page_model.dart';

class ListCameraPageWidget extends StatefulWidget {
  const ListCameraPageWidget({super.key});

  static String routeName = 'ListCameraPage';
  static String routePath = '/list-camera';

  @override
  State<ListCameraPageWidget> createState() => _ListCameraPageWidgetState();
}

class _ListCameraPageWidgetState extends State<ListCameraPageWidget> {
  late ListCameraPageModel _model;
  final scaffoldKey = GlobalKey<ScaffoldState>();

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => ListCameraPageModel());
    _model.searchBarTextController?.addListener(() => safeSetState(() {}));

    SchedulerBinding.instance.addPostFrameCallback((_) async {
      await Future.wait([_fetchCameras(page: 1), _fetchCameraStats()]);
    });

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Data fetching
  // ---------------------------------------------------------------------------

  Future<void> _fetchCameras({required int page, String search = ''}) async {
    if (!mounted) return;
    safeSetState(() => _model.isLoading = true);

    try {
      final response = await CameraService().getCameras(
        page: page.toString(),
        limit: ListCameraPageModel.pageSize.toString(),
        search: search.isNotEmpty ? search : null,
      );

      if (response.succeeded) {
        final dataList = CameraService().parseDataList(response.jsonBody) ?? [];

        // Sort: exact/prefix match float to top
        final q = search.toLowerCase();
        if (q.isNotEmpty) {
          dataList.sort((a, b) {
            final nameA =
                (getJsonField(a, r'$.name')?.toString() ?? '').toLowerCase();
            final nameB =
                (getJsonField(b, r'$.name')?.toString() ?? '').toLowerCase();
            final aExact = nameA == q;
            final bExact = nameB == q;
            if (aExact && !bExact) return -1;
            if (!aExact && bExact) return 1;
            final aStarts = nameA.startsWith(q);
            final bStarts = nameB.startsWith(q);
            if (aStarts && !bStarts) return -1;
            if (!aStarts && bStarts) return 1;
            final aContains = nameA.contains(q);
            final bContains = nameB.contains(q);
            if (aContains && !bContains) return -1;
            if (!aContains && bContains) return 1;
            return nameA.compareTo(nameB);
          });
        }

        _model.listOFcamera = dataList;

        final meta = getJsonField(response.jsonBody, r'$.meta');
        if (meta is Map<String, dynamic>) {
          _model.totalCameras = (meta['totalItems'] as int?) ?? dataList.length;
          _model.totalPages = (meta['totalPages'] as int?) ?? 1;
        } else {
          _model.totalCameras = dataList.length;
          _model.totalPages = 1;
        }
      } else {
        debugPrint('API error: ${response.statusCode}');
        _model.listOFcamera = [];
      }

      _model.currentPage = page;
      _model.searchQuery = search;
    } catch (e) {
      debugPrint('Error fetching cameras: $e');
    } finally {
      if (mounted) safeSetState(() => _model.isLoading = false);
    }
  }

  Future<void> _fetchCameraStats() async {
    try {
      final response = await CameraService().getCamerasTotal();
      if (response.succeeded) {
        final body = response.jsonBody;
        _model.totalCameras = _parseInt(body?['total']);
        _model.onlineCameras = _parseInt(body?['online']);
        _model.offlineCameras = _parseInt(body?['offline']);
      }
      if (mounted) safeSetState(() {});
    } catch (e) {
      debugPrint('Error fetching camera stats: $e');
    }
  }

  static int _parseInt(dynamic v) =>
      v is int ? v : int.tryParse(v?.toString() ?? '') ?? 0;

  void _onSearchChanged(String value) {
    EasyDebounce.debounce(
      'camera_search',
      const Duration(milliseconds: 400),
      () => _fetchCameras(page: 1, search: value),
    );
  }

  Future<void> _refresh() => Future.wait([
        _fetchCameras(page: 1, search: _model.searchQuery),
        _fetchCameraStats(),
      ]);

  // ---------------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------------

  Future<void> _confirmDelete(BuildContext context, dynamic item) async {
    final name = getJsonField(item, r'$.name')?.toString() ?? 'this camera';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Deletion'),
        content: Text('Are you sure you want to delete "$name"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444)),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final cameraId = getJsonField(item, r'$.id')?.toString() ?? '';
    if (cameraId.isEmpty) return;

    final response = await CameraService().deleteCamera(cameraId);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(response.succeeded
          ? 'Deleted "$name" successfully'
          : 'Failed to delete: ${response.statusCode}'),
      backgroundColor: response.succeeded
          ? const Color(0xFF16A34A)
          : const Color(0xFFEF4444),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ));

    await Future.wait([
      _fetchCameras(page: _model.currentPage, search: _model.searchQuery),
      _fetchCameraStats(),
    ]);
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: const Color(0xFFF3F4F6),
        appBar: AppBar(
          backgroundColor: Colors.white,
          automaticallyImplyLeading: false,
          title: wrapWithModel(
            model: _model.navBarMainModel,
            updateCallback: () => safeSetState(() {}),
            child: NavBarMainWidget(),
          ),
          centerTitle: false,
          toolbarHeight: AppTextStyles.navBarHeight,
          elevation: 2,
        ),
        body: SafeArea(
          top: true,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'List Cameras',
                  style: FlutterFlowTheme.of(context).headlineLarge.override(
                        fontFamily: FlutterFlowTheme.of(context)
                            .headlineLargeFamily,
                        color: const Color(0xFF111827),
                        letterSpacing: 0,
                        useGoogleFonts: !FlutterFlowTheme.of(context)
                            .headlineLargeIsCustom,
                      ),
                ),
                const SizedBox(height: 20),

                // Stat Cards
                CameraStatRow(model: _model),
                const SizedBox(height: 24),

                // Table Card
                CameraTableCard(
                  model: _model,
                  onSearchChanged: _onSearchChanged,
                  onClearSearch: () {
                    _model.searchBarTextController?.clear();
                    _fetchCameras(page: 1, search: '');
                  },
                  onAddCamera: () async {
                    await showDialog(
                      context: context,
                      builder: (_) => const AddnewcameraWidget(),
                    );
                    await _refresh();
                  },
                  onPageChanged: (p) =>
                      _fetchCameras(page: p, search: _model.searchQuery),
                  buildTable: () => _buildDataTable(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Table builder (อยู่ใน State เพราะต้องการ context + callbacks)
  // ---------------------------------------------------------------------------

  Widget _buildDataTable(BuildContext context) {
    const columns = [
      'Name', 'LatLong', 'Address', 'Status', 'Category', 'Action'
    ];
    const columnWidths = <int, TableColumnWidth>{
      0: FlexColumnWidth(2),
      1: FlexColumnWidth(2),
      2: FlexColumnWidth(3),
      3: FlexColumnWidth(1.5),
      4: FlexColumnWidth(1.5),
      5: FlexColumnWidth(2),
    };

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Table(
        columnWidths: columnWidths,
        border: TableBorder(
            horizontalInside: BorderSide(color: Colors.grey.shade200)),
        children: [
          // Header row
          TableRow(
            decoration:
                BoxDecoration(color: FlutterFlowTheme.of(context).primary),
            children: columns
                .map((col) => TableCell(
                      verticalAlignment: TableCellVerticalAlignment.middle,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 14),
                        child: Text(
                          col,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: AppTextStyles.tableHeader,
                          ),
                        ),
                      ),
                    ))
                .toList(),
          ),

          // Data rows
          ..._model.listOFcamera.asMap().entries.map((entry) {
            final i = entry.key;
            final item = entry.value;
            final name = getJsonField(item, r'$.name')?.toString() ?? '-';
            final status =
                getJsonField(item, r'$.status')?.toString() ?? 'unknown';
            final lastSeenRaw = getJsonField(item, r'$.lastSeen');

            DateTime? lastSeen;
            if (lastSeenRaw is String) {
              lastSeen = DateTime.tryParse(lastSeenRaw);
            } else if (lastSeenRaw is int) {
              lastSeen =
                  DateTime.fromMillisecondsSinceEpoch(lastSeenRaw * 1000);
            }

            return TableRow(
              decoration: BoxDecoration(
                color: i % 2 == 1 ? const Color(0xFFF9FAFB) : Colors.white,
              ),
              children: [
                NameCell(name: name, search: _model.searchQuery),
                TextCell(
                  getJsonField(item, r'$.latLong')?.toString() ?? '-',
                  fontSize: AppTextStyles.tableTimestamp,
                  color: const Color(0xFF6B7280),
                ),
                TextCell(
                  getJsonField(item, r'$.address')?.toString() ?? '-',
                  fontSize: AppTextStyles.tableTimestamp,
                ),
                TableCell(
                  verticalAlignment: TableCellVerticalAlignment.middle,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    child: StatusChip(
                      status: status,
                      lastSeen: lastSeen,
                      fontSize: AppTextStyles.commandSmall,
                    ),
                  ),
                ),
                TableCell(
                  verticalAlignment: TableCellVerticalAlignment.middle,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    child: _buildCategoryChips(item),
                  ),
                ),
                TableCell(
                  verticalAlignment: TableCellVerticalAlignment.middle,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 4, vertical: 6),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ActionBtn(
                          icon: Icons.remove_red_eye_outlined,
                          tooltip: 'View details',
                          color: FlutterFlowTheme.of(context).primary,
                          onPressed: () => showDialog(
                            context: context,
                            builder: (_) =>
                                DetailscameraWidget(cameraData: item),
                          ),
                        ),
                        ActionBtn(
                          icon: Icons.edit_outlined,
                          tooltip: 'Edit',
                          color: const Color(0xFFF59E0B),
                          onPressed: () async {
                            final result = await showDialog<bool>(
                              context: context,
                              builder: (_) =>
                                  EditdatacameraWidget(cameraData: item),
                            );
                            if (result == true) {
                              await Future.wait([
                                _fetchCameras(
                                    page: _model.currentPage,
                                    search: _model.searchQuery),
                                _fetchCameraStats(),
                              ]);
                            }
                          },
                        ),
                        ActionBtn(
                          icon: Icons.delete_outline,
                          tooltip: 'Delete',
                          color: const Color(0xFFEF4444),
                          onPressed: () => _confirmDelete(context, item),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildCategoryChips(dynamic item) {
    final cats = getJsonField(item, r'$.categories');
    if (cats == null || (cats is List && cats.isEmpty)) {
      return const SizedBox.shrink();
    }
    final list = cats is List ? cats : [cats];
    final names = list
        .map((c) => c is Map ? c['name']?.toString() ?? '' : c.toString())
        .where((n) => n.isNotEmpty)
        .toList();
    if (names.isEmpty) return const SizedBox.shrink();
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: names
          .map((n) =>
              CategoryChip(name: n, fontSize: AppTextStyles.tableStatus))
          .toList(),
    );
  }
}