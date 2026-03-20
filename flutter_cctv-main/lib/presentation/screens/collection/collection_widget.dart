import '/data/services/index.dart';
import '/presentation/widgets/nav_bar_main_widget.dart';
import '/utils/flutter_flow_data_table.dart';
import '/utils/flutter_flow_theme.dart';
import '/utils/flutter_flow_util.dart';
import 'package:easy_debounce/easy_debounce.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'widgets/collection_toolbar.dart';
import 'widgets/collection_table_cells.dart';
import 'widgets/collection_pagination.dart';
import 'widgets/manage_categories_dialog.dart';
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

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => CollectionModel());
    _model.textController ??= TextEditingController();
    _model.textFieldFocusNode ??= FocusNode();
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

  Future<void> _fetchCameras({required int page, String search = ''}) async {
    if (!mounted) return;
    safeSetState(() => _model.isLoading = true);

    try {
      final response = await CameraService().getCameras(
        page: page.toString(),
        limit: CollectionModel.pageSize.toString(),
        search: search.isNotEmpty ? search : null,
      );

      if (!mounted) return;

      if (response.succeeded) {
        final dataList = CameraService().parseDataList(response.jsonBody) ?? [];
        final meta = getJsonField(response.jsonBody, r'$.meta');
        safeSetState(() {
          _model.listOfCameras = dataList;
          _model.currentPage = page;
          _model.searchQuery = search;
          _model.isLoading = false;
          if (meta is Map<String, dynamic>) {
            _model.totalCameras =
                (meta['totalItems'] as int?) ?? dataList.length;
            _model.totalPages = (meta['totalPages'] as int?) ?? 1;
          } else {
            _model.totalCameras = dataList.length;
            _model.totalPages = 1;
          }
        });
      } else {
        debugPrint('API error: ${response.statusCode}');
        safeSetState(() {
          _model.listOfCameras = [];
          _model.currentPage = page;
          _model.searchQuery = search;
          _model.isLoading = false;
        });
      }

      _model.paginatedDataTableController.paginatorController.goToFirstPage();
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

  void _onRefresh() {
    safeSetState(() {
      _model.textController?.clear();
      _model.searchQuery = '';
    });
    _fetchCameras(page: 1, search: '');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(children: [
          Icon(Icons.refresh_rounded, color: Colors.white),
          SizedBox(width: 8),
          Text('Search cleared, showing all cameras'),
        ]),
        duration: const Duration(milliseconds: 2000),
        backgroundColor: const Color(0xFF6C757D),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _onManageCategories() async {
    await showDialog(
      context: context,
      builder: (_) => const ManageCategoriesDialog(),
    );
    if (mounted) {
      _fetchCameras(
          page: _model.currentPage, search: _model.searchQuery);
    }
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

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
          physics: const NeverScrollableScrollPhysics(),
          headerSliverBuilder: (context, _) => [
            SliverAppBar(
              pinned: true,
              floating: true,
              toolbarHeight: AppTextStyles.navBarHeight,
              backgroundColor: const Color(0xFFF3F4F6),
              iconTheme: const IconThemeData(color: Color(0xFFD6C6C6)),
              automaticallyImplyLeading: false,
              title: wrapWithModel(
                model: _model.navBarMainModel,
                updateCallback: () => safeSetState(() {}),
                child: NavBarMainWidget(),
              ),
              centerTitle: true,
              elevation: 0,
            ),
          ],
          body: Builder(
            builder: (context) => SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      'Category Management',
                      style: FlutterFlowTheme.of(context)
                          .headlineLarge
                          .override(
                            fontFamily: FlutterFlowTheme.of(context)
                                .headlineLargeFamily,
                            color: const Color(0xFF111827),
                            letterSpacing: 0,
                            useGoogleFonts: !FlutterFlowTheme.of(context)
                                .headlineLargeIsCustom,
                          ),
                    ),
                    const SizedBox(height: 20),

                    // Main card
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
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // ── Toolbar ──────────────────────────
                              CollectionToolbar(
                                textController: _model.textController,
                                focusNode: _model.textFieldFocusNode,
                                onSearchChanged: (v) {
                                  safeSetState(
                                      () => _model.searchQuery = v);
                                  _onSearchChanged(v);
                                },
                                onClearSearch: () {
                                  _model.textController?.clear();
                                  safeSetState(
                                      () => _model.searchQuery = '');
                                  _fetchCameras(page: 1, search: '');
                                },
                                onRefresh: _onRefresh,
                                onManageCategories: _onManageCategories,
                              ),
                              const SizedBox(height: 16),

                              // ── Table ─────────────────────────────
                              Expanded(child: _buildTableArea(context)),
                              const SizedBox(height: 20),

                              // ── Pagination ────────────────────────
                              if (!_model.isLoading) ...[
                                const Divider(
                                    height: 1,
                                    color: Color(0xFFE5E7EB)),
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
                                          fontSize: 13),
                                    ),
                                    CollectionPagination(
                                      currentPage: _model.currentPage,
                                      totalPages: _model.totalPages,
                                      onPageChanged: (p) => _fetchCameras(
                                          page: p,
                                          search: _model.searchQuery),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Table area
  // ---------------------------------------------------------------------------

  Widget _buildTableArea(BuildContext context) {
    if (_model.isLoading) {
      return Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(
              FlutterFlowTheme.of(context).primary),
        ),
      );
    }

    if (_model.listOfCameras.isEmpty) {
      return CollectionEmptyState(
          searchText: _model.textController?.text ?? '');
    }

    return FlutterFlowDataTable<dynamic>(
      controller: _model.paginatedDataTableController,
      data: _model.listOfCameras,
      columnsBuilder: (onSortChanged) => [
        _headerCol(context, 'Name', ColumnSize.L),
        _headerCol(context, 'Address', ColumnSize.L),
        _headerCol(context, 'Status', ColumnSize.S),
        _headerCol(context, 'Categories', ColumnSize.L),
      ],
      dataRowBuilder: (item, idx, selected, onSelectChanged) => DataRow(
        color: MaterialStateProperty.all(
          idx % 2 == 0
              ? FlutterFlowTheme.of(context).secondaryBackground
              : FlutterFlowTheme.of(context).primaryBackground,
        ),
        cells: [
          Text(getJsonField(item, r'$.name').toString(),
              style: FlutterFlowTheme.of(context).bodySmall.override(
                    fontFamily:
                        FlutterFlowTheme.of(context).bodySmallFamily,
                    fontSize: AppTextStyles.tableCell,
                    letterSpacing: 0,
                    useGoogleFonts:
                        !FlutterFlowTheme.of(context).bodySmallIsCustom,
                  )),
          Text(getJsonField(item, r'$.address').toString(),
              style: FlutterFlowTheme.of(context).bodySmall.override(
                    fontFamily:
                        FlutterFlowTheme.of(context).bodySmallFamily,
                    fontSize: AppTextStyles.tableCell,
                    letterSpacing: 0,
                    useGoogleFonts:
                        !FlutterFlowTheme.of(context).bodySmallIsCustom,
                  )),
          StatusBadge(
              status: getJsonField(item, r'$.status').toString()),
          CollectionCategoryChips(item: item),
        ].map((c) => DataCell(c)).toList(),
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
      headingRowColor: FlutterFlowTheme.of(context).primary,
      borderRadius: BorderRadius.circular(12.0),
      addHorizontalDivider: true,
      addTopAndBottomDivider: false,
      hideDefaultHorizontalDivider: true,
      horizontalDividerColor:
          FlutterFlowTheme.of(context).secondaryBackground,
      horizontalDividerThickness: 1.0,
      addVerticalDivider: false,
    );
  }

  DataColumn2 _headerCol(
      BuildContext context, String label, ColumnSize size) {
    return DataColumn2(
      size: size,
      label: DefaultTextStyle.merge(
        softWrap: true,
        child: Text(
          label,
          style: FlutterFlowTheme.of(context).labelMedium.override(
                fontFamily:
                    FlutterFlowTheme.of(context).labelMediumFamily,
                color: Colors.white,
                fontSize: AppTextStyles.tableHeader,
                letterSpacing: 0,
                useGoogleFonts:
                    !FlutterFlowTheme.of(context).labelMediumIsCustom,
              ),
        ),
      ),
    );
  }
}