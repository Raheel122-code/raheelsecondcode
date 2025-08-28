class CreatorStatsModel {
  final int totalPosts;
  final double averageRating;
  final int totalRatings;
  final int totalComments;
  final Map<String, int> ratingDistribution;

  CreatorStatsModel({
    required this.totalPosts,
    required this.averageRating,
    required this.totalRatings,
    required this.totalComments,
    required this.ratingDistribution,
  });

  factory CreatorStatsModel.fromJson(Map<String, dynamic> json) {
    final ratingDistMap =
        (json['ratingDistribution'] as Map<String, dynamic>? ?? {}).map(
          (key, value) => MapEntry(key, value as int),
        );

    return CreatorStatsModel(
      totalPosts: json['totalPosts'] ?? 0,
      averageRating: (json['averageRating'] ?? 0.0).toDouble(),
      totalRatings: json['totalRatings'] ?? 0,
      totalComments: json['totalComments'] ?? 0,
      ratingDistribution: ratingDistMap,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalPosts': totalPosts,
      'averageRating': averageRating,
      'totalRatings': totalRatings,
      'totalComments': totalComments,
      'ratingDistribution': ratingDistribution,
    };
  }
}
