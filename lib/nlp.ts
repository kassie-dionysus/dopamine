const STOP_WORDS = new Set([
  "the",
  "a",
  "an",
  "and",
  "or",
  "to",
  "of",
  "in",
  "for",
  "on",
  "with",
  "is",
  "it",
  "this",
  "that",
  "i",
  "we",
  "you",
  "my",
  "our",
  "be",
  "at",
  "as",
  "by",
  "from",
  "me"
]);

export function tokenize(text: string): string[] {
  return text
    .toLowerCase()
    .replace(/[^a-z0-9\s]/g, " ")
    .split(/\s+/)
    .filter((token) => token.length > 1 && !STOP_WORDS.has(token));
}

export function vectorize(text: string): Record<string, number> {
  const counts: Record<string, number> = {};
  for (const token of tokenize(text)) {
    counts[token] = (counts[token] ?? 0) + 1;
  }
  const norm = Math.sqrt(Object.values(counts).reduce((sum, value) => sum + value * value, 0));
  if (!norm) {
    return counts;
  }
  const normalized: Record<string, number> = {};
  for (const [token, value] of Object.entries(counts)) {
    normalized[token] = value / norm;
  }
  return normalized;
}

export function cosineSimilarity(a: Record<string, number>, b: Record<string, number>): number {
  let score = 0;
  for (const [token, aValue] of Object.entries(a)) {
    const bValue = b[token] ?? 0;
    score += aValue * bValue;
  }
  return score;
}

export function blendCentroid(
  centroid: Record<string, number>,
  vector: Record<string, number>,
  messageCount: number
): Record<string, number> {
  if (messageCount <= 0) {
    return { ...vector };
  }
  const next: Record<string, number> = { ...centroid };
  for (const [token, value] of Object.entries(vector)) {
    next[token] = ((centroid[token] ?? 0) * messageCount + value) / (messageCount + 1);
  }
  return next;
}
