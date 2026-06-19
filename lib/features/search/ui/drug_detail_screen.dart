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
  final Map<String, int> _selectedQuantities = {};
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
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final screenWidth = constraints.maxWidth;
            final isNarrow = screenWidth < 380;
            final hPad = isNarrow ? 12.0 : 16.0;

            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: SingleChildScrollView(
                  child: Container(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
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
                                _buildMedicineHeader(
                                  context,
                                  pharmacies.length,
                                  hPad,
                                  isNarrow,
                                ),
                                const Divider(
                                  height: 1,
                                  color: AppColors.border,
                                ),
                                Padding(
                                  padding: EdgeInsets.fromLTRB(
                                    hPad,
                                    18,
                                    hPad,
                                    24,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                                      _buildPharmacyList(snapshot, isNarrow),
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
            );
          },
        ),
      ),
    );
  }

  Widget _buildMedicineHeader(
    BuildContext context,
    int pharmacyCount,
    double hPad,
    bool isNarrow,
  ) {
    return Padding(
      padding: EdgeInsets.fromLTRB(hPad, 12, hPad, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back, size: 20),
            color: AppColors.textPrimary,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints.tightFor(width: 36, height: 36),
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.drug.displayName,
                      style: TextStyle(
                        fontSize: isNarrow ? 17 : 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _categoryLine,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$pharmacyCount available',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPharmacyList(
    AsyncSnapshot<List<PharmacyResultModel>> snapshot,
    bool isNarrow,
  ) {
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
      children: pharmacies.map((p) => _buildPharmacyCard(p, isNarrow)).toList(),
    );
  }

  Widget _buildPharmacyCard(PharmacyResultModel pharmacy, bool isNarrow) {
    final isReserving = _reservingInventoryId == pharmacy.id;
    final quantity = _quantityFor(pharmacy);
    final maxQuantity = pharmacy.stockQuantity ?? 99;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.fromLTRB(
        isNarrow ? 10 : 14,
        12,
        isNarrow ? 10 : 14,
        12,
      ),
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
          // Top row: pharmacy info.
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
                            style: TextStyle(
                              fontSize: isNarrow ? 13 : 14,
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
                    if (pharmacy.distanceLabel.isNotEmpty) ...[
                      const SizedBox(height: 4),
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
            ],
          ),

          const SizedBox(height: 10),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 12),

          // Bottom row: price, quantity, and reserve action.
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          '\$${pharmacy.price.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: isNarrow ? 16 : 18,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        if (pharmacy.displayOriginalPrice != null) ...[
                          const SizedBox(width: 6),
                          Text(
                            '\$${pharmacy.displayOriginalPrice!.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (pharmacy.displayDiscountPercent != null) ...[
                      const SizedBox(height: 5),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.errorBg,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'SAVE ${pharmacy.displayDiscountPercent}%',
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: AppColors.error,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(width: 10),

              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _buildQuantityStepper(
                    quantity: quantity,
                    canDecrease: quantity > 1,
                    canIncrease: quantity < maxQuantity,
                    onDecrease: () => _changeQuantity(pharmacy, -1),
                    onIncrease: () => _changeQuantity(pharmacy, 1),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: isNarrow ? 90 : 100,
                    height: 34,
                    child: _buildReserveButton(pharmacy, isReserving),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReserveButton(PharmacyResultModel pharmacy, bool isReserving) {
    return ElevatedButton(
      onPressed: isReserving ? null : () => _confirmAndReserve(pharmacy),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        disabledBackgroundColor: AppColors.primaryLight,
        disabledForegroundColor: Colors.white,
        elevation: 0,
        padding: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
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
    );
  }

  Widget _buildQuantityStepper({
    required int quantity,
    required bool canDecrease,
    required bool canIncrease,
    required VoidCallback onDecrease,
    required VoidCallback onIncrease,
  }) {
    return Container(
      height: 30,
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.primaryLight),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 28,
            child: IconButton(
              onPressed: canDecrease ? onDecrease : null,
              icon: const Icon(Icons.remove, size: 14),
              color: AppColors.primary,
              disabledColor: AppColors.textHint,
              padding: EdgeInsets.zero,
            ),
          ),
          Container(width: 1, height: 18, color: AppColors.primaryLight),
          SizedBox(
            width: 28,
            child: Center(
              child: Text(
                quantity.toString(),
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          Container(width: 1, height: 18, color: AppColors.primaryLight),
          SizedBox(
            width: 28,
            child: IconButton(
              onPressed: canIncrease ? onIncrease : null,
              icon: const Icon(Icons.add, size: 14),
              color: AppColors.primary,
              disabledColor: AppColors.textHint,
              padding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    );
  }

  int _quantityFor(PharmacyResultModel pharmacy) {
    final maxQuantity = pharmacy.stockQuantity ?? 99;
    final current = _selectedQuantities[pharmacy.id] ?? 1;
    return current.clamp(1, maxQuantity < 1 ? 1 : maxQuantity).toInt();
  }

  void _changeQuantity(PharmacyResultModel pharmacy, int delta) {
    final maxQuantity = pharmacy.stockQuantity ?? 99;
    final next = (_quantityFor(pharmacy) + delta)
        .clamp(1, maxQuantity < 1 ? 1 : maxQuantity)
        .toInt();
    setState(() => _selectedQuantities[pharmacy.id] = next);
  }

  Future<void> _confirmAndReserve(PharmacyResultModel pharmacy) async {
    final quantity = _quantityFor(pharmacy);
    final total = pharmacy.price * quantity;

    final shouldReserve = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => _ReservationDialog(
        drugName: widget.drug.displayName,
        pharmacyName: pharmacy.name,
        quantity: quantity,
        total: total,
      ),
    );

    if (shouldReserve == true && mounted) {
      await _reserve(pharmacy, quantity);
    }
  }

  Future<void> _reserve(PharmacyResultModel pharmacy, int quantity) async {
    setState(() => _reservingInventoryId = pharmacy.id);
    try {
      await ReservationRepository().createReservation(
        inventoryId: pharmacy.id,
        quantity: quantity,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Reserved $quantity ${quantity == 1 ? 'item' : 'items'} at ${pharmacy.name}',
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not reserve this medicine.')),
      );
    } finally {
      if (mounted) setState(() => _reservingInventoryId = null);
    }
  }

  String get _categoryLine {
    final parts = [
      widget.drug.genericName ?? widget.drug.activeIngredient,
      widget.drug.category,
      widget.drug.dosageForm,
      widget.drug.manufacturer,
    ].where((p) => p != null && p.trim().isNotEmpty).cast<String>().toList();
    return parts.isEmpty ? 'Medicine details' : parts.join(' - ');
  }
}

class _ReservationDialog extends StatelessWidget {
  final String drugName;
  final String pharmacyName;
  final int quantity;
  final double total;

  const _ReservationDialog({
    required this.drugName,
    required this.pharmacyName,
    required this.quantity,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final hInset = screenWidth < 400 ? 20.0 : 32.0;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: EdgeInsets.symmetric(horizontal: hInset, vertical: 24),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.local_pharmacy_outlined,
                    color: AppColors.primary,
                    size: 17,
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Confirm Reservation',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  icon: const Icon(Icons.close, size: 17),
                  color: AppColors.textSecondary,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints.tightFor(
                    width: 28,
                    height: 28,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 1, color: AppColors.border),
            const SizedBox(height: 16),

            _DetailRow(
              icon: Icons.medication_outlined,
              label: 'Medicine',
              value: drugName,
            ),
            const SizedBox(height: 12),
            _DetailRow(
              icon: Icons.store_outlined,
              label: 'Pharmacy',
              value: pharmacyName,
            ),
            const SizedBox(height: 12),
            _DetailRow(
              icon: Icons.numbers_outlined,
              label: 'Quantity',
              value: quantity.toString(),
            ),
            const SizedBox(height: 12),
            _DetailRow(
              icon: Icons.receipt_outlined,
              label: 'Total',
              value: '\$${total.toStringAsFixed(2)}',
              valueStyle: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                      side: const BorderSide(color: AppColors.border),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 11),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 11),
                    ),
                    child: const Text(
                      'Reserve',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final TextStyle? valueStyle;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 15, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        SizedBox(
          width: 68,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style:
                valueStyle ??
                const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
          ),
        ),
      ],
    );
  }
}
