import 'package:flutter/foundation.dart';
import '../features/feed/models/media_model.dart';
import '../features/feed/services/feed_service.dart';

enum FeedStatus { initial, loading, loaded, error }

class FeedProvider with ChangeNotifier {
  final FeedService _feedService;
  List<MediaModel> _posts = [];
  int _currentPage = 1;
  bool _hasMore = true;
  int _totalPages = 1;
  int _totalPosts = 0;
  FeedStatus _status = FeedStatus.initial;
  String? _error;

  FeedProvider({FeedService? feedService})
    : _feedService = feedService ?? FeedService() {
    _loadInitialFeed();
  }

  List<MediaModel> get posts => _posts;
  FeedStatus get status => _status;
  String? get error => _error;
  bool get hasMore => _hasMore;
  int get totalPosts => _totalPosts;
  int get currentPage => _currentPage;
  int get totalPages => _totalPages;

  Future<void> _loadInitialFeed() async {
    if (_status == FeedStatus.loading) return;

    try {
      _status = FeedStatus.loading;
      _error = null;
      notifyListeners();

      final response = await _feedService.getFeed(page: 1);
      _posts = response.media;
      _currentPage = response.pagination.currentPage;
      _hasMore = response.pagination.hasMore;
      _totalPages = response.pagination.totalPages;
      _totalPosts = response.pagination.total;
      _status = FeedStatus.loaded;
    } catch (e) {
      _status = FeedStatus.error;
      _error = e.toString();
    }
    notifyListeners();
  }

  Future<void> loadMore() async {
    if (_status == FeedStatus.loading || !_hasMore) return;

    try {
      _status = FeedStatus.loading;
      notifyListeners();

      final response = await _feedService.getFeed(page: _currentPage + 1);
      _posts.addAll(response.media);
      _currentPage = response.pagination.currentPage;
      _hasMore = response.pagination.hasMore;
      _totalPages = response.pagination.totalPages;
      _totalPosts = response.pagination.total;
      _status = FeedStatus.loaded;
    } catch (e) {
      _status = FeedStatus.error;
      _error = e.toString();
    }
    notifyListeners();
  }

  Future<void> addComment(String postId, String text) async {
    if (!RegExp(r'^[0-9a-fA-F]{24}$').hasMatch(postId)) {
      _error = 'Invalid post ID format';
      notifyListeners();
      return;
    }

    if (text.trim().isEmpty) {
      _error = 'Comment text cannot be empty';
      notifyListeners();
      return;
    }

    try {
      final updatedPost = await _feedService.addComment(postId, text);
      final postIndex = _posts.indexWhere((post) => post.id == postId);
      if (postIndex != -1) {
        _posts[postIndex] = updatedPost;
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> addRating(String postId, int rating) async {
    if (!RegExp(r'^[0-9a-fA-F]{24}$').hasMatch(postId)) {
      _error = 'Invalid post ID format';
      notifyListeners();
      return;
    }

    if (rating < 1 || rating > 10) {
      _error = 'Rating must be between 1 and 10';
      notifyListeners();
      return;
    }

    try {
      final updatedPost = await _feedService.addRating(postId, rating);
      final postIndex = _posts.indexWhere((post) => post.id == postId);
      if (postIndex != -1) {
        _posts[postIndex] = updatedPost;
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> refresh() => _loadInitialFeed();
}
