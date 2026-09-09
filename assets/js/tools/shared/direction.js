/* ============================================================
   Lume — which way a number moved

   Four money tools draw the same up/down/flat treatment, and a
   fifth copy of this would be a fifth chance for one of them to
   disagree about what zero means.
   ============================================================ */

export function dirOf(n) { return n > 0 ? 'up' : n < 0 ? 'down' : 'flat'; }
