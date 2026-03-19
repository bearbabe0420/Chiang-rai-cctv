// Automatic FlutterFlow imports
import '/core/i18n/i18n.dart';
import '/utils/flutter_flow/theme.dart';
import '/utils/flutter_flow/util.dart';
import '../index.dart'; // Imports other custom widgets
import 'package:flutter/material.dart';
// Begin custom widget code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

// Set your widget name, define your parameter, and then add the
// boilerplate code using the green button on the right!

class CameraDashboardTable extends StatefulWidget {
  const CameraDashboardTable({
    Key? key,
    this.width,
    this.height,
    required this.cameras,
    this.onDelete,
    this.onEdit,
    this.onView,
  }) : super(key: key);

  final double? width;
  final double? height;
  final List<dynamic> cameras;

  final Future Function(dynamic id)? onDelete;
  final Future Function(dynamic id)? onEdit;
  final Future Function(dynamic id)? onView;

  @override
  State<CameraDashboardTable> createState() => _CameraDashboardTableState();
}

class _CameraDashboardTableState extends State<CameraDashboardTable> {
  String searchText = "";

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> safeList = widget.cameras
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .where((cam) =>
            cam['name']
                ?.toString()
                .toLowerCase()
                .contains(searchText.toLowerCase()) ??
            true)
        .toList();

    final total = widget.cameras.length;
    final online = widget.cameras.where((c) => c['status'] == 'online').length;
    final offline =
        widget.cameras.where((c) => c['status'] == 'offline').length;

    return Container(
      width: widget.width,
      height: widget.height,
      padding: const EdgeInsets.all(30),
      color: const Color(0xfff3f4f6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// TITLE
          Text(
            context.tr('camera_dashboard.title'),
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 30),

          /// STAT CARDS
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _statCard(context.tr('camera_dashboard.total_cameras'), total, Icons.home_work_outlined),
              _statCard(context.tr('camera_dashboard.online_cameras'), online, Icons.videocam),
              _statCard(context.tr('camera_dashboard.offline_cameras'), offline, Icons.videocam_off),
            ],
          ),

          const SizedBox(height: 30),

          /// SEARCH + BUTTONS
          Row(
            children: [
              /// SEARCH INPUT
              Expanded(
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: context.tr('camera_dashboard.search_hint'),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    onChanged: (val) {
                      setState(() {
                        searchText = val;
                      });
                    },
                  ),
                ),
              ),

              const SizedBox(width: 15),

              _blackButton(
                icon: Icons.search,
                label: context.tr('common.search'),
                onTap: () {},
              ),

              const SizedBox(width: 10),

              _blackButton(
                icon: Icons.add,
                label: context.tr('camera_list.add_camera'),
                onTap: () {
                  widget.onEdit?.call(null);
                },
              ),

              const SizedBox(width: 10),

              _blackButton(
                icon: Icons.file_upload_outlined,
                label: context.tr('camera_dashboard.import_files'),
                onTap: () {},
              ),
            ],
          ),

          const SizedBox(height: 30),

          /// TABLE
          Expanded(
            child: _buildTable(safeList),
          ),
        ],
      ),
    );
  }

  Widget _buildTable(List<Map<String, dynamic>> safeList) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          /// TABLE HEADER
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Color(0xffe5e7eb)),
              ),
            ),
            child: Row(
              children: [
                _HeaderCell("${context.tr('camera_list.columns.name')}", 2),
                _HeaderCell("${context.tr('camera_list.columns.latlong')}", 2),
                _HeaderCell("${context.tr('camera_list.columns.address')}", 3),
                _HeaderCell("${context.tr('camera_list.columns.status')}", 1),
                _HeaderCell("${context.tr('camera_list.columns.category')}", 2),
                _HeaderCell("${context.tr('camera_list.columns.action')}", 2),
              ],
            ),
          ),

          /// TABLE ROWS
          Expanded(
            child: ListView.builder(
              itemCount: safeList.length,
              itemBuilder: (context, index) {
                final cam = safeList[index];
                final categories =
                    (cam['categories'] as List?)?.join(", ") ?? "-";

                final isOnline = cam['status'] == 'online';

                return Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Color(0xfff1f1f1)),
                    ),
                  ),
                  child: Row(
                    children: [
                      _DataCell(cam['name'], 2),
                      _DataCell(cam['latLong'], 2),
                      _DataCell(cam['address'], 3),

                      /// STATUS CHIP
                      Expanded(
                        flex: 1,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          decoration: BoxDecoration(
                            color: isOnline
                                ? Colors.green.withOpacity(0.1)
                                : Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Center(
                            child: Text(
                              cam['status']?.toString() ?? "-",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isOnline ? Colors.green : Colors.red,
                              ),
                            ),
                          ),
                        ),
                      ),

                      _DataCell(categories, 2),

                      /// ACTIONS
                      Expanded(
                        flex: 2,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.visibility),
                              onPressed: () => widget.onView?.call(cam['id']),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () => widget.onEdit?.call(cam['id']),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () => widget.onDelete?.call(cam['id']),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// HEADER CELL
class _HeaderCell extends StatelessWidget {
  final String text;
  final int flex;

  const _HeaderCell(this.text, this.flex);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

/// DATA CELL
class _DataCell extends StatelessWidget {
  final dynamic text;
  final int flex;

  const _DataCell(this.text, this.flex);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Text(
        text?.toString() ?? "-",
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

/// STAT CARD
Widget _statCard(String title, int value, IconData icon) {
  return Container(
    width: 280,
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.grey.shade300),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Icon(icon, size: 28),
            const SizedBox(width: 12),
            Text(
              value.toString(),
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

/// BLACK BUTTON
Widget _blackButton({
  required IconData icon,
  required String label,
  required VoidCallback onTap,
}) {
  return Container(
    height: 48,
    padding: const EdgeInsets.symmetric(horizontal: 18),
    decoration: BoxDecoration(
      color: Colors.black,
      borderRadius: BorderRadius.circular(8),
    ),
    child: InkWell(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(color: Colors.white),
          ),
        ],
      ),
    ),
  );
}
