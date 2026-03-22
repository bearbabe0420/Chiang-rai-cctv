import '/data/services/index.dart';
import '../../widgets/nav/nav_bar_main_widget.dart';
import '/core/i18n/i18n.dart';
import '/utils/flutter_flow/theme.dart';
import '/utils/flutter_flow/util.dart';
import 'package:easy_debounce/easy_debounce.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'widgets/plate_main_card.dart';
import 'widgets/plate_table_cells.dart';
import 'widgets/image_viewer_dialog.dart';
import 'searchlicenseplate_model.dart';
export 'searchlicenseplate_model.dart';

class ListPlatePageWidget extends StatefulWidget {
  const ListPlatePageWidget({super.key});

  static String routeName = 'ListPlatePage';
  static String routePath = '/list-plate';

  @override
  State<ListPlatePageWidget> createState() => _ListPlatePageWidgetState();
}

class _ListPlatePageWidgetState extends State<ListPlatePageWidget> {
  late ListPlatePageModel _model;
  final scaffoldKey = GlobalKey<ScaffoldState>();

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => ListPlatePageModel());
    _model.searchBarController.addListener(() => safeSetState(() {}));

    SchedulerBinding.instance.addPostFrameCallback((_) async {
      final fullPlate = Uri.base.queryParameters['fullPlate'] ?? '';
      if (fullPlate.isNotEmpty) {
        _model.searchBarController.text = fullPlate;
      }
      await _fetchPlates(page: 1, search: fullPlate);
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

  Future<void> _fetchPlates({required int page, String search = ''}) async {
    if (!mounted) return;
    safeSetState(() => _model.isLoading = true);

    try {
      final response = await LicensePlateService().searchLicensePlates(
        licensePlate: search.isNotEmpty ? search : null,
      );

      if (response.succeeded) {
        final raw = _parsePlateList(response.jsonBody);
        _model.listOfPlates = _sortPlates(raw, search);
        _model.totalItems = _model.listOfPlates.length;
        _model.totalPages =
            ((_model.totalItems / ListPlatePageModel.pageSize).ceil())
                .clamp(1, 9999)
                .toInt();
      } else {
        debugPrint('API error: ${response.statusCode}');
        _model.listOfPlates = [];
        _model.totalItems = 0;
        _model.totalPages = 1;
      }

      _model.currentPage = page.clamp(1, _model.totalPages).toInt();
      _model.searchQuery = search;
    } catch (e) {
      debugPrint('Error fetching plates: $e');
    } finally {
      if (mounted) safeSetState(() => _model.isLoading = false);
    }
  }

  List<Map<String, dynamic>> _parsePlateList(dynamic body) {
    List<dynamic> raw;
    if (body is List) {
      raw = body;
    } else {
      final dataField = getJsonField(body, r'$.data');
      raw = dataField is List ? dataField : [];
    }
    return raw
        .map((item) =>
            item is Map<String, dynamic> ? item : <String, dynamic>{})
        .toList();
  }

  List<Map<String, dynamic>> _sortPlates(
      List<Map<String, dynamic>> list, String search) {
    final searchLower = search.toLowerCase();
    return list
      ..sort((a, b) {
        final plateA =
            (a['licensePlate']?['fullPlate'] ?? '').toString().toLowerCase();
        final plateB =
            (b['licensePlate']?['fullPlate'] ?? '').toString().toLowerCase();
        final aStarts = plateA.startsWith(searchLower);
        final bStarts = plateB.startsWith(searchLower);
        if (aStarts && !bStarts) return -1;
        if (!aStarts && bStarts) return 1;
        return (b['timestamp'] ?? '').compareTo(a['timestamp'] ?? '');
      });
  }

  void _onSearchChanged(String value) {
    EasyDebounce.debounce(
      'plate_search',
      const Duration(milliseconds: 500),
      () => _fetchPlates(page: 1, search: value),
    );
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  static String _formatTimestamp(String raw) {
    try {
      final value = raw.trim();
      if (value.isEmpty) return '-';

      String two(int n) => n.toString().padLeft(2, '0');
      String fmt(DateTime dt) {
        final l = dt.toLocal();
        return '${two(l.day)}/${two(l.month)}/${l.year} '
            '${two(l.hour)}:${two(l.minute)}:${two(l.second)}';
      }

      // Format: 20260215_224822
      final compact = RegExp(
              r'^(\d{4})(\d{2})(\d{2})_(\d{2})(\d{2})(\d{2})$')
          .firstMatch(value);
      if (compact != null) {
        return fmt(DateTime(
          int.parse(compact.group(1)!),
          int.parse(compact.group(2)!),
          int.parse(compact.group(3)!),
          int.parse(compact.group(4)!),
          int.parse(compact.group(5)!),
          int.parse(compact.group(6)!),
        ));
      }

      // ISO
      final parsed = DateTime.tryParse(value);
      if (parsed != null) return fmt(parsed);

      // Already display format
      if (RegExp(r'^\d{2}/\d{2}/\d{4}\s\d{2}:\d{2}:\d{2}$').hasMatch(value)) {
        return value;
      }

      return value;
    } catch (_) {
      return raw;
    }
  }

  void _openImageViewer(BuildContext context, String imageUrl,
      {String? plateText, String? province}) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (_) => ImageViewerDialog(
        imageUrl: imageUrl,
        plateText: plateText,
        province: province,
      ),
    );
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
                  context.tr('plate.title'),
                  style: FlutterFlowTheme.of(context).headlineLarge.override(
                        fontFamily: FlutterFlowTheme.of(context)
                            .headlineLargeFamily,
                        color: const Color(0xFF111827),
                        letterSpacing: 0,
                        useGoogleFonts: !FlutterFlowTheme.of(context)
                            .headlineLargeIsCustom,
                      ),
                ),
                const SizedBox(height: 24),

                PlateMainCard(
                  model: _model,
                  onSearchChanged: _onSearchChanged,
                  onClearSearch: () {
                    _model.searchBarController.clear();
                    _fetchPlates(page: 1);
                  },
                  onPageChanged: (page) =>
                      _fetchPlates(page: page, search: _model.searchQuery),
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
  // Table builder
  // ---------------------------------------------------------------------------

  Widget _buildDataTable(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Table(
        columnWidths: const {
          0: FlexColumnWidth(2.0),
          1: FlexColumnWidth(2.0),
          2: FlexColumnWidth(2.2),
          3: FlexColumnWidth(2.0),
        },
        border: TableBorder(
          horizontalInside: BorderSide(color: Colors.grey.shade200),
        ),
        children: [
          _buildTableHeader(context),
          ..._buildTableRows(context),
        ],
      ),
    );
  }

  TableRow _buildTableHeader(BuildContext context) {
    final columns = [
      context.tr('plate.columns.full_plate'),
      context.tr('plate.columns.camera_name'),
      context.tr('plate.columns.timestamp'),
      context.tr('plate.columns.image'),
    ];
    return TableRow(
      decoration: BoxDecoration(color: FlutterFlowTheme.of(context).primary),
      children: columns
          .map((col) => TableCell(
                verticalAlignment: TableCellVerticalAlignment.middle,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 14),
                  child: Text(
                    col,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: AppTextStyles.tableHeader,
                    ),
                  ),
                ),
              ))
          .toList(),
    );
  }

  List<TableRow> _buildTableRows(BuildContext context) {
    final start = (_model.currentPage - 1) * ListPlatePageModel.pageSize;
    final end = (start + ListPlatePageModel.pageSize)
        .clamp(0, _model.listOfPlates.length)
        .toInt();
    final items = start >= _model.listOfPlates.length
        ? <Map<String, dynamic>>[]
        : _model.listOfPlates.sublist(start, end);

    return items.asMap().entries.map((entry) {
      final i = entry.key;
      final item = entry.value;

      final plate = item['licensePlate'] as Map<String, dynamic>?;
      final fullPlate = plate?['fullPlate'] as String? ?? '-';
      final province = plate?['province'] as String? ?? '';
      final cameraName =
          (item['camera'] as Map<String, dynamic>?)?['cameraName']
                  as String? ??
              '-';
      final timestamp = item['timestamp'] as String? ?? '-';
      final imageUrl = item['imageUrl'] as String? ?? '';

      return TableRow(
        decoration: BoxDecoration(
          color: i % 2 == 1 ? const Color(0xFFF9FAFB) : Colors.white,
        ),
        children: [
          PlateCell(fullPlate: fullPlate, province: province),
          IconLabelCell(
            icon: Icons.videocam_outlined,
            label: cameraName,
            fontSize: AppTextStyles.tableCell,
          ),
          IconLabelCell(
            icon: Icons.access_time,
            label: _formatTimestamp(timestamp),
            fontSize: AppTextStyles.tableTimestamp,
            labelColor: const Color(0xFF6B7280),
            iconColor: Colors.grey.shade400,
          ),
          TableCell(
            verticalAlignment: TableCellVerticalAlignment.middle,
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: imageUrl.isEmpty
                  ? const Icon(Icons.no_photography_outlined,
                      color: Color(0xFFD1D5DB), size: 28)
                  : HoverableImage(
                      imageUrl: imageUrl,
                      fullPlate: fullPlate,
                      province: province,
                      onTap: () => _openImageViewer(
                        context,
                        imageUrl,
                        plateText: fullPlate,
                        province: province,
                      ),
                    ),
            ),
          ),
        ],
      );
    }).toList();
  }
}