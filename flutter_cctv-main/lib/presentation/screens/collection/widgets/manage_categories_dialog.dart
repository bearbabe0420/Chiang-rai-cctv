import '/data/services/index.dart';
import '/core/i18n/i18n.dart';
import '/utils/flutter_flow_export.dart';
import 'package:flutter/material.dart';

// =============================================================================
// Color helper
// =============================================================================

class ChipColor {
  final Color bg;
  final Color text;
  const ChipColor({required this.bg, required this.text});
}

const List<ChipColor> chipPalette = [
  ChipColor(bg: Color(0xFFEDE9FE), text: Color(0xFF5B21B6)),
  ChipColor(bg: Color(0xFFDBEAFE), text: Color(0xFF1D4ED8)),
  ChipColor(bg: Color(0xFFD1FAE5), text: Color(0xFF065F46)),
  ChipColor(bg: Color(0xFFFEF3C7), text: Color(0xFF92400E)),
  ChipColor(bg: Color(0xFFFCE7F3), text: Color(0xFF9F1239)),
  ChipColor(bg: Color(0xFFCCFBF1), text: Color(0xFF115E59)),
  ChipColor(bg: Color(0xFFE0E7FF), text: Color(0xFF3730A3)),
  ChipColor(bg: Color(0xFFFFEDD5), text: Color(0xFF9A3412)),
  ChipColor(bg: Color(0xFFF3E8FF), text: Color(0xFF6B21A8)),
  ChipColor(bg: Color(0xFFD1FAE5), text: Color(0xFF047857)),
  ChipColor(bg: Color(0xFFE0F2FE), text: Color(0xFF075985)),
  ChipColor(bg: Color(0xFFFEE2E2), text: Color(0xFFB91C1C)),
];

ChipColor colorForName(String name) {
  final idx =
      name.codeUnits.fold(0, (a, b) => a + b) % chipPalette.length;
  return chipPalette[idx];
}

// =============================================================================
// ManageCategoriesDialog
// =============================================================================

/// Dialog หลัก: รายการ categories + CRUD + expand cameras
class ManageCategoriesDialog extends StatefulWidget {
  const ManageCategoriesDialog({super.key});

  @override
  State<ManageCategoriesDialog> createState() =>
      _ManageCategoriesDialogState();
}

class _ManageCategoriesDialogState extends State<ManageCategoriesDialog> {
  final Map<String, bool> _expanded = {};

  void _refresh() => setState(() {});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ApiCallResponse>(
      future: CategoryService().getCategories(limit: '100'),
      builder: (context, catSnap) {
        if (!catSnap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final categories =
            CategoryService().parseDataList(catSnap.data!.jsonBody) ?? [];

        return FutureBuilder<ApiCallResponse>(
          future: CameraService().getCameras(limit: '100'),
          builder: (context, camSnap) {
            final allCameras = camSnap.hasData
                ? (CameraService().parseDataList(
                        camSnap.data!.jsonBody) ??
                    [])
                : [];

            return AlertDialog(
              title: Row(
                children: [
                  const Icon(Icons.video_library, color: Color(0xFF4B39EF)),
                  const SizedBox(width: 8),
                  Text(context.tr('nav.collection', fallback: 'จัดการหมวดหมู่')),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.add_circle,
                        color: Color(0xFF4B39EF)),
                    tooltip: context.tr('collection.edit.title', fallback: 'สร้างหมวดหมู่ใหม่'),
                    onPressed: () async {
                      await _showCreateDialog(context);
                      _refresh();
                    },
                  ),
                ],
              ),
              content: SizedBox(
                width: 600,
                height: 500,
                child: categories.isEmpty
                    ? _EmptyCategoryState()
                    : ListView.builder(
                        itemCount: categories.length,
                        itemBuilder: (context, index) {
                          final cat = categories[index];
                          final catId =
                              getJsonField(cat, r'$.id').toString();
                          final catName =
                              getJsonField(cat, r'$.name').toString();
                          final color = colorForName(catName);
                          final isExpanded = _expanded[catId] ?? false;

                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            elevation: 2,
                            child: Column(
                              children: [
                                // ── Category header tile ─────────────
                                ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: color.text,
                                    child: const Icon(Icons.folder,
                                        color: Colors.white, size: 20),
                                  ),
                                  title: Text(catName,
                                      style: FlutterFlowTheme.of(context)
                                          .titleMedium
                                          .override(
                                            fontFamily: 'Readex Pro',
                                            fontWeight: FontWeight.w600,
                                          )),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      // Expand
                                      IconButton(
                                        icon: Icon(
                                          isExpanded
                                              ? Icons.expand_less
                                              : Icons.expand_more,
                                          color: color.text,
                                        ),
                                        onPressed: () => setState(() =>
                                            _expanded[catId] = !isExpanded),
                                      ),
                                      // Edit
                                      IconButton(
                                        icon: Icon(Icons.edit,
                                            color: color.text, size: 20),
                                        tooltip: context.tr('collection.tooltip.edit_name', fallback: 'แก้ไขชื่อ'),
                                        onPressed: () async {
                                          await _showEditDialog(
                                              context, catId, catName);
                                          _refresh();
                                        },
                                      ),
                                      // Delete
                                      IconButton(
                                        icon: const Icon(Icons.delete,
                                            color: Colors.red, size: 20),
                                        tooltip: context.tr('common.delete', fallback: 'ลบ'),
                                        onPressed: () async {
                                          await _handleDelete(
                                              context, catId, catName);
                                          _refresh();
                                        },
                                      ),
                                    ],
                                  ),
                                ),

                                // ── Expanded cameras panel ───────────
                                if (isExpanded)
                                  _CategoryCamerasPanel(
                                    categoryId: catId,
                                    categoryName: catName,
                                    allCameras: allCameras,
                                    onChanged: _refresh,
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(context.tr('common.close', fallback: 'ปิด')),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ── Create ──────────────────────────────────────────────────────────────

  Future<void> _showCreateDialog(BuildContext context) async {
    final ctrl = TextEditingController();
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(children: [
          Icon(Icons.create_new_folder_outlined, color: Color(0xFF4B39EF)),
          SizedBox(width: 8),
          Text(context.tr('collection.edit.title', fallback: 'สร้างหมวดหมู่ใหม่')),
        ]),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: InputDecoration(
            labelText: context.tr('collection.edit.name_label', fallback: 'ชื่อหมวดหมู่ *'),
            hintText: context.tr('collection.edit.name_label', fallback: 'เช่น กล้องทางเข้า'),
            border:
                OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            prefixIcon:
                const Icon(Icons.label_outlined, color: Color(0xFF4B39EF)),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(context.tr('common.cancel', fallback: 'ยกเลิก'))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4B39EF)),
            onPressed: () async {
              final name = ctrl.text.trim();
              if (name.isEmpty) {
                _snack(context, context.tr('collection.edit.name_required', fallback: 'กรุณากรอกชื่อหมวดหมู่'),
                    isError: true);
                return;
              }
              Navigator.pop(ctx);
              _showLoader(context);
              final res =
                  await CategoryService().createCategory(name: name);
              if (context.mounted) Navigator.pop(context);
              _snack(context,
                  res.succeeded
                      ? context.tr('collection.edit.updated_success', fallback: 'สร้างหมวดหมู่ "$name" สำเร็จ')
                      : context.tr('collection.edit.update_failed', fallback: 'สร้างหมวดหมู่ไม่สำเร็จ'),
                  isError: !res.succeeded);
            },
            child: Text(context.tr('common.close', fallback: 'สร้าง'),
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ── Edit ─────────────────────────────────────────────────────────────────

  Future<void> _showEditDialog(
      BuildContext context, String catId, String catName) async {
    final ctrl = TextEditingController(text: catName);
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.tr('collection.edit.title', fallback: 'แก้ไขหมวดหมู่')),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: InputDecoration(
              labelText: context.tr('collection.edit.name_label', fallback: 'ชื่อหมวดหมู่'), border: const OutlineInputBorder()),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(context.tr('common.cancel', fallback: 'ยกเลิก'))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4B39EF)),
            onPressed: () async {
              final name = ctrl.text.trim();
              if (name.isEmpty) {
                _snack(context, context.tr('collection.edit.name_required', fallback: 'กรุณากรอกชื่อ'), isError: true);
                return;
              }
              Navigator.pop(ctx);
              _showLoader(context);
              final res = await CategoryService()
                  .editCategory(categoryId: catId, name: name);
              if (context.mounted) Navigator.pop(context);
              _snack(context,
                  res.succeeded
                      ? context.tr('collection.edit.updated_success', fallback: 'อัปเดตหมวดหมู่สำเร็จ')
                      : context.tr('collection.edit.update_failed', fallback: 'อัปเดตไม่สำเร็จ'),
                  isError: !res.succeeded);
            },
            child: Text(context.tr('collection.edit.save', fallback: 'บันทึก'),
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ── Delete (with 409 force-delete flow) ──────────────────────────────────

  Future<void> _handleDelete(
      BuildContext context, String catId, String catName) async {
    final confirmed = await _showConfirmDelete(context, catName);
    if (confirmed != true) return;

    _showLoader(context);
    final res = await CategoryService().deleteCategory(catId);
    if (context.mounted) Navigator.pop(context);

    if (res.succeeded) {
      _snack(context, context.tr('collection.delete.deleted_success', fallback: 'ลบหมวดหมู่สำเร็จ'));
      return;
    }

    // 409 — category in use
    final isConflict = res.statusCode == 409 ||
        getJsonField(res.jsonBody, r'$.status') == 409;
    if (!isConflict || !context.mounted) {
      _snack(context, context.tr('collection.delete.delete_failed', params: {'statusCode': '${res.statusCode}'}, fallback: 'ลบไม่สำเร็จ (${res.statusCode})'), isError: true);
      return;
    }

    final force = await _showForceDeleteDialog(context, catName);
    if (force != true || !context.mounted) return;

    _showLoader(context);
    final forceRes =
        await CategoryService().deleteCategory(catId, force: true);
    if (context.mounted) Navigator.pop(context);
    _snack(
        context,
      forceRes.succeeded
        ? context.tr('collection.delete.force_deleted_success', fallback: 'ลบแบบบังคับสำเร็จ')
        : context.tr('collection.delete.force_delete_failed', fallback: 'ลบแบบบังคับไม่สำเร็จ'),
        isError: !forceRes.succeeded);
  }

  Future<bool?> _showConfirmDelete(
      BuildContext context, String catName) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(children: [
          Icon(Icons.warning_amber_rounded, color: Colors.red),
          SizedBox(width: 8),
          Text(context.tr('collection.delete.title', fallback: 'ลบหมวดหมู่')),
        ]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(context.tr('collection.delete.confirm', params: {'name': catName}, fallback: 'ลบ "$catName" ?')),
            const SizedBox(height: 12),
            Row(children: [
              const Icon(Icons.info_outline, size: 14, color: Colors.red),
              const SizedBox(width: 4),
              Text(context.tr('collection.delete.undo_warning', fallback: 'การกระทำนี้ไม่สามารถย้อนกลับได้'),
                  style: TextStyle(
                      color: Colors.red,
                      fontSize: 12,
                      fontWeight: FontWeight.w600)),
            ]),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(context.tr('common.cancel', fallback: 'ยกเลิก'))),
          ElevatedButton(
            style:
                ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(context.tr('common.delete', fallback: 'ลบ'),
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<bool?> _showForceDeleteDialog(
      BuildContext context, String catName) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(children: [
          Icon(Icons.warning_amber_rounded, color: Colors.orange),
          SizedBox(width: 8),
          Text(context.tr('collection.delete.in_use_title', fallback: 'หมวดหมู่กำลังถูกใช้งาน')),
        ]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(context.tr('collection.delete.in_use_message', params: {'name': catName}, fallback: '"$catName" ยังถูกใช้งานโดยกล้องอย่างน้อยหนึ่งตัว')),
            const SizedBox(height: 8),
            Text(
              context.tr('collection.delete.force_delete_message', fallback: 'การลบแบบบังคับจะนำหมวดหมู่นี้ออกจากกล้องทั้งหมดก่อน แล้วจึงลบหมวดหมู่'),
              style: TextStyle(color: Color(0xFF6B7280)),
            ),
            const SizedBox(height: 12),
            Row(children: [
              const Icon(Icons.info_outline, size: 14, color: Colors.red),
              const SizedBox(width: 4),
              Text(context.tr('collection.delete.undo_warning', fallback: 'การกระทำนี้ไม่สามารถย้อนกลับได้'),
                  style: TextStyle(
                      color: Colors.red,
                      fontSize: 12,
                      fontWeight: FontWeight.w600)),
            ]),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(context.tr('common.cancel', fallback: 'ยกเลิก'))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444)),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(context.tr('collection.delete.force_delete', fallback: 'ลบแบบบังคับ'),
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  void _showLoader(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) =>
          const Center(child: CircularProgressIndicator()),
    );
  }

  void _snack(BuildContext context, String msg, {bool isError = false}) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor:
          isError ? Colors.red : const Color(0xFF4CAF50),
    ));
  }
}

// =============================================================================
// _EmptyCategoryState
// =============================================================================

class _EmptyCategoryState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.category_outlined,
            size: 64,
            color: FlutterFlowTheme.of(context).secondaryText),
        const SizedBox(height: 16),
        Text('ยังไม่มีหมวดหมู่',
            style: FlutterFlowTheme.of(context).titleMedium),
        const SizedBox(height: 8),
        Text(
          'กดปุ่ม + ด้านบนเพื่อสร้างหมวดหมู่แรก',
          style: FlutterFlowTheme.of(context).bodySmall,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

// =============================================================================
// _CategoryCamerasPanel — expanded panel แสดง cameras ใน category
// =============================================================================

class _CategoryCamerasPanel extends StatelessWidget {
  final String categoryId;
  final String categoryName;
  final List<dynamic> allCameras;
  final VoidCallback onChanged;

  const _CategoryCamerasPanel({
    required this.categoryId,
    required this.categoryName,
    required this.allCameras,
    required this.onChanged,
  });

  List<dynamic> get _cameras => allCameras.where((cam) {
        final cats = getJsonField(cam, r'$.categories');
        if (cats == null) return false;
        final list = cats is List ? cats : [cats];
        return list.any(
            (c) => getJsonField(c, r'$.id').toString() == categoryId);
      }).toList();

  @override
  Widget build(BuildContext context) {
    final cameras = _cameras;
    return Container(
      padding: const EdgeInsets.all(12),
      color: Colors.grey[50],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'กล้อง (${cameras.length})',
                style: FlutterFlowTheme.of(context)
                    .labelLarge
                    .override(
                        fontFamily: 'Readex Pro',
                        fontWeight: FontWeight.w600),
              ),
              ElevatedButton.icon(
                onPressed: () async {
                  await _showAddCameraDialog(context, cameras);
                  onChanged();
                },
                icon: const Icon(Icons.add, size: 16),
                label: const Text('เพิ่มกล้อง'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF39D2C0),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Camera list
          if (cameras.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: Text(
                  'ไม่มีข้อมูลกล้องในหมวดหมู่นี้',
                  style: FlutterFlowTheme.of(context)
                      .bodySmall
                      .override(
                          fontFamily: 'Readex Pro',
                          fontStyle: FontStyle.italic),
                ),
              ),
            )
          else
            ...cameras.map((cam) => _CameraListTile(
                  camera: cam,
                  categoryId: categoryId,
                  categoryName: categoryName,
                  onChanged: onChanged,
                )),
        ],
      ),
    );
  }

  Future<void> _showAddCameraDialog(
      BuildContext context, List<dynamic> currentCameras) async {
    final currentIds =
        currentCameras.map((c) => getJsonField(c, r'$.id').toString()).toSet();
    final available =
        allCameras.where((c) => !currentIds.contains(getJsonField(c, r'$.id').toString())).toList();

    if (available.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('กล้องทั้งหมดถูกเพิ่มในหมวดหมู่นี้แล้ว'),
        backgroundColor: Color(0xFFFFA726),
      ));
      return;
    }

    await showDialog(
      context: context,
      builder: (ctx) => _AddCameraDialog(
        categoryId: categoryId,
        categoryName: categoryName,
        availableCameras: available,
        onAdded: onChanged,
      ),
    );
  }
}

// =============================================================================
// _CameraListTile — row ใน panel พร้อมปุ่ม Remove
// =============================================================================

class _CameraListTile extends StatelessWidget {
  final dynamic camera;
  final String categoryId;
  final String categoryName;
  final VoidCallback onChanged;

  const _CameraListTile({
    required this.camera,
    required this.categoryId,
    required this.categoryName,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cameraId = getJsonField(camera, r'$.id').toString();
    final cameraName = getJsonField(camera, r'$.name').toString();

    return ListTile(
      dense: true,
      leading: const Icon(Icons.videocam,
          color: Color(0xFF39D2C0), size: 20),
      title: Text(cameraName,
          style: FlutterFlowTheme.of(context).bodyMedium),
      trailing: IconButton(
        icon: const Icon(Icons.remove_circle, color: Colors.red, size: 20),
        tooltip: 'นำออก',
        onPressed: () async {
          final confirm = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('นำกล้องออก'),
              content: Text(
                  'นำ "$cameraName" ออกจาก "$categoryName" ?'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('ยกเลิก')),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red),
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('นำออก',
                      style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          );
          if (confirm != true) return;
          await _doRemove(context, cameraId, cameraName);
        },
      ),
    );
  }

  Future<void> _doRemove(
      BuildContext context, String cameraId, String cameraName) async {
    final navigator =
        Navigator.of(context, rootNavigator: true);
    final sm = ScaffoldMessenger.of(context);
    bool loaderShown = false;

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) {
          loaderShown = true;
          return WillPopScope(
              onWillPop: () async => false,
              child: const Center(child: CircularProgressIndicator()));
        },
      );

      final res = await CameraService().deleteCategoryFromCamera(
          categoryId: categoryId, cameraId: cameraId);

      if (loaderShown && navigator.canPop()) navigator.pop();

      sm.showSnackBar(SnackBar(
        content: Text(
          res.succeeded ? 'นำกล้องออกสำเร็จ' : 'นำกล้องออกไม่สำเร็จ'),
        backgroundColor:
            res.succeeded ? const Color(0xFF4CAF50) : Colors.red,
      ));

      if (res.succeeded) onChanged();
    } catch (e) {
      if (loaderShown && navigator.canPop()) navigator.pop();
      sm.showSnackBar(SnackBar(
        content: Text('เกิดข้อผิดพลาด: $e'),
        backgroundColor: Colors.red,
      ));
    }
  }
}

// =============================================================================
// _AddCameraDialog — dialog เลือกกล้องเพื่อเพิ่มเข้า category
// =============================================================================

class _AddCameraDialog extends StatefulWidget {
  final String categoryId;
  final String categoryName;
  final List<dynamic> availableCameras;
  final VoidCallback onAdded;

  const _AddCameraDialog({
    required this.categoryId,
    required this.categoryName,
    required this.availableCameras,
    required this.onAdded,
  });

  @override
  State<_AddCameraDialog> createState() => _AddCameraDialogState();
}

class _AddCameraDialogState extends State<_AddCameraDialog> {
  String _search = '';

  List<dynamic> get _filtered => widget.availableCameras
      .where((c) => getJsonField(c, r'$.name')
          .toString()
          .toLowerCase()
          .contains(_search.toLowerCase()))
      .toList();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('เพิ่มกล้องใน "${widget.categoryName}"'),
      content: SizedBox(
        width: 500,
        height: 400,
        child: Column(
          children: [
            // Search
            TextField(
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: 'ค้นหากล้อง...',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
              ),
              onChanged: (v) => setState(() => _search = v),
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerLeft,
              child: Text('พบ ${_filtered.length} กล้อง',
                  style: TextStyle(
                      fontSize: AppTextStyles.commandBody,
                      color: Colors.grey[600])),
            ),
            const SizedBox(height: 8),
            const Divider(height: 1),
            const SizedBox(height: 8),
            Expanded(
              child: _filtered.isEmpty
                  ? const Center(
                    child: Text('ไม่พบข้อมูลกล้อง',
                          style: TextStyle(color: Colors.grey)))
                  : ListView.builder(
                      itemCount: _filtered.length,
                      itemBuilder: (ctx, i) {
                        final cam = _filtered[i];
                        final camId =
                            getJsonField(cam, r'$.id').toString();
                        final camName =
                            getJsonField(cam, r'$.name').toString();
                        return ListTile(
                          leading: const Icon(Icons.videocam,
                              color: Color(0xFF39D2C0)),
                          title: Text(camName),
                          trailing: IconButton(
                            icon: const Icon(Icons.add_circle,
                                color: Color(0xFF4B39EF)),
                            onPressed: () async {
                              Navigator.of(context).pop();
                              await _doAdd(context, camId, camName);
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
            onPressed: () => Navigator.pop(context),
        child: const Text('ปิด')),
      ],
    );
  }

  Future<void> _doAdd(
      BuildContext context, String camId, String camName) async {
    final navigator =
        Navigator.of(context, rootNavigator: true);
    final sm = ScaffoldMessenger.of(context);
    bool loaderShown = false;

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) {
          loaderShown = true;
          return WillPopScope(
              onWillPop: () async => false,
              child: const Center(child: CircularProgressIndicator()));
        },
      );

      final res = await CameraService().addCategoryToCamera(
          categoryId: widget.categoryId, cameraId: camId);

      if (loaderShown && navigator.canPop()) navigator.pop();

      sm.showSnackBar(SnackBar(
        content:
          Text(res.succeeded ? 'เพิ่มกล้องสำเร็จ' : 'เพิ่มกล้องไม่สำเร็จ'),
        backgroundColor:
            res.succeeded ? const Color(0xFF4CAF50) : Colors.red,
      ));

      if (res.succeeded) widget.onAdded();
    } catch (e) {
      if (loaderShown && navigator.canPop()) navigator.pop();
      sm.showSnackBar(SnackBar(
        content: Text('เกิดข้อผิดพลาด: $e'),
        backgroundColor: Colors.red,
      ));
    }
  }
}