// Import de notes en lot : une note par ligne, champs séparés par « | » ou « ; ».
//
//   Matière | note/barème | date | intitulé
//   Math | 15/20 | 12/10/2026 | Interro dérivées
//
// La date et l'intitulé sont facultatifs (date par défaut : aujourd'hui).
// Pensé pour recopier d'un coup un bulletin Cabanga : tout est traité
// localement, rien n'est envoyé.

import { todayKey } from "./store.js";

/** « 12/10/2026 », « 12/10 », « 2026-10-12 » → « 2026-10-12 ». */
function parseDay(raw) {
  const s = String(raw || "").trim();
  if (!s) return null;
  let m = s.match(/^(\d{4})-(\d{1,2})-(\d{1,2})$/);
  if (m) return `${m[1]}-${m[2].padStart(2, "0")}-${m[3].padStart(2, "0")}`;
  m = s.match(/^(\d{1,2})[/.-](\d{1,2})(?:[/.-](\d{2,4}))?$/);
  if (!m) return null;
  let year = m[3] ? Number(m[3]) : new Date().getFullYear();
  if (year < 100) year += 2000;
  return `${year}-${m[2].padStart(2, "0")}-${m[1].padStart(2, "0")}`;
}

/** « 15/20 », « 15,5 / 20 », « 7.5/10 » → { score, outOf }. */
function parseScore(raw) {
  const m = String(raw || "").trim()
    .match(/^(\d+(?:[.,]\d+)?)\s*\/\s*(\d+(?:[.,]\d+)?)$/);
  if (!m) return null;
  const score = Number(m[1].replace(",", "."));
  const outOf = Number(m[2].replace(",", "."));
  if (!Number.isFinite(score) || !Number.isFinite(outOf)) return null;
  if (outOf <= 0 || score < 0 || score > outOf) return null;
  return { score, outOf };
}

function splitFields(line) {
  // Séparateur : le premier présent parmi « | », « ; », tabulation.
  for (const sep of ["|", ";", "\t"]) {
    if (line.includes(sep)) return line.split(sep).map((f) => f.trim());
  }
  return [line.trim()];
}

/**
 * @param {string} text Le bloc collé par l'utilisateur.
 * @returns {{grades: Array, errors: Array<{line:number, text:string, reason:string}>}}
 */
export function parseGradesText(text) {
  const grades = [];
  const errors = [];
  const lines = String(text || "").split(/\r?\n/);

  lines.forEach((raw, i) => {
    const line = raw.trim();
    if (!line || line.startsWith("#")) return; // ligne vide ou commentaire

    const fields = splitFields(line);
    if (fields.length < 2) {
      errors.push({ line: i + 1, text: line, reason: "séparateur « | » manquant" });
      return;
    }
    const [subject, scoreRaw, dateRaw, ...rest] = fields;
    if (!subject) {
      errors.push({ line: i + 1, text: line, reason: "matière vide" });
      return;
    }
    const score = parseScore(scoreRaw);
    if (!score) {
      errors.push({ line: i + 1, text: line, reason: `note « ${scoreRaw} » illisible (attendu : 15/20)` });
      return;
    }
    const date = dateRaw ? parseDay(dateRaw) : todayKey();
    if (!date) {
      errors.push({ line: i + 1, text: line, reason: `date « ${dateRaw} » illisible (attendu : 12/10/2026)` });
      return;
    }
    grades.push({
      subject,
      score: score.score,
      outOf: score.outOf,
      date,
      label: rest.join(" ").trim(),
    });
  });

  return { grades, errors };
}

/** Clé de doublon : même matière, même note, même date, même intitulé. */
export function gradeKey(g) {
  return [g.subject.toLowerCase(), g.score, g.outOf, g.date, (g.label || "").toLowerCase()].join("|");
}
