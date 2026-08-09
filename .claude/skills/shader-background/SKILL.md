---
name: shader-background
description: Ajoute un fond dégradé animé WebGL (ShaderGradient) derrière l'interface d'un projet web — React ou vanilla JS. Utiliser ce skill dès que l'utilisateur demande un "fond animé", un "fond shader", un "dégradé animé", un "background ShaderGradient", ou veut reproduire le fond du Dashboard dans un autre projet, même s'il ne nomme pas ShaderGradient explicitement.
---

# Fond animé ShaderGradient

Ce skill installe un fond dégradé animé plein écran avec la librairie
[ShaderGradient](https://github.com/ruucm/shadergradient), derrière tout le
contenu de la page, sans intercepter les interactions.

## Configuration par défaut de Tim

Sauf indication contraire de l'utilisateur, utiliser ce préréglage (celui de
son Dashboard) :

```jsx
<ShaderGradient
  control="props"
  type="waterPlane"
  color1="#ff5005"
  color2="#dbba95"
  color3="#d0bce1"
  animate="on"
  uSpeed={0.3}
/>
```

Demander (ou déduire du contexte) uniquement si le projet a une identité
visuelle qui jure avec ces couleurs chaudes. Le grain est activé par défaut
par la librairie ; ajouter `grain="off"` si l'utilisateur le trouve trop
présent.

## Étape 1 — Identifier le type de projet

- **Projet React avec bundler** (Next.js, Vite, CRA… — il y a un
  `package.json` avec `react`) → suivre « Cas A ».
- **Site statique / vanilla JS** (pas de `package.json`, HTML servi tel
  quel) → suivre « Cas B ». Ne pas convertir le projet en React juste pour
  le fond.

## Cas A — Projet React

1. `npm i @shadergradient/react @react-three/fiber three three-stdlib camera-controls`
2. Créer un composant à partir de `assets/Background.jsx` et le monter une
   fois, au niveau racine de l'app (layout / App), en premier enfant.
3. S'assurer que le conteneur du fond est en `position: fixed; inset: 0;
   z-index: -1; pointer-events: none;` pour qu'il reste derrière tout et ne
   bloque aucun clic.

## Cas B — Site vanilla (sans build à l'exécution)

Le principe : un mini-projet de build compile le composant React en **un
seul fichier statique** que le site charge comme n'importe quel script. Le
site reste 100 % vanilla ; React n'existe qu'au moment de la compilation.

1. Créer un dossier `shader-background/` à la racine du dépôt (hors du
   dossier servi) avec :
   - `src/main.jsx` : copie de `assets/main.jsx` (il monte le composant
     dans un `div#shader-bg` ajouté en tête de `<body>`) ;
   - `.gitignore` contenant `node_modules/` ;
   - un `package.json` : `npm init -y`, puis les dépendances du Cas A plus
     `react react-dom` et `esbuild` en dev.
2. Ajouter le script de build (adapter le chemin de sortie au dossier
   réellement servi — `web/`, `public/`, `dist/`…) :
   ```sh
   npm pkg set scripts.build="esbuild src/main.jsx --bundle --minify --format=iife --outfile=../web/js/shader-bg.js --define:process.env.NODE_ENV='\"production\"'"
   npm run build
   ```
   Le bundle fait ~1,3 Mo (three.js inclus) : c'est attendu, le committer.
3. Dans le HTML : `<script src="js/shader-bg.js" defer></script>` avant le
   script principal de l'app.
4. Dans le CSS :
   ```css
   #shader-bg { position: fixed; inset: 0; z-index: -1; pointer-events: none; }
   ```
5. Garder une couleur de fond sombre sur `body` en secours : elle s'affiche
   pendant le chargement du bundle et si WebGL est indisponible.
6. Si le site est une PWA avec service worker : ajouter le bundle à la
   liste de précache et incrémenter la version du cache.

## Vérification

Toujours vérifier le rendu réel avant de livrer : servir le site
(`python3 -m http.server`), charger la page en Chromium headless
(`--use-gl=angle --use-angle=swiftshader` pour le WebGL logiciel),
confirmer qu'un `<canvas>` existe dans `#shader-bg`, qu'il n'y a aucune
erreur console, et prendre une capture d'écran à montrer à l'utilisateur.
Le rendu headless paraît plus granuleux qu'un vrai appareil — le dire en
présentant la capture.

## Point de vigilance : le contraste

Un dégradé clair derrière une UI conçue pour fond sombre dégrade la
lisibilité des textes secondaires. Après l'installation, regarder la
capture d'écran avec cet œil et, si besoin, proposer à l'utilisateur : un
voile sombre semi-transparent entre le dégradé et le contenu, ou des
couleurs de dégradé plus sombres. Ne pas l'appliquer d'office — c'est un
choix esthétique qui lui revient.
