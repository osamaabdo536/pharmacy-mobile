import 'package:equatable/equatable.dart';
import 'package:geolocator/geolocator.dart';

import '../data/models/trending_drug_model.dart';

enum SearchStatus { initial, loading, loaded, error }

enum DrugSearchStatus { initial, loading, loaded, error }

class SearchState extends Equatable {
  final SearchStatus status;
  final DrugSearchStatus drugSearchStatus;
  final List<TrendingDrugModel> trending;
  final List<TrendingDrugModel> searchResults;
  final String searchQuery;
  final String? errorMessage;
  final String? searchErrorMessage;
  final Position? currentLocation;
  final String? locationName;
  final List<String> recentSearches;

  const SearchState({
    this.status = SearchStatus.initial,
    this.drugSearchStatus = DrugSearchStatus.initial,
    this.trending = const [],
    this.searchResults = const [],
    this.searchQuery = '',
    this.errorMessage,
    this.searchErrorMessage,
    this.currentLocation,
    this.locationName,
    this.recentSearches = const [],
  });

  SearchState copyWith({
    SearchStatus? status,
    DrugSearchStatus? drugSearchStatus,
    List<TrendingDrugModel>? trending,
    List<TrendingDrugModel>? searchResults,
    String? searchQuery,
    String? errorMessage,
    String? searchErrorMessage,
    Position? currentLocation,
    String? locationName,
    List<String>? recentSearches,
  }) {
    return SearchState(
      status: status ?? this.status,
      drugSearchStatus: drugSearchStatus ?? this.drugSearchStatus,
      trending: trending ?? this.trending,
      searchResults: searchResults ?? this.searchResults,
      searchQuery: searchQuery ?? this.searchQuery,
      errorMessage: errorMessage ?? this.errorMessage,
      searchErrorMessage: searchErrorMessage ?? this.searchErrorMessage,
      currentLocation: currentLocation ?? this.currentLocation,
      locationName: locationName ?? this.locationName,
      recentSearches: recentSearches ?? this.recentSearches,
    );
  }

  @override
  List<Object?> get props => [
    status,
    drugSearchStatus,
    trending,
    searchResults,
    searchQuery,
    errorMessage,
    searchErrorMessage,
    currentLocation,
    locationName,
    recentSearches,
  ];
}
