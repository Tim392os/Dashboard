// Sources de données externes, derrière une interface commune.
//
// Même principe que l'app native : chaque provider expose { isLive, fetchSummary() }.
// Tant qu'aucune intégration réelle n'est branchée, l'app affiche des données
// d'exemple (badge « Démo » sur la carte).
//
// Vélo : intégration intervals.icu (API ouverte aux particuliers, clé API
// personnelle). La clé est stockée uniquement en localStorage sur l'appareil —
// jamais dans le code ni sur un serveur. TrainingPeaks n'ouvre son API qu'aux
// partenaires approuvés ; intervals.icu se synchronise avec Garmin/Strava/Wahoo
// et sert de passerelle réaliste.
//
// Banque / école : une PWA statique ne peut pas contenir de secret OAuth (tout
// le code est public). Pour brancher un agrégateur bancaire, il faudra un petit
// backend (Cloudflare Worker) qui garde les secrets. Ne jamais mettre de jeton
// bancaire dans ce fichier.

import { todayKey, startOfToday } from "./store.js";

// ---------- Identifiants d'intégration (stockés sur l'appareil) ----------

const INTEGRATIONS_KEY = "dashboard.integrations.v1";
const TRAINING_CACHE_KEY = "dashboard.training.cache.v1";

export function getIntegrations() {
  try {
    return JSON.parse(localStorage.getItem(INTEGRATIONS_KEY)) || {};
  } catch {
    return {};
  }
}

export function setIntegration(name, config) {
  const all = getIntegrations();
  if (config) all[name] = config;
  else delete all[name];
  localStorage.setItem(INTEGRATIONS_KEY, JSON.stringify(all));
}

function inDays(n) {
  const t = startOfToday();
  return todayKey(new Date(t.getFullYear(), t.getMonth(), t.getDate() + n));
}

// ---------- Vélo : intervals.icu ----------

/** L'API accepte l'athlete id `0` = « le propriétaire de la clé » : l'ID
 *  explicite est donc optionnel et ne sert qu'aux comptes multi-athlètes. */
function icuAthleteId(cfg) {
  const id = String(cfg.athleteId || "").trim();
  return id === "" ? "0" : id;
}

async function icuGet(cfg, path, params = {}) {
  const url = new URL(`https://intervals.icu/api/v1/athlete/${encodeURIComponent(icuAthleteId(cfg))}/${path}`);
  for (const [key, value] of Object.entries(params)) url.searchParams.set(key, value);
  const res = await fetch(url, {
    headers: { Authorization: "Basic " + btoa("API_KEY:" + cfg.apiKey) },
  });
  if (!res.ok) {
    const error = new Error(`intervals.icu HTTP ${res.status}`);
    error.status = res.status;
    throw error;
  }
  return res.json();
}

/** Message d'erreur précis et actionnable pour l'utilisateur. */
export function icuErrorMessage(error) {
  switch (error?.status) {
    case 401:
    case 403:
      return "Clé API refusée par intervals.icu — vérifie la clé (Settings → Developer Settings) ou regénère-la.";
    case 404:
      return "Athlète introuvable — laisse le champ Athlete ID vide (recommandé).";
    default:
      return "intervals.icu injoignable (réseau ou blocage navigateur). Réessaie ; si ça persiste, préviens-moi en précisant ce message.";
  }
}

/** Test de connexion léger : valide la clé et l'athlete id. */
export async function testIntervalsConnection(cfg) {
  const today = todayKey();
  try {
    await icuGet(cfg, "wellness", { oldest: today, newest: today });
    return { ok: true };
  } catch (error) {
    return { ok: false, message: icuErrorMessage(error) };
  }
}

async function fetchIntervalsSummary(cfg) {
  const today = todayKey();
  const jan1 = `${startOfToday().getFullYear()}-01-01`;

  const [events, activities, wellness] = await Promise.all([
    icuGet(cfg, "events", { oldest: today, newest: inDays(90) }),
    icuGet(cfg, "activities", { oldest: jan1, newest: today }),
    icuGet(cfg, "wellness", { oldest: inDays(-7), newest: today }),
  ]);

  // Courses : événements du calendrier intervals.icu en catégorie Race (A/B/C).
  const races = (events || [])
    .filter((e) => String(e.category || "").startsWith("RACE"))
    .map((e) => ({ name: e.name || "Course", date: String(e.start_date_local || "").slice(0, 10) }))
    .filter((r) => r.date >= today)
    .sort((a, b) => a.date.localeCompare(b.date));

  const workouts = (events || [])
    .filter((e) => e.category === "WORKOUT")
    .map((e) => ({
      title: e.name || "Entraînement",
      date: String(e.start_date_local || "").slice(0, 10),
      durationMinutes: Math.round((e.moving_time || 0) / 60),
    }))
    .sort((a, b) => a.date.localeCompare(b.date))
    .slice(0, 4);

  // Heures par mois + charge sur 7 jours, à partir des activités réalisées.
  const t = startOfToday();
  const sevenDaysAgo = new Date(t.getFullYear(), t.getMonth(), t.getDate() - 7);
  const yearHoursByMonth = {};
  let last7Hours = 0;
  let last7TSS = 0;
  for (const a of activities || []) {
    const day = String(a.start_date_local || "").slice(0, 10);
    if (!day) continue;
    const date = new Date(day + "T00:00");
    const hours = (a.moving_time || 0) / 3600;
    const month = date.getMonth() + 1;
    yearHoursByMonth[month] = (yearHoursByMonth[month] || 0) + hours;
    if (date >= sevenDaysAgo) {
      last7Hours += hours;
      last7TSS += a.icu_training_load || 0;
    }
  }
  for (const m of Object.keys(yearHoursByMonth)) {
    yearHoursByMonth[m] = Math.round(yearHoursByMonth[m] * 10) / 10;
  }

  // CTL (forme) : dernière valeur connue du journal wellness.
  let ctl = null;
  const sortedWellness = (wellness || []).slice().sort((a, b) => String(a.id).localeCompare(String(b.id)));
  for (const w of sortedWellness) if (w.ctl != null) ctl = w.ctl;

  return {
    nextRace: races[0] || null,
    upcomingWorkouts: workouts,
    recentLoad: {
      last7DaysHours: Math.round(last7Hours * 10) / 10,
      last7DaysTSS: Math.round(last7TSS),
      fitnessCTL: ctl != null ? Math.round(ctl) : null,
    },
    yearHoursByMonth,
  };
}

function demoTrainingSummary() {
  const month = new Date().getMonth() + 1;
  const sample = [32, 38, 41, 45, 39, 47, 22];
  const yearHoursByMonth = {};
  for (let m = 1; m <= month; m++) yearHoursByMonth[m] = sample[(m - 1) % sample.length];

  return {
    nextRace: { name: "GP de la Wallonie Juniors", date: inDays(19) },
    upcomingWorkouts: [
      { title: "Endurance Z2", date: inDays(1), durationMinutes: 120 },
      { title: "Intervalles 4×8'", date: inDays(2), durationMinutes: 90 },
      { title: "Récupération", date: inDays(3), durationMinutes: 60 },
    ],
    recentLoad: { last7DaysHours: 11.5, last7DaysTSS: 620, fitnessCTL: 78 },
    yearHoursByMonth,
  };
}

export const trainingProvider = {
  get isLive() {
    return Boolean(getIntegrations().intervals?.apiKey);
  },

  get sourceName() {
    return this.isLive ? "intervals.icu" : "Démo";
  },

  async fetchSummary() {
    if (!this.isLive) return demoTrainingSummary();
    const cfg = getIntegrations().intervals;
    try {
      const summary = await fetchIntervalsSummary(cfg);
      localStorage.setItem(TRAINING_CACHE_KEY, JSON.stringify({ at: Date.now(), summary }));
      return summary;
    } catch (error) {
      // Hors-ligne ou clé invalide : dernières données connues si disponibles.
      try {
        const cached = JSON.parse(localStorage.getItem(TRAINING_CACHE_KEY));
        if (cached?.summary) return { ...cached.summary, stale: true };
      } catch { /* pas de cache */ }
      return { error: icuErrorMessage(error) };
    }
  },
};

// ---------- École (Cabanga : pas d'API publique — voir README) ----------

export const schoolProvider = {
  isLive: false,

  async fetchSummary() {
    return {
      homework: [
        { subject: "Math", title: "Exercices dérivées p. 142", dueDate: inDays(1) },
        { subject: "Anglais", title: "Essay — My ambitions", dueDate: inDays(2) },
        { subject: "Physique", title: "Rapport de labo", dueDate: inDays(4) },
      ],
      exams: [
        { subject: "Histoire", title: "Contrôle ch. 5–6", date: inDays(3) },
        { subject: "Math", title: "Interro dérivées", date: inDays(6) },
      ],
      average: 82,
      averageScale: 100,
      studyMinutesToday: 45,
    };
  },
};

// ---------- Banque (BNP : PSD2 réservé aux agrégateurs agréés) ----------
// null = pas de provider connecté → la carte Finances utilise la saisie manuelle.

export const bankProvider = null;
