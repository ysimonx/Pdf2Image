import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:pdfx/pdfx.dart';

/// Classe abstraite de base pour les convertisseurs PDF vers Image
/// Contient toute la logique commune aux versions Web et Mobile
abstract class PdfToImageConverterBase extends StatefulWidget {
  const PdfToImageConverterBase({super.key});
}

abstract class PdfToImageConverterBaseState<T extends PdfToImageConverterBase> extends State<T> {
  // Propriétés protégées accessibles aux classes dérivées
  @protected
  PdfDocument? pdfDocument;
  @protected
  Uint8List? pdfBytes;
  @protected
  int? totalPages;
  @protected
  int selectedPage = 1;
  @protected
  Uint8List? renderedImage;
  @protected
  bool isLoading = false;
  @protected
  String? fileName;
  @protected
  int selectedDpi = 150; // DPI par défaut

  // Liste des valeurs DPI disponibles
  static const List<int> availableDpis = [72, 150, 300, 600];

  // Index dans la liste des DPI (par défaut 1 = 150 DPI)
  int _dpiIndex = 1;

  /// Méthode de sélection de fichier PDF commune
  Future<void> pickPdfFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        withData: true,
      );

      if (result != null && result.files.single.bytes != null) {
        setState(() {
          isLoading = true;
          pdfBytes = result.files.single.bytes;
          fileName = result.files.single.name;
          renderedImage = null;
          onPdfFileSelected();
        });

        final document = await PdfDocument.openData(pdfBytes!);

        setState(() {
          pdfDocument = document;
          totalPages = document.pagesCount;
          selectedPage = 1;
          isLoading = false;
        });

        // Convertir automatiquement la page 1 après le chargement du PDF
        await convertPageToImage();
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors du chargement du PDF: $e')),
        );
      }
    }
  }

  /// Hook appelé lors de la sélection d'un fichier PDF
  /// Permet aux classes dérivées d'effectuer des actions supplémentaires
  void onPdfFileSelected() {}

  /// Calcule le facteur de scaling basé sur le DPI sélectionné
  /// PDF par défaut utilise 72 DPI
  double _getDpiScaleFactor() {
    return selectedDpi / 72.0;
  }

  /// Méthode de conversion de page en image commune
  Future<void> convertPageToImage() async {
    if (pdfDocument == null) return;

    setState(() {
      isLoading = true;
    });

    try {
      final page = await pdfDocument!.getPage(selectedPage);
      final scaleFactor = _getDpiScaleFactor();
      final pageImage = await page.render(
        width: page.width * scaleFactor,
        height: page.height * scaleFactor,
        format: PdfPageImageFormat.png,
      );

      setState(() {
        renderedImage = pageImage?.bytes;
        isLoading = false;
        onImageConverted();
      });

      await page.close();
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la conversion: $e')),
        );
      }
    }
  }

  /// Hook appelé après la conversion d'une image
  /// Permet aux classes dérivées d'effectuer des actions supplémentaires
  void onImageConverted() {}

  /// Génère le nom de fichier pour l'image à sauvegarder
  String generateImageFileName() {
    final baseFileName = fileName?.replaceAll('.pdf', '') ?? 'document';
    return '${baseFileName}_page_$selectedPage.png';
  }

  /// Méthode abstraite pour sauvegarder/télécharger l'image
  /// Doit être implémentée différemment par Web et Mobile
  void saveOrDownloadImage();

  /// Handler pour le changement de page via le slider
  void onPageChanged(double value) {
    setState(() {
      selectedPage = value.toInt();
      renderedImage = null;
      onPageSelectionChanged();
    });
    // Conversion automatique lors du déplacement du slider
    convertPageToImage();
  }

  /// Hook appelé lors du changement de sélection de page
  /// Permet aux classes dérivées d'effectuer des actions supplémentaires
  void onPageSelectionChanged() {}

  /// Handler pour le changement de DPI via le slider
  void onDpiChanged(double value) {
    setState(() {
      _dpiIndex = value.toInt();
      selectedDpi = availableDpis[_dpiIndex];
      renderedImage = null;
    });
    // Reconvertir l'image avec le nouveau DPI
    if (pdfDocument != null) {
      convertPageToImage();
    }
  }

  @override
  void dispose() {
    pdfDocument?.close();
    super.dispose();
  }

  /// Widget de sélection de fichier PDF
  Widget buildFilePickerCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Icon(
              Icons.picture_as_pdf,
              size: 64,
              color: Colors.blue,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: isLoading ? null : pickPdfFile,
              icon: const Icon(Icons.upload_file),
              label: const Text('Choisir un fichier PDF'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
            ),
            if (fileName != null) ...[
              const SizedBox(height: 16),
              Text(
                'Fichier: $fileName',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Widget de sélection de page
  Widget buildPageSelectorCard() {
    if (totalPages == null) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sélectionner la page',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Slider(
                    value: selectedPage.toDouble(),
                    min: 1,
                    max: totalPages!.toDouble(),
                    divisions: totalPages! - 1,
                    label: 'Page $selectedPage',
                    onChanged: onPageChanged,
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  'Page $selectedPage / $totalPages',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Widget de sélection de DPI
  Widget buildDpiSelectorCard() {
    if (totalPages == null) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Qualité d\'image (DPI)',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              '72 DPI = Basse qualité | 150 DPI = Standard | 300 DPI = Haute qualité | 600 DPI = Très haute qualité',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Slider(
                    value: _dpiIndex.toDouble(),
                    min: 0,
                    max: (availableDpis.length - 1).toDouble(),
                    divisions: availableDpis.length - 1,
                    label: '$selectedDpi DPI',
                    onChanged: onDpiChanged,
                  ),
                ),
                const SizedBox(width: 16),
                SizedBox(
                  width: 80,
                  child: Text(
                    '$selectedDpi DPI',
                    style: Theme.of(context).textTheme.titleMedium,
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Widget d'indicateur de chargement
  Widget buildLoadingIndicator() {
    if (!isLoading) return const SizedBox.shrink();

    return const Column(
      children: [
        Center(child: CircularProgressIndicator()),
        SizedBox(height: 16),
        Center(child: Text('Traitement en cours...')),
      ],
    );
  }

  /// Widget d'affichage de l'image convertie
  /// Inclut un bouton de sauvegarde/téléchargement et le contenu spécifique à la plateforme
  Widget buildConvertedImageCard() {
    if (renderedImage == null) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Image PNG générée',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                ElevatedButton.icon(
                  onPressed: saveOrDownloadImage,
                  icon: Icon(getSaveButtonIcon()),
                  label: Text(getSaveButtonLabel()),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            ),
            // Contenu spécifique à la plateforme (chemin de sauvegarde, etc.)
            buildPlatformSpecificContent(),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.memory(
                  renderedImage!,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Retourne l'icône du bouton de sauvegarde selon la plateforme
  IconData getSaveButtonIcon();

  /// Retourne le label du bouton de sauvegarde selon la plateforme
  String getSaveButtonLabel();

  /// Widget spécifique à la plateforme (ex: affichage du chemin de sauvegarde)
  Widget buildPlatformSpecificContent();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Convertisseur PDF vers PNG'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                buildFilePickerCard(),
                const SizedBox(height: 24),
                buildPageSelectorCard(),
                if (totalPages != null) const SizedBox(height: 24),
                buildDpiSelectorCard(),
                if (totalPages != null) const SizedBox(height: 24),
                buildLoadingIndicator(),
                buildConvertedImageCard(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
