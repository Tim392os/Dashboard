# shader-background

Mini-projet de build pour le fond animé du dashboard (ShaderGradient).
Le site dans `web/` reste 100 % statique : ce dossier sert uniquement à
compiler le composant React en un seul fichier `web/js/shader-bg.js`.

## Modifier le dégradé

Éditer les props dans `src/main.jsx` (couleurs, type, vitesse), puis :

```sh
npm install   # première fois seulement
npm run build # régénère web/js/shader-bg.js
```

Penser à incrémenter `CACHE_VERSION` dans `web/sw.js` pour que la PWA
récupère le nouveau fichier.
