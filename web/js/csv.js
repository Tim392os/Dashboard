// Analyse de relevés bancaires CSV — pensé pour l'export « CSV » d'Easy
// Banking Web (BNP Paribas Fortis), tolérant aux variantes (fr/nl/en,
// délimiteur ; ou , ou tabulation, montants « 1.234,56 », dates jj/mm/aaaa).
// Tout est traité localement dans le navigateur : le fichier ne quitte
// jamais l'appareil.

/** Découpe une ligne CSV en champs, en respectant les guillemets. */
function splitLine(line, delimiter) {
  const fields = [];
  let current = "";
  let inQuotes = false;
  for (let i = 0; i < line.length; i++) {
    const c = line[i];
    if (inQuotes) {
      if (c === '"' && line[i + 1] === '"') { current += '"'; i++; }
      else if (c === '"') inQuotes = false;
      else current += c;
    } else if (c === '"') {
      inQuotes = true;
    } else if (c === delimiter) {
      fields.push(current);
      current = "";
    } else {
      current += c;
    }
  }
  fields.push(current);
  return fields.map((f) => f.trim());
}

function detectDelimiter(headerLine) {
  const candidates = [";", ",", "\t"];
  let best = ";";
  let bestCount = -1;
  for (const d of candidates) {
    const count = headerLine.split(d).length - 1;
    if (count > bestCount) { best = d; bestCount = count; }
  }
  return best;
}

/** « -1.234,56 » / « -1,234.56 » / « -1234.56 » → nombre. */
function parseAmount(raw) {
  if (raw == null) return NaN;
  let s = String(raw).replace(/\s|€|EUR/gi, "");
  if (!s) return NaN;
  const lastComma = s.lastIndexOf(",");
  const lastDot = s.lastIndexOf(".");
  if (lastComma > lastDot) {
    // virgule décimale (format belge/français) — les points sont des milliers
    s = s.replace(/\./g, "").replace(",", ".");
  } else if (lastComma !== -1 && lastDot > lastComma) {
    // point décimal — les virgules sont des milliers
    s = s.replace(/,/g, "");
  }
  const value = Number(s);
  return Number.isFinite(value) ? value : NaN;
}

/** « 05/07/2026 », « 05-07-2026 » ou « 2026-07-05 » → « 2026-07-05 ». */
function parseDate(raw) {
  if (!raw) return null;
  const s = String(raw).trim().slice(0, 10);
  let m = s.match(/^(\d{4})-(\d{2})-(\d{2})/);
  if (m) return `${m[1]}-${m[2]}-${m[3]}`;
  m = s.match(/^(\d{1,2})[/.-](\d{1,2})[/.-](\d{4})/);
  if (m) return `${m[3]}-${m[2].padStart(2, "0")}-${m[1].padStart(2, "0")}`;
  return null;
}

function findColumn(headers, keywords) {
  for (let i = 0; i < headers.length; i++) {
    const h = headers[i].toLowerCase();
    if (keywords.some((k) => h.includes(k))) return i;
  }
  return -1;
}

/**
 * @param {string} text Contenu du fichier CSV.
 * @returns {{transactions: Array<{key,date,amount,label}>, error?: string}}
 */
export function parseBankCSV(text) {
  const lines = String(text).replace(/^﻿/, "").split(/\r?\n/).filter((l) => l.trim() !== "");
  if (lines.length < 2) return { transactions: [], error: "Fichier vide ou sans données." };

  const delimiter = detectDelimiter(lines[0]);
  const headers = splitLine(lines[0], delimiter);

  const amountCol = findColumn(headers, ["montant", "bedrag", "amount"]);
  // Date d'exécution de préférence, sinon n'importe quelle colonne date.
  let dateCol = findColumn(headers, ["date d'ex", "date d’ex", "uitvoeringsdatum", "execution date", "boekingsdatum", "date de comptabilisation"]);
  if (dateCol === -1) dateCol = findColumn(headers, ["date", "datum"]);
  const nameCol = findColumn(headers, ["nom de la contrepartie", "naam tegenpartij", "counterparty name", "contrepartie", "tegenpartij", "counterparty"]);
  const commCol = findColumn(headers, ["communication", "mededeling", "détails", "details", "description", "libellé"]);
  const seqCol = findColumn(headers, ["séquence", "sequence", "volgnummer", "referen"]);

  if (amountCol === -1 || dateCol === -1) {
    return {
      transactions: [],
      error: "Colonnes « montant » et « date » introuvables — est-ce bien l'export CSV des opérations ?",
    };
  }

  const transactions = [];
  for (let i = 1; i < lines.length; i++) {
    const fields = splitLine(lines[i], delimiter);
    const amount = parseAmount(fields[amountCol]);
    const date = parseDate(fields[dateCol]);
    if (!date || !Number.isFinite(amount)) continue; // ligne de solde, en-tête répété…
    const label = [nameCol !== -1 ? fields[nameCol] : "", commCol !== -1 ? fields[commCol] : ""]
      .filter(Boolean).join(" — ").slice(0, 120);
    const seq = seqCol !== -1 ? fields[seqCol] : "";
    transactions.push({
      key: seq || `${date}|${amount}|${label}`,
      date,
      amount,
      label,
    });
  }

  if (!transactions.length) {
    return { transactions: [], error: "Aucune opération reconnue dans ce fichier." };
  }
  return { transactions };
}

/** Dépenses (montants négatifs, en valeur absolue) d'un mois donné. */
export function monthExpensesFrom(transactions, year, month) {
  const prefix = `${year}-${String(month).padStart(2, "0")}`;
  let total = 0;
  for (const t of transactions) {
    if (t.date.startsWith(prefix) && t.amount < 0) total += -t.amount;
  }
  return Math.round(total * 100) / 100;
}
