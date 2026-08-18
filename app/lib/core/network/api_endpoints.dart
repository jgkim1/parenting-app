class ApiEndpoints {
  ApiEndpoints._();

  // 웹(Edge/Chrome)에서 로컬 백엔드로 접속할 때 쓰는 기본 주소.
  // 안드로이드 에뮬레이터에서 로컬 백엔드에 접속하려면 localhost 대신 10.0.2.2를 사용해야 한다.
  // 백엔드를 Node.js(포트 4000)에서 Spring Boot(포트 8080)로 교체하면서 함께 변경함.
  static const String baseUrl = 'http://localhost:8080/api';

  static const String signup = '/auth/signup';
  static const String login = '/auth/login';
  static const String refresh = '/auth/refresh';
  static const String logout = '/auth/logout';
  static const String kakaoLogin = '/auth/kakao';
  static const String googleLogin = '/auth/google';
  static const String me = '/users/me';

  static const String categories = '/categories';
  static const String products = '/products';
  static String product(String id) => '/products/$id';
  static String productReviews(String productId) => '/products/$productId/reviews';
  static String review(String id) => '/reviews/$id';

  static const String articleCategories = '/article-categories';
  static const String articles = '/articles';
  static String article(String id) => '/articles/$id';

  static const String cart = '/cart';
  static const String cartItems = '/cart/items';
  static String cartItem(String productId) => '/cart/items/$productId';

  static const String orders = '/orders';
  static String order(String id) => '/orders/$id';

  static const String posts = '/posts';
  static String post(String id) => '/posts/$id';
  static String postComments(String postId) => '/posts/$postId/comments';
  static String postLike(String postId) => '/posts/$postId/like';
  static String comment(String id) => '/comments/$id';

  static const String uploads = '/uploads';

  static const String children = '/children';
  static String child(String id) => '/children/$id';

  static const String ads = '/ads';
  static String ad(String id) => '/ads/$id';
}
