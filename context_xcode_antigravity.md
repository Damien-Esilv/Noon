# Contexte du Projet : Noon (Mac Utility App)

## Architecture Globale & Environnements
Ce projet est développé via une interface hybride :
- **L'Agent IA (Antigravity)** gère la création de l'architecture, la refonte du code SwiftUI / Swift et observe les modifications en temps réel sur les fichiers du projet.
- **Xcode** est l'IDE principal utilisé par l'utilisateur (Damien) pour compiler, signer et exécuter l'application nativement. 

**ATTENTION POUR LES FUTURES IA** :
Il ne faut en aucun cas recréer des structures de dossiers `.xcodeproj` ou manipuler les configurations d'environnements Xcode directement depuis l'agent à l'aveugle. Les modifications de code source (`.swift`, `.plist`, `.m`, `.h`, `.xcstrings`) modifiées par l'IA dans l'espace de base sont instantanément répercutées dans Xcode. Toujours conseiller à l'utilisateur de cliquer sur "Build / Run" depuis Xcode et lui indiquer d'ajouter des fichiers manuellement (comme `Localizable.xcstrings`) dans la liste des assets de Xcode si un nouveau fichier est créé ici.

## Résumé du Fonctionnement de Noon
"Noon" est une application macOS discrète (`MenuBarExtra`) qui réside dans la barre des menus.
Son but est de cibler des professionnels créatifs pour qui la fidélité colorimétrique est critique : Elle détecte l'ouverture de logiciels créatifs (ex: Photoshop, Lightroom, DaVinci) et **désactive automatiquement True Tone et Night Shift** le temps que l'app est active, puis les réactive ensuite, de manière totalement transparente.

### Spécificités Techniques :
1. **CoreBrightness Bridge** : Puisque True Tone n'a pas d'API publique, nous faisons un appel privé via Objective-C (Bridging Header) au framework `CoreBrightness`.
2. **Design Glassmorphique** : Tout le rendu visuel est construit en SwiftUI en tirant parti du material design `.thinMaterial` d'Apple.
3. **Menu Bar vs Dock** : L'app fonctionne background (`LSUIElement` = true). L'icône dans le dock est masquée par défaut. Cependant, via un `NSApp.setActivationPolicy`, elle adopte dynamiquement le statut `.regular` (apparait dans le Dock et force le premier plan) **uniquement** quand on ouvre la fenêtre de réglages de l'application !
4. **Localisation dynamique** : L'app supporte de multiples langues injectées de force (`\.locale`) dans tous les composants natifs SwiftUI (`LocalizedStringKey`).
5. **Surveillance Discrète** : La surveillance des applications s'effectue en lisant les `BundleIdentifier` via `NSWorkspace` pour détecter de manière robuste l'emplacement de logiciels métiers.

## Consignes Générales
- **Design** : Les icônes doivent utiliser les standard Apple (`SF Symbols`), et les composants visuels doivent êtres alignés à gauche de manière propre avec de grand blocs uniformes (Flat Colors).
- **Compilation** : Attendre que l'utilisateur compile dans Xcode pour tester nos mises à jour. Si l'utilisateur signale des API introuvables ou des icônes inconnues, l'IA doit s'adapter aux limitations du SDK présent chez l'utilisateur (macOS 13 / 14 Xcode).
