// 서버 AdPlacement enum과 1:1로 대응한다. AdBanner 위젯이 삽입되는 6개 화면 자리.
enum AdPlacement {
  today,
  productList,
  articleList,
  communityList,
  productDetail,
  postDetail;

  String get apiValue => switch (this) {
        AdPlacement.today => 'TODAY',
        AdPlacement.productList => 'PRODUCT_LIST',
        AdPlacement.articleList => 'ARTICLE_LIST',
        AdPlacement.communityList => 'COMMUNITY_LIST',
        AdPlacement.productDetail => 'PRODUCT_DETAIL',
        AdPlacement.postDetail => 'POST_DETAIL',
      };

  String get label => switch (this) {
        AdPlacement.today => '투데이',
        AdPlacement.productList => '쇼핑 목록',
        AdPlacement.articleList => '육아정보 목록',
        AdPlacement.communityList => '커뮤니티 목록',
        AdPlacement.productDetail => '상품 상세',
        AdPlacement.postDetail => '게시글 상세',
      };

  static AdPlacement fromApiValue(String value) => switch (value) {
        'TODAY' => AdPlacement.today,
        'PRODUCT_LIST' => AdPlacement.productList,
        'ARTICLE_LIST' => AdPlacement.articleList,
        'COMMUNITY_LIST' => AdPlacement.communityList,
        'PRODUCT_DETAIL' => AdPlacement.productDetail,
        'POST_DETAIL' => AdPlacement.postDetail,
        _ => AdPlacement.today,
      };
}

class Ad {
  const Ad({
    required this.id,
    required this.placement,
    required this.title,
    required this.imageUrl,
    required this.linkUrl,
    required this.isActive,
    required this.sortOrder,
  });

  final String id;
  final AdPlacement placement;
  final String title;
  final String imageUrl;
  final String? linkUrl;
  final bool isActive;
  final int sortOrder;

  factory Ad.fromJson(Map<String, dynamic> json) => Ad(
        id: json['id'] as String,
        placement: AdPlacement.fromApiValue(json['placement'] as String),
        title: json['title'] as String,
        imageUrl: json['imageUrl'] as String,
        linkUrl: json['linkUrl'] as String?,
        isActive: json['isActive'] as bool,
        sortOrder: json['sortOrder'] as int,
      );
}
