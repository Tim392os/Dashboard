# Dashboard — tableau de bord personnel pour iPhone

Tableau de bord d'une seule page qui regroupe toute la journée — tâches,
objectifs, vélo, école, habitudes, statistiques, finances, compteurs et notes
rapides. Design Apple moderne : fond noir profond, cartes translucides
(glassmorphism léger), coins arrondis continus, animations spring, typographie
système SF Pro.

Le dépôt contient **deux versions** :

| | Dossier | Pour qui |
|---|---|---|
| **App native SwiftUI** (iOS 17+) | `Dashboard/` + `Dashboard.xcodeproj` | Nécessite un Mac avec Xcode pour compiler ; seule version avec Apple Santé (sommeil automatique) |
| **PWA (application web)** | `web/` | Aucun Mac requis : s'installe depuis Safari via « Ajouter à l'écran d'accueil » ; sommeil en saisie manuelle |

## Installer la PWA (sans Mac)

1. Héberger le dossier `web/` en HTTPS. Le workflow
   `.github/workflows/deploy-pages.yml` déploie automatiquement sur
   **GitHub Pages** à chaque push sur `main` (Settings → Pages → Source :
   « GitHub Actions »). ⚠️ Pages sur un dépôt **privé** exige un compte GitHub
   payant — alternatives gratuites : rendre le dépôt public, ou déployer
   `web/` sur Cloudflare Pages / Netlify / Vercel (gratuits, dépôts privés OK).
2. Ouvrir l'URL dans **Safari** sur l'iPhone.
3. Bouton **Partager** → **Sur l'écran d'accueil**. L'app s'ouvre plein écran,
   fonctionne hors-ligne (service worker) et garde ses données sur l'appareil
   (localStorage — rien n'est envoyé sur un serveur).

La PWA reprend l'architecture de l'app native : les sources externes sont dans
`web/js/providers.js` derrière une interface commune (`{ isLive, fetchSummary }`)
— mode démo tant qu'une vraie intégration (via un petit backend qui garde les
secrets OAuth) n'est pas branchée.

# Version native SwiftUI

## Compiler

1. Ouvrir `Dashboard.xcodeproj` avec **Xcode 16+**.
2. Sélectionner votre équipe de signature (Signing & Capabilities → Team).
3. ⌘R sur un iPhone ou le simulateur (iOS 17 minimum).

Aucune dépendance externe : uniquement SwiftUI, SwiftData, Swift Charts,
HealthKit et Foundation.

## Architecture

```
Dashboard/
├── DashboardApp.swift        Point d'entrée, conteneur SwiftData
├── DashboardModel.swift      État observable des données externes
├── Support/                  Thème (couleurs, métriques), GlassCard, utilitaires dates
├── Models/                   Modèles SwiftData (tâches, objectifs, habitudes,
│                             recettes, notes, compteurs, finances)
├── Services/                 Intégrations : protocoles + implémentations
│   ├── ProviderRegistry.swift   ← point unique de branchement des sources
│   ├── TrainingProvider.swift   TrainingPeaks (OAuth2) + données d'exemple
│   ├── SchoolProvider.swift     Cabanga (squelette) + données d'exemple
│   ├── BankProvider.swift       Open Banking PSD2 (squelette) + saisie manuelle
│   ├── HealthKitService.swift   Sommeil via Apple Santé
│   ├── Keychain.swift           Stockage sécurisé des jetons
│   └── APIClient.swift          Client HTTP partagé
└── Views/                    Une vue par carte du dashboard
```

**Principe clé :** chaque source externe est derrière un protocole
(`TrainingDataProvider`, `SchoolDataProvider`, `BankDataProvider`).
`ProviderRegistry` active l'implémentation réelle dès que ses identifiants
sont présents dans le trousseau, sinon l'app retombe sur des données d'exemple
(badge « Démo » sur la carte) ou la saisie manuelle. Ajouter une intégration
plus tard = implémenter le protocole et la brancher dans le registre, **sans
toucher aux vues ni aux modèles**.

## État des intégrations

| Source | Statut | Détails |
|---|---|---|
| **Apple Santé (sommeil)** | ✅ Fonctionnel | HealthKit, lecture seule, autorisation demandée au premier lancement |
| **Vélo — intervals.icu (PWA)** | ✅ Fonctionnel | Carte Vélo → bouton ⚙︎ : saisir l'Athlete ID et la clé API (intervals.icu → Settings → Developer Settings). La clé reste sur l'appareil (localStorage). Courses = événements « Race » du calendrier intervals.icu ; les activités remontent via la synchro Garmin/Strava d'intervals.icu. |
| **TrainingPeaks (app native)** | 🔌 Prêt à brancher | L'API officielle (`api.trainingpeaks.com`) est réservée aux partenaires : demander un accès développeur (client OAuth2), puis stocker le jeton via `Keychain.set(_:for: .trainingPeaksToken)`. Le provider s'active automatiquement. En attendant : mode démo. |
| **Cabanga (école)** | 🔌 Prêt à brancher | Pas d'API publique documentée à ce jour. `CabangaProvider` est le point d'accroche ; ne jamais scraper avec les identifiants de l'élève — uniquement une méthode approuvée par l'école. En attendant : mode démo. |
| **BNP Paribas (finances)** | 🔌 Prêt à brancher | Les API PSD2 de BNP sont réservées aux prestataires agréés (AISP). Voie réaliste : un agrégateur agréé (Tink, Powens, GoCardless Bank Account Data…) via `OpenBankingProvider`. En attendant : saisie manuelle. |
| **Temps d'écran** | ✋ Saisie manuelle | Apple n'expose pas les totaux Temps d'écran aux apps tierces (l'API DeviceActivity ne fournit pas de valeurs brutes). Saisie rapide prévue dans la carte Habitudes. |

## Sécurité

- **Aucun identifiant bancaire ni mot de passe n'est stocké** — nulle part.
- Les jetons d'API (OAuth) vivent exclusivement dans le **trousseau iOS**
  (`kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly`), jamais dans
  UserDefaults, SwiftData ou un fichier.
- La carte Finances ne conserve que des montants saisis par l'utilisateur.
- HealthKit : lecture seule du sommeil, rien n'est écrit.

## Fonctionnalités

- **Tâches** : ajout/modification/suppression, cases à cocher, archivage
  automatique des tâches terminées au changement de jour.
- **Objectifs** : semaine / mois / année — texte, barre de progression,
  pourcentage exact, date limite ; tout modifiable au toucher.
- **Vélo** : compte à rebours avant la prochaine course, prochains
  entraînements, charge récente (heures 7 j, TSS, CTL/ATL).
- **École** : devoirs, contrôles, moyenne générale, temps d'étude du jour.
- **Habitudes** : sommeil (Apple Santé), portions fruits/légumes (saisie
  rapide ±), temps d'écran ; série (streak) de jours réussis.
- **Statistiques** : streak, heures d'entraînement de l'année avec graphique
  mensuel (Swift Charts), recettes testées avec historique + notation ⭐,
  argent économisé.
- **Finances** : disponible, épargne, dépenses du mois, objectif d'épargne
  avec barre de progression.
- **Compteurs** : vacances, anniversaire, Noël, voyage — dates modifiables,
  événements annuels reconduits automatiquement, ajout de compteurs libres.
- **Notes rapides** : idées / à acheter / liens, recherche instantanée,
  liens cliquables.
