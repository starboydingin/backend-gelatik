import 'package:flutter/material.dart';

enum GelatikIllustration { muliMeghanai }

class IllustrationAsset extends StatelessWidget {
  final GelatikIllustration illustration;
  final double? width;
  final double? height;
  final BoxFit fit;
  final String? semanticLabel;

  const IllustrationAsset({
    super.key,
    this.illustration = GelatikIllustration.muliMeghanai,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.semanticLabel = 'Ilustrasi Muli dan Meghanai Lampung',
  });

  String get _path => switch (illustration) {
    GelatikIllustration.muliMeghanai =>
      'assets/images/illustrations/muli-meghanai-guides.png',
  };

  @override
  Widget build(BuildContext context) => Semantics(
    image: true,
    label: semanticLabel,
    child: Image.asset(
      _path,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (_, _, _) => SizedBox(
        width: width,
        height: height,
        child: const Icon(Icons.people_alt_outlined, size: 44),
      ),
    ),
  );
}
