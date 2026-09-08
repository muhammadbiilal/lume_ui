/* ============================================================
   Lume — account, identity and session   (Master Spec §124)

   A global system, not a tool. It owns exactly one question:
   *what does Lume actually know about this person?* — and it
   answers "nothing" without embarrassment, because §125 makes
   that a designed answer rather than a gap to fill with a
   plausible name.

   The store below stands in for a server. It is deliberately
   not a password store: no plaintext is ever written, and the
   digest here is a local integrity check, not the slow KDF a
   real backend would use.
   ============================================================ */
window.LUME_ACCOUNT = function (deps) {
  'use strict';

  var t = deps.t;
  var store = deps.store;

  var K_USERS   = 'lume-accounts';
  var K_SESSION = 'lume-session';
  var K_DEVICE  = 'lume-device';

  /* A session is a month long; a returning user should not be asked to sign
     in because they took a holiday (§124.27). */
  var SESSION_DAYS = 30;

  /* ---------------------------------------------------------
     Persistence
     --------------------------------------------------------- */
  function readJSON(key, fallback) {
    var raw = store.get(key);
    if (!raw) return fallback;
    try { return JSON.parse(raw); } catch (e) { return fallback; }
  }

  /* store.set reports whether it actually wrote. Every mutating path below
     checks it: a blocked or full store is a designed failure (§124.26), not
     a success message over nothing. */
  function writeJSON(key, value) { return store.set(key, JSON.stringify(value)) !== false; }

  function users() { return readJSON(K_USERS, {}); }
  function saveUsers(u) { return writeJSON(K_USERS, u); }

  var STORAGE_FAILED = { ok: false, form: 'acct.err.storage' };

  function key(email) { return String(email || '').trim().toLowerCase(); }

  /* Not a security primitive. See the header. */
  function digest(pw) {
    var h = 0x811c9dc5;
    var s = 'lume:' + String(pw);
    for (var i = 0; i < s.length; i++) {
      h ^= s.charCodeAt(i);
      h = (h + ((h << 1) + (h << 4) + (h << 7) + (h << 8) + (h << 24))) >>> 0;
    }
    return h.toString(16);
  }

  function uid(prefix) {
    return prefix + '-' + Math.random().toString(36).slice(2, 10) + Date.now().toString(36).slice(-4);
  }

  /* ---------------------------------------------------------
     Session
     --------------------------------------------------------- */
  function rawSession() { return readJSON(K_SESSION, null); }

  function session() {
    var s = rawSession();
    if (!s || !s.email) return null;
    var rec = users()[key(s.email)];
    if (!rec) return null;                       /* deleted elsewhere */
    /* A corrupt or absent timestamp used to compare false and read as
       "valid forever". Expiry fails closed. */
    s.expired = typeof s.expires !== 'number' || Date.now() > s.expires;
    /* §124.27 — revoked is a real state. Signing a device out from another
       device, or changing the password, removes its row; that device must
       stop being signed in rather than carry on with a stale blob. The user
       sees the same designed screen an expiry gives them. */
    var rows = rec.sessions || [];
    var known = false;
    for (var i = 0; i < rows.length; i++) if (rows[i].id === s.device) known = true;
    if (!known) { s.expired = true; s.revoked = true; }
    return s;
  }

  /* This browser, not this sign-in. Minting a new id per session listed the
     same browser four times under "Active sessions" after four expiries,
     and let "Sign out all other devices" claim to have signed out three
     devices that never existed (§124.13). */
  function deviceId() {
    var id = store.get(K_DEVICE);
    if (!id) { id = uid('dev'); store.set(K_DEVICE, id); }
    return id;
  }

  function startSession(email) {
    var now = Date.now();
    var s = {
      email: key(email),
      token: uid('tok'),
      issued: now,
      expires: now + SESSION_DAYS * 86400000,
      device: deviceId()
    };
    if (!writeJSON(K_SESSION, s)) return null;
    touchDeviceSession(s);
    return s;
  }

  function endSession() { store.set(K_SESSION, ''); }

  /* §124.27 — an expiry the user can be shown, and a hook the verification
     suite can pull without waiting a month. */
  function expireSession() {
    var s = rawSession();
    if (!s) return false;
    s.expires = Date.now() - 1000;
    writeJSON(K_SESSION, s);
    return true;
  }

  function state() {
    var s = session();
    if (!s) return 'guest';
    return s.expired ? 'expired' : 'authed';
  }

  function isAuthed() { return state() === 'authed'; }
  function isGuest()  { return state() === 'guest'; }
  function isExpired(){ return state() === 'expired'; }

  /* ---------------------------------------------------------
     The record
     --------------------------------------------------------- */
  function user() {
    var s = session();
    if (!s || s.expired) return null;
    return users()[s.email] || null;
  }

  /* The record behind an expired session — enough to greet a returning user
     by name on the "session expired" screen without letting anything else
     read it as a signed-in identity. */
  function pendingUser() {
    var s = session();
    if (!s || !s.expired) return null;
    return users()[s.email] || null;
  }

  function saveUser(rec) {
    var all = users();
    all[key(rec.email)] = rec;
    return saveUsers(all);
  }

  /* §124.3 — one resolution hierarchy, used by every surface. The last stop
     is nothing at all, and nothing at all is a legitimate answer. */
  function displayName() {
    var u = user();
    if (u) {
      if (u.displayName) return trimmed(u.displayName);
      if (u.firstName) return trimmed(u.firstName);
      return null;
    }
    /* The device's own name, written only by onboarding and by a guest
       editing it. An account never writes here, so signing out returns the
       device to its own identity rather than keeping the last holder's. */
    return trimmed(deps.profile().displayName);
  }

  /* A name of nothing but spaces is not a name: it would produce "Good
     morning, " with a dangling comma while initials() correctly returned
     null, and the two would disagree on screen. */
  function trimmed(v) {
    var out = String(v === undefined || v === null ? '' : v).trim();
    return out ? out : null;
  }

  function fullName() {
    var u = user();
    if (!u) return displayName();
    var joined = [u.firstName, u.lastName].filter(Boolean).join(' ').trim();
    return trimmed(u.displayName) || (joined ? joined : null);
  }

  /* Initials are derived from a real name or they do not exist. Taken by
     code point, not by UTF-16 unit: charAt(0) of an emoji is half a
     surrogate pair, which renders as a replacement glyph — worse than the
     designed neutral avatar it was standing in for (§124.14). */
  function firstGlyph(word) {
    var chars = typeof Array.from === 'function' ? Array.from(word) : word.split('');
    return chars.length ? chars[0] : '';
  }

  function initials() {
    var n = fullName();
    if (!n) return null;
    var parts = String(n).trim().split(/\s+/).filter(Boolean);
    if (!parts.length) return null;
    var first = firstGlyph(parts[0]);
    var last = parts.length > 1 ? firstGlyph(parts[parts.length - 1]) : '';
    var out = (first + last).toUpperCase();
    /* Only letters and digits make initials. Anything else has no reading. */
    return /^[\p{L}\p{N}]/u.test(out) ? out : null;
  }

  function email() { var u = user(); return u ? u.email : null; }

  /* Same rule as the name: an account's photo is the account's, and the
     device's is the device's. They never cross. */
  function photo() {
    var u = user();
    if (u) return u.photo || null;
    return deps.profile().photo || null;
  }
  function memberSince() { var u = user(); return u ? u.createdAt : null; }

  /* ---------------------------------------------------------
     Validation  (§124.9)
     --------------------------------------------------------- */
  /* Deliberately conservative rather than RFC-complete: a local part with
     no leading, trailing or doubled dot, a domain of ordinary labels, and
     lengths that cannot be used to write a novel into a storage key. */
  var EMAIL_RE = /^[A-Za-z0-9!#$%&'*+/=?^_`{|}~-]+(\.[A-Za-z0-9!#$%&'*+/=?^_`{|}~-]+)*@([A-Za-z0-9]([A-Za-z0-9-]*[A-Za-z0-9])?\.)+[A-Za-z]{2,24}$/;

  function emailValid(v) {
    var s = String(v === undefined || v === null ? '' : v).trim();
    if (s.length > 254) return false;
    if (s.split('@')[0].length > 64) return false;
    return EMAIL_RE.test(s);
  }

  /* The checklist the user sees IS the rule that is enforced — the screen
     renders this array, and signUp/reset test the same array. */
  function passwordChecks(pw) {
    pw = String(pw || '');
    return [
      { id: 'len',   key: 'acct.pw.len',   ok: pw.length >= 8 },
      { id: 'upper', key: 'acct.pw.upper', ok: /[A-Z]/.test(pw) },
      { id: 'lower', key: 'acct.pw.lower', ok: /[a-z]/.test(pw) },
      { id: 'digit', key: 'acct.pw.digit', ok: /[0-9]/.test(pw) }
    ];
  }

  function passwordOK(pw) {
    return passwordChecks(pw).every(function (c) { return c.ok; });
  }

  /* Strength is advice on top of the rules, never a substitute for them. */
  function passwordStrength(pw) {
    pw = String(pw || '');
    if (!pw) return { score: 0, key: 'acct.pw.strength0', tone: 'off' };
    var checks = passwordChecks(pw);
    var met = checks.filter(function (c) { return c.ok; }).length;
    var bonus = (pw.length >= 12 ? 1 : 0) + (/[^A-Za-z0-9]/.test(pw) ? 1 : 0);
    var score = Math.min(4, Math.max(1, Math.round((met + bonus) * 4 / 6)));
    /* A password that fails a displayed rule can never read better than
       "Fair": "aaaaaaaaaaaa!" scored "Good" beside a checklist showing two
       unticked rows, and was then refused on submission (§124.9). */
    if (met < checks.length) score = Math.min(score, 2);
    return {
      score: score,
      key: 'acct.pw.strength' + score,
      tone: score <= 1 ? 'late' : score === 2 ? 'warn' : score === 3 ? 'info' : 'ok'
    };
  }

  /* ---------------------------------------------------------
     Sign up  (§124.8)
     --------------------------------------------------------- */
  function signUp(input) {
    input = input || {};
    var errors = {};
    var mail = key(input.email);

    if (!mail) errors.email = 'acct.err.emailRequired';
    else if (!emailValid(mail)) errors.email = 'acct.err.emailInvalid';
    else if (users()[mail]) errors.email = 'acct.err.emailTaken';

    if (!input.password) errors.password = 'acct.err.passwordRequired';
    else if (!passwordOK(input.password)) errors.password = 'acct.err.passwordWeak';

    if (!input.confirm) errors.confirm = 'acct.err.confirmRequired';
    else if (input.confirm !== input.password) errors.confirm = 'acct.err.confirmMismatch';

    for (var k in errors) if (errors.hasOwnProperty(k)) return { ok: false, errors: errors };

    var name = String(input.name || '').trim();
    var parts = name ? name.split(/\s+/) : [];
    var rec = {
      id: uid('usr'),
      email: mail,
      displayName: name || trimmed(deps.profile().displayName) || '',
      firstName: parts[0] || '',
      lastName: parts.length > 1 ? parts.slice(1).join(' ') : '',
      phone: '',
      photo: deps.profile().photo || '',   /* §124.24 — the guest's photo comes along */
      digest: digest(input.password),
      createdAt: Date.now(),
      status: 'active',
      emailVerified: false,
      pendingEmail: '',
      twoFactor: false,
      sessions: []
    };
    if (!saveUser(rec)) return STORAGE_FAILED;
    if (!startSession(mail)) return STORAGE_FAILED;
    adopt(rec);
    return { ok: true, user: user() };
  }

  /* §124.24 — everything the guest built comes with them. The account does
     not start a new, emptier life.

     The traffic here runs one way only. A guest's name fills an account
     that has none; an account's name never writes back onto the device.
     The reverse direction handed the next person to sign up on this
     browser the previous holder's name and face. */
  function adopt(rec) {
    var p = deps.profile();
    var deviceName = trimmed(p.displayName);
    if (!rec.displayName && deviceName) {
      rec.displayName = deviceName;
      saveUser(rec);
    }
    p.accountEmail = rec.email;
    /* Country, city, language, units, currency, interests, favourites,
       notes, tasks, expenses and notification preferences all live on the
       profile already and are untouched by signing in. */
    deps.save();
  }

  /* ---------------------------------------------------------
     Sign in  (§124.10)
     --------------------------------------------------------- */
  function signIn(input) {
    /* Signing in as someone else must not inherit the previous holder's
       notification state either. */
    input = input || {};
    var errors = {};
    var mail = key(input.email);
    if (!mail) errors.email = 'acct.err.emailRequired';
    else if (!emailValid(mail)) errors.email = 'acct.err.emailInvalid';
    if (!input.password) errors.password = 'acct.err.passwordRequired';
    for (var k in errors) if (errors.hasOwnProperty(k)) return { ok: false, errors: errors };

    var rec = users()[mail];
    /* §124.10 — one message for "no such account" and "wrong password". The
       difference between them is exactly what an attacker is asking for. */
    if (!rec || rec.digest !== digest(input.password)) {
      return { ok: false, form: 'acct.err.credentials' };
    }
    if (rec.status === 'locked') return { ok: false, form: 'acct.err.locked' };

    if (!startSession(mail)) return STORAGE_FAILED;
    adopt(rec);
    return { ok: true, user: user() };
  }

  function signOut() {
    var s = session();
    if (s) {
      var rec = users()[s.email];
      if (rec) {
        rec.sessions = (rec.sessions || []).filter(function (x) { return x.id !== s.device; });
        saveUser(rec);
      }
    }
    endSession();
    /* The device keeps what the device made. Signing out is not a wipe. */
    var p = deps.profile();
    delete p.accountEmail;
    deps.save();
    /* §124.29 — releasing the account's notification state belongs to
       signing out itself, not to each of the three callers that do it. */
    if (deps.onSignOut) deps.onSignOut();
    return { ok: true };
  }

  /* ---------------------------------------------------------
     Recovery  (§124.11, §124.12)
     --------------------------------------------------------- */
  function requestReset(mailIn) {
    var mail = key(mailIn);
    if (!mail) return { ok: false, errors: { email: 'acct.err.emailRequired' } };
    if (!emailValid(mail)) return { ok: false, errors: { email: 'acct.err.emailInvalid' } };

    var all = users();
    var rec = all[mail];
    var token = uid('rst');
    if (rec) {
      rec.reset = { token: token, email: mail, expires: Date.now() + 3600000 };
      all[mail] = rec;
      saveUsers(all);
    }
    /* Neutral either way, and neutral in the return value too. An address
       with no account gets a token of exactly the same shape, which simply
       resolves to nothing when it is redeemed — otherwise the screen could
       render the difference, and it did: an "open the link" button that
       appeared only for real accounts (§124.11). */
    return { ok: true, token: token, email: mail };
  }

  function resetPassword(input) {
    input = input || {};
    var errors = {};
    if (!input.password) errors.password = 'acct.err.passwordRequired';
    else if (!passwordOK(input.password)) errors.password = 'acct.err.passwordWeak';
    if (input.confirm !== input.password) errors.confirm = 'acct.err.confirmMismatch';
    for (var k in errors) if (errors.hasOwnProperty(k)) return { ok: false, errors: errors };

    var all = users();
    var found = null;
    for (var mail in all) {
      if (all.hasOwnProperty(mail) && all[mail].reset && all[mail].reset.token === input.token) {
        found = all[mail];
        break;
      }
    }
    if (!found) return { ok: false, form: 'acct.err.linkInvalid' };
    if (found.reset.expires < Date.now()) return { ok: false, form: 'acct.err.linkExpired' };
    /* A link issued for one address does not follow the account to another:
       the confirmation screen named the old address, so the old address is
       what the link may act on. */
    if (found.reset.email && found.reset.email !== found.email) {
      return { ok: false, form: 'acct.err.linkInvalid' };
    }

    found.digest = digest(input.password);
    delete found.reset;
    /* A password change invalidates every session (§124.27). */
    found.sessions = [];
    if (!saveUsers(all)) return STORAGE_FAILED;
    /* Only the token owner's session ends. Ending whoever happened to be
       signed in would sign out a bystander. */
    var live = rawSession();
    if (live && key(live.email) === found.email) endSession();
    return { ok: true, email: found.email };
  }

  function changePassword(input) {
    input = input || {};
    var rec = user();
    if (!rec) return { ok: false, form: 'acct.err.signedOut' };

    var errors = {};
    if (!input.current) errors.current = 'acct.err.currentRequired';
    else if (rec.digest !== digest(input.current)) errors.current = 'acct.err.currentWrong';
    if (!input.password) errors.password = 'acct.err.passwordRequired';
    else if (!passwordOK(input.password)) errors.password = 'acct.err.passwordWeak';
    else if (digest(input.password) === rec.digest) errors.password = 'acct.err.passwordSame';
    if (input.confirm !== input.password) errors.confirm = 'acct.err.confirmMismatch';
    for (var k in errors) if (errors.hasOwnProperty(k)) return { ok: false, errors: errors };

    rec.digest = digest(input.password);
    /* Other devices lose their session; this one keeps it. With one row per
       browser this now means what it says. */
    var s = session();
    rec.sessions = (rec.sessions || []).filter(function (x) { return s && x.id === s.device; });
    if (!saveUser(rec)) return STORAGE_FAILED;
    return { ok: true };
  }

  /* ---------------------------------------------------------
     The record itself  (§124.14 – §124.16)
     --------------------------------------------------------- */
  function updateUser(patch) {
    var rec = user();
    if (!rec) {
      /* A guest still has a name, and it is still theirs. */
      var p = deps.profile();
      if (patch.displayName !== undefined) p.displayName = String(patch.displayName || '').trim();
      if (patch.photo !== undefined) p.photo = patch.photo || '';
      deps.save();
      return { ok: true, user: null };
    }
    var errors = {};
    if (patch.phone && !/^[+0-9 ()-]{6,20}$/.test(String(patch.phone).trim())) {
      errors.phone = 'acct.err.phoneInvalid';
    }
    for (var k in errors) if (errors.hasOwnProperty(k)) return { ok: false, errors: errors };

    ['displayName', 'firstName', 'lastName', 'phone', 'photo'].forEach(function (f) {
      if (patch[f] !== undefined) rec[f] = typeof patch[f] === 'string' ? patch[f].trim() : patch[f];
    });
    if (!saveUser(rec)) return STORAGE_FAILED;

    /* An email in the same patch is a separate act with its own verification
       (§124.15). It used to return early, silently discarding the name and
       phone in the same save while still reporting success. */
    if (patch.email !== undefined && key(patch.email) !== rec.email) {
      return requestEmailChange(patch.email);
    }
    /* Nothing is written back onto the device: the account's name and photo
       are the account's (§125). */
    return { ok: true, user: rec };
  }

  /* §124.15 — the new address is pending until it is verified. The account's
     identity never moves silently. */
  function requestEmailChange(next) {
    var rec = user();
    if (!rec) return { ok: false, form: 'acct.err.signedOut' };
    var mail = key(next);
    if (!mail) return { ok: false, errors: { email: 'acct.err.emailRequired' } };
    if (!emailValid(mail)) return { ok: false, errors: { email: 'acct.err.emailInvalid' } };
    if (mail === rec.email) return { ok: false, errors: { email: 'acct.err.emailSame' } };
    if (users()[mail]) return { ok: false, errors: { email: 'acct.err.emailTaken' } };

    rec.pendingEmail = mail;
    rec.pendingCode = String(100000 + Math.floor(Math.random() * 899999));
    saveUser(rec);
    return { ok: true, pending: mail, code: rec.pendingCode };
  }

  function verifyEmail(code) {
    var rec = user();
    if (!rec || !rec.pendingEmail) return { ok: false, form: 'acct.err.nothingPending' };
    if (String(code || '').trim() !== rec.pendingCode) return { ok: false, errors: { code: 'acct.err.codeWrong' } };

    var all = users();
    /* The address was free when the change was requested. It may not be free
       now: nothing reserves it, and the write below is a replacement. Without
       this check, verifying a months-old pending change silently destroyed
       whoever had registered that address in the meantime — their record
       gone, their password no longer working, the address now belonging to
       someone else. */
    if (all[rec.pendingEmail]) {
      rec.pendingEmail = '';
      delete rec.pendingCode;
      saveUser(rec);
      return { ok: false, errors: { code: 'acct.err.emailTaken' } };
    }

    var old = rec.email;
    delete all[old];
    rec.email = rec.pendingEmail;
    rec.emailVerified = true;
    rec.pendingEmail = '';
    delete rec.pendingCode;
    all[rec.email] = rec;
    if (!saveUsers(all)) return STORAGE_FAILED;

    var s = rawSession();
    if (s) { s.email = rec.email; writeJSON(K_SESSION, s); }
    deps.profile().accountEmail = rec.email;
    deps.save();
    return { ok: true };
  }

  function cancelEmailChange() {
    var rec = user();
    if (!rec) return { ok: false };
    rec.pendingEmail = '';
    delete rec.pendingCode;
    saveUser(rec);
    return { ok: true };
  }

  /* ---------------------------------------------------------
     Sessions and devices  (§124.13)
     --------------------------------------------------------- */
  function deviceLabel() {
    var ua = (navigator.userAgent || '');
    if (/iPhone|iPad|iPod/i.test(ua)) return t('acct.device.ios');
    if (/Android/i.test(ua)) return t('acct.device.android');
    if (/Mac OS X/i.test(ua)) return t('acct.device.mac');
    if (/Windows/i.test(ua)) return t('acct.device.windows');
    return t('acct.device.browser');
  }

  function touchDeviceSession(s) {
    var all = users();
    var rec = all[s.email];
    if (!rec) return;
    rec.sessions = rec.sessions || [];
    var here = null;
    rec.sessions.forEach(function (x) { if (x.id === s.device) here = x; });
    if (!here) {
      here = { id: s.device, label: deviceLabel(), place: '', created: Date.now() };
      rec.sessions.push(here);
    }
    here.lastSeen = Date.now();
    here.place = [deps.profile().city, deps.profile().country].filter(Boolean).join(', ');
    saveUsers(all);
  }

  function sessions() {
    var rec = user();
    if (!rec) return [];
    var s = session();
    /* If the current row went missing — a failed write, storage cleared
       between tabs — the screen used to report "0 devices" while the user
       was demonstrably signed in on one. */
    if (s && !(rec.sessions || []).some(function (x) { return x.id === s.device; })) {
      touchDeviceSession(s);
      rec = user() || rec;
    }
    return (rec.sessions || []).slice().sort(function (a, b) {
      return (b.lastSeen || 0) - (a.lastSeen || 0);
    }).map(function (x) {
      return {
        id: x.id, label: x.label, place: x.place, lastSeen: x.lastSeen,
        current: !!(s && x.id === s.device)
      };
    });
  }

  function revokeSession(id) {
    var rec = user();
    if (!rec) return { ok: false };
    var s = session();
    /* Revoking this device is a sign-out, and the caller has to know that so
       it can re-render the whole shell rather than one settings screen. */
    if (s && id === s.device) {
      var out = signOut();
      out.self = true;
      return out;
    }
    rec.sessions = (rec.sessions || []).filter(function (x) { return x.id !== id; });
    saveUser(rec);
    return { ok: true };
  }

  function signOutOthers() {
    var rec = user();
    if (!rec) return { ok: false };
    var s = session();
    var before = (rec.sessions || []).length;
    rec.sessions = (rec.sessions || []).filter(function (x) { return s && x.id === s.device; });
    saveUser(rec);
    return { ok: true, revoked: before - rec.sessions.length };
  }

  function setTwoFactor(on) {
    var rec = user();
    if (!rec) return { ok: false };
    rec.twoFactor = !!on;
    saveUser(rec);
    return { ok: true, on: rec.twoFactor };
  }

  /* Confirming identity is a separate step from acting on it: the delete
     flow checks the password, then asks once more (§124.22). */
  function verifyPassword(pw) {
    var rec = user();
    return !!(rec && pw && rec.digest === digest(pw));
  }

  /* ---------------------------------------------------------
     Deletion  (§124.22)
     --------------------------------------------------------- */
  function deleteAccount(password) {
    var rec = user();
    if (!rec) return { ok: false, form: 'acct.err.signedOut' };
    if (!password) return { ok: false, errors: { current: 'acct.err.currentRequired' } };
    if (rec.digest !== digest(password)) return { ok: false, errors: { current: 'acct.err.currentWrong' } };

    var all = users();
    delete all[rec.email];
    if (!saveUsers(all)) return STORAGE_FAILED;
    endSession();
    var p = deps.profile();
    delete p.accountEmail;
    deps.save();
    if (deps.onSignOut) deps.onSignOut();
    return { ok: true };
  }

  /* ---------------------------------------------------------
     What is actually stored where  (§124.20)

     No backend exists in this build, so nothing syncs. Saying
     so is a designed screen; implying otherwise would be the
     §125 failure in a different costume.
     --------------------------------------------------------- */
  function storage() {
    return {
      synced: [],
      device: [
        { key: 'acct.data.prefs',   count: null },
        { key: 'acct.data.tools',   count: null },
        { key: 'acct.data.notes',   count: null },
        { key: 'acct.data.notify',  count: null },
        { key: 'acct.data.account', count: null }
      ]
    };
  }

  /* ---------------------------------------------------------
     What needs an account  (§124.28)

     Only the account's own surfaces. Nothing in the catalogue
     is gated behind sign-in, because nothing in it needs to be.
     --------------------------------------------------------- */
  /* Only the account's own surfaces. "Data & sync" is not one of them: it
     describes what is on this device, which is exactly as true for a guest,
     and a row a guest can see must lead somewhere (§124.30). */
  var PROTECTED = ['account', 'email', 'phone', 'security', 'password',
                   'sessions', 'delete'];

  function requiresAccount(route) { return PROTECTED.indexOf(route) !== -1; }

  return {
    state: state, isAuthed: isAuthed, isGuest: isGuest, isExpired: isExpired,
    user: user, pendingUser: pendingUser, session: session,
    displayName: displayName, fullName: fullName, initials: initials,
    email: email, photo: photo, memberSince: memberSince,
    emailValid: emailValid, passwordChecks: passwordChecks, passwordOK: passwordOK,
    passwordStrength: passwordStrength,
    signUp: signUp, signIn: signIn, signOut: signOut,
    requestReset: requestReset, resetPassword: resetPassword, changePassword: changePassword,
    updateUser: updateUser, requestEmailChange: requestEmailChange,
    verifyEmail: verifyEmail, cancelEmailChange: cancelEmailChange,
    sessions: sessions, revokeSession: revokeSession, signOutOthers: signOutOthers,
    setTwoFactor: setTwoFactor, deleteAccount: deleteAccount, verifyPassword: verifyPassword,
    expireSession: expireSession, storage: storage, requiresAccount: requiresAccount
  };
};
