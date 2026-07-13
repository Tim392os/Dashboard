# Dashboard — tableau de bord personnel pour iPhone

Application iPhone native **SwiftUI** (iOS 17+) : une seule page qui regroupe
toute la journée — tâches, objectifs, vélo, école, habitudes, statistiques,
finances, compteurs et notes rapides. Design Apple moderne : fond noir profond,
cartes translucides (glassmorphism léger), coins arrondis continus, animations
spring, typographie système SF Pro.

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
| **TrainingPeaks** | 🔌 Prêt à brancher | L'API officielle (`api.trainingpeaks.com`) est réservée aux partenaires : demander un accès développeur (client OAuth2), puis stocker le jeton via `Keychain.set(_:for: .trainingPeaksToken)`. Le provider s'active automatiquement. En attendant : mode démo. |
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
