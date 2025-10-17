# PDF to PNG Converter

Une application Flutter Web qui permet de convertir une page d'un fichier PDF en image PNG.

## Fonctionnalités

- Sélection d'un fichier PDF depuis votre navigateur
- Visualisation du nombre total de pages du PDF
- Sélection de la page à convertir avec un slider interactif
- Conversion de la page sélectionnée en image PNG haute qualité
- Affichage de l'image PNG générée directement dans le navigateur
- Téléchargement de l'image PNG sur votre ordinateur avec un nom de fichier intelligent

## Installation et Lancement

### Prérequis

- Flutter SDK (version 3.0 ou supérieure)
- Un navigateur web moderne (Chrome, Firefox, Safari, Edge)

### Étapes d'installation

1. Cloner ou télécharger ce projet

2. Installer les dépendances :
```bash
flutter pub get
```

3. Installer le support web pour pdfx :
```bash
flutter pub run pdfx:install_web
```

4. Lancer l'application :
```bash
flutter run -d chrome
```

L'application s'ouvrira automatiquement dans votre navigateur Chrome.

## Utilisation

1. **Choisir un fichier PDF** : Cliquez sur le bouton "Choisir un fichier PDF" et sélectionnez un PDF depuis votre ordinateur

2. **Sélectionner une page** : Une fois le PDF chargé, utilisez le slider pour sélectionner le numéro de page que vous souhaitez convertir

3. **Convertir** : Cliquez sur le bouton "Convertir en PNG" pour générer l'image

4. **Visualiser** : L'image PNG s'affichera automatiquement dans le navigateur

5. **Télécharger** : Cliquez sur le bouton "Télécharger" (vert) pour sauvegarder l'image sur votre ordinateur. Le fichier sera automatiquement nommé selon le format : `[nom_du_pdf]_page_[numéro].png`

## Dépendances principales

- **file_picker** (^8.1.4) : Pour la sélection de fichiers dans le navigateur
- **pdfx** (^2.7.0) : Pour le rendu et la manipulation de fichiers PDF

## Build pour la production

Pour créer une version de production optimisée :

```bash
flutter build web
```

Les fichiers compilés seront disponibles dans le dossier `build/web/`.

## Limitations

- L'application fonctionne uniquement sur navigateurs web (pas d'application mobile native)
- La taille maximale du fichier PDF dépend de la mémoire disponible du navigateur
- La qualité de l'image générée est fixée à 2x la résolution originale de la page

## Technologies utilisées

- Flutter 3.32.1
- Dart 3.8.1
- pdfx pour le rendu PDF
- file_picker pour la sélection de fichiers
