import 'package:flutter/material.dart';

import 'openchargemap_embed_stub.dart'
    if (dart.library.html) 'openchargemap_embed_web.dart';

/// Platform-aware embed for OpenChargeMap. On web, renders an iframe.
/// On mobile/desktop, shows a CTA that opens the external map.
class OpenChargeMapEmbed extends StatelessWidget {
  const OpenChargeMapEmbed({
    super.key,
    required this.onOpenExternal,
  });

  final VoidCallback onOpenExternal;

  @override
  Widget build(BuildContext context) {
    // kIsWeb is not strictly needed because the conditional import
    // handles platform differences, but we keep it clear for readers.
    return buildOpenChargeMapEmbed(onOpenExternal);
  }
}
