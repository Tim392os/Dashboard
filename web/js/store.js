// État de l'application, persisté dans localStorage.
// Toutes les données restent sur le téléphone — rien n'est envoyé sur un serveur.

const STORAGE_KEY = "dashboard.v1";

export const FRUITS_TARGET = 5;

// ---------- Dates ----------

export function todayKey(date = new Date()) {
  const y = date.getFullYear();
  const m = String(date.getMonth() + 1).padStart(2, "0");
  const d = String(date.getDate()).padStart(2, "0");
  return `${y}-${m}-${d}`;
}

export function startOfToday() {
  const now = new Date();
  return new Date(now.getFullYear(), now.getMonth(), now.getDate());
}

export function parseDay(key) {
  const [y, m, d] = key.split("-").map(Number);
  return new Date(y, m - 1, d);
}

export function daysUntil(dayKey) {
  const target = parseDay(dayKey);
  return Math.round((target - startOfToday()) / 86_400_000);
}

/** Prochaine occurrence annuelle d'une date (anniversaire, Noël…). */
export function nextYearlyOccurrence(dayKey) {
  const base = parseDay(dayKey);
  const today = startOfToday();
  let next = new Date(today.getFullYear(), base.getMonth(), base.getDate());
  if (next < today) next = new Date(today.getFullYear() + 1, base.getMonth(), base.getDate());
  return todayKey(next);
}

export function formatDay(dayKey, opts = { day: "numeric", month: "long" }) {
  return parseDay(dayKey).toLocaleDateString("fr-FR", opts);
}

export function formatHours(hours) {
  const h = Math.floor(hours);
  const m = Math.round((hours - h) * 60);
  return m === 0 ? `${h} h` : `${h} h ${String(m).padStart(2, "0")}`;
}

export function formatEuro(amount) {
  return new Intl.NumberFormat("fr-FR", {
    style: "currency", currency: "EUR", maximumFractionDigits: 0,
  }).format(amount || 0);
}

// ---------- État ----------

let state = null;
const listeners = new Set();

export function getState() {
  return state;
}

export function subscribe(fn) {
  listeners.add(fn);
}

/** Applique une mutation puis persiste et notifie les vues. */
export function update(mutator) {
  mutator(state);
  save();
  listeners.forEach((fn) => fn(state));
}

function save() {
  localStorage.setItem(STORAGE_KEY, JSON.stringify(state));
}

const uid = () => Math.random().toString(36).slice(2, 10) + Date.now().toString(36);
export { uid };

// ---------- Initialisation & seed ----------

function endOfWeekKey() {
  const today = startOfToday();
  const dow = (today.getDay() + 6) % 7; // 0 = lundi
  return todayKey(new Date(today.getFullYear(), today.getMonth(), today.getDate() + (7 - dow)));
}

function seed() {
  const today = startOfToday();
  const year = today.getFullYear();
  const plusMonths = (n) => todayKey(new Date(year, today.getMonth() + n, today.getDate()));

  let vacation = new Date(year, 6, 1); // 1er juillet
  if (vacation < today) vacation = new Date(year + 1, 6, 1);

  return {
    tasks: [],
    goals: [
      { id: uid(), period: "week", text: "Définir mon objectif de la semaine", progress: 0, deadline: endOfWeekKey() },
      { id: uid(), period: "month", text: "Définir mon objectif du mois", progress: 0, deadline: todayKey(new Date(year, today.getMonth() + 1, 0)) },
      { id: uid(), period: "year", text: "Définir mon objectif de l'année", progress: 0, deadline: `${year}-12-31` },
    ],
    habits: {}, // { 'YYYY-MM-DD': { sleepHours, fruits, screenMinutes } }
    recipes: [],
    notes: [],
    countdowns: [
      { id: uid(), name: "Vacances", icon: "☀️", date: todayKey(vacation), repeatsYearly: false },
      { id: uid(), name: "Mon anniversaire", icon: "🎁", date: plusMonths(3), repeatsYearly: true },
      { id: uid(), name: "Noël", icon: "❄️", date: `${year}-12-25`, repeatsYearly: true },
      { id: uid(), name: "Voyage", icon: "✈️", date: plusMonths(2), repeatsYearly: false },
    ],
    finance: { available: 0, savings: 0, monthExpenses: 0, savingsGoal: 1000, moneySaved: 0 },
  };
}

export function initStore() {
  try {
    state = JSON.parse(localStorage.getItem(STORAGE_KEY));
  } catch {
    state = null;
  }
  if (!state || typeof state !== "object") state = seed();
  archiveOldTasks();
  save();
  return state;
}

// ---------- Règles métier ----------

/** Archive les tâches terminées avant aujourd'hui (appelé au chargement
 *  et à chaque retour au premier plan). */
export function archiveOldTasks() {
  const cutoff = startOfToday().getTime();
  let changed = false;
  for (const task of state.tasks) {
    if (task.done && !task.archived && (task.completedAt || task.createdAt) < cutoff) {
      task.archived = true;
      changed = true;
    }
  }
  if (changed) {
    save();
    listeners.forEach((fn) => fn(state));
  }
}

export function habitsForDay(dayKey) {
  return state.habits[dayKey] || { sleepHours: 0, fruits: 0, screenMinutes: 0 };
}

export function setHabit(dayKey, patch) {
  update((s) => {
    s.habits[dayKey] = { ...habitsForDay(dayKey), ...patch };
  });
}

function habitDayComplete(entry) {
  return entry && entry.fruits >= FRUITS_TARGET;
}

/** Série de jours consécutifs réussis (aujourd'hui compte s'il est déjà réussi,
 *  sinon il ne casse pas la série tant que la journée n'est pas finie). */
export function currentStreak() {
  let streak = 0;
  const day = startOfToday();
  if (habitDayComplete(state.habits[todayKey(day)])) streak += 1;
  for (let i = 1; ; i++) {
    const key = todayKey(new Date(day.getFullYear(), day.getMonth(), day.getDate() - i));
    if (habitDayComplete(state.habits[key])) streak += 1;
    else break;
  }
  return streak;
}
