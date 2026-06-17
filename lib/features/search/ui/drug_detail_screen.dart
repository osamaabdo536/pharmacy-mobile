import 'package:flutter/material.dart';

import '../../../core/utils/location_service.dart';
import '../../reservation/data/models/reservation_repository.dart';
import '../../../shared/theme/app_colors.dart';
import '../data/models/pharmacy_result_model.dart';
import '../data/models/trending_drug_model.dart';
import '../data/search_repository.dart';

class DrugDetailScreen extends StatefulWidget {
  final TrendingDrugModel drug;

  const DrugDetailScreen({required this.drug, super.key});

  @override
  State<DrugDetailScreen> createState() => _DrugDetailScreenState();
}

class _DrugDetailScreenState extends State<DrugDetailScreen> {
  late final Future<List<PharmacyResultModel>> _pharmaciesFuture;
  String? _reservingInventoryId;

  @override
  void initState() {
    super.initState();
    _pharmaciesFuture = _loadNearbyPharmacies();
  }

  Future<List<PharmacyResultModel>> _loadNearbyPharmacies() async {
    if (widget.drug.hasPharmacyResults) {
      return widget.drug.pharmacies;
    }

    final position = await LocationService().getCurrentPosition();

    return SearchRepository().getNearbyPharmacies(
      widget.drug.id,
      lat: position?.latitude ?? 30.0444,
      lng: position?.longitude ?? 31.2357,
      radius: 100,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceVariant,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 430),
          child: SingleChildScrollView(
            child: Container(
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FutureBuilder<List<PharmacyResultModel>>(
                    future: _pharmaciesFuture,
                    builder: (context, snapshot) {
                      final pharmacies = snapshot.data ?? const [];

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildMedicineHeader(context, pharmacies.length),
                          const Divider(height: 1, color: AppColors.border),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Nearby Pharmacies',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                _buildPharmacyList(snapshot),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMedicineHeader(BuildContext context, int pharmacyCount) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 64),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back, size: 20),
            color: AppColors.textPrimary,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints.tightFor(width: 32, height: 32),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 2, top: 30, right: 118),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.drug.displayName,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    height: 1.05,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _categoryLine,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            right: -8,
            top: 24,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$pharmacyCount Pharmacies Available',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPharmacyList(AsyncSnapshot<List<PharmacyResultModel>> snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 28),
        child: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    if (snapshot.hasError) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Text(
          'Could not load pharmacies for this medicine.',
          style: TextStyle(color: AppColors.error, fontSize: 13),
        ),
      );
    }

    final pharmacies = snapshot.data ?? const [];

    if (pharmacies.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Text(
          'No pharmacies available for this medicine right now.',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
      );
    }

    return Column(
      children: pharmacies
          .map((pharmacy) => _buildPharmacyCard(pharmacy))
          .toList(),
    );
  }

  Widget _buildPharmacyCard(PharmacyResultModel pharmacy) {
    final isReserving = _reservingInventoryId == pharmacy.id;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            pharmacy.name,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.verified_outlined,
                          color: AppColors.primary,
                          size: 13,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.near_me_outlined,
                          color: AppColors.textSecondary,
                          size: 10,
                        ),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            pharmacy.address ?? 'Address unavailable',
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppColors.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    if (pharmacy.distanceLabel.isNotEmpty) ...[
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            color: AppColors.primary,
                            size: 10,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            pharmacy.distanceLabel,
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              _buildQuantityStepper(),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '\$${pharmacy.price.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: 8),
              if (pharmacy.displayOriginalPrice != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Text(
                    '\$${pharmacy.displayOriginalPrice!.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.textSecondary,
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                ),
              const Spacer(),
              SizedBox(
                width: 72,
                height: 30,
                child: ElevatedButton(
                  onPressed: isReserving ? null : () => _reserve(pharmacy),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: AppColors.primaryLight,
                    disabledForegroundColor: Colors.white,
                    elevation: 0,
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  child: isReserving
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Reserve'),
                ),
              ),
            ],
          ),
          if (pharmacy.displayDiscountPercent != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.errorBg,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'SAVE ${pharmacy.displayDiscountPercent}%',
                style: const TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.w700,
                  color: AppColors.error,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _reserve(PharmacyResultModel pharmacy) async {
    setState(() => _reservingInventoryId = pharmacy.id);

    try {
      await ReservationRepository().createReservation(
        inventoryId: pharmacy.id,
        quantity: 1,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Reserved at ${pharmacy.name}')));
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not reserve this medicine.')),
      );
    } finally {
      if (mounted) {
        setState(() => _reservingInventoryId = null);
      }
    }
  }

  Widget _buildQuantityStepper() {
    return Container(
      height: 28,
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.primaryLight),
        borderRadius: BorderRadius.circular(9),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 24,
            child: Center(
              child: Text(
                '-',
                style: TextStyle(fontSize: 16, color: AppColors.textPrimary),
              ),
            ),
          ),
          SizedBox(
            width: 20,
            child: Center(
              child: Text(
                '1',
                style: TextStyle(fontSize: 13, color: AppColors.textPrimary),
              ),
            ),
          ),
          SizedBox(
            width: 24,
            child: Center(
              child: Text(
                '+',
                style: TextStyle(fontSize: 16, color: AppColors.textPrimary),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String get _categoryLine {
    final parts =
        [
              widget.drug.genericName ?? widget.drug.activeIngredient,
              widget.drug.category,
              widget.drug.dosageForm,
              widget.drug.manufacturer,
            ]
            .where((part) => part != null && part.trim().isNotEmpty)
            .cast<String>()
            .toList();

    if (parts.isEmpty) {
      return 'Medicine details';
    }

    return parts.join(': ');
  }
}
