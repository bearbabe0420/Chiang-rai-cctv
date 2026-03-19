import '/data/services/index.dart';
import '/core/i18n/i18n.dart';
import '/presentation/widgets/nav_bar_main_widget.dart';
import '/presentation/widgets/shared/category_chip.dart';
import '/utils/flutter_flow_data_table.dart';
import '/utils/flutter_flow_icon_button.dart';
import '/utils/flutter_flow_theme.dart';
import '/utils/flutter_flow_util.dart';
import '/utils/flutter_flow_widgets.dart';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:text_search/text_search.dart';
import 'package:easy_debounce/easy_debounce.dart';
import 'collection_model.dart';
export 'collection_model.dart';

class CollectionWidget extends StatefulWidget {
  const CollectionWidget({super.key});

  static String routeName = 'Collection';
  static String routePath = '/Collection';

  @override
  State<CollectionWidget> createState() => _CollectionWidgetState();
}

class _CollectionWidgetState extends State<CollectionWidget> {
  late CollectionModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => CollectionModel());

    _model.textController ??= TextEditingController();
    _model.textFieldFocusNode ??= FocusNode();
    
    // Rebuild when search text changes (so X button shows/hides)
    _model.textController?.addListener(() => safeSetState(() {}));

    SchedulerBinding.instance.addPostFrameCallback((_) async {
      await _fetchCameras(page: 1);
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

  /// Fetch a page of cameras from the API.
  Future<void> _fetchCameras({required int page, String search = ''}) async {
    if (!mounted) return;

    try {
      safeSetState(() => _model.isLoading = true);

      final response = await CameraService().getCameras(
        page: page.toString(),
        limit: CollectionModel.pageSize.toString(),
        search: search.isNotEmpty ? search : null,
      );

      if (!mounted) return;

      if (response.succeeded) {
        final dataList = CameraService().parseDataList(response.jsonBody) ?? [];
        final meta = getJsonField(response.jsonBody, r'$.meta');

        // Single atomic rebuild — all state set together
        if (mounted) {
          safeSetState(() {
            _model.listOfCameras = dataList;
            _model.currentPage = page;
            _model.searchQuery = search;
            _model.isLoading = false;
            if (meta != null && meta is Map<String, dynamic>) {
              _model.totalCameras =
                  (meta['totalItems'] as int?) ?? dataList.length;
              _model.totalPages = (meta['totalPages'] as int?) ?? 1;
            } else {
              _model.totalCameras = dataList.length;
              _model.totalPages = 1;
            }
          });

          // Reset PaginatedDataTable to first page — guarded with mounted & try-catch
          try {
            if (_model.paginatedDataTableController.paginatorController != null) {
              _model.paginatedDataTableController.paginatorController
                  .goToFirstPage();
            }
          } catch (e) {
            debugPrint('Could not reset paginator (not yet attached): $e');
          }
        }
      } else {
        debugPrint('API error: ${response.statusCode}');
        if (mounted) {
          safeSetState(() {
            _model.listOfCameras = [];
            _model.currentPage = page;
            _model.searchQuery = search;
            _model.isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching cameras: $e');
      if (mounted) safeSetState(() => _model.isLoading = false);
    }
  }

  void _onSearchChanged(String value) {
    EasyDebounce.debounce(
      'camera_search',
      const Duration(milliseconds: 500),
      () => _fetchCameras(page: 1, search: value),
    );
  }

  // ---------------------------------------------------------------------------
  // Pagination UI
  // ---------------------------------------------------------------------------

  Widget _buildPagination(BuildContext context) {
    final total = _model.totalPages;
    final current = _model.currentPage;

    // Build visible page numbers with ellipsis logic
    final List<int?> pageNums = []; // null = ellipsis
    if (total <= 7) {
      for (int p = 1; p <= total; p++) pageNums.add(p);
    } else {
      pageNums.add(1);
      if (current > 3) pageNums.add(null); // ...
      final start = (current - 1).clamp(2, total - 1);
      final end = (current + 1).clamp(2, total - 1);
      for (int p = start; p <= end; p++) pageNums.add(p);
      if (current < total - 2) pageNums.add(null); // ...
      pageNums.add(total);
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // First
        _pageNavButton(
          icon: Icons.first_page,
          enabled: current > 1,
          onTap: () => _fetchCameras(page: 1, search: _model.searchQuery),
        ),
        const SizedBox(width: 2),
        // Prev
        _pageNavButton(
          icon: Icons.chevron_left,
          enabled: current > 1,
          onTap: () => _fetchCameras(
              page: current - 1, search: _model.searchQuery),
        ),
        const SizedBox(width: 4),
        // Page buttons
        ...pageNums.map(
          (p) {
            if (p == null) {
              return const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4),
                child: Text('...', style: TextStyle(color: Color(0xFF6B7280), fontSize: 14)),
              );
            }
            final isActive = p == current;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: InkWell(
                onTap: isActive
                    ? null
                    : () => _fetchCameras(page: p, search: _model.searchQuery),
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isActive
                        ? FlutterFlowTheme.of(context).primary
                        : Colors.white,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isActive
                          ? FlutterFlowTheme.of(context).primary
                          : const Color(0xFFD1D5DB),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '$p',
                      style: TextStyle(
                        color: isActive ? Colors.white : const Color(0xFF374151),
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(width: 4),
        // Next
        _pageNavButton(
          icon: Icons.chevron_right,
          enabled: current < total,
          onTap: () => _fetchCameras(
              page: current + 1, search: _model.searchQuery),
        ),
        const SizedBox(width: 2),
        // Last
        _pageNavButton(
          icon: Icons.last_page,
          enabled: current < total,
          onTap: () => _fetchCameras(page: total, search: _model.searchQuery),
        ),
      ],
    );
  }

  Widget _pageNavButton({
    required IconData icon,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: enabled
                ? const Color(0xFFD1D5DB)
                : const Color(0xFFE5E7EB),
          ),
        ),
        child: Icon(
          icon,
          size: 20,
          color: enabled
              ? const Color(0xFF374151)
              : const Color(0xFFD1D5DB),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // UI helpers
  // ---------------------------------------------------------------------------

  /// Fixed palette of background/text color pairs for category chips.
  static const List<_ChipColor> _chipPalette = [
    _ChipColor(bg: Color(0xFFEDE9FE), text: Color(0xFF5B21B6)), // violet
    _ChipColor(bg: Color(0xFFDBEAFE), text: Color(0xFF1D4ED8)), // blue
    _ChipColor(bg: Color(0xFFD1FAE5), text: Color(0xFF065F46)), // green
    _ChipColor(bg: Color(0xFFFEF3C7), text: Color(0xFF92400E)), // amber
    _ChipColor(bg: Color(0xFFFCE7F3), text: Color(0xFF9F1239)), // rose
    _ChipColor(bg: Color(0xFFCCFBF1), text: Color(0xFF115E59)), // teal
    _ChipColor(bg: Color(0xFFE0E7FF), text: Color(0xFF3730A3)), // indigo
    _ChipColor(bg: Color(0xFFFFEDD5), text: Color(0xFF9A3412)), // orange
    _ChipColor(bg: Color(0xFFF3E8FF), text: Color(0xFF6B21A8)), // purple
    _ChipColor(bg: Color(0xFFD1FAE5), text: Color(0xFF047857)), // emerald
    _ChipColor(bg: Color(0xFFE0F2FE), text: Color(0xFF075985)), // sky
    _ChipColor(bg: Color(0xFFFEE2E2), text: Color(0xFFB91C1C)), // red
  ];

  /// Returns a consistent color for a given category name.
  _ChipColor _colorFor(String name) {
    final idx = name.codeUnits.fold(0, (a, b) => a + b) % _chipPalette.length;
    return _chipPalette[idx];
  }

  Widget _buildCategoryChips(dynamic item) {
  final cats = getJsonField(item, r'$.categories');
  if (cats == null || (cats is List && cats.isEmpty)) {
    return const SizedBox.shrink();
  }
  final list = cats is List ? cats : [cats];
  final names = list
      .map((c) {
        if (c is Map) return c['name']?.toString() ?? '';
        return c.toString();
      })
      .where((n) => n.isNotEmpty)
      .toList();
  if (names.isEmpty) {
    return const SizedBox.shrink();
  }
  return Wrap(
    spacing: 6,
    runSpacing: 6,
    children: names.map((name) {
      return CategoryChip(
        name: name,
        fontSize: AppTextStyles.tableStatus, // หรือ 14
      );
    }).toList(),
  );
}

  /// Builds a status badge with colored background and dot indicator
  Widget _buildStatusBadge(String status) {
    final isOnline = status.toLowerCase() == 'online';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isOnline ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: isOnline ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            isOnline ? context.tr('marker_popup.online') : context.tr('marker_popup.offline'),
            style: TextStyle(
              color: isOnline ? const Color(0xFF15803D) : const Color(0xFFDC2626),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: const Color(0xFFF3F4F6),
        body: NestedScrollView(
          floatHeaderSlivers: true,
          physics: NeverScrollableScrollPhysics(),
          headerSliverBuilder: (context, _) => [
            SliverAppBar(
              pinned: true,
              floating: true,
              toolbarHeight: AppTextStyles.navBarHeight,
              backgroundColor: const Color(0xFFF3F4F6),
              iconTheme: IconThemeData(color: Color(0xFFD6C6C6)),
              automaticallyImplyLeading: false,
              title: wrapWithModel(
                model: _model.navBarMainModel,
                updateCallback: () => safeSetState(() {}),
                child: NavBarMainWidget(),
              ),
              actions: [],
              centerTitle: true,
              elevation: 0.0,
            )
          ],
          body: Builder(
            builder: (context) {
              return SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.max,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Page title
                      Text(
                        'จัดการหมวดหมู่',
                        style: FlutterFlowTheme.of(context).headlineLarge.override(
                              fontFamily:
                                  FlutterFlowTheme.of(context).headlineLargeFamily,
                              color: const Color(0xFF111827),
                              letterSpacing: 0,
                              useGoogleFonts: !FlutterFlowTheme.of(context)
                                  .headlineLargeIsCustom,
                            ),
                      ),
                      const SizedBox(height: 20),
                      // Container with search, buttons, table, and pagination
                      Expanded(
                        child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            mainAxisSize: MainAxisSize.max,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Search bar and action buttons row
                              Row(
                                mainAxisSize: MainAxisSize.max,
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                Expanded(
                                  child: SizedBox(
                                    height: 44,
                                    child: TextField(
                                    controller: _model.textController,
                                    focusNode: _model.textFieldFocusNode,
                                    onChanged: (value) {
                                      safeSetState(() {
                                        _model.searchQuery = value;
                                      });
                                      _onSearchChanged(value);
                                    },
                                    decoration: InputDecoration(
                                      hintText: context.tr('collection.search_hint'),
                                      hintStyle: const TextStyle(
                                          color: Color(0xFF9CA3AF),
                                          fontSize: 14),
                                      prefixIcon: const Icon(
                                          Icons.search,
                                          color: Color(0xFF9CA3AF),
                                          size: 20),
                                      suffixIcon: (_model.textController?.text.isNotEmpty ?? false)
                                          ? IconButton(
                                              icon: const Icon(Icons.close,
                                                  size: 18,
                                                  color: Color(0xFF9CA3AF)),
                                              onPressed: () {
                                                _model.textController?.clear();
                                                safeSetState(() {
                                                  _model.searchQuery = '';
                                                });
                                                _fetchCameras(page: 1, search: '');
                                              },
                                            )
                                          : null,
                                      filled: true,
                                      fillColor: const Color(0xFFF9FAFB),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 14, vertical: 10),
                                      border: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(8),
                                        borderSide: const BorderSide(
                                            color: Color(0xFFE5E7EB)),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(8),
                                        borderSide: const BorderSide(
                                            color: Color(0xFFE5E7EB)),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(8),
                                        borderSide: BorderSide(
                                            color: FlutterFlowTheme.of(context)
                                                .primary),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                            FlutterFlowIconButton(
                              borderColor: Color(0xFFDC2626),
                                borderRadius: 12.0,
                                borderWidth: 2.0,
                                buttonSize: 50.0,
                                fillColor: Colors.transparent,
                                icon: Icon(
                                  Icons.refresh,
                                  color: Color(0xFFDC2626),
                                  size: 26.0,
                                ),
                                onPressed: () async {
                                  // Clear search and reset to show all cameras
                                  safeSetState(() {
                                    _model.textController?.clear();
                                    _model.searchQuery = '';
                                  });
                                  
                                  // Fetch first page with no search
                                  _fetchCameras(page: 1, search: '');

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Row(
                                        children: [
                                          Icon(Icons.refresh_rounded,
                                              color: Colors.white),
                                          SizedBox(width: 8.0),
                                          Text(
                                              context.tr('collection.search_cleared')),
                                        ],
                                      ),
                                      duration: Duration(milliseconds: 2000),
                                      backgroundColor: Color(0xFF6C757D),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                },
                              ),
                            const SizedBox(width: 16),
                            FFButtonWidget(
                              onPressed: () async {
                                  // Show comprehensive category management dialog
                                  await showDialog(
                                    context: context,
                                    builder: (BuildContext dialogContext) {
                                      // State for the dialog
                                      Map<String, bool> expandedMap = {};
                                      Map<String, List<dynamic>> categoryCameras = {};
                                      
                                      return StatefulBuilder(
                                        builder: (context, setDialogState) {
                                          return FutureBuilder<ApiCallResponse>(
                                            future: CategoryService().getCategories(limit: '100'),
                                            builder: (context, snapshot) {
                                              if (!snapshot.hasData) {
                                                return Center(
                                                  child: SizedBox(
                                                    width: 50.0,
                                                    height: 50.0,
                                                    child: CircularProgressIndicator(
                                                      valueColor:
                                                          AlwaysStoppedAnimation<Color>(
                                                        FlutterFlowTheme.of(context)
                                                            .primary,
                                                      ),
                                                    ),
                                                  ),
                                                );
                                              }
                                              
                                              final categoriesResponse = snapshot.data!;
                                              final categories = CategoryService().parseDataList(
                                                categoriesResponse.jsonBody) ?? [];
                                              
                                              // Fetch all cameras once for efficient filtering
                                              return FutureBuilder<ApiCallResponse>(
                                                future: CameraService().getCameras(limit: '100'),
                                                builder: (context, allCamerasSnapshot) {
                                                  final allCameras = allCamerasSnapshot.hasData
                                                      ? (CameraService().parseDataList(
                                                              allCamerasSnapshot.data!.jsonBody) ?? [])
                                                      : [];
                                                  
                                                  return AlertDialog(
                                                title: Row(
                                                  children: [
                                                    Icon(Icons.video_library,
                                                        color: Color(0xFF4B39EF)),
                                                    SizedBox(width: 8.0),
                                                    Text('จัดการหมวดหมู่'),
                                                    Spacer(),
                                                    IconButton(
                                                      icon: Icon(Icons.add_circle, color: Color(0xFF4B39EF)),
                                                      tooltip: 'สร้างหมวดหมู่ใหม่',
                                                      onPressed: () async {
                                                        // Show create category dialog
                                                        final TextEditingController newCategoryController = 
                                                            TextEditingController();
                                                        
                                                        await showDialog(
                                                          context: context,
                                                          builder: (createContext) {
                                                            return AlertDialog(
                                                              title: Row(
                                                                children: [
                                                                  Icon(Icons.create_new_folder_outlined,
                                                                      color: Color(0xFF4B39EF)),
                                                                  SizedBox(width: 8.0),
                                                                  Text('สร้างหมวดหมู่ใหม่'),
                                                                ],
                                                              ),
                                                              content: TextField(
                                                                controller: newCategoryController,
                                                                decoration: InputDecoration(
                                                                  labelText: 'ชื่อหมวดหมู่ *',
                                                                  hintText: 'เช่น กล้องทางเข้า',
                                                                  border: OutlineInputBorder(
                                                                    borderRadius: BorderRadius.circular(8.0),
                                                                  ),
                                                                  prefixIcon: Icon(Icons.label_outlined,
                                                                      color: Color(0xFF4B39EF)),
                                                                ),
                                                                autofocus: true,
                                                              ),
                                                              actions: [
                                                                TextButton(
                                                                  onPressed: () => Navigator.pop(createContext),
                                                                  child: Text('ยกเลิก'),
                                                                ),
                                                                ElevatedButton(
                                                                  onPressed: () async {
                                                                    final name = newCategoryController.text.trim();
                                                                    if (name.isEmpty) {
                                                                      ScaffoldMessenger.of(context).showSnackBar(
                                                                        SnackBar(
                                                                          content: Text('กรุณากรอกชื่อหมวดหมู่'),
                                                                          backgroundColor: Colors.red,
                                                                        ),
                                                                      );
                                                                      return;
                                                                    }
                                                                    
                                                                    Navigator.pop(createContext);
                                                                    
                                                                    // Show loading
                                                                    showDialog(
                                                                      context: context,
                                                                      barrierDismissible: false,
                                                                      builder: (loadingContext) => Center(
                                                                        child: CircularProgressIndicator(),
                                                                      ),
                                                                    );
                                                                    
                                                                    final createResponse = await CategoryService()
                                                                        .createCategory(name: name);
                                                                    
                                                                    Navigator.pop(context);
                                                                    
                                                                    if (createResponse.succeeded) {
                                                                      ScaffoldMessenger.of(context).showSnackBar(
                                                                        SnackBar(
                                                                          content: Text('สร้างหมวดหมู่ "$name" สำเร็จ'),
                                                                          backgroundColor: Color(0xFF4CAF50),
                                                                        ),
                                                                      );
                                                                      // Refresh the dialog
                                                                      setDialogState(() {});
                                                                    } else {
                                                                      ScaffoldMessenger.of(context).showSnackBar(
                                                                        SnackBar(
                                                                          content: Text('สร้างหมวดหมู่ไม่สำเร็จ'),
                                                                          backgroundColor: Colors.red,
                                                                        ),
                                                                      );
                                                                    }
                                                                  },
                                                                  style: ElevatedButton.styleFrom(
                                                                    backgroundColor: Color(0xFF4B39EF),
                                                                  ),
                                                                  child: Text('สร้าง',
                                                                      style: TextStyle(color: Colors.white)),
                                                                ),
                                                              ],
                                                            );
                                                          },
                                                        );
                                                      },
                                                    ),
                                                  ],
                                                ),
                                                content: Container(
                                                  width: 600.0,
                                                  height: 500.0,
                                                  child: categories.isEmpty
                                                      ? Column(
                                                          mainAxisSize: MainAxisSize.min,
                                                          mainAxisAlignment: MainAxisAlignment.center,
                                                          children: [
                                                            Icon(
                                                              Icons.category_outlined,
                                                              size: 64.0,
                                                              color: FlutterFlowTheme.of(context)
                                                                  .secondaryText,
                                                            ),
                                                            SizedBox(height: 16.0),
                                                            Text(
                                                              'ยังไม่มีหมวดหมู่',
                                                              style: FlutterFlowTheme.of(context)
                                                                  .titleMedium,
                                                            ),
                                                            SizedBox(height: 8.0),
                                                            Text(
                                                              'กดไอคอน + ด้านบนเพื่อสร้างหมวดหมู่แรก',
                                                              style: FlutterFlowTheme.of(context)
                                                                  .bodySmall,
                                                              textAlign: TextAlign.center,
                                                            ),
                                                          ],
                                                        )
                                                      : ListView.builder(
                                                          shrinkWrap: true,
                                                          itemCount: categories.length,
                                                          itemBuilder: (context, index) {
                                                            final category = categories[index];
                                                            final categoryId = getJsonField(category, r'$.id').toString();
                                                            final categoryName = getJsonField(category, r'$.name').toString();
                                                            final isExpanded = expandedMap[categoryId] ?? false;
                                                            final categoryColor = _colorFor(categoryName);
                                                            
                                                            return Card(
                                                              margin: EdgeInsets.symmetric(vertical: 4.0),
                                                              elevation: 2.0,
                                                              child: Column(
                                                                children: [
                                                                  ListTile(
                                                                    leading: CircleAvatar(
                                                                      backgroundColor: categoryColor.text,
                                                                      child: Icon(
                                                                        Icons.folder,
                                                                        color: Colors.white,
                                                                        size: 20.0,
                                                                      ),
                                                                    ),
                                                                    title: Text(
                                                                      categoryName,
                                                                      style: FlutterFlowTheme.of(context)
                                                                          .titleMedium
                                                                          .override(
                                                                            fontFamily: 'Readex Pro',
                                                                            fontWeight: FontWeight.w600,
                                                                          ),
                                                                    ),
                                                                    trailing: Row(
                                                                      mainAxisSize: MainAxisSize.min,
                                                                      children: [
                                                                        IconButton(
                                                                          icon: Icon(
                                                                            isExpanded 
                                                                                ? Icons.expand_less 
                                                                                : Icons.expand_more,
                                                                            color: categoryColor.text,
                                                                          ),
                                                                          tooltip: isExpanded
                                                                              ? context.tr('collection.tooltip.collapse')
                                                                              : context.tr('collection.tooltip.expand'),
                                                                          onPressed: () {
                                                                            setDialogState(() {
                                                                              expandedMap[categoryId] = !isExpanded;
                                                                            });
                                                                          },
                                                                        ),
                                                                        IconButton(
                                                                          icon: Icon(
                                                                            Icons.edit,
                                                                            color: categoryColor.text,
                                                                            size: 20.0,
                                                                          ),
                                                                          tooltip: context.tr('collection.tooltip.edit_name'),
                                                                          onPressed: () async {
                                                                            final TextEditingController editController =
                                                                                TextEditingController(text: categoryName);
                                                                            
                                                                            await showDialog(
                                                                              context: context,
                                                                              builder: (editContext) {
                                                                                return AlertDialog(
                                                                                  title: Text(context.tr('collection.edit.title')),
                                                                                  content: TextField(
                                                                                    controller: editController,
                                                                                    decoration: InputDecoration(
                                                                                      labelText: context.tr('collection.edit.name_label'),
                                                                                      border: OutlineInputBorder(),
                                                                                    ),
                                                                                    autofocus: true,
                                                                                  ),
                                                                                  actions: [
                                                                                    TextButton(
                                                                                      onPressed: () =>
                                                                                          Navigator.pop(editContext),
                                                                                      child: Text(context.tr('common.cancel')),
                                                                                    ),
                                                                                    ElevatedButton(
                                                                                      onPressed: () async {
                                                                                        final newName = editController.text.trim();
                                                                                        if (newName.isEmpty) {
                                                                                          ScaffoldMessenger.of(context)
                                                                                              .showSnackBar(
                                                                                            SnackBar(
                                                                                              content: Text(
                                                                                                  context.tr('collection.edit.name_required')),
                                                                                              backgroundColor: Colors.red,
                                                                                            ),
                                                                                          );
                                                                                          return;
                                                                                        }
                                                                                        
                                                                                        Navigator.pop(editContext);
                                                                                        
                                                                                        showDialog(
                                                                                          context: context,
                                                                                          barrierDismissible: false,
                                                                                          builder: (loadingContext) =>
                                                                                              Center(
                                                                                            child:
                                                                                                CircularProgressIndicator(),
                                                                                          ),
                                                                                        );
                                                                                        
                                                                                        final updateResponse =
                                                                                            await CategoryService()
                                                                                                .editCategory(
                                                                                          categoryId: categoryId,
                                                                                          name: newName,
                                                                                        );
                                                                                        
                                                                                        Navigator.pop(context);
                                                                                        
                                                                                        if (updateResponse.succeeded) {
                                                                                          ScaffoldMessenger.of(context)
                                                                                              .showSnackBar(
                                                                                            SnackBar(
                                                                                              content: Text(
                                                                                                  context.tr('collection.edit.updated_success')),
                                                                                              backgroundColor:
                                                                                                  Color(0xFF4CAF50),
                                                                                            ),
                                                                                          );
                                                                                          setDialogState(() {});
                                                                                        } else {
                                                                                          ScaffoldMessenger.of(context)
                                                                                              .showSnackBar(
                                                                                            SnackBar(
                                                                                              content: Text(
                                                                                                  context.tr('collection.edit.update_failed')),
                                                                                              backgroundColor: Colors.red,
                                                                                            ),
                                                                                          );
                                                                                        }
                                                                                      },
                                                                                      style: ElevatedButton.styleFrom(
                                                                                        backgroundColor:
                                                                                            Color(0xFF4B39EF),
                                                                                      ),
                                                                                      child: Text(context.tr('collection.edit.save'),
                                                                                          style: TextStyle(
                                                                                              color: Colors.white)),
                                                                                    ),
                                                                                  ],
                                                                                );
                                                                              },
                                                                            );
                                                                          },
                                                                        ),
                                                                        IconButton(
                                                                          icon: Icon(
                                                                            Icons.delete,
                                                                            color: Colors.red,
                                                                            size: 20.0,
                                                                          ),
                                                                          tooltip: context.tr('common.delete'),
                                                                          onPressed: () async {
                                                                            // ── Normal delete confirm ──────────────────────────────
                                                                            final confirmDelete =
                                                                                await showDialog<bool>(
                                                                              context: context,
                                                                              builder: (confirmContext) {
                                                                                return AlertDialog(
                                                                                  title: Row(
                                                                                    children: [
                                                                                      Icon(Icons.warning_amber_rounded,
                                                                                          color: Colors.red),
                                                                                      SizedBox(width: 8.0),
                                                                                      Text(context.tr('collection.delete.title')),
                                                                                    ],
                                                                                  ),
                                                                                  content: Column(
                                                                                    mainAxisSize: MainAxisSize.min,
                                                                                    crossAxisAlignment:
                                                                                        CrossAxisAlignment.start,
                                                                                    children: [
                                                                                      Text(
                                                                                        context.tr(
                                                                                          'collection.delete.confirm',
                                                                                          params: {'name': categoryName},
                                                                                        ),
                                                                                      ),
                                                                                      SizedBox(height: 12.0),
                                                                                      Row(
                                                                                        children: [
                                                                                          Icon(
                                                                                              Icons.info_outline,
                                                                                              size: 14,
                                                                                              color: Colors.red),
                                                                                          SizedBox(width: 4.0),
                                                                                          Text(
                                                                                            context.tr('collection.delete.undo_warning'),
                                                                                            style: TextStyle(
                                                                                              color: Colors.red,
                                                                                              fontSize: 12,
                                                                                              fontWeight:
                                                                                                  FontWeight.w600,
                                                                                            ),
                                                                                          ),
                                                                                        ],
                                                                                      ),
                                                                                    ],
                                                                                  ),
                                                                                  actions: [
                                                                                    TextButton(
                                                                                      onPressed: () =>
                                                                                          Navigator.pop(
                                                                                              confirmContext, false),
                                                                                      child: Text(context.tr('common.cancel')),
                                                                                    ),
                                                                                    ElevatedButton(
                                                                                      onPressed: () =>
                                                                                          Navigator.pop(
                                                                                              confirmContext, true),
                                                                                      style:
                                                                                          ElevatedButton.styleFrom(
                                                                                        backgroundColor: Colors.red,
                                                                                      ),
                                                                                      child: Text(context.tr('common.delete'),
                                                                                          style: TextStyle(
                                                                                              color: Colors.white)),
                                                                                    ),
                                                                                  ],
                                                                                );
                                                                              },
                                                                            );

                                                                            if (confirmDelete != true) return;

                                                                            // ── Call normal delete ─────────────────────────────────
                                                                            showDialog(
                                                                              context: context,
                                                                              barrierDismissible: false,
                                                                              builder: (_) => const Center(
                                                                                  child:
                                                                                      CircularProgressIndicator()),
                                                                            );

                                                                            final deleteResponse =
                                                                                await CategoryService()
                                                                                    .deleteCategory(categoryId);

                                                                            if (context.mounted)
                                                                              Navigator.pop(context); // close loader

                                                                            if (deleteResponse.succeeded) {
                                                                              if (context.mounted)
                                                                                ScaffoldMessenger.of(context)
                                                                                    .showSnackBar(SnackBar(
                                                                                  content:
                                                                                      Text(context.tr('collection.delete.deleted_success')),
                                                                                  backgroundColor:
                                                                                      Color(0xFF4CAF50),
                                                                                ));
                                                                              setDialogState(() {});
                                                                              return;
                                                                            }

                                                                            // ── Handle 409 – category has cameras ─────────────────
                                                                            // Check both HTTP status AND JSON body (web CORS can alter the HTTP layer)
                                                                            final bool _isConflict =
                                                                                deleteResponse.statusCode == 409 ||
                                                                                    getJsonField(deleteResponse.jsonBody,
                                                                                            r'$.status') ==
                                                                                        409;
                                                                            if (_isConflict) {
                                                                              if (!context.mounted) return;
                                                                              final forceConfirm =
                                                                                  await showDialog<bool>(
                                                                                context: context,
                                                                                builder: (forceContext) {
                                                                                  return AlertDialog(
                                                                                    title: Row(
                                                                                      children: [
                                                                                        Icon(
                                                                                            Icons
                                                                                                .warning_amber_rounded,
                                                                                            color: Colors.orange),
                                                                                        SizedBox(width: 8.0),
                                                                                        Text(context.tr('collection.delete.in_use_title')),
                                                                                      ],
                                                                                    ),
                                                                                    content: Column(
                                                                                      mainAxisSize: MainAxisSize.min,
                                                                                      crossAxisAlignment:
                                                                                          CrossAxisAlignment.start,
                                                                                      children: [
                                                                                        Text(
                                                                                          context.tr(
                                                                                            'collection.delete.in_use_message',
                                                                                            params: {'name': categoryName},
                                                                                          ),
                                                                                        ),
                                                                                        SizedBox(height: 8.0),
                                                                                        Text(
                                                                                          context.tr('collection.delete.force_delete_message'),
                                                                                          style: TextStyle(
                                                                                              color:
                                                                                                  Color(0xFF6B7280)),
                                                                                        ),
                                                                                        SizedBox(height: 12.0),
                                                                                        Row(
                                                                                          children: [
                                                                                            Icon(
                                                                                                Icons.info_outline,
                                                                                                size: 14,
                                                                                                color: Colors.red),
                                                                                            SizedBox(width: 4.0),
                                                                                            Text(
                                                                                              context.tr('collection.delete.undo_warning'),
                                                                                              style: TextStyle(
                                                                                                color: Colors.red,
                                                                                                fontSize: 12,
                                                                                                fontWeight:
                                                                                                    FontWeight.w600,
                                                                                              ),
                                                                                            ),
                                                                                          ],
                                                                                        ),
                                                                                      ],
                                                                                    ),
                                                                                    actions: [
                                                                                      TextButton(
                                                                                        onPressed: () =>
                                                                                            Navigator.pop(
                                                                                                forceContext, false),
                                                                                        child: Text(context.tr('common.cancel')),
                                                                                      ),
                                                                                      ElevatedButton(
                                                                                        onPressed: () =>
                                                                                            Navigator.pop(
                                                                                                forceContext, true),
                                                                                        style: ElevatedButton
                                                                                            .styleFrom(
                                                                                          backgroundColor:
                                                                                              Color(0xFFEF4444),
                                                                                        ),
                                                                                        child: Text(
                                                                                            context.tr('collection.delete.force_delete'),
                                                                                            style: TextStyle(
                                                                                                color: Colors.white)),
                                                                                      ),
                                                                                    ],
                                                                                  );
                                                                                },
                                                                              );

                                                                              if (forceConfirm != true) return;

                                                                              // ── Call force delete ─────────────────────────────
                                                                              if (!context.mounted) return;
                                                                              showDialog(
                                                                                context: context,
                                                                                barrierDismissible: false,
                                                                                builder: (_) => const Center(
                                                                                    child:
                                                                                        CircularProgressIndicator()),
                                                                              );

                                                                              final forceResponse =
                                                                                  await CategoryService()
                                                                                      .deleteCategory(categoryId,
                                                                                          force: true);

                                                                              if (context.mounted)
                                                                                Navigator.pop(
                                                                                    context); // close loader

                                                                              if (context.mounted)
                                                                                ScaffoldMessenger.of(context)
                                                                                    .showSnackBar(SnackBar(
                                                                                  content: Text(
                                                                                    forceResponse.succeeded
                                                                                        ? context.tr('collection.delete.force_deleted_success')
                                                                                        : context.tr('collection.delete.force_delete_failed'),
                                                                                  ),
                                                                                  backgroundColor: forceResponse
                                                                                          .succeeded
                                                                                      ? Color(0xFF4CAF50)
                                                                                      : Colors.red,
                                                                                ));

                                                                              if (forceResponse.succeeded)
                                                                                setDialogState(() {});
                                                                            } else {
                                                                              // ── Other errors ──────────────────────────────────
                                                                              if (context.mounted)
                                                                                ScaffoldMessenger.of(context)
                                                                                    .showSnackBar(SnackBar(
                                                                                  content: Text(
                                                                                    context.tr(
                                                                                      'collection.delete.delete_failed',
                                                                                      params: {
                                                                                        'statusCode': '${deleteResponse.statusCode}'
                                                                                      },
                                                                                    ),
                                                                                  ),
                                                                                  backgroundColor: Colors.red,
                                                                                ));
                                                                            }
                                                                          },
                                                                        ),
                                                                      ],
                                                                    ),
                                                                  ),
                                                                  if (isExpanded)
                                                                    Container(
                                                                      padding: EdgeInsets.all(12.0),
                                                                      color: Colors.grey[50],
                                                                      child: Builder(
                                                                        builder: (context) {
                                                                          // Filter cameras that belong to this category
                                                                          final cameras = allCameras.where((camera) {
                                                                            final cameraCategories = getJsonField(
                                                                              camera,
                                                                              r'$.categories',
                                                                            );
                                                                            if (cameraCategories == null) return false;
                                                                            
                                                                            // Check if this category ID is in the camera's categories
                                                                            final categoriesList = cameraCategories is List 
                                                                                ? cameraCategories 
                                                                                : [cameraCategories];
                                                                            
                                                                            return categoriesList.any((cat) => 
                                                                              getJsonField(cat, r'$.id').toString() == categoryId
                                                                            );
                                                                          }).toList();
                                                                          
                                                                          return Column(
                                                                            crossAxisAlignment:
                                                                                CrossAxisAlignment.start,
                                                                            children: [
                                                                              Row(
                                                                                mainAxisAlignment:
                                                                                    MainAxisAlignment.spaceBetween,
                                                                                children: [
                                                                                  Text(
                                                                                    context.tr(
                                                                                      'collection.cameras_count',
                                                                                      params: {'count': '${cameras.length}'},
                                                                                    ),
                                                                                    style: FlutterFlowTheme.of(
                                                                                            context)
                                                                                        .labelLarge
                                                                                        .override(
                                                                                          fontFamily: 'Readex Pro',
                                                                                          fontWeight:
                                                                                              FontWeight.w600,
                                                                                        ),
                                                                                  ),
                                                                                  ElevatedButton.icon(
                                                                                    onPressed: () async {
                                                                                      // Filter out cameras already in this category
                                                                                      final currentCameraIds =
                                                                                          cameras
                                                                                              .map((c) =>
                                                                                                  getJsonField(
                                                                                                      c, r'$.id')
                                                                                                  .toString())
                                                                                              .toSet();
                                                                                      final availableCameras =
                                                                                          allCameras
                                                                                              .where((c) =>
                                                                                                  !currentCameraIds
                                                                                                      .contains(getJsonField(
                                                                                                              c,
                                                                                                              r'$.id')
                                                                                                          .toString()))
                                                                                              .toList();
                                                                                      
                                                                                      if (availableCameras.isEmpty) {
                                                                                        ScaffoldMessenger.of(context)
                                                                                            .showSnackBar(
                                                                                          SnackBar(
                                                                                            content: Text(
                                                                                              context.tr('collection.all_cameras_in_category'),
                                                                                            ),
                                                                                            backgroundColor:
                                                                                                Color(0xFFFFA726),
                                                                                          ),
                                                                                        );
                                                                                        return;
                                                                                      }
                                                                                      
                                                                                      await showDialog(
                                                                                        context: context,
                                                                                        builder: (addContext) {
                                                                                          return StatefulBuilder(
                                                                                            builder: (context, setSearchState) {
                                                                                              final searchController = TextEditingController();
                                                                                              
                                                                                              final filteredCameras = availableCameras.where((camera) {
                                                                                                final cameraName = getJsonField(camera, r'$.name').toString().toLowerCase();
                                                                                                return cameraName.contains(searchController.text.toLowerCase());
                                                                                              }).toList();
                                                                                              
                                                                                              return AlertDialog(
                                                                                                title: Text('เพิ่มกล้องไปยัง "$categoryName"'),
                                                                                                content: Container(
                                                                                                  width: 500,
                                                                                                  height: 400,
                                                                                                  child: Column(
                                                                                                    children: [
                                                                                                      // Search field
                                                                                                      TextField(
                                                                                                        controller: searchController,
                                                                                                        decoration: InputDecoration(
                                                                                                          prefixIcon: Icon(Icons.search),
                                                                                                          hintText: 'ค้นหากล้อง...',
                                                                                                          border: OutlineInputBorder(
                                                                                                            borderRadius: BorderRadius.circular(8),
                                                                                                          ),
                                                                                                          contentPadding: EdgeInsets.symmetric(
                                                                                                            horizontal: 12,
                                                                                                            vertical: 8,
                                                                                                          ),
                                                                                                        ),
                                                                                                        onChanged: (value) {
                                                                                                          setSearchState(() {});
                                                                                                        },
                                                                                                      ),
                                                                                                      SizedBox(height: 16),
                                                                                                      // Results count
                                                                                                      Align(
                                                                                                        alignment: Alignment.centerLeft,
                                                                                                        child: Text(
                                                                                                          '${filteredCameras.length} กล้องที่พร้อมใช้งาน',
                                                                                                          style: TextStyle(
                                                                                                            fontSize: AppTextStyles.commandBody,
                                                                                                            color: Colors.grey[600],
                                                                                                          ),
                                                                                                        ),
                                                                                                      ),
                                                                                                      SizedBox(height: 8),
                                                                                                      Divider(height: 1),
                                                                                                      SizedBox(height: 8),
                                                                                                      // Camera list
                                                                                                      Expanded(
                                                                                                        child: filteredCameras.isEmpty
                                                                                                          ? Center(
                                                                                                              child: Text(
                                                                                                                'ไม่พบกล้อง',
                                                                                                                style: TextStyle(color: Colors.grey),
                                                                                                              ),
                                                                                                            )
                                                                                                          : ListView.builder(
                                                                                                              itemCount: filteredCameras.length,
                                                                                                              itemBuilder: (context, idx) {
                                                                                                                final camera = filteredCameras[idx];
                                                                                                                final cameraId = getJsonField(camera, r'$.id').toString();
                                                                                                                final cameraName = getJsonField(camera, r'$.name').toString();
                                                                                                                
                                                                                                                return ListTile(
                                                                                                                  leading: Icon(
                                                                                                                    Icons.videocam,
                                                                                                                    color: Color(0xFF39D2C0),
                                                                                                                  ),
                                                                                                                  title: Text(cameraName),
                                                                                                                  trailing: IconButton(
                                                                                                                    icon: Icon(
                                                                                                                      Icons.add_circle,
                                                                                                                      color: Color(0xFF4B39EF),
                                                                                                                    ),
                                                                                                                    onPressed: () async {
                                                                                                        // Close the selection dialog first
                                                                                                        Navigator.of(addContext).pop();
                                                                                                        
                                                                                                        // Capture navigator and scaffold messenger before async
                                                                                                        final navigator = Navigator.of(context, rootNavigator: true);
                                                                                                        final scaffoldMessenger = ScaffoldMessenger.of(context);
                                                                                                        
                                                                                                        // Show loading
                                                                                                        bool isLoadingShown = false;
                                                                                                        try {
                                                                                                          showDialog(
                                                                                                            context: context,
                                                                                                            barrierDismissible: false,
                                                                                                            builder: (loadingContext) {
                                                                                                              isLoadingShown = true;
                                                                                                              return WillPopScope(
                                                                                                                onWillPop: () async => false,
                                                                                                                child: Center(
                                                                                                                  child: CircularProgressIndicator(),
                                                                                                                ),
                                                                                                              );
                                                                                                            },
                                                                                                          );
                                                                                                          
                                                                                                          final addResponse = await CameraService()
                                                                                                              .addCategoryToCamera(
                                                                                                            categoryId: categoryId,
                                                                                                            cameraId: cameraId,
                                                                                                          );
                                                                                                          
                                                                                                          // Close loading if still mounted
                                                                                                          if (isLoadingShown) {
                                                                                                            try {
                                                                                                              if (navigator.canPop()) navigator.pop();
                                                                                                            } catch (_) {}
                                                                                                          }
                                                                                                          
                                                                                                          // Show result if still mounted
                                                                                                          if (!mounted) return;
                                                                                                          
                                                                                                          if (addResponse.succeeded) {
                                                                                                            scaffoldMessenger.showSnackBar(
                                                                                                              SnackBar(
                                                                                                                content: Text('เพิ่มกล้องสำเร็จ'),
                                                                                                                backgroundColor: Color(0xFF4CAF50),
                                                                                                              ),
                                                                                                            );
                                                                                                            setDialogState(() {});
                                                                                                            Future.delayed(Duration(milliseconds: 100), () {
                                                                                                              if (mounted) safeSetState(() {});
                                                                                                            });
                                                                                                          } else {
                                                                                                            scaffoldMessenger.showSnackBar(
                                                                                                              SnackBar(
                                                                                                                content: Text('เพิ่มกล้องไม่สำเร็จ'),
                                                                                                                backgroundColor: Colors.red,
                                                                                                              ),
                                                                                                            );
                                                                                                          }
                                                                                                        } catch (e) {
                                                                                                          // Ensure loading closes
                                                                                                          if (isLoadingShown) {
                                                                                                            try {
                                                                                                              if (navigator.canPop()) navigator.pop();
                                                                                                            } catch (_) {}
                                                                                                          }
                                                                                                          if (mounted) {
                                                                                                            scaffoldMessenger.showSnackBar(
                                                                                                              SnackBar(
                                                                                                                content: Text('ข้อผิดพลาด: ${e.toString()}'),
                                                                                                                backgroundColor: Colors.red,
                                                                                                              ),
                                                                                                            );
                                                                                                          }
                                                                                                        }
                                                                                                      },
                                                                                                    ),
                                                                                                  );
                                                                                                },
                                                                                              ),
                                                                                      ),
                                                                                    ],
                                                                                  ),
                                                                                ),
                                                                                actions: [
                                                                                  TextButton(
                                                                                    onPressed: () => Navigator.pop(addContext),
                                                                                    child: Text('ปิด'),
                                                                                  ),
                                                                                ],
                                                                              );
                                                                            },
                                                                          );
                                                                        },
                                                                      );
                                                                                    },
                                                                                    icon: Icon(Icons.add,
                                                                                        size: 16.0),
                                                                                    label: Text('เพิ่มกล้อง'),
                                                                                    style: ElevatedButton.styleFrom(
                                                                                      backgroundColor:
                                                                                          Color(0xFF39D2C0),
                                                                                      foregroundColor: Colors.white,
                                                                                      padding: EdgeInsets.symmetric(
                                                                                          horizontal: 12.0,
                                                                                          vertical: 8.0),
                                                                                    ),
                                                                                  ),
                                                                                ],
                                                                              ),
                                                                              SizedBox(height: 8.0),
                                                                              if (cameras.isEmpty)
                                                                                Padding(
                                                                                  padding: EdgeInsets.all(16.0),
                                                                                  child: Center(
                                                                                    child: Text(
                                                                                      'ไม่มีรายการกล้องในหมวดหมู่นี้',
                                                                                      style: FlutterFlowTheme.of(
                                                                                              context)
                                                                                          .bodySmall
                                                                                          .override(
                                                                                            fontFamily:
                                                                                                'Readex Pro',
                                                                                            fontStyle:
                                                                                                FontStyle.italic,
                                                                                          ),
                                                                                    ),
                                                                                  ),
                                                                                )
                                                                              else
                                                                                ...cameras.map((camera) {
                                                                                  final cameraId = getJsonField(
                                                                                          camera, r'$.id')
                                                                                      .toString();
                                                                                  final cameraName =
                                                                                      getJsonField(camera,
                                                                                              r'$.name')
                                                                                          .toString();
                                                                                  
                                                                                  return ListTile(
                                                                                    dense: true,
                                                                                    leading: Icon(
                                                                                        Icons.videocam,
                                                                                        color:
                                                                                            Color(0xFF39D2C0),
                                                                                        size: 20.0),
                                                                                    title: Text(
                                                                                      cameraName,
                                                                                      style:
                                                                                          FlutterFlowTheme.of(
                                                                                                  context)
                                                                                              .bodyMedium,
                                                                                    ),
                                                                                    trailing: IconButton(
                                                                                      icon: Icon(
                                                                                        Icons.remove_circle,
                                                                                        color: Colors.red,
                                                                                        size: 20.0,
                                                                                      ),
                                                                                        tooltip: 'ลบออก',
                                                                                      onPressed: () async {
                                                                                        final confirmRemove =
                                                                                            await showDialog<
                                                                                                bool>(
                                                                                          context: context,
                                                                                          builder:
                                                                                              (confirmContext) {
                                                                                            return AlertDialog(
                                                                                              title: Text(
                                                                                              'ลบกล้อง'),
                                                                                              content: Text(
                                                                                              'ต้องการลบ "$cameraName" ออกจาก "$categoryName" หรือไม่?'),
                                                                                              actions: [
                                                                                                TextButton(
                                                                                                  onPressed: () =>
                                                                                                      Navigator.pop(
                                                                                                          confirmContext,
                                                                                                          false),
                                                                                                  child: Text(
                                                                                                'ยกเลิก'),
                                                                                                ),
                                                                                                ElevatedButton(
                                                                                                  onPressed: () =>
                                                                                                      Navigator.pop(
                                                                                                          confirmContext,
                                                                                                          true),
                                                                                                  style: ElevatedButton
                                                                                                      .styleFrom(
                                                                                                    backgroundColor:
                                                                                                        Colors
                                                                                                            .red,
                                                                                                  ),
                                                                                                  child: Text(
                                                                                                'ลบออก',
                                                                                                      style: TextStyle(
                                                                                                          color: Colors
                                                                                                              .white)),
                                                                                                ),
                                                                                              ],
                                                                                            );
                                                                                          },
                                                                                        );
                                                                                        
                                                                                        if (confirmRemove == true) {
                                                                                          // Capture navigator and scaffold messenger before async
                                                                                          final navigator = Navigator.of(context, rootNavigator: true);
                                                                                          final scaffoldMessenger = ScaffoldMessenger.of(context);
                                                                                          
                                                                                          // Show loading
                                                                                          bool isLoadingShown = false;
                                                                                          try {
                                                                                            showDialog(
                                                                                              context: context,
                                                                                              barrierDismissible: false,
                                                                                              builder: (loadingContext) {
                                                                                                isLoadingShown = true;
                                                                                                return WillPopScope(
                                                                                                  onWillPop: () async => false,
                                                                                                  child: Center(
                                                                                                    child: CircularProgressIndicator(),
                                                                                                  ),
                                                                                                );
                                                                                              },
                                                                                            );
                                                                                            
                                                                                            final removeResponse =
                                                                                                await CameraService()
                                                                                                    .deleteCategoryFromCamera(
                                                                                              categoryId: categoryId,
                                                                                              cameraId: cameraId,
                                                                                            );
                                                                                            
                                                                                            // Close loading if still mounted
                                                                                            if (isLoadingShown) {
                                                                                              try {
                                                                                                if (navigator.canPop()) navigator.pop();
                                                                                              } catch (_) {}
                                                                                            }
                                                                                            
                                                                                            // Show result if still mounted
                                                                                            if (!mounted) return;
                                                                                            
                                                                                            if (removeResponse.succeeded) {
                                                                                              scaffoldMessenger.showSnackBar(
                                                                                                SnackBar(
                                                                                                  content: Text('ลบกล้องสำเร็จ'),
                                                                                                  backgroundColor: Color(0xFF4CAF50),
                                                                                                ),
                                                                                              );
                                                                                              setDialogState(() {});
                                                                                              Future.delayed(Duration(milliseconds: 100), () {
                                                                                                if (mounted) safeSetState(() {});
                                                                                              });
                                                                                            } else {
                                                                                              scaffoldMessenger.showSnackBar(
                                                                                                SnackBar(
                                                                                                  content: Text('ลบกล้องไม่สำเร็จ'),
                                                                                                  backgroundColor: Colors.red,
                                                                                                ),
                                                                                              );
                                                                                            }
                                                                                          } catch (e) {
                                                                                            // Ensure loading closes
                                                                                            if (isLoadingShown) {
                                                                                              try {
                                                                                                if (navigator.canPop()) navigator.pop();
                                                                                              } catch (_) {}
                                                                                            }
                                                                                            if (mounted) {
                                                                                              scaffoldMessenger.showSnackBar(
                                                                                                SnackBar(
                                                                                                  content: Text('ข้อผิดพลาด: ${e.toString()}'),
                                                                                                  backgroundColor: Colors.red,
                                                                                                ),
                                                                                              );
                                                                                            }
                                                                                          }
                                                                                        }
                                                                                      },
                                                                                    ),
                                                                                  );
                                                                                }).toList(),
                                                                            ],
                                                                          );
                                                                        },
                                                                      ),
                                                                    ),
                                                                ],
                                                              ),
                                                            );
                                                          },
                                                        ),
                                                ),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () {
                                                      Navigator.pop(dialogContext);
                                                      safeSetState(() {});
                                                    },
                                                    child: Text('ปิด'),
                                                  ),
                                                ],
                                              );
                                                },
                                              );
                                            },
                                          );
                                        },
                                      );
                                    },
                                  );
                                  // Re-fetch table after dialog closes to reflect any category changes
                                  if (mounted) {
                                    _fetchCameras(
                                      page: _model.currentPage,
                                      search: _model.searchQuery,
                                    );
                                  }
                                },
                                text: 'จัดการหมวดหมู่',
                                icon: Icon(
                                  Icons.settings,
                                  size: 22.0,
                                  color: Colors.white,
                                ),
                                options: FFButtonOptions(
                                  height: 50.0,
                                  padding: EdgeInsetsDirectional.fromSTEB(
                                      20.0, 0.0, 20.0, 0.0),
                                  iconPadding: EdgeInsetsDirectional.fromSTEB(
                                      0.0, 0.0, 0.0, 0.0),
                                  color: Color(0xFF10B981),
                                  textStyle: FlutterFlowTheme.of(context)
                                      .titleSmall
                                      .override(
                                        fontFamily: FlutterFlowTheme.of(context)
                                            .titleSmallFamily,
                                        color: Colors.white,
                                        letterSpacing: 0.0,
                                        useGoogleFonts:
                                            !FlutterFlowTheme.of(context)
                                                .titleSmallIsCustom,
                                      ),
                                  elevation: 0.0,
                                  borderSide: BorderSide(
                                    color: Color(0xFF10B981),
                                  ),
                                  borderRadius: BorderRadius.circular(10.0),
                                  hoverColor: Color(0xFF059669),
                                  hoverBorderSide: BorderSide(
                                    color: Color(0xFF10B981),
                                  ),
                                  hoverTextColor: Colors.white,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Table area
                        Expanded(
                          child: Builder(
                          builder: (context) {
                                    if (_model.isLoading) {
                                      return Center(
                                          child: CircularProgressIndicator(
                                            valueColor: AlwaysStoppedAnimation<Color>(
                                              FlutterFlowTheme.of(context).primary,
                                            ),
                                          ),
                                      );
                                    }
                                    // Start with paginated camera list
                                    var cameraItems = _model.listOfCameras;
                                        
                                        if (cameraItems.isEmpty) {
                                          return Center(
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  Icons.search_off_rounded,
                                                  size: 80.0,
                                                  color: FlutterFlowTheme.of(
                                                          context)
                                                      .secondaryText,
                                                ),
                                                SizedBox(height: 16.0),
                                                Text(
                                                  _model.textController.text.isNotEmpty
                                                      ? 'ไม่พบกล้องที่ตรงกับ "${_model.textController.text}"'
                                                      : 'ไม่มีกล้องที่ใช้งานได้',
                                                  style: FlutterFlowTheme.of(context).titleMedium,
                                                  textAlign: TextAlign.center,
                                                ),
                                              ],
                                            ),
                                          );
                                        }

                                        return FlutterFlowDataTable<dynamic>(
                                              controller: _model
                                                  .paginatedDataTableController,
                                              data: cameraItems,
                                              columnsBuilder: (onSortChanged) =>
                                                  [
                                                DataColumn2(
                                                  size: ColumnSize.L,
                                                  label: DefaultTextStyle.merge(
                                                    softWrap: true,
                                                    child: Text(
                                                      'ชื่อ',
                                                      style: FlutterFlowTheme
                                                              .of(context)
                                                          .labelMedium
                                                          .override(
                                                            fontFamily:
                                                                FlutterFlowTheme.of(
                                                                        context)
                                                                    .labelMediumFamily,
                                                            color: Colors.white,
                                                            fontSize: AppTextStyles.tableHeader,
                                                            letterSpacing: 0.0,
                                                            useGoogleFonts:
                                                                !FlutterFlowTheme.of(
                                                                        context)
                                                                    .labelMediumIsCustom,
                                                          ),
                                                    ),
                                                  ),
                                                ),
                                                DataColumn2(
                                                  size: ColumnSize.L,
                                                  label: DefaultTextStyle.merge(
                                                    softWrap: true,
                                                    child: Text(
                                                      'ที่อยู่',
                                                      style: FlutterFlowTheme
                                                              .of(context)
                                                          .labelMedium
                                                          .override(
                                                            fontFamily:
                                                                FlutterFlowTheme.of(
                                                                        context)
                                                                    .labelMediumFamily,
                                                            color: Colors.white,
                                                            fontSize: AppTextStyles.tableHeader,
                                                            letterSpacing: 0.0,
                                                            useGoogleFonts:
                                                                !FlutterFlowTheme.of(
                                                                        context)
                                                                    .labelMediumIsCustom,
                                                          ),
                                                    ),
                                                  ),
                                                ),
                                                DataColumn2(
                                                  size: ColumnSize.S,
                                                  label: DefaultTextStyle.merge(
                                                    softWrap: true,
                                                    child: Text(
                                                      'Status',
                                                      style: FlutterFlowTheme
                                                              .of(context)
                                                          .labelMedium
                                                          .override(
                                                            fontFamily:
                                                                FlutterFlowTheme.of(
                                                                        context)
                                                                    .labelMediumFamily,
                                                            color: Colors.white,
                                                            fontSize: AppTextStyles.tableHeader,
                                                            letterSpacing: 0.0,
                                                            useGoogleFonts:
                                                                !FlutterFlowTheme.of(
                                                                        context)
                                                                    .labelMediumIsCustom,
                                                          ),
                                                    ),
                                                  ),
                                                ),
                                                DataColumn2(
                                                  size: ColumnSize.L,
                                                  label: DefaultTextStyle.merge(
                                                    softWrap: true,
                                                    child: Text(
                                                      'Categories',
                                                      style: FlutterFlowTheme
                                                              .of(context)
                                                          .labelMedium
                                                          .override(
                                                            fontFamily:
                                                                FlutterFlowTheme.of(
                                                                        context)
                                                                    .labelMediumFamily,
                                                            color: Colors.white,
                                                            fontSize: AppTextStyles.tableHeader,
                                                            letterSpacing: 0.0,
                                                            useGoogleFonts:
                                                                !FlutterFlowTheme.of(
                                                                        context)
                                                                    .labelMediumIsCustom,
                                                          ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                              dataRowBuilder: (cameraItemsItem,
                                                      cameraItemsIndex,
                                                      selected,
                                                      onSelectChanged) =>
                                                  DataRow(
                                                color:
                                                    MaterialStateProperty.all(
                                                  cameraItemsIndex % 2 == 0
                                                      ? FlutterFlowTheme.of(
                                                              context)
                                                          .secondaryBackground
                                                      : FlutterFlowTheme.of(
                                                              context)
                                                          .primaryBackground,
                                                ),
                                                cells: [
                                                  Text(
                                                        getJsonField(
                                                          cameraItemsItem,
                                                          r'''$.name''',
                                                        ).toString(),
                                                        style: FlutterFlowTheme
                                                                .of(context)
                                                            .bodySmall
                                                            .override(
                                                              fontFamily:
                                                                  FlutterFlowTheme.of(
                                                                          context)
                                                                      .bodySmallFamily,
                                                              fontSize: AppTextStyles.tableCell,
                                                              letterSpacing:
                                                                  0.0,
                                                              useGoogleFonts:
                                                                  !FlutterFlowTheme.of(
                                                                          context)
                                                                      .bodySmallIsCustom,
                                                            ),
                                                      ),
                                                  Text(
                                                    getJsonField(
                                                      cameraItemsItem,
                                                      r'''$.address''',
                                                    ).toString(),
                                                    style: FlutterFlowTheme.of(
                                                            context)
                                                        .bodySmall
                                                        .override(
                                                          fontFamily:
                                                              FlutterFlowTheme.of(
                                                                      context)
                                                                  .bodySmallFamily,
                                                          fontSize: AppTextStyles.tableCell,
                                                          letterSpacing: 0.0,
                                                          useGoogleFonts:
                                                              !FlutterFlowTheme
                                                                      .of(context)
                                                                  .bodySmallIsCustom,
                                                        ),
                                                  ),
                                                  _buildStatusBadge(
                                                    getJsonField(
                                                      cameraItemsItem,
                                                      r'''$.status''',
                                                    ).toString(),
                                                  ),
                                                  _buildCategoryChips(cameraItemsItem),
                                                ]
                                                    .map((c) => DataCell(c))
                                                    .toList(),
                                              ),
                                              emptyBuilder: () => Center(
                                                child: Image.asset(
                                                  'assets/images/Screenshot_2024_1228_145217.png',
                                                  fit: BoxFit.contain,
                                                ),
                                              ),
                                              paginated: false,
                                              selectable: false,
                                              hidePaginator: true,
                                              headingRowHeight: 44.0,
                                              dataRowHeight: 48.0,
                                              columnSpacing: 16.0,
                                              headingRowColor:
                                                  FlutterFlowTheme.of(context)
                                                      .primary,
                                              borderRadius:
                                                  BorderRadius.circular(12.0),
                                              addHorizontalDivider: true,
                                              addTopAndBottomDivider: false,
                                              hideDefaultHorizontalDivider:
                                                  true,
                                              horizontalDividerColor:
                                                  FlutterFlowTheme.of(context)
                                                      .secondaryBackground,
                                              horizontalDividerThickness: 1.0,
                                              addVerticalDivider: false,
                                            );
                                    },
                                  ),
                                ),
                                const SizedBox(height: 20),
                        // Pagination controls
                        if (!_model.isLoading)
                          Column(
                            children: [
                              const Divider(height: 1, color: Color(0xFFE5E7EB)),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Page ${_model.currentPage} of ${_model.totalPages}  '
                                    '(Total ${_model.totalCameras} items)',
                                    style: const TextStyle(
                                      color: Color(0xFF6B7280),
                                      fontSize: 13,
                                    ),
                                  ),
                                  _buildPagination(context),
                                ],
                              ),
                            ],
                          ),
                            ],
                          ),
                        ),
                      ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Immutable color pair used for category chips.
class _ChipColor {
  final Color bg;
  final Color text;
  const _ChipColor({required this.bg, required this.text});
}
