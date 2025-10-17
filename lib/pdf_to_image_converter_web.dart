import 'package:flutter/material.dart';
import 'pdf_to_image_converter_base.dart';
import 'download_helper.dart';

class PdfToImageConverterWeb extends PdfToImageConverterBase {
  const PdfToImageConverterWeb({super.key});

  @override
  State<PdfToImageConverterWeb> createState() => _PdfToImageConverterWebState();
}

class _PdfToImageConverterWebState extends PdfToImageConverterBaseState<PdfToImageConverterWeb> {
  @override
  void saveOrDownloadImage() {
    if (renderedImage == null) return;

    final imageName = generateImageFileName();

    // Utiliser le helper pour télécharger l'image
    downloadImage(renderedImage!, imageName);

    // Afficher un message de confirmation
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Image téléchargée: $imageName'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  IconData getSaveButtonIcon() => Icons.download;

  @override
  String getSaveButtonLabel() => 'Télécharger';

  @override
  Widget buildPlatformSpecificContent() {
    // Pas de contenu spécifique pour la version Web
    return const SizedBox.shrink();
  }
}
