// Web-only PublicStuff embed via iframe (package:web).
import 'package:web/web.dart' as web;
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';

bool _registered = false;

Widget buildPublicStuffEmbed() {
  if (!_registered) {
    ui_web.platformViewRegistry.registerViewFactory(
      'publicstuff-iframe',
      (int viewId) {
        final iframe = web.HTMLIFrameElement()
          ..src = 'https://iframe.publicstuff.com/#?client_id=1000167'
          ..style.border = '0'
          ..width = '100%'
          ..height = '420';
        return iframe as Object;
      },
    );
    _registered = true;
  }

  return SizedBox(
    height: 420,
    child: const HtmlElementView(viewType: 'publicstuff-iframe'),
  );
}
