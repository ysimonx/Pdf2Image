import 'package:flutter/material.dart';
import 'pdf_to_image_converter_base.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class PdfToImageConverterMobile extends PdfToImageConverterBase {
  const PdfToImageConverterMobile({super.key});

  @override
  State<PdfToImageConverterMobile> createState() => _PdfToImageConverterMobileState();
}

class _PdfToImageConverterMobileState extends PdfToImageConverterBaseState<PdfToImageConverterMobile> {
  String? _savedImagePath;

  @override
  void onPdfFileSelected() {
    // Reset du chemin de sauvegarde lors du chargement d'un nouveau PDF
    _savedImagePath = null;
  }

  @override
  void onImageConverted() {
    // Reset du chemin de sauvegarde lors de la génération d'une nouvelle image
    setState(() {
      _savedImagePath = null;
    });
  }

  @override
  void onPageSelectionChanged() {
    // Reset du chemin de sauvegarde lors du changement de page
    _savedImagePath = null;
  }

  @override
  Future<void> saveOrDownloadImage() async {
    if (renderedImage == null) return;

    try {
      final imageName = generateImageFileName();

      // Obtenir le répertoire de documents de l'application
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/$imageName';

      // Sauvegarder l'image
      final file = File(filePath);
      await file.writeAsBytes(renderedImage!);

      setState(() {
        _savedImagePath = filePath;
      });

      // Afficher un message de confirmation
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Image sauvegardée: $filePath'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la sauvegarde: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  IconData getSaveButtonIcon() => Icons.save;

  @override
  String getSaveButtonLabel() => 'Sauvegarder';

  @override
  Widget buildPlatformSpecificContent() {
    // Affichage du chemin de sauvegarde pour la version Mobile
    if (_savedImagePath == null) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        const SizedBox(height: 8),
        Text(
          'Sauvegardée dans: $_savedImagePath',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.green,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
