import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:pdfx/pdfx.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class PdfToImageConverterMobile extends StatefulWidget {
  const PdfToImageConverterMobile({super.key});

  @override
  State<PdfToImageConverterMobile> createState() => _PdfToImageConverterMobileState();
}

class _PdfToImageConverterMobileState extends State<PdfToImageConverterMobile> {
  PdfDocument? _pdfDocument;
  Uint8List? _pdfBytes;
  int? _totalPages;
  int _selectedPage = 1;
  Uint8List? _renderedImage;
  bool _isLoading = false;
  String? _fileName;
  String? _savedImagePath;

  Future<void> _pickPdfFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        withData: true,
      );

      if (result != null && result.files.single.bytes != null) {
        setState(() {
          _isLoading = true;
          _pdfBytes = result.files.single.bytes;
          _fileName = result.files.single.name;
          _renderedImage = null;
          _savedImagePath = null;
        });

        final document = await PdfDocument.openData(_pdfBytes!);

        setState(() {
          _pdfDocument = document;
          _totalPages = document.pagesCount;
          _selectedPage = 1;
          _isLoading = false;
        });

        // Convertir automatiquement la page 1 après le chargement du PDF
        await _convertPageToImage();
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors du chargement du PDF: $e')),
        );
      }
    }
  }

  Future<void> _convertPageToImage() async {
    if (_pdfDocument == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final page = await _pdfDocument!.getPage(_selectedPage);
      final pageImage = await page.render(
        width: page.width * 2,
        height: page.height * 2,
        format: PdfPageImageFormat.png,
      );

      setState(() {
        _renderedImage = pageImage?.bytes;
        _isLoading = false;
        _savedImagePath = null; // Reset saved path when generating new image
      });

      await page.close();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la conversion: $e')),
        );
      }
    }
  }

  Future<void> _saveImage() async {
    if (_renderedImage == null) return;

    try {
      // Créer un nom de fichier basé sur le PDF original et le numéro de page
      final baseFileName = _fileName?.replaceAll('.pdf', '') ?? 'document';
      final fileName = '${baseFileName}_page_$_selectedPage.png';

      // Obtenir le répertoire de documents de l'application
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/$fileName';

      // Sauvegarder l'image
      final file = File(filePath);
      await file.writeAsBytes(_renderedImage!);

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
  void dispose() {
    _pdfDocument?.close();
    super.dispose();
  }

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
                // Bouton de sélection de fichier
                Card(
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
                          onPressed: _isLoading ? null : _pickPdfFile,
                          icon: const Icon(Icons.upload_file),
                          label: const Text('Choisir un fichier PDF'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 16,
                            ),
                          ),
                        ),
                        if (_fileName != null) ...[
                          const SizedBox(height: 16),
                          Text(
                            'Fichier: $_fileName',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Sélection de la page
                if (_totalPages != null) ...[
                  Card(
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
                                  value: _selectedPage.toDouble(),
                                  min: 1,
                                  max: _totalPages!.toDouble(),
                                  divisions: _totalPages! - 1,
                                  label: 'Page $_selectedPage',
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedPage = value.toInt();
                                      _renderedImage = null;
                                      _savedImagePath = null;
                                    });
                                    // Conversion automatique lors du déplacement du slider
                                    _convertPageToImage();
                                  },
                                ),
                              ),
                              const SizedBox(width: 16),
                              Text(
                                'Page $_selectedPage / $_totalPages',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Indicateur de chargement
                if (_isLoading) ...[
                  const Center(child: CircularProgressIndicator()),
                  const SizedBox(height: 16),
                  const Center(child: Text('Traitement en cours...')),
                ],

                // Affichage de l'image convertie
                if (_renderedImage != null) ...[
                  Card(
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
                                onPressed: _saveImage,
                                icon: const Icon(Icons.save),
                                label: const Text('Sauvegarder'),
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
                          if (_savedImagePath != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              'Sauvegardée dans: $_savedImagePath',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                          const SizedBox(height: 16),
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.memory(
                                _renderedImage!,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
