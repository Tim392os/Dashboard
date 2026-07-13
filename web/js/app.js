// Rendu du dashboard : une fonction de rendu par carte, re-rendu complet à
// chaque mutation de l'état (via subscribe). Les champs de saisie transitoires
// (nouvelle tâche, recherche…) sont restaurés après re-rendu.

import {
  initStore, getState, subscribe, update, uid,
  todayKey, parseDay, daysUntil, nextYearlyOccurrence,
  formatDay, formatHours, formatEuro,
  archiveOldTasks, habitsForDay, setHabit, currentStreak, FRUITS_TARGET,
} from "./store.js";
import { trainingProvider, schoolProvider, bankProvider } from "./providers.js";

const app = document.getElementById("app");

// Données externes (vélo / école / banque), chargées au démarrage.
const external = { training: null, school: null, bank: null };

// État d'interface non persisté.
const ui = { search: "", newTask: "", newNote: "", noteCategory: "idea" };

const esc = (s) => String(s ?? "").replace(/[&<>"']/g, (c) =>
  ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" }[c]));

const NOTE_CATS = {
  idea: { label: "Idée", icon: "💡" },
  shopping: { label: "À acheter", icon: "🛒" },
  link: { label: "Lien", icon: "🔗" },
};

const GOAL_META = {
  week: { label: "Objectif de la semaine", icon: "🗓", color: "var(--accent)" },
  month: { label: "Objectif du mois", icon: "📅", color: "var(--s4)" },
  year: { label: "Objectif de l'année", icon: "✨", color: "var(--s3)" },
};

// ============================== Rendu ==============================

function render() {
  const s = getState();
  app.innerHTML = [
    renderHeader(),
    renderTasks(s),
    ...s.goals.map(renderGoal),
    renderBike(),
    renderSchool(),
    renderHabits(s),
    renderStats(s),
    renderFinance(s),
    renderCounters(s),
    renderNotes(s),
    `<footer>Données stockées sur cet appareil uniquement.</footer>`,
  ].join("");
  restoreTransientInputs();
}

function renderHeader() {
  const now = new Date();
  const date = now.toLocaleDateString("fr-FR", { weekday: "long", day: "numeric", month: "long" });
  const h = now.getHours();
  const greeting = h < 12 && h >= 5 ? "Bonjour Tim" : h < 18 ? "Bon après-midi" : "Bonsoir Tim";
  return `<header>
    <div class="date">${esc(date)}</div>
    <h1>${greeting}</h1>
  </header>`;
}

function card(icon, title, badge, body) {
  return `<section class="card">
    <div class="card-head">
      <span>${icon}</span><span class="title">${title}</span>
      <span class="spacer"></span>${badge || ""}
    </div>
    ${body}
  </section>`;
}

// ---------- Tâches ----------

function renderTasks(s) {
  const tasks = s.tasks.filter((t) => !t.archived);
  const done = tasks.filter((t) => t.done).length;
  const rows = tasks.map((t) => `
    <div class="task-row">
      <button class="task-check ${t.done ? "done" : ""}" data-action="toggle-task" data-id="${t.id}" aria-label="Cocher">✓</button>
      <span class="task-title ${t.done ? "done" : ""}" data-action="edit-task" data-id="${t.id}">${esc(t.title)}</span>
      <button class="task-del" data-action="del-task" data-id="${t.id}" aria-label="Supprimer">×</button>
    </div>`).join("");

  return card("✅", "Tâches",
    `<span class="badge">${done}/${tasks.length}</span>`,
    `${tasks.length ? rows : `<div class="hint">Aucune tâche pour aujourd'hui.</div>`}
     <div class="add-row">
       <span class="plus">＋</span>
       <input id="new-task" placeholder="Nouvelle tâche" enterkeyhint="done" data-input="newTask">
     </div>`);
}

// ---------- Objectifs ----------

function renderGoal(goal) {
  const meta = GOAL_META[goal.period];
  const pct = Math.round(goal.progress * 100);
  return card(meta.icon, meta.label,
    `<span class="pct" style="color:${meta.color}">${pct}%</span>`,
    `<div data-action="edit-goal" data-id="${goal.id}">
      <div class="goal-text">${esc(goal.text)}</div>
      <div class="progress"><div style="width:${pct}%;background:${meta.color}"></div></div>
      <div class="goal-meta">
        <span>🏁 Échéance : ${formatDay(goal.deadline)}</span>
        <span>${daysUntil(goal.deadline)} j restants</span>
      </div>
    </div>`);
}

// ---------- Vélo ----------

function renderBike() {
  const t = external.training;
  const badge = `<span class="badge ${trainingProvider.isLive ? "live" : ""}">${trainingProvider.isLive ? "TrainingPeaks" : "Démo"}</span>`;
  if (!t) return card("🚴", "Vélo", badge, `<div class="hint">Chargement…</div>`);

  const race = t.nextRace ? `
    <div class="race-hero">
      <div class="days"><div class="n">${daysUntil(t.nextRace.date)}</div><div class="u">jours</div></div>
      <div>
        <div class="k">Prochaine course</div>
        <div class="name">${esc(t.nextRace.name)}</div>
        <div class="when">${formatDay(t.nextRace.date)}</div>
      </div>
    </div>` : `<div class="hint">Aucune course planifiée.</div>`;

  const workouts = t.upcomingWorkouts.map((w) => `
    <div class="list-row">
      <span class="day">${parseDay(w.date).toLocaleDateString("fr-FR", { weekday: "short" })}</span>
      <span class="grow">${esc(w.title)}</span>
      <span class="end">${w.durationMinutes} min</span>
    </div>`).join("");

  const load = t.recentLoad ? `
    <div class="tiles" style="margin-top:12px">
      <div class="tile"><div class="value">${formatHours(t.recentLoad.last7DaysHours)}</div><div class="label">7 derniers jours</div></div>
      <div class="tile"><div class="value">${Math.round(t.recentLoad.last7DaysTSS)}</div><div class="label">TSS · 7 jours</div></div>
      <div class="tile"><div class="value">${Math.round(t.recentLoad.fitnessCTL)}</div><div class="label">Forme (CTL)</div></div>
    </div>` : "";

  return card("🚴", "Vélo", badge,
    `${race}<div class="subhead">Prochains entraînements</div>${workouts}${load}`);
}

// ---------- École ----------

function renderSchool() {
  const sc = external.school;
  const badge = `<span class="badge ${schoolProvider.isLive ? "live" : ""}">${schoolProvider.isLive ? "Cabanga" : "Démo"}</span>`;
  if (!sc) return card("📚", "École", badge, `<div class="hint">Chargement…</div>`);

  const relative = (d) => {
    const n = daysUntil(d);
    return n === 0 ? "aujourd'hui" : n === 1 ? "demain" : `dans ${n} j`;
  };
  const row = (chipClass, subject, title, date) => `
    <div class="list-row">
      <span class="chip ${chipClass}">${esc(subject)}</span>
      <span class="grow">${esc(title)}</span>
      <span class="end">${relative(date)}</span>
    </div>`;

  const study = sc.studyMinutesToday >= 60
    ? formatHours(sc.studyMinutesToday / 60) : `${sc.studyMinutesToday} min`;

  return card("📚", "École", badge, `
    <div class="tiles">
      <div class="tile"><div class="value" style="color:var(--s4)">${sc.average}/${sc.averageScale}</div><div class="label">Moyenne générale</div></div>
      <div class="tile"><div class="value">${study}</div><div class="label">Étude aujourd'hui</div></div>
    </div>
    <div class="subhead">Devoirs à rendre</div>
    ${sc.homework.map((h) => row("hw", h.subject, h.title, h.dueDate)).join("") || `<div class="hint">Aucun devoir 🎉</div>`}
    <div class="subhead">Contrôles à venir</div>
    ${sc.exams.map((e) => row("exam", e.subject, e.title, e.date)).join("") || `<div class="hint">Aucun contrôle planifié.</div>`}`);
}

// ---------- Habitudes ----------

function renderHabits(s) {
  const today = habitsForDay(todayKey());
  const streak = currentStreak();
  const sleep = today.sleepHours > 0
    ? `<span class="val">${formatHours(today.sleepHours)}</span>`
    : `<span class="val link">Saisir</span>`;
  const screen = today.screenMinutes > 0
    ? `<span class="val">${formatHours(today.screenMinutes / 60)}</span>`
    : `<span class="val link">Saisir</span>`;

  return card("❤️", "Habitudes",
    `<span class="streak ${streak > 0 ? "on" : "off"}">🔥 ${streak}</span>`, `
    <div class="habit-row" data-action="edit-sleep">
      <span class="ico">😴</span><span class="lbl">Sommeil</span>${sleep}
    </div>
    <div class="habit-row">
      <span class="ico">🥦</span><span class="lbl">Fruits &amp; légumes</span>
      <span class="stepper">
        <button data-action="fruits" data-delta="-1">−</button>
        <span class="count ${today.fruits >= FRUITS_TARGET ? "ok" : ""}">${today.fruits}/${FRUITS_TARGET}</span>
        <button data-action="fruits" data-delta="1">＋</button>
      </span>
    </div>
    <div class="habit-row" data-action="edit-screen">
      <span class="ico">📱</span><span class="lbl">Temps d'écran</span>${screen}
    </div>`);
}

// ---------- Statistiques ----------

function renderStats(s) {
  const streak = currentStreak();
  const yearHours = external.training
    ? Object.values(external.training.yearHoursByMonth).reduce((a, b) => a + b, 0) : 0;

  return card("📊", "Statistiques", "", `
    <div class="tiles">
      <div class="tile"><div class="value" ${streak > 0 ? 'style="color:var(--s3)"' : ""}>${streak} j</div><div class="label">Série d'habitudes</div></div>
      <div class="tile"><div class="value">${formatHours(yearHours)}</div><div class="label">Entraînement cette année</div></div>
    </div>
    <div class="tiles" style="margin-top:10px">
      <div class="tile"><div class="value">${s.recipes.length}</div><div class="label">Recettes testées</div></div>
      <div class="tile"><div class="value" style="color:var(--good)">${formatEuro(s.finance.moneySaved)}</div><div class="label">Argent économisé</div></div>
    </div>
    ${external.training ? `<div class="subhead">Heures d'entraînement par mois</div>
    <div class="chart-wrap">${barChart(external.training.yearHoursByMonth)}</div>` : ""}
    <button class="row-btn" data-action="open-recipes">🍴 Historique des recettes <span class="chev">›</span></button>`);
}

/** Graphique en barres SVG — série unique, marques fines à sommet arrondi,
 *  axes discrets, valeur au toucher (info-bulle). */
function barChart(hoursByMonth) {
  const months = Object.keys(hoursByMonth).map(Number).sort((a, b) => a - b);
  if (!months.length) return "";
  const W = 520, H = 150, padB = 20, padT = 12, padR = 30;
  const max = Math.max(...months.map((m) => hoursByMonth[m]), 1);
  const step = (W - padR) / months.length;
  const barW = Math.min(26, step * 0.55);
  const names = ["Jan", "Fév", "Mar", "Avr", "Mai", "Juin", "Juil", "Aoû", "Sep", "Oct", "Nov", "Déc"];

  let bars = "", labels = "";
  months.forEach((m, i) => {
    const h = Math.max(3, (hoursByMonth[m] / max) * (H - padB - padT));
    const x = i * step + (step - barW) / 2;
    const y = H - padB - h;
    bars += `<path d="M${x},${y + h} v${-(h - 4)} q0,-4 4,-4 h${barW - 8} q4,0 4,4 v${h - 4} z"
      fill="var(--accent)" data-tip="${names[m - 1]} : ${hoursByMonth[m]} h" opacity="0.92"/>`;
    labels += `<text x="${x + barW / 2}" y="${H - 5}" text-anchor="middle" font-size="10" fill="var(--muted)">${names[m - 1]}</text>`;
  });

  // Graduations Y discrètes (2 lignes)
  let grid = "";
  [0.5, 1].forEach((f) => {
    const y = H - padB - f * (H - padB - padT);
    grid += `<line x1="0" x2="${W - padR}" y1="${y}" y2="${y}" stroke="var(--hairline)" stroke-width="1"/>
      <text x="${W - padR + 4}" y="${y + 3}" font-size="10" fill="var(--muted)">${Math.round(max * f)}</text>`;
  });

  return `<svg viewBox="0 0 ${W} ${H}" role="img" aria-label="Heures d'entraînement par mois">
    ${grid}${bars}${labels}
    <line x1="0" x2="${W - padR}" y1="${H - padB}" y2="${H - padB}" stroke="var(--stroke)" stroke-width="1"/>
  </svg>`;
}

// ---------- Finances ----------

function renderFinance(s) {
  const f = s.finance;
  const bank = external.bank;
  const available = bank?.available ?? f.available;
  const savings = bank?.savings ?? f.savings;
  const expenses = bank?.monthExpenses ?? f.monthExpenses;
  const progress = f.savingsGoal > 0 ? Math.min(savings / f.savingsGoal, 1) : 0;

  return card("💰", "Finances",
    `<button class="badge" data-action="edit-finance">Modifier</button>`, `
    <div class="tiles">
      <div class="tile"><div class="value">${formatEuro(available)}</div><div class="label">Disponible</div></div>
      <div class="tile"><div class="value" style="color:var(--good)">${formatEuro(savings)}</div><div class="label">Épargne</div></div>
      <div class="tile"><div class="value" style="color:var(--s5)">${formatEuro(expenses)}</div><div class="label">Dépenses du mois</div></div>
    </div>
    <div class="subhead">Objectif d'épargne — ${Math.round(progress * 100)}%</div>
    <div class="progress"><div style="width:${progress * 100}%;background:var(--good)"></div></div>
    <div class="goal-meta"><span>${formatEuro(savings)} / ${formatEuro(f.savingsGoal)}</span>
    <span>${bank ? "Open Banking connecté" : "Saisie manuelle — aucun identifiant stocké"}</span></div>`);
}

// ---------- Compteurs ----------

function renderCounters(s) {
  const tiles = s.countdowns.map((c) => {
    const date = c.repeatsYearly ? nextYearlyOccurrence(c.date) : c.date;
    return `<button class="count-tile" data-action="edit-countdown" data-id="${c.id}">
      <div>${c.icon}</div>
      <div class="n">${daysUntil(date)}</div>
      <div class="l">jours · ${esc(c.name)}</div>
    </button>`;
  }).join("");

  return card("⏳", "Compteurs",
    `<button class="badge" data-action="add-countdown">＋ Ajouter</button>`,
    `<div class="grid-2">${tiles}</div>`);
}

// ---------- Notes ----------

function renderNotes(s) {
  const q = ui.search.trim().toLowerCase();
  const filtered = q
    ? s.notes.filter((n) => n.text.toLowerCase().includes(q) || NOTE_CATS[n.category].label.toLowerCase().includes(q))
    : s.notes;

  const rows = filtered.slice(0, 12).map((n) => {
    const cat = NOTE_CATS[n.category];
    const isLink = n.category === "link" && /^https?:\/\//i.test(n.text);
    const text = isLink
      ? `<a href="${esc(n.text)}" target="_blank" rel="noopener">${esc(n.text)}</a>`
      : esc(n.text);
    return `<div class="note-row">
      <span class="ico">${cat.icon}</span>
      <div class="body"><div class="txt">${text}</div><div class="cat">${cat.label}</div></div>
      <button class="del" data-action="del-note" data-id="${n.id}">×</button>
    </div>`;
  }).join("");

  const cat = NOTE_CATS[ui.noteCategory];
  return card("📝", "Notes rapides", "", `
    <div class="search">
      <span>🔍</span>
      <input id="note-search" placeholder="Rechercher…" data-input="search">
      ${q ? `<button class="clear" data-action="clear-search">✕</button>` : ""}
    </div>
    ${rows || `<div class="hint">${q ? `Aucun résultat pour « ${esc(ui.search)} »` : "Aucune note pour l'instant."}</div>`}
    <div class="add-row">
      <button class="plus" data-action="cycle-note-cat" title="${cat.label}">${cat.icon}</button>
      <input id="new-note" placeholder="Nouvelle note (${cat.label.toLowerCase()})" enterkeyhint="done" data-input="newNote">
    </div>`);
}

// ============================== Dialogues ==============================

function openDialog(html, onMount) {
  const dialog = document.createElement("dialog");
  dialog.innerHTML = html;
  document.body.appendChild(dialog);
  dialog.addEventListener("close", () => dialog.remove());
  dialog.addEventListener("click", (e) => { if (e.target === dialog) dialog.close(); });
  if (onMount) onMount(dialog);
  dialog.showModal();
  return dialog;
}

function editGoalDialog(goal) {
  const meta = GOAL_META[goal.period];
  openDialog(`
    <h3>${meta.icon} ${meta.label}</h3>
    <div class="field"><label>Objectif</label>
      <textarea id="g-text" rows="2">${esc(goal.text)}</textarea></div>
    <div class="field"><label>Progression — <span id="g-pct">${Math.round(goal.progress * 100)}%</span></label>
      <input type="range" id="g-progress" min="0" max="100" value="${Math.round(goal.progress * 100)}"></div>
    <div class="field"><label>Date limite</label>
      <input type="date" id="g-deadline" value="${goal.deadline}"></div>
    <div class="dialog-actions">
      <button class="ghost" data-close>Annuler</button>
      <button class="primary" data-save>OK</button>
    </div>`,
    (d) => {
      d.querySelector("#g-progress").addEventListener("input", (e) => {
        d.querySelector("#g-pct").textContent = `${e.target.value}%`;
      });
      d.querySelector("[data-close]").onclick = () => d.close();
      d.querySelector("[data-save]").onclick = () => {
        update((s) => {
          const g = s.goals.find((x) => x.id === goal.id);
          g.text = d.querySelector("#g-text").value.trim() || g.text;
          g.progress = Number(d.querySelector("#g-progress").value) / 100;
          g.deadline = d.querySelector("#g-deadline").value || g.deadline;
        });
        d.close();
      };
    });
}

function editTaskDialog(task) {
  openDialog(`
    <h3>Modifier la tâche</h3>
    <div class="field"><textarea id="t-title" rows="2">${esc(task.title)}</textarea></div>
    <div class="dialog-actions">
      <button class="danger" data-del>Supprimer</button>
      <button class="ghost" data-close>Annuler</button>
      <button class="primary" data-save>OK</button>
    </div>`,
    (d) => {
      d.querySelector("[data-close]").onclick = () => d.close();
      d.querySelector("[data-del]").onclick = () => {
        update((s) => { s.tasks = s.tasks.filter((t) => t.id !== task.id); });
        d.close();
      };
      d.querySelector("[data-save]").onclick = () => {
        const title = d.querySelector("#t-title").value.trim();
        if (title) update((s) => { s.tasks.find((t) => t.id === task.id).title = title; });
        d.close();
      };
    });
}

function editFinanceDialog() {
  const f = getState().finance;
  const field = (id, label, value) => `
    <div class="field"><label>${label}</label>
      <input type="number" inputmode="decimal" id="${id}" value="${value}"></div>`;
  openDialog(`
    <h3>💰 Finances</h3>
    ${field("f-available", "Disponible (€)", f.available)}
    ${field("f-savings", "Épargne (€)", f.savings)}
    ${field("f-expenses", "Dépenses du mois (€)", f.monthExpenses)}
    ${field("f-goal", "Objectif d'épargne (€)", f.savingsGoal)}
    ${field("f-saved", "Argent économisé — stats (€)", f.moneySaved)}
    <div class="dialog-actions">
      <button class="ghost" data-close>Annuler</button>
      <button class="primary" data-save>OK</button>
    </div>`,
    (d) => {
      d.querySelector("[data-close]").onclick = () => d.close();
      d.querySelector("[data-save]").onclick = () => {
        update((s) => {
          s.finance.available = Number(d.querySelector("#f-available").value) || 0;
          s.finance.savings = Number(d.querySelector("#f-savings").value) || 0;
          s.finance.monthExpenses = Number(d.querySelector("#f-expenses").value) || 0;
          s.finance.savingsGoal = Number(d.querySelector("#f-goal").value) || 0;
          s.finance.moneySaved = Number(d.querySelector("#f-saved").value) || 0;
        });
        d.close();
      };
    });
}

function editCountdownDialog(countdown) {
  const isNew = !countdown;
  const c = countdown || { name: "", icon: "⭐", date: todayKey(), repeatsYearly: false };
  const emojis = ["⭐", "☀️", "🎁", "❄️", "✈️", "🎓", "🚴", "❤️", "🎉", "🏔"];
  openDialog(`
    <h3>${isNew ? "Nouveau compteur" : "Modifier le compteur"}</h3>
    <div class="field"><label>Nom</label><input id="c-name" value="${esc(c.name)}"></div>
    <div class="field"><label>Date</label><input type="date" id="c-date" value="${c.date}"></div>
    <div class="field"><label><input type="checkbox" id="c-yearly" ${c.repeatsYearly ? "checked" : ""}> Chaque année</label></div>
    <div class="field"><label>Icône</label>
      <div class="emoji-grid">${emojis.map((e) =>
        `<button class="${e === c.icon ? "on" : ""}" data-emoji="${e}">${e}</button>`).join("")}</div></div>
    <div class="dialog-actions">
      ${isNew ? "" : `<button class="danger" data-del>Supprimer</button>`}
      <button class="ghost" data-close>Annuler</button>
      <button class="primary" data-save>OK</button>
    </div>`,
    (d) => {
      let icon = c.icon;
      d.querySelectorAll("[data-emoji]").forEach((b) => b.onclick = () => {
        icon = b.dataset.emoji;
        d.querySelectorAll("[data-emoji]").forEach((x) => x.classList.toggle("on", x === b));
      });
      d.querySelector("[data-close]").onclick = () => d.close();
      if (!isNew) d.querySelector("[data-del]").onclick = () => {
        update((s) => { s.countdowns = s.countdowns.filter((x) => x.id !== c.id); });
        d.close();
      };
      d.querySelector("[data-save]").onclick = () => {
        const name = d.querySelector("#c-name").value.trim();
        const date = d.querySelector("#c-date").value;
        const repeatsYearly = d.querySelector("#c-yearly").checked;
        if (!name || !date) return;
        update((s) => {
          if (isNew) s.countdowns.push({ id: uid(), name, icon, date, repeatsYearly });
          else Object.assign(s.countdowns.find((x) => x.id === c.id), { name, icon, date, repeatsYearly });
        });
        d.close();
      };
    });
}

function sliderDialog({ title, note, max, step, value, unit, onSave }) {
  openDialog(`
    <h3>${title}</h3>
    <div class="field">
      <label><span id="sl-val">${unit(value)}</span></label>
      <input type="range" id="sl" min="0" max="${max}" step="${step}" value="${value}">
      ${note ? `<div class="note">${note}</div>` : ""}
    </div>
    <div class="dialog-actions">
      <button class="ghost" data-close>Annuler</button>
      <button class="primary" data-save>OK</button>
    </div>`,
    (d) => {
      const slider = d.querySelector("#sl");
      slider.addEventListener("input", () => {
        d.querySelector("#sl-val").textContent = unit(Number(slider.value));
      });
      d.querySelector("[data-close]").onclick = () => d.close();
      d.querySelector("[data-save]").onclick = () => { onSave(Number(slider.value)); d.close(); };
    });
}

function recipesDialog() {
  const renderList = () => getState().recipes
    .slice().sort((a, b) => b.testedAt - a.testedAt)
    .map((r) => `
      <div class="recipe-row" data-id="${r.id}">
        <div class="top"><span>${esc(r.name)}</span>
          <span class="when">${new Date(r.testedAt).toLocaleDateString("fr-FR", { day: "numeric", month: "short" })}</span></div>
        <div class="stars">${[1, 2, 3, 4, 5].map((n) =>
          `<button class="${n <= r.rating ? "on" : ""}" data-star="${n}">⭐</button>`).join("")}</div>
        <textarea rows="1" placeholder="Retour sur la recette…" data-feedback>${esc(r.feedback)}</textarea>
      </div>`).join("") || `<div class="hint">Aucune recette testée pour l'instant.</div>`;

  const d = openDialog(`
    <h3>🍴 Recettes testées</h3>
    <div class="field"><input id="r-name" placeholder="Nouvelle recette testée" enterkeyhint="done"></div>
    <div id="r-list">${renderList()}</div>
    <div class="dialog-actions"><button class="primary" data-close>OK</button></div>`,
    (d) => {
      d.querySelector("[data-close]").onclick = () => d.close();
      d.querySelector("#r-name").addEventListener("keydown", (e) => {
        if (e.key !== "Enter") return;
        const name = e.target.value.trim();
        if (!name) return;
        update((s) => s.recipes.push({ id: uid(), name, rating: 0, feedback: "", testedAt: Date.now() }));
        e.target.value = "";
        d.querySelector("#r-list").innerHTML = renderList();
      });
      d.querySelector("#r-list").addEventListener("click", (e) => {
        const star = e.target.closest("[data-star]");
        if (!star) return;
        const id = star.closest(".recipe-row").dataset.id;
        const n = Number(star.dataset.star);
        update((s) => {
          const r = s.recipes.find((x) => x.id === id);
          r.rating = r.rating === n ? 0 : n;
        });
        d.querySelector("#r-list").innerHTML = renderList();
      });
      d.querySelector("#r-list").addEventListener("change", (e) => {
        const ta = e.target.closest("[data-feedback]");
        if (!ta) return;
        const id = ta.closest(".recipe-row").dataset.id;
        update((s) => { s.recipes.find((x) => x.id === id).feedback = ta.value; });
      });
    });
  return d;
}

// ============================== Événements ==============================

document.addEventListener("click", (e) => {
  const el = e.target.closest("[data-action]");
  if (!el) {
    hideTip();
    return;
  }
  const id = el.dataset.id;
  const s = getState();

  switch (el.dataset.action) {
    case "toggle-task":
      update((st) => {
        const t = st.tasks.find((x) => x.id === id);
        t.done = !t.done;
        t.completedAt = t.done ? Date.now() : null;
      });
      break;
    case "del-task":
      update((st) => { st.tasks = st.tasks.filter((x) => x.id !== id); });
      break;
    case "edit-task":
      editTaskDialog(s.tasks.find((x) => x.id === id));
      break;
    case "edit-goal":
      editGoalDialog(s.goals.find((x) => x.id === id));
      break;
    case "fruits": {
      const key = todayKey();
      const current = habitsForDay(key).fruits;
      setHabit(key, { fruits: Math.max(0, current + Number(el.dataset.delta)) });
      break;
    }
    case "edit-sleep":
      sliderDialog({
        title: "😴 Sommeil de la nuit dernière",
        note: "Sur iPhone, la version web ne peut pas lire Apple Santé : recopie la valeur de l'app Santé.",
        max: 14, step: 0.25,
        value: habitsForDay(todayKey()).sleepHours,
        unit: (v) => formatHours(v),
        onSave: (v) => setHabit(todayKey(), { sleepHours: v }),
      });
      break;
    case "edit-screen":
      sliderDialog({
        title: "📱 Temps d'écran aujourd'hui",
        note: "Valeur visible dans Réglages → Temps d'écran.",
        max: 12, step: 0.25,
        value: habitsForDay(todayKey()).screenMinutes / 60,
        unit: (v) => formatHours(v),
        onSave: (v) => setHabit(todayKey(), { screenMinutes: Math.round(v * 60) }),
      });
      break;
    case "edit-finance": editFinanceDialog(); break;
    case "edit-countdown": editCountdownDialog(s.countdowns.find((x) => x.id === id)); break;
    case "add-countdown": editCountdownDialog(null); break;
    case "open-recipes": recipesDialog(); break;
    case "del-note":
      update((st) => { st.notes = st.notes.filter((x) => x.id !== id); });
      break;
    case "clear-search":
      ui.search = "";
      render();
      break;
    case "cycle-note-cat": {
      const cats = Object.keys(NOTE_CATS);
      ui.noteCategory = cats[(cats.indexOf(ui.noteCategory) + 1) % cats.length];
      render();
      document.getElementById("new-note")?.focus();
      break;
    }
  }
});

// Saisie transitoire (nouvelle tâche, note, recherche).
document.addEventListener("input", (e) => {
  const key = e.target.dataset?.input;
  if (!key) return;
  ui[key] = e.target.value;
  if (key === "search") {
    // Recherche instantanée : ne re-rendre que la carte notes serait mieux,
    // mais le re-rendu complet reste fluide ici (listes courtes).
    render();
  }
});

document.addEventListener("keydown", (e) => {
  if (e.key !== "Enter") return;
  if (e.target.id === "new-task") {
    const title = e.target.value.trim();
    if (!title) return;
    ui.newTask = "";
    update((s) => s.tasks.push({ id: uid(), title, done: false, createdAt: Date.now(), completedAt: null, archived: false }));
    document.getElementById("new-task")?.focus();
  }
  if (e.target.id === "new-note") {
    const text = e.target.value.trim();
    if (!text) return;
    ui.newNote = "";
    update((s) => s.notes.unshift({ id: uid(), category: ui.noteCategory, text, createdAt: Date.now() }));
    document.getElementById("new-note")?.focus();
  }
});

function restoreTransientInputs() {
  const map = { "new-task": ui.newTask, "new-note": ui.newNote, "note-search": ui.search };
  for (const [id, value] of Object.entries(map)) {
    const input = document.getElementById(id);
    if (input && input.value !== value) input.value = value;
  }
  // Conserver le focus de la recherche pendant la frappe.
  if (document.activeElement === document.body && ui.search) {
    const search = document.getElementById("note-search");
    if (search) {
      search.focus();
      search.setSelectionRange(search.value.length, search.value.length);
    }
  }
}

// Info-bulle du graphique (toucher / survol).
const tip = document.getElementById("chart-tip");
document.addEventListener("pointerdown", (e) => {
  const target = e.target.closest("[data-tip]");
  if (!target) return;
  tip.textContent = target.dataset.tip;
  tip.style.display = "block";
  tip.style.left = `${e.clientX}px`;
  tip.style.top = `${e.clientY}px`;
});
function hideTip() { tip.style.display = "none"; }

// ============================== Démarrage ==============================

initStore();
subscribe(render);
render();

(async () => {
  const [training, school] = await Promise.all([
    trainingProvider.fetchSummary().catch(() => null),
    schoolProvider.fetchSummary().catch(() => null),
  ]);
  external.training = training;
  external.school = school;
  if (bankProvider) external.bank = await bankProvider.fetchSummary().catch(() => null);
  render();
})();

// Changement de jour / retour au premier plan : archivage + rafraîchissement.
document.addEventListener("visibilitychange", () => {
  if (document.visibilityState === "visible") {
    archiveOldTasks();
    render();
  }
});

if ("serviceWorker" in navigator) {
  navigator.serviceWorker.register("./sw.js").catch(() => {});
}
