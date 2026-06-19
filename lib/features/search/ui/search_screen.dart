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
          SearchCubit(SearchRepository(), LocationService())
            ..initializeSearch(),
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
            final cardAspect = crossAxisCount == 2
                ? 2.8
                : (isNarrow ? 3.5 : 4.0);

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
                          isNarrow ? 12 : 16,
                          0,
                          isNarrow ? 12 : 16,
                          4,
                        ),
                        sliver: SliverToBoxAdapter(
                          child: _buildSearchResults(
                            context,
                            state,
                            crossAxisCount,
                            cardAspect,
                          ),
                        ),
                      ),
                    ] else ...[
                      SliverToBoxAdapter(
                        child: _buildSectionTitle(
                          title: 'Recent searches',
                          isNarrow: isNarrow,
                          icon: Icons.history,
                          actionLabel: state.recentSearches.isEmpty
                              ? null
                              : 'Clear All',
                          action: state.recentSearches.isEmpty
                              ? null
                              : () => context
                                    .read<SearchCubit>()
                                    .clearRecentSearches(),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: _buildRecentSearches(context, state, isNarrow),
                      ),
                      SliverToBoxAdapter(
                        child: _buildSectionTitle(
                          title: 'Trending medicines',
                          icon: Icons.trending_up,
                          isNarrow: isNarrow,
                        ),
                      ),
                      SliverPadding(
                        padding: EdgeInsets.fromLTRB(
                          isNarrow ? 12 : 16,
                          0,
                          isNarrow ? 12 : 16,
                          24,
                        ),
                        sliver: SliverToBoxAdapter(
                          child: _buildTrendingMedicines(
                            context,
                            state,
                            crossAxisCount,
                            cardAspect,
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
                  icon: const Icon(
                    Icons.filter_list,
                    color: AppColors.primary,
                  ),
                  onPressed: () {},
                ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 14,
            horizontal: 16,
          ),
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
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
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
        ],
      ),
    );
  }

  Widget _buildSectionTitle({
    required String title,
    required bool isNarrow,
    String? actionLabel,
    VoidCallback? action,
    IconData? icon,
  }) {
    final hPad = isNarrow ? 12.0 : 16.0;
    return Padding(
      padding: EdgeInsets.fromLTRB(hPad, isNarrow ? 18 : 24, hPad, 10),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, color: AppColors.primary, size: 18),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Text(
              title.toUpperCase(),
              style: TextStyle(
                fontSize: isNarrow ? 12 : 13,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
                letterSpacing: 0.8,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (actionLabel != null && action != null)
            TextButton(
              onPressed: action,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
                padding: EdgeInsets.symmetric(
                  horizontal: isNarrow ? 6 : 12,
                ),
              ),
              child: Text(
                actionLabel,
                style: TextStyle(
                  fontSize: isNarrow ? 12 : 13,
                  fontWeight: FontWeight.w600,
                ),
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
          return InkWell(
            onTap: () {
              _searchController.text = term;
              context.read<SearchCubit>().searchDrugs(term);
            },
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isNarrow ? 4 : 0,
                vertical: isNarrow ? 9 : 12,
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.search,
                    color: AppColors.textSecondary,
                    size: 19,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      term,
                      style: TextStyle(
                        fontSize: isNarrow ? 14 : 16,
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    onPressed: () =>
                        context.read<SearchCubit>().removeRecentSearch(term),
                    icon: const Icon(Icons.close, size: 18),
                    color: AppColors.textSecondary,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints.tightFor(
                      width: 32,
                      height: 32,
                    ),
                  ),
                ],
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
        child: LoadingWidget(
          message: 'Searching for ${state.searchQuery}...',
        ),
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