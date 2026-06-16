import 'package:equatable/equatable.dart';
import 'package:geolocator/geolocator.dart';

import '../data/models/trending_drug_model.dart';

enum SearchStatus { initial, loading, loaded, error }

class SearchState extends Equatable {
  final SearchStatus status;
  final List<TrendingDrugModel> trending;
  final String? errorMessage;
  final Position? currentLocation;
  final String? locationName;
  final List<String> recentSearches;

  const SearchState({
    this.status = SearchStatus.initial,
    this.trending = const [],
    this.errorMessage,
    this.currentLocation,
    this.locationName,
    this.recentSearches = const [],
  });

  SearchState copyWith({
    SearchStatus? status,
    List<TrendingDrugModel>? trending,
    String? errorMessage,
    Position? currentLocation,
    String? locationName,
    List<String>? recentSearches,
  }) {
    return SearchState(
      status: status ?? this.status,
      trending: trending ?? this.trending,
      errorMessage: errorMessage ?? this.errorMessage,
      currentLocation: currentLocation ?? this.currentLocation,
      locationName: locationName ?? this.locationName,
      recentSearches: recentSearches ?? this.recentSearches,
    );
  }

  @override
  List<Object?> get props => [status, trending, errorMessage, currentLocation, locationName, recentSearches];
}

