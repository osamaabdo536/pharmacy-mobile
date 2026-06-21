import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_colors.dart';
import '../../features/search/data/models/trending_drug_model.dart';

class TrendingDrugCard extends StatelessWidget {
  final TrendingDrugModel drug;

  const TrendingDrugCard({super.key, required this.drug});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFEFF0F6)),
        ),
        child: InkWell(
          onTap: () => _openDetails(context),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.max,
              children: [
                // ─── Name ───────────────────────────────────
                Text(
                  drug.name,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    height: 1.15,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),

                // ─── Subtitle ────────────────────────────────
                Text(
                  _subtitle,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    height: 1.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),

                const Spacer(),

                // ─── Details button ──────────────────────────
                SizedBox(
                  width: double.infinity,
                  height: 38,
                  child: ElevatedButton(
                    onPressed: drug.id.isNotEmpty
                        ? () => _openDetails(context)
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: AppColors.surfaceVariant,
                      disabledForegroundColor: AppColors.textSecondary,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('DETAILS'),
                        SizedBox(width: 8),
                        Icon(Icons.chevron_right, size: 20),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String get _subtitle {
    final parts = [drug.strength, drug.dosageForm]
        .where((part) => part != null && part.trim().isNotEmpty)
        .cast<String>()
        .toList();

    if (parts.isNotEmpty) {
      return parts.join(' ');
    }

    return drug.manufacturer ?? '';
  }

  void _openDetails(BuildContext context) {
    if (drug.id.isEmpty) return;
    context.push('/search/drug-detail/${drug.id}', extra: drug);
  }
}
