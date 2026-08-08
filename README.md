# yemchi_wyji

## Mapbox (obligatoire)

La carte ne possède volontairement aucun fournisseur de secours. Copiez
`mapbox.json.example` vers `mapbox.json`, renseignez un jeton public Mapbox
(`pk...`), puis démarrez l'application avec :

```powershell
flutter run --dart-define-from-file=mapbox.json
```

Pour produire un APK :

```powershell
flutter build apk --dart-define-from-file=mapbox.json
```

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
