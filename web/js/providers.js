// Sources de données externes, derrière une interface commune.
//
// Même principe que l'app native : chaque provider expose { isLive, fetchSummary() }.
// Tant qu'aucune intégration réelle n'est branchée, l'app affiche des données
// d'exemple (badge « Démo » sur la carte).
//
// Important : une PWA statique ne peut pas contenir de secret OAuth (tout le
// code est public). Pour brancher TrainingPeaks ou un agrégateur bancaire, il
// faudra un petit backend (ou un service type Cloudflare Worker) qui garde le
// secret et relaie les requêtes — remplacer alors `fetchSummary` par un appel
// à ce backend. Ne jamais mettre de jeton ou de mot de passe dans ce fichier.

import { todayKey, startOfToday } from "./store.js";

function inDays(n) {
  const t = startOfToday();
  return todayKey(new Date(t.getFullYear(), t.getMonth(), t.getDate() + n));
}

// ---------- Vélo (TrainingPeaks : API partenaires — voir README) ----------

export const trainingProvider = {
  isLive: false,

  async fetchSummary() {
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
