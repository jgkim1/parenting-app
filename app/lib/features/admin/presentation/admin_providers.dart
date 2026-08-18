import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../articles/domain/article.dart';
import '../../articles/presentation/articles_controller.dart' show articlesRepositoryProvider;
import '../../auth/presentation/auth_controller.dart' show dioProvider;
import '../../products/domain/product.dart';
import '../../products/presentation/products_controller.dart' show productsRepositoryProvider;
import '../data/ads_repository.dart';
import '../domain/ad.dart';

final adsRepositoryProvider = Provider<AdsRepository>((ref) {
  return AdsRepository(ref.watch(dioProvider));
});

// 관리자 목록 화면은 비활성/비공개 항목까지 모두 보여줘야 하므로 공개 목록 컨트롤러와는
// 별도로, 페이지네이션 없이 한 번에 넉넉히 불러오는 단순한 FutureProvider를 쓴다.
final adminProductsProvider = FutureProvider.autoDispose<List<Product>>((ref) async {
  final page = await ref
      .watch(productsRepositoryProvider)
      .fetchProducts(page: 1, includeInactive: true);
  return page.items;
});

final adminArticlesProvider = FutureProvider.autoDispose<List<Article>>((ref) async {
  final page = await ref
      .watch(articlesRepositoryProvider)
      .fetchArticles(page: 1, includeInactive: true);
  return page.items;
});

final adminAdsProvider = FutureProvider.autoDispose<List<Ad>>((ref) {
  return ref.watch(adsRepositoryProvider).fetchAds(includeInactive: true);
});

// AdBanner 위젯이 화면 자리별로 노출할 활성 광고를 조회할 때 쓴다.
final adsByPlacementProvider =
    FutureProvider.family.autoDispose<List<Ad>, AdPlacement>((ref, placement) {
  return ref.watch(adsRepositoryProvider).fetchAds(placement: placement);
});
