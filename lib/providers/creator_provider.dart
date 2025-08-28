import 'dart:io';
import 'package:flutter/foundation.dart';
import '../features/creator/services/creator_service.dart';
import '../features/feed/models/media_model.dart';

enum CreatorStatus { initial, loading, loaded, error }

class PostStats {
  final int totalComments;
  final int totalRatings;
  final double averageRating;
  final Map<String, int> ratingDistribution;
  final List<String> recentComments;

  PostStats({
    required this.totalComments,
    required this.totalRatings,
    required this.averageRating,
    required this.ratingDistribution,
    required this.recentComments,
  });

  factory PostStats.fromJson(Map<String, dynamic> json) {
    return PostStats(
      totalComments: json['totalComments'] as int,
      totalRatings: json['totalRatings'] as int,
      averageRating: json['averageRating'] as double,
      ratingDistribution: Map<String, int>.from(json['ratingDistribution']),
      recentComments: List<String>.from(json['recentComments']),
    );
  }
}

class CreatorFeedResponse {
  final List<MediaModel> videos;
  final int currentPage;
  final bool hasMore;
  final int totalPages;
  final int total;

  CreatorFeedResponse({
    required this.videos,
    required this.currentPage,
    required this.hasMore,
    required this.totalPages,
    required this.total,
  });
}

class CreatorProvider with ChangeNotifier {
  final CreatorService _creatorService;
  CreatorStatus _status = CreatorStatus.initial;
  String? _error;
  PostStats? _stats;
  List<MediaModel> _posts = [];
  int _currentPage = 1;
  bool _hasMore = true;
  int _totalPages = 1;
  int _total = 0;

  CreatorProvider({CreatorService? creatorService})
    : _creatorService = creatorService ?? CreatorService();

  CreatorStatus get status => _status;
  String? get error => _error;
  PostStats? get stats => _stats;
  List<MediaModel> get posts => _posts;
  bool get hasMore => _hasMore;
  int get totalPosts => _total;

  Future<void> loadInitialData(String userId) async {
    if (userId.isEmpty) {
      _error = 'User ID is required';
      _status = CreatorStatus.error;
      notifyListeners();
      return;
    }

    if (_status == CreatorStatus.loading) return;

    _status = CreatorStatus.loading;
    _error = null;
    notifyListeners();

    try {
      // Get creator feed for posts
      final feedResponse = await _creatorService.getCreatorFeed(userId);

      // Get stats from first post if available
      PostStats? newStats;
      if (feedResponse['videos'] is List<MediaModel> &&
          (feedResponse['videos'] as List<MediaModel>).isNotEmpty) {
        final statsData = await _creatorService.getPostStats(
          (feedResponse['videos'] as List<MediaModel>)[0].id,
        );
        newStats = PostStats.fromJson(statsData);
      }

      // Update state only if still mounted and status hasn't changed
      if (_status == CreatorStatus.loading) {
        _posts = (feedResponse['videos'] as List<MediaModel>);
        _currentPage = feedResponse['pagination']['currentPage'] as int;
        _hasMore = feedResponse['pagination']['hasMore'] as bool;
        _totalPages = feedResponse['pagination']['totalPages'] as int;
        _total = feedResponse['pagination']['total'] as int;
        _stats = newStats;
        _status = CreatorStatus.loaded;
        notifyListeners();
      }
    } catch (e) {
      // Only update error state if still in loading state
      if (_status == CreatorStatus.loading) {
        _status = CreatorStatus.error;
        _error = e.toString();
        notifyListeners();
      }
    }
  }

  Future<void> loadMore(String userId) async {
    if (_status == CreatorStatus.loading || !_hasMore) return;

    final previousStatus = _status;
    _status = CreatorStatus.loading;
    notifyListeners();

    try {
      final feedResponse = await _creatorService.getCreatorFeed(
        userId,
        page: _currentPage + 1,
      );

      // Update state only if status hasn't changed during the request
      if (_status == CreatorStatus.loading) {
        final newPosts = feedResponse['videos'] as List<MediaModel>;
        _posts.addAll(newPosts);
        _currentPage = feedResponse['pagination']['currentPage'] as int;
        _hasMore = feedResponse['pagination']['hasMore'] as bool;
        _totalPages = feedResponse['pagination']['totalPages'] as int;
        _total = feedResponse['pagination']['total'] as int;
        _status = CreatorStatus.loaded;
        notifyListeners();
      }
    } catch (e) {
      // Restore previous status on error, unless already changed
      if (_status == CreatorStatus.loading) {
        _status = previousStatus;
        _error = e.toString();
        notifyListeners();
      }
    }
  }

  Future<void> uploadVideo({
    required String title,
    required String caption,
    required String ageRating,
    required dynamic video, // File for mobile, XFile for web
    required dynamic thumbnail, // File for mobile, XFile for web
  }) async {
    try {
      _status = CreatorStatus.loading;
      notifyListeners();

      final newPost = await _creatorService.uploadVideo(
        title: title,
        caption: caption,
        ageRating: ageRating,
        videoPath: kIsWeb ? video.path : video.path,
        thumbnailPath: kIsWeb ? thumbnail.path : thumbnail.path,
      );

      _posts.insert(0, newPost);
      _total++;

      // Update stats if we have them
      if (_stats != null) {
        final newStats = await _creatorService.getPostStats(newPost.id);
        _stats = PostStats.fromJson(newStats);
      }

      _status = CreatorStatus.loaded;
    } catch (e) {
      _status = CreatorStatus.error;
      _error = e.toString();
    }
    notifyListeners();
  }

  Future<void> updateProfilePicture(File image) async {
    try {
      await _creatorService.updateProfilePicture(image.path);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }
}
