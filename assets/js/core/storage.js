/* ============================================================
   Lume — device storage

   Every read and write of browser storage in the application
   goes through here. Storage throws rather than returns on a
   file:// origin and with site data blocked, so a bare
   localStorage call is a crash waiting for the wrong browser
   setting.

   set() reports whether the write actually happened. A blocked
   or full store used to fail silently, which once let the
   account system announce "Account created" over an account
   that had not been written.
   ============================================================ */

export const store = {
  get: function (k) {
    try { return localStorage.getItem(k); } catch (e) { return null; }
  },

  set: function (k, v) {
    try { localStorage.setItem(k, v); return true; } catch (e) { return false; }
  }
};
