import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/illustration_asset.dart';
import '../theme/auth_typography.dart';

/// Shared authentication hero with reserved space for branding and artwork.
/// The light mist surface keeps both the dark Gelatik logo and the colourful
/// Lampung illustration readable on narrow screens.
class AuthHeroCard extends StatelessWidget {
  final Key logoKey;
  final String title;
  final String subtitle;

  const AuthHeroCard({
    super.key,
    required this.logoKey,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) => Container(
    key: const Key('auth-hero-card'),
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      color: AppColors.colorAuthHero,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: AppColors.colorBorder),
      boxShadow: const [
        BoxShadow(
          color: Color(0x0D0F172A),
          blurRadius: 16,
          offset: Offset(0, 6),
        ),
      ],
    ),
    child: LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 330;
        final illustrationWidth = compact ? 82.0 : 104.0;
        final illustrationHeight = compact ? 130.0 : 154.0;

        return Stack(
          children: [
            Positioned(
              right: -30,
              top: -38,
              child: Container(
                width: 118,
                height: 118,
                decoration: const BoxDecoration(
                  color: AppColors.colorAuthHeroAccent,
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 10, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 18),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Image.asset(
                            'assets/images/logo-tanpabackground.png',
                            key: logoKey,
                            width: compact ? 112 : 126,
                            fit: BoxFit.contain,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            title,
                            softWrap: true,
                            style:
                                AuthTypography.brandTitle(
                                  context,
                                  fontSize: compact ? 10.5 : 12,
                                ).copyWith(
                                  color: AppColors.colorPrimary,
                                  letterSpacing: compact ? 0.9 : 1.2,
                                  height: 1.3,
                                ),
                          ),
                          const SizedBox(height: 7),
                          Text(
                            subtitle,
                            softWrap: true,
                            style: const TextStyle(
                              color: AppColors.colorTextMuted,
                              fontSize: 12,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  IllustrationAsset(
                    width: illustrationWidth,
                    height: illustrationHeight,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    ),
  );
}
