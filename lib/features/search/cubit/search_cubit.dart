import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geocoding/geocoding.dart' as geo;
import 'package:geolocator/geolocator.dart';

import '../../../core/errors/failures.dart';
import '../../../core/utils/location_service.dart';
import '../data/search_repository.dart';
import 'search_state.dart';

class SearchCubit extends Cubit<SearchState> {
  final SearchRepository _repository;
  final LocationService _locationService;

  SearchCubit(this._repository, this._locationService)
    : super(const SearchState());

  Future<void> initializeSearch() async {
    await loadTrending(limit: 8);
    await loadLocation();
  }

  Future<void> loadTrending({int limit = 8}) async {
    emit(state.copyWith(status: SearchStatus.loading, errorMessage: null));
    try {
      final trending = await _repository.getTrending(limit: limit);
      emit(state.copyWith(status: SearchStatus.loaded, trending: trending));
    } catch (error) {
      emit(
        state.copyWith(
          status: SearchStatus.error,
          errorMessage: _messageFromError(error),
        ),
      );
    }
  }

  Future<void> loadLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission =
            await Geolocator.requestPermission(); // ده اللي بيظهر الـ dialog
        if (permission == LocationPermission.denied ||
            permission == LocationPermission.deniedForever) {
          emit(state.copyWith(locationName: 'Location not available'));
          return;
        }
      }

      final position = await _locationService.getCurrentPosition();
      if (position != null) {
        final locationName = await _getLocationName(position);
        emit(
          state.copyWith(currentLocation: position, locationName: locationName),
        );
      }
    } catch (_) {}
  }

  Future<String> _getLocationName(Position position) async {
    try {
      final placemarks = await geo.placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        final parts = [
          place.thoroughfare,
          place.locality,
        ].where((p) => p != null && p.isNotEmpty).toList();

        return parts.isNotEmpty ? parts.join(', ') : 'Unknown location';
      }
      return 'Unknown location';
    } catch (_) {
      return 'Unknown location';
    }
  }

  void addRecentSearch(String query) {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;

    final updated = [
      trimmed,
      ...state.recentSearches,
    ].toSet().toList().take(10).toList();

    emit(state.copyWith(recentSearches: updated));
  }

  void removeRecentSearch(String query) {
    final updated = state.recentSearches.where((s) => s != query).toList();
    emit(state.copyWith(recentSearches: updated));
  }

  void clearRecentSearches() {
    emit(state.copyWith(recentSearches: []));
  }

  Future<void> updateLocation(Position position) async {
    final locationName = await _getLocationName(position);
    emit(state.copyWith(currentLocation: position, locationName: locationName));
  }

  String _messageFromError(Object error) {
    if (error is Failure) return error.message;
    return error.toString();
  }
}
