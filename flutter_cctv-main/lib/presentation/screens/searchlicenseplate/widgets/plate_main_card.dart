import 'package:central_command/utils/app_text_styles.dart';

import '/core/i18n/i18n.dart';
import '/utils/flutter_flow/theme.dart';
import 'package:flutter/material.dart';
import '../searchlicenseplate_model.dart';
import 'plate_toolbar.dart';
import 'plate_table_cells.dart';
import 'plate_pagination.dart';

/// Card หลักที่รวม SearchBar + Table + Pagination
class PlateMainCard extends StatelessWidget {
  final ListPlatePageModel model;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onClearSearch;
  final ValueChanged<int> onPageChanged;
  final Widget Function() buildTable;

  const PlateMainCard({
    super.key,
    required this.model,
    required this.onSearchChanged,
    required this.onClearSearch,
    required this.onPageChanged,
    required this.buildTable,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
            // ── Toolbar ──────────────────────────────────────────────────────
            Row(
              children: [
                PlateSearchBar(
                  controller: model.searchBarController,
                  focusNode: model.searchBarFocusNode,
                  onChanged: onSearchChanged,
                  onClear: onClearSearch,
                ),
                const Spacer(),
                PlateTotalBadge(total: model.totalItems),
              ],
            ),
            const SizedBox(height: 16),

            // ── Table / Loading / Empty ───────────────────────────────────
            if (model.isLoading)
              SizedBox(
                height: 300,
                child: Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      FlutterFlowTheme.of(context).primary,
                    ),
                  ),
                ),
              )
            else if (model.listOfPlates.isEmpty)
              const PlateEmptyState()
            else
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minWidth: MediaQuery.of(context).size.width - 88,
                  ),
                  child: buildTable(),
                ),
              ),

            const SizedBox(height: 20),

            // ── Pagination ────────────────────────────────────────────────
            if (!model.isLoading && model.totalPages > 1) ...[
              const Divider(height: 1, color: Color(0xFFE5E7EB)),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    context.tr(
                      'plate.page_summary',
                      params: {
                        'page': '${model.currentPage}',
                        'totalPages': '${model.totalPages}',
                        'totalItems': '${model.totalItems}',
                      },
                    ),
                    style: const TextStyle(
                      color: Color(0xFF6B7280),
                      fontSize: AppTextStyles.labelSmall,
                    ),
                  ),
                  PlatePagination(
                    currentPage: model.currentPage,
                    totalPages: model.totalPages,
                    onPageChanged: onPageChanged,
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}