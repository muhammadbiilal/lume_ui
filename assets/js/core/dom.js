/* ============================================================
   Lume — the four DOM helpers everything shares

   Deliberately small. A screen reaches for these to find its
   own nodes; anything larger belongs to the screen or to the
   component library, not here.
   ============================================================ */

export function $(sel, root) {
  return (root || document).querySelector(sel);
}

export function $$(sel, root) {
  return Array.prototype.slice.call((root || document).querySelectorAll(sel));
}

export function pad2(n) {
  return n < 10 ? '0' + n : '' + n;
}

const ESCAPES = { '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' };

/* Every value that reaches a template through string concatenation goes
   through here. Feature names, city names and anything a user typed all
   arrive as text, so none of them can close a tag. */
export function esc(s) {
  return String(s).replace(/[&<>"']/g, function (c) { return ESCAPES[c]; });
}
