// Captures d'écran stockées dans l'app (IndexedDB), pour recopier ses notes
// sans jongler entre deux applications.
//
// Pourquoi IndexedDB et pas localStorage : localStorage est limité à quelques
// Mo et ne stocke que du texte ; une capture d'iPhone pèse 1 à 3 Mo. Les
// images sont donc redimensionnées puis rangées ici comme blobs.
//
// Tout reste sur l'appareil : aucune image n'est envoyée nulle part.

const DB_NAME = "dashboard-photos";
const STORE = "shots";
const MAX_SIDE = 1400;   // suffisant pour relire un bulletin, ~10× plus léger
const QUALITY = 0.78;

let dbPromise = null;

function db() {
  if (!dbPromise) {
    dbPromise = new Promise((resolve, reject) => {
      const req = indexedDB.open(DB_NAME, 1);
      req.onupgradeneeded = () => {
        const d = req.result;
        if (!d.objectStoreNames.contains(STORE)) {
          d.createObjectStore(STORE, { keyPath: "id" });
        }
      };
      req.onsuccess = () => resolve(req.result);
      req.onerror = () => reject(req.error);
    });
  }
  return dbPromise;
}

function tx(mode, fn) {
  return db().then((d) => new Promise((resolve, reject) => {
    const t = d.transaction(STORE, mode);
    const req = fn(t.objectStore(STORE));
    // On attend la fin de la transaction, pas seulement celle de la requête :
    // c'est elle qui garantit que l'écriture est bien committée.
    t.oncomplete = () => resolve(req ? req.result : undefined);
    t.onerror = () => reject(t.error);
    t.onabort = () => reject(t.error);
  }));
}

/** Charge l'image quel que soit le navigateur (createImageBitmap ou <img>). */
async function loadImage(file) {
  if (typeof createImageBitmap === "function") {
    try {
      return await createImageBitmap(file);
    } catch { /* repli ci-dessous */ }
  }
  const url = URL.createObjectURL(file);
  try {
    return await new Promise((resolve, reject) => {
      const img = new Image();
      img.onload = () => resolve(img);
      img.onerror = () => reject(new Error("image illisible"));
      img.src = url;
    });
  } finally {
    URL.revokeObjectURL(url);
  }
}

/** Redimensionne et recompresse : une capture d'iPhone passe de ~2 Mo à ~200 Ko. */
async function shrink(file) {
  const img = await loadImage(file);
  const w = img.width, h = img.height;
  const scale = Math.min(1, MAX_SIDE / Math.max(w, h));
  const canvas = document.createElement("canvas");
  canvas.width = Math.max(1, Math.round(w * scale));
  canvas.height = Math.max(1, Math.round(h * scale));
  canvas.getContext("2d").drawImage(img, 0, 0, canvas.width, canvas.height);
  if (img.close) img.close();

  const blob = await new Promise((resolve) =>
    canvas.toBlob(resolve, "image/jpeg", QUALITY));
  // Si la recompression échoue ou grossit l'image, on garde l'originale.
  return blob && blob.size < file.size ? blob : file;
}

const uid = () => Date.now().toString(36) + Math.random().toString(36).slice(2, 8);

/** Ajoute une capture. Renvoie son id. */
export async function addShot(file) {
  const blob = await shrink(file);
  const shot = { id: uid(), blob, addedAt: Date.now(), type: blob.type || "image/jpeg" };
  await tx("readwrite", (store) => store.put(shot));
  return shot.id;
}

/** Toutes les captures, la plus récente d'abord. */
export async function listShots() {
  const all = await tx("readonly", (store) => store.getAll());
  return (all || []).sort((a, b) => b.addedAt - a.addedAt);
}

export async function countShots() {
  const n = await tx("readonly", (store) => store.count());
  return n || 0;
}

export async function deleteShot(id) {
  await tx("readwrite", (store) => store.delete(id));
}
