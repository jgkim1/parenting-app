import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../features/admin/domain/ad.dart';
import '../../features/admin/presentation/admin_providers.dart';

enum AdBannerStyle { banner, native }

// 관리자가 등록한 광고가 있으면 그 광고를, 없으면(또는 불러오는 중/실패 시) 플레이스홀더를
// 보여준다. 삽입 지점은 항상 placement별로 이 위젯을 거치도록 배선해뒀다.
class AdBanner extends ConsumerWidget {
  const AdBanner({required this.placement, this.style = AdBannerStyle.banner, super.key});

  final AdPlacement placement;
  final AdBannerStyle style;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final adsAsync = ref.watch(adsByPlacementProvider(placement));
    final ads = adsAsync.asData?.value ?? const [];
    final ad = ads.isNotEmpty ? ads.first : null;

    if (ad != null) {
      return _RealAdBanner(ad: ad, style: style);
    }
    return _PlaceholderAdBanner(style: style);
  }
}

class _RealAdBanner extends StatelessWidget {
  const _RealAdBanner({required this.ad, required this.style});

  final Ad ad;
  final AdBannerStyle style;

  Future<void> _openLink(BuildContext context) async {
    final uri = Uri.tryParse(ad.linkUrl!);
    if (uri == null) return;

    var opened = false;
    try {
      opened = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
        webOnlyWindowName: '_blank',
      );
    } catch (_) {
      opened = false;
    }

    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('링크를 열 수 없습니다.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final height = style == AdBannerStyle.banner ? 84.0 : 110.0;

    return GestureDetector(
      onTap: ad.linkUrl == null ? null : () => _openLink(context),
      child: Container(
        height: height,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              ad.imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => _PlaceholderAdBanner(style: style),
            ),
            Positioned(
              top: 6,
              left: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text('광고', style: Theme.of(context).textTheme.labelSmall),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlaceholderAdBanner extends StatelessWidget {
  const _PlaceholderAdBanner({required this.style});

  final AdBannerStyle style;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final height = style == AdBannerStyle.banner ? 84.0 : 110.0;

    return Container(
      height: height,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.campaign_outlined, color: colorScheme.onSurfaceVariant),
                const SizedBox(height: 4),
                Text(
                  '광고 영역',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          Positioned(
            top: 6,
            left: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text('광고', style: Theme.of(context).textTheme.labelSmall),
            ),
          ),
        ],
      ),
    );
  }
}
