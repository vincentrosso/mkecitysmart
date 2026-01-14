import 'package:flutter/material.dart';

import 'publicstuff_embed_stub.dart'
    if (dart.library.html) 'publicstuff_embed_web.dart';

/// Platform-aware embed for PublicStuff (Milwaukee 311).
class PublicStuffEmbed extends StatelessWidget {
  const PublicStuffEmbed({super.key});

  @override
  Widget build(BuildContext context) {
    return buildPublicStuffEmbed();
  }
}
