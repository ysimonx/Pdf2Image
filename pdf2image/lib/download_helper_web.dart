import 'dart:convert';
import 'dart:typed_data';
import 'package:web/web.dart' as web;

void downloadImage(Uint8List imageBytes, String fileName) {
  // Encoder l'image en base64
  final base64Image = base64Encode(imageBytes);

  // Créer un lien de téléchargement et cliquer pour déclencher le téléchargement
  final anchor = web.document.createElement('a') as web.HTMLAnchorElement;
  anchor.href = 'data:image/png;base64,$base64Image';
  anchor.download = fileName;
  anchor.click();
}
