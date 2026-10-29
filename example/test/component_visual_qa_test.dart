import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fossui/app_ui.dart';
import 'package:fossui/fossui.dart';
import 'package:fossui_example/component_catalog.dart';

import 'catalog_overlay_test_utils.dart';

/// Optional visual evidence export; kept separate from regression baselines.
void main() {
  final output = Platform.environment['APPUI_QA_CAPTURE_DIR'];
  setUpAll(() async {
    if (output == null) return;
    final text = FontLoader('packages/fossui/Geist')
      ..addFont(
        File(
          '../fonts/Geist-Variable.ttf',
        ).readAsBytes().then((b) => b.buffer.asByteData()),
      );
    await text.load();
    final icons = FontLoader('packages/lucide_icons_flutter/Lucide')
      ..addFont(
        rootBundle.load('packages/lucide_icons_flutter/assets/lucide.ttf'),
      );
    await icons.load();
    await Directory(output).create(recursive: true);
  });

  for (final dark in [false, true]) {
    testWidgets('export every component in ${dark ? 'dark' : 'light'}', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(440, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final theme = dark ? AppThemeData.dark : AppThemeData.light;
      final images = <({String name, ui.Image image})>[];
      final openImages = <({String name, ui.Image image})>[];
      var page = 0;
      var openPage = 0;
      for (final entry in componentCatalog) {
        final key = GlobalKey();
        final viewportKey = GlobalKey();
        await tester.pumpWidget(
          RepaintBoundary(
            key: viewportKey,
            child: AppTheme(
              data: theme,
              child: WidgetsApp(
                debugShowCheckedModeBanner: false,
                color: theme.tokens.colors.background,
                pageRouteBuilder: <T>(settings, builder) => PageRouteBuilder<T>(
                  settings: settings,
                  pageBuilder: (context, _, _) => builder(context),
                ),
                home: MediaQuery(
                  data: const MediaQueryData(
                    size: Size(440, 900),
                    disableAnimations: true,
                  ),
                  child: FossToaster(
                    child: SizedBox.expand(
                      child: ColoredBox(
                        color: theme.tokens.colors.background,
                        child: SingleChildScrollView(
                          child: RepaintBoundary(
                            key: key,
                            child: ColoredBox(
                              color: theme.tokens.colors.background,
                              child: Padding(
                                padding: const EdgeInsets.all(20),
                                child: IconTheme(
                                  data: IconThemeData(
                                    color: theme.tokens.colors.foreground,
                                    size: 20,
                                  ),
                                  child: ComponentSample(id: entry.id),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 200));
        await tester.pump();
        expect(tester.takeException(), isNull, reason: entry.id);
        final boundary =
            key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        final image = await tester.runAsync(boundary.toImage);
        images.add((name: entry.name, image: image!));
        await tester.runAsync(() async {
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          await File(
            '$output/${entry.id}_${dark ? 'dark' : 'light'}.png',
          ).writeAsBytes(bytes!.buffer.asUint8List());
        });
        if (images.length == 6 || entry == componentCatalog.last) {
          page++;
          await tester.runAsync(() => _board(images, output!, dark, page));
          for (final item in images) {
            item.image.dispose();
          }
          images.clear();
        }
        if (catalogOverlayIds.contains(entry.id)) {
          await openCatalogOverlay(tester, entry.id);
          expect(tester.takeException(), isNull, reason: '${entry.id} open');
          final viewport =
              viewportKey.currentContext!.findRenderObject()!
                  as RenderRepaintBoundary;
          final openImage = await tester.runAsync(viewport.toImage);
          openImages.add((name: '${entry.name} · open', image: openImage!));
          await tester.runAsync(() async {
            final bytes = await openImage.toByteData(
              format: ui.ImageByteFormat.png,
            );
            await File(
              '$output/${entry.id}_open_${dark ? 'dark' : 'light'}.png',
            ).writeAsBytes(bytes!.buffer.asUint8List());
          });
          if (openImages.length == 6 || entry.id == catalogOverlayIds.last) {
            openPage++;
            await tester.runAsync(
              () => _board(openImages, output!, dark, openPage, prefix: 'open'),
            );
            for (final item in openImages) {
              item.image.dispose();
            }
            openImages.clear();
          }
        }
        await tester.pumpWidget(const SizedBox());
      }
    }, skip: output == null);
  }
}

Future<void> _board(
  List<({String name, ui.Image image})> images,
  String output,
  bool dark,
  int page, {
  String prefix = 'board',
}) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder)
    ..drawColor(
      dark ? const Color(0xFF08090B) : const Color(0xFFE2E3E8),
      BlendMode.src,
    );
  for (var i = 0; i < images.length; i++) {
    final item = images[i];
    final x = (i % 2) * 480.0 + 12;
    final y = (i ~/ 2) * 620.0 + 12;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, 456, 596),
        const Radius.circular(12),
      ),
      Paint()..color = dark ? const Color(0xFF1C1C1E) : const Color(0xFFFFFFFF),
    );
    TextPainter(
        text: TextSpan(
          text: '${item.name} · ${dark ? 'dark' : 'light'}',
          style: TextStyle(
            fontFamily: 'packages/fossui/Geist',
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: dark ? const Color(0xFFFFFFFF) : const Color(0xFF101012),
          ),
        ),
        textDirection: TextDirection.ltr,
      )
      ..layout(maxWidth: 428)
      ..paint(canvas, Offset(x + 14, y + 14))
      ..dispose();
    final scale = math.min<double>(
      1,
      math.min(428 / item.image.width, 532 / item.image.height),
    );
    canvas.drawImageRect(
      item.image,
      Rect.fromLTWH(
        0,
        0,
        item.image.width.toDouble(),
        item.image.height.toDouble(),
      ),
      Rect.fromLTWH(
        x + 14,
        y + 52,
        item.image.width * scale,
        item.image.height * scale,
      ),
      Paint(),
    );
  }
  final picture = recorder.endRecording();
  final board = await picture.toImage(960, 1860);
  final bytes = await board.toByteData(format: ui.ImageByteFormat.png);
  await File(
    '$output/${prefix}_${dark ? 'dark' : 'light'}_$page.png',
  ).writeAsBytes(bytes!.buffer.asUint8List());
  board.dispose();
  picture.dispose();
}
