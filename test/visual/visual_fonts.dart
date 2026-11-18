import 'dart:io';

import 'package:flutter/services.dart';

/// Apenas renderer de testes; não copia fontes para o aplicativo.
Future<void> loadFinancialVisualFonts() async {
  final fonts = Platform.environment['BOLSOZEN_FONT_DIR'];
  if (fonts == null) {
    throw StateError(
      'Informe BOLSOZEN_FONT_DIR apontando para material_fonts do SDK local.',
    );
  }
  final roboto = FontLoader('Roboto');
  for (final file in [
    'roboto-regular.ttf',
    'roboto-medium.ttf',
    'roboto-bold.ttf',
  ]) {
    roboto.addFont(
      Future.value(
        ByteData.sublistView(await File('$fonts/$file').readAsBytes()),
      ),
    );
  }
  await roboto.load();
  await (FontLoader('MaterialIcons')..addFont(
        Future.value(
          ByteData.sublistView(
            await File('$fonts/materialicons-regular.otf').readAsBytes(),
          ),
        ),
      ))
      .load();
  final emoji = File('C:/Windows/Fonts/seguiemj.ttf');
  if (await emoji.exists()) {
    await (FontLoader('Segoe UI Emoji')..addFont(
          Future.value(ByteData.sublistView(await emoji.readAsBytes())),
        ))
        .load();
  }
}
