import 'dart:typed_data';

void downloadImage(Uint8List imageBytes, String fileName) {
  // Cette fonction ne devrait jamais être appelée sur mobile
  // Elle est remplacée par la sauvegarde de fichier dans le converter mobile
  throw UnsupportedError('downloadImage is only supported on web platform');
}
