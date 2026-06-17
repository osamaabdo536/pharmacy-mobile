import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';

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
            final crossAxisCount = constraints.maxWidth >= 360 ? 2 : 1;
            final cardAspect = crossAxisCount == 2 ? 1.55 : 2.25;

            return BlocBuilder<SearchCubit, SearchState>(
              builder: (context, state) {
                final hasActiveSearch =
                    state.drugSearchStatus != DrugSearchStatus.initial ||
                    state.searchQuery.isNotEmpty;

                return CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(child: _buildHeader(context, state)),
                    if (hasActiveSearch) ...[
                      SliverToBoxAdapter(
                        child: _buildSectionTitle(
                          title: 'Search results',
                          actionLabel: 'Clear',
                          action: () {
                            _searchController.clear();
                            context.read<SearchCubit>().clearSearchResults();
                          },
                        ),
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
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
                          actionLabel: state.recentSearches.isEmpty
                              ? null
                              : 'Clear all',
                          action: state.recentSearches.isEmpty
                              ? null
                              : () => context
                                    .read<SearchCubit>()
                                    .clearRecentSearches(),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: _buildRecentSearches(context, state),
                      ),
                      SliverToBoxAdapter(
                        child: _buildSectionTitle(title: 'Trending medicines'),
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
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

  Widget _buildHeader(BuildContext context, SearchState state) {
    final displayLocation = state.locationName ?? 'Loading location...';

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primaryLight, AppColors.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Search medicine',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 18),
          _buildSearchBar(context, state),
          const SizedBox(height: 18),
          _buildLocationCard(context, displayLocation),
        ],
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
          hintStyle: const TextStyle(color: AppColors.textHint),
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
          contentPadding: const EdgeInsets.symmetric(
            vertical: 16,
            horizontal: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildLocationCard(BuildContext context, String displayLocation) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryContainer,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.location_on_outlined,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Current location',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  displayLocation,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => _changeLocation(context),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
              textStyle: const TextStyle(fontWeight: FontWeight.w600),
            ),
            child: const Text('Change'),
          ),
        ],
      ),
    );
  }

  Future<void> _changeLocation(BuildContext context) async {
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );

      if (context.mounted) {
        await context.read<SearchCubit>().updateLocation(position);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not fetch location: $e')));
      }
    }
  }

  Widget _buildSectionTitle({
    required String title,
    String? actionLabel,
    VoidCallback? action,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const Spacer(),
          if (actionLabel != null && action != null)
            TextButton(
              onPressed: action,
              style: TextButton.styleFrom(foregroundColor: AppColors.primary),
              child: Text(actionLabel),
            ),
        ],
      ),
    );
  }

  Widget _buildRecentSearches(BuildContext context, SearchState state) {
    if (state.recentSearches.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Text(
          'Your recent searches will appear here.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
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
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 6,
              ),
              leading: const Icon(Icons.history, color: AppColors.primary),
              title: Text(
                term,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              trailing: IconButton(
                icon: const Icon(Icons.close, color: AppColors.textSecondary),
                onPressed: () =>
                    context.read<SearchCubit>().removeRecentSearch(term),
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
            style: const TextStyle(color: AppColors.error, fontSize: 15),
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
            style: const TextStyle(color: AppColors.error, fontSize: 15),
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

    if (state.searchResults.isEmpty) {
      return const SizedBox.shrink();
    }

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
            crossAxisSpacing: 16,
            mainAxisSpacing: 18,
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
