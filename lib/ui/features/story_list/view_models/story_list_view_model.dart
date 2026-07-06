import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:my_morning_coffee/data/models/hn_story.dart';
import 'package:my_morning_coffee/data/services/hn_api_service.dart';

class StoryListViewModel extends ChangeNotifier {
  final HnApiService _apiService;
  final http.Client _client;

  StoryListViewModel({
    http.Client? client,
    HnApiService? apiService,
  }) : this._internal(
          client: client ?? http.Client(),
          apiService: apiService,
        );

  StoryListViewModel._internal({
    required http.Client client,
    HnApiService? apiService,
  })  : _client = client,
        _apiService = apiService ?? HnApiService(client: client);

  List<HnStory> _stories = [];
  List<HnStory> get stories => _stories;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isLoadingMore = false;
  bool get isLoadingMore => _isLoadingMore;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  int _currentPage = 0;
  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  bool _hasMore = true;
  bool get hasMore => _hasMore;

  Timer? _searchDebounce;

  /// Loads the initial list of stories.
  Future<void> fetchInitialStories({bool showLoadingIndicator = true}) async {
    if (showLoadingIndicator) {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
    }

    try {
      _currentPage = 0;
      final fetched = await _apiService.fetchStories(
        page: _currentPage,
        query: _searchQuery,
      );

      _stories = fetched;
      // If we got fewer than 20 stories, we probably reached the end.
      _hasMore = fetched.length >= 20;
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _stories = [];
      _hasMore = false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Fetches the next page of stories for infinite scrolling.
  Future<void> loadMoreStories() async {
    if (_isLoadingMore || !_hasMore) return;

    _isLoadingMore = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final nextPage = _currentPage + 1;
      final fetched = await _apiService.fetchStories(
        page: nextPage,
        query: _searchQuery,
      );

      if (fetched.isEmpty) {
        _hasMore = false;
      } else {
        // Filter out duplicates (if any) based on objectId
        final existingIds = _stories.map((s) => s.objectId).toSet();
        final newStories = fetched
            .where((s) => !existingIds.contains(s.objectId))
            .toList();

        _stories.addAll(newStories);
        _currentPage = nextPage;
        _hasMore = fetched.length >= 20;
      }
    } catch (e) {
      // Don't clear existing stories on load more error, just capture error
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  /// Sets the search query and triggers a debounced search.
  void setSearchQuery(String query) {
    if (_searchQuery == query) return;
    _searchQuery = query;

    // Debounce API calls by 500ms when typing
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 500), () {
      fetchInitialStories(showLoadingIndicator: true);
    });
  }

  /// Refreshes the feed.
  Future<void> refresh() async {
    await fetchInitialStories(showLoadingIndicator: false);
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _client.close();
    super.dispose();
  }
}
