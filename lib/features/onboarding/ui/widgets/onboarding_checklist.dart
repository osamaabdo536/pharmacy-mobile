import 'package:flutter/material.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/utils/responsive.dart';

class OnboardingChecklist extends StatelessWidget {
  final List<String> items;

  const OnboardingChecklist({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items
          .map((item) => _ChecklistRow(label: item))
          .toList(growable: false),
    );
  }
}

class _ChecklistRow extends StatelessWidget {
  final String label;

  const _ChecklistRow({required this.label});

  @override
  Widget build(BuildContext context) {
    final iconSize = context.scale(22);

    return Padding(
      padding: EdgeInsets.only(bottom: context.scale(10)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: iconSize,
            height: iconSize,
            decoration: const BoxDecoration(
              color: AppColors.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check,
              size: iconSize * 0.55,
              color: AppColors.primary,
            ),
          ),
          SizedBox(width: context.scale(10)),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(top: context.scale(2)),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: context.scale(14),
                  color: AppColors.textPrimary,
                  height: 1.35,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
