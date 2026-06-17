import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/utils/location_service.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../../shared/widgets/trending_drug_card.dart';
import '../cubit/search_cubit.dart';
import '../cubit/search_state.dart';
import '../data/models/trending_drug_model.dart';
import '../data/search_repository.dart';

class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          SearchCubit(SearchRepository(), LocationService())..initializeSearch(),
      child: const _SearchView(),
    );
  }
}

class _SearchView extends StatefulWidget {
  const _SearchView();

  @override
  State<_SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends State<_SearchView> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
            final crossAxisCount = screenWidth >= 600 ? 2 : 1;
            final cardAspect = crossAxisCount == 2 ? 1.55 : (isNarrow ? 2.7 : 3.05);

            return BlocBuilder<SearchCubit, SearchState>(
              builder: (context, state) {
                final hasActiveSearch =
                    state.drugSearchStatus != DrugSearchStatus.initial ||
                    state.searchQuery.isNotEmpty;

                return CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: _buildHeader(context, state, isNarrow),
                    ),
                    if (hasActiveSearch) ...[
                      SliverToBoxAdapter(
                        child: _buildSectionTitle(
                          title: 'Search results',
                          actionLabel: 'Clear',
                          isNarrow: isNarrow,
                          action: () {
                            _searchController.clear();
                            context.read<SearchCubit>().clearSearchResults();
                          },
                        ),
                      ),
                      SliverPadding(
                        padding: EdgeInsets.fromLTRB(
                          isNarrow ? 12 : 16, 0, isNarrow ? 12 : 16, 4,
                        ),
                        sliver: SliverToBoxAdapter(
                          child: _buildSearchResults(
                            context, state, crossAxisCount, cardAspect,
                          ),
                        ),
                      ),
                    ] else ...[
                      SliverToBoxAdapter(
                        child: _buildSectionTitle(
                          title: 'Recent searches',
                          isNarrow: isNarrow,
                          actionLabel: state.recentSearches.isEmpty ? null : 'Clear all',
                          action: state.recentSearches.isEmpty
                              ? null
                              : () => context.read<SearchCubit>().clearRecentSearches(),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: _buildRecentSearches(context, state, isNarrow),
                      ),
                      SliverToBoxAdapter(
                        child: _buildSectionTitle(
                          title: 'Trending medicines',
                          isNarrow: isNarrow,
                        ),
                      ),
                      SliverPadding(
                        padding: EdgeInsets.fromLTRB(
                          isNarrow ? 12 : 16, 0, isNarrow ? 12 : 16, 24,
                        ),
                        sliver: SliverToBoxAdapter(
                          child: _buildTrendingMedicines(
                            context, state, crossAxisCount, cardAspect,
                          ),
                        ),
                      ),
                    ],
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, SearchState state, bool isNarrow) {
    final displayLocation = state.locationName ?? 'Loading location...';
    final hPad = isNarrow ? 12.0 : 16.0;
    final vPad = isNarrow ? 14.0 : 20.0;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: Container(
          margin: EdgeInsets.fromLTRB(hPad, hPad, hPad, 0),
          padding: EdgeInsets.all(vPad),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primaryLight, AppColors.primary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(isNarrow ? 18 : 24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Search medicine',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: isNarrow ? 18 : null,
                ),
              ),
              SizedBox(height: isNarrow ? 12 : 18),
              _buildSearchBar(context, state),
              SizedBox(height: isNarrow ? 12 : 18),
              _buildLocationCard(context, displayLocation, isNarrow),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context, SearchState state) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: TextField(
        controller: _searchController,
        onSubmitted: (query) {
          if (query.trim().isNotEmpty) {
            context.read<SearchCubit>().searchDrugs(query);
          }
        },
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: 'Brand, generic or active ingredient',
          hintStyle: const TextStyle(color: AppColors.textHint, fontSize: 13),
          prefixIcon: const Icon(Icons.search, color: AppColors.primary),
          suffixIcon: state.searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close, color: AppColors.primary),
                  onPressed: () {
                    _searchController.clear();
                    context.read<SearchCubit>().clearSearchResults();
                  },
                )
              : IconButton(
                  icon: const Icon(Icons.filter_list, color: AppColors.primary),
                  onPressed: () {},
                ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        ),
      ),
    );
  }

  Widget _buildLocationCard(
    BuildContext context,
    String displayLocation,
    bool isNarrow,
  ) {
    return Container(
      padding: EdgeInsets.all(isNarrow ? 12 : 16),
      decoration: BoxDecoration(
        color: AppColors.primaryContainer,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: isNarrow ? 36 : 44,
            height: isNarrow ? 36 : 44,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.location_on_outlined,
              color: AppColors.primary,
              size: isNarrow ? 18 : 22,
            ),
          ),
          SizedBox(width: isNarrow ? 10 : 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Current location',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
                const SizedBox(height: 2),
                Text(
                  displayLocation,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: isNarrow ? 13 : 15,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => _showManualLocationDialog(context),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
              textStyle: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: isNarrow ? 12 : 14,
              ),
              padding: EdgeInsets.symmetric(horizontal: isNarrow ? 6 : 12),
            ),
            child: const Text('Change'),
          ),
        ],
      ),
    );
  }

  Future<void> _showManualLocationDialog(BuildContext context) async {
    final controller = TextEditingController();
    final cubit = context.read<SearchCubit>();

    final confirmed = await showDialog<String>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 28,
            vertical: 24,
          ),
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
                        Icons.location_on_outlined,
                        color: AppColors.primary,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Enter your location',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(dialogContext).pop(null),
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
                TextField(
                  controller: controller,
                  autofocus: true,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (val) {
                    if (val.trim().isNotEmpty) {
                      Navigator.of(dialogContext).pop(val.trim());
                    }
                  },
                  decoration: InputDecoration(
                    hintText: 'e.g. Cairo, Giza, Fayoum...',
                    hintStyle: const TextStyle(
                      color: AppColors.textHint,
                      fontSize: 13,
                    ),
                    prefixIcon: const Icon(
                      Icons.search,
                      color: AppColors.primary,
                      size: 18,
                    ),
                    filled: true,
                    fillColor: AppColors.surfaceVariant,
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 14,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                        color: AppColors.primary,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(dialogContext).pop(null),
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
                        onPressed: () {
                          final val = controller.text.trim();
                          if (val.isNotEmpty) {
                            Navigator.of(dialogContext).pop(val);
                          }
                        },
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
                          'Confirm',
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
      },
    );

    if (confirmed != null && confirmed.isNotEmpty && context.mounted) {
      cubit.updateLocationName(confirmed);
    }
  }

  Widget _buildSectionTitle({
    required String title,
    required bool isNarrow,
    String? actionLabel,
    VoidCallback? action,
  }) {
    final hPad = isNarrow ? 12.0 : 16.0;
    return Padding(
      padding: EdgeInsets.fromLTRB(hPad, isNarrow ? 18 : 24, hPad, 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: isNarrow ? 16 : 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (actionLabel != null && action != null)
            TextButton(
              onPressed: action,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
                padding: EdgeInsets.symmetric(horizontal: isNarrow ? 6 : 12),
              ),
              child: Text(
                actionLabel,
                style: TextStyle(fontSize: isNarrow ? 12 : 14),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRecentSearches(
    BuildContext context,
    SearchState state,
    bool isNarrow,
  ) {
    final hPad = isNarrow ? 12.0 : 16.0;

    if (state.recentSearches.isEmpty) {
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: hPad, vertical: 12),
        child: const Text(
          'Your recent searches will appear here.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: hPad),
      child: Column(
        children: state.recentSearches.map((term) {
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.border),
            ),
            child: ListTile(
              onTap: () {
                _searchController.text = term;
                context.read<SearchCubit>().searchDrugs(term);
              },
              contentPadding: EdgeInsets.symmetric(
                horizontal: isNarrow ? 12 : 16,
                vertical: isNarrow ? 2 : 6,
              ),
              leading: const Icon(Icons.history, color: AppColors.primary),
              title: Text(
                term,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: isNarrow ? 13 : 14,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              trailing: IconButton(
                icon: const Icon(Icons.close, color: AppColors.textSecondary, size: 18),
                onPressed: () => context.read<SearchCubit>().removeRecentSearch(term),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTrendingMedicines(
    BuildContext context,
    SearchState state,
    int crossAxisCount,
    double cardAspect,
  ) {
    if (state.status == SearchStatus.loading) {
      return const Padding(
        padding: EdgeInsets.only(top: 16),
        child: LoadingWidget(message: 'Loading trending medicines...'),
      );
    }

    if (state.status == SearchStatus.error) {
      return Padding(
        padding: const EdgeInsets.only(top: 16),
        child: Center(
          child: Text(
            state.errorMessage ?? 'Unable to load trending medicines.',
            style: const TextStyle(color: AppColors.error, fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    if (state.trending.isEmpty) {
      return const Padding(
        padding: EdgeInsets.only(top: 16),
        child: Center(
          child: Text(
            'No trending medicines available right now.',
            style: TextStyle(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return _buildDrugGrid(
      drugs: state.trending,
      crossAxisCount: crossAxisCount,
      cardAspect: cardAspect,
    );
  }

  Widget _buildSearchResults(
    BuildContext context,
    SearchState state,
    int crossAxisCount,
    double cardAspect,
  ) {
    if (state.drugSearchStatus == DrugSearchStatus.loading) {
      return Padding(
        padding: const EdgeInsets.only(top: 16),
        child: LoadingWidget(message: 'Searching for ${state.searchQuery}...'),
      );
    }

    if (state.drugSearchStatus == DrugSearchStatus.error) {
      final message = state.searchErrorMessage?.isNotEmpty == true
          ? state.searchErrorMessage!
          : 'Unable to search medicines.';
      return Padding(
        padding: const EdgeInsets.only(top: 16),
        child: Center(
          child: Text(
            message,
            style: const TextStyle(color: AppColors.error, fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    if (state.drugSearchStatus == DrugSearchStatus.loaded &&
        state.searchResults.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 16),
        child: Center(
          child: Text(
            'No medicines found for "${state.searchQuery}".',
            style: const TextStyle(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    if (state.searchResults.isEmpty) return const SizedBox.shrink();

    return _buildDrugGrid(
      drugs: state.searchResults,
      crossAxisCount: crossAxisCount,
      cardAspect: cardAspect,
    );
  }

  Widget _buildDrugGrid({
    required List<TrendingDrugModel> drugs,
    required int crossAxisCount,
    required double cardAspect,
  }) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: drugs.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 12,
            mainAxisSpacing: 14,
            childAspectRatio: cardAspect,
          ),
          itemBuilder: (context, index) {
            return TrendingDrugCard(drug: drugs[index]);
          },
        ),
      ),
    );
  }
}