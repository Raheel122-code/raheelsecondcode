class ApiConstants {
  static const String baseUrl =
      'https://raheelbackend2025-djaefrbdducch4f3.eastus-01.azurewebsites.net/api';
  static const int timeoutSeconds = 30;

  // Auth endpoints
  static const String register = '/auth/register';
  static const String login = '/auth/login';
  static const String currentUser = '/auth/current';

  // Media endpoints
  static const String uploadMedia = '/media/upload';
  static const String getFeed = '/media/feed';
  static const String getCreatorFeed = '/media/creator';
  static String getMediaById(String id) => '/media/$id';
  static String getMediaStats(String id) => '/media/$id/stats';
  static String addComment(String id) => '/media/$id/comment';
  static String rateMedia(String id) => '/media/$id/rate';

  // User endpoints
  static const String uploadProfilePicture = '/users/profile-picture';
}
