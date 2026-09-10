/* ============================================================
   Lume — the record store  (CRUD guide §1, §10)

   Everything the user creates lives here: tasks, notes,
   expenses, doses, documents, measurements, entries, items and
   events. One store rather than twelve, because the twelve
   differ in their fields and not in what create, read, update
   and delete mean.

   The guide asks for more than four verbs. What makes the
   difference is the states around them, and those are real here
   rather than mocked:

     loading   a collection is hydrated the first time it is
               opened, on a real deferred read, so the skeleton
               is a frame that actually happens;
     offline   navigator.onLine, and writes made while offline
               are marked queued rather than pretended current;
     error     device storage genuinely refuses writes on a
               file:// origin and with site data blocked, and a
               stored collection can genuinely be corrupt;
     conflict  a record carries a version, and a form that was
               opened against version 3 will not silently
               overwrite version 4.

   Nothing here formats, translates or draws. It holds records,
   reports what happened, and tells whoever is listening.

   Deletion keeps one step of history so Undo is real rather
   than a toast that lies. One step, not a stack: the guide
   offers Undo on the action just taken, and a deeper history
   would let a user restore something they had deliberately
   removed three screens ago.
   ============================================================ */

const KEY = 'lume-records';
const SCHEMA_VERSION = 1;

/* Enough entropy that two records created in the same millisecond do not
   collide, and short enough to read in a URL or a test failure. */
function newId(prefix) {
  return (prefix || 'r') + '-' +
    Date.now().toString(36) +
    Math.random().toString(36).slice(2, 6);
}

export function createRecords(deps) {
  const store = deps.store;
  /* seeds(collection) returns the demonstration records a collection opens
     with the very first time, or null for one that starts empty. It is a
     callback rather than a table so this module never imports tool data. */
  const seeds = deps.seeds || function () { return null; };
  const now = deps.now || function () { return Date.now(); };

  const listeners = [];
  /* Collections are hydrated lazily and cached here. A collection that has
     never been opened is not in this object, which is exactly what makes
     the first open a loading state rather than a synchronous appearance. */
  const cache = {};
  const loading = {};
  const failed = {};

  let undoable = null;

  /* ---------------------------------------------------------
     Disk
     --------------------------------------------------------- */

  function readAll() {
    const raw = store.get(KEY);
    if (!raw) return { v: SCHEMA_VERSION, c: {} };
    try {
      const parsed = JSON.parse(raw);
      if (!parsed || typeof parsed !== 'object' || !parsed.c) throw new Error('shape');
      return parsed;
    } catch (e) {
      /* A corrupt store is a genuine load error, and the honest answer is
         to say so rather than to silently start again over the top of
         whatever the user had. */
      return null;
    }
  }

  function writeAll(all) {
    return store.set(KEY, JSON.stringify(all));
  }

  /* ---------------------------------------------------------
     Hydration

     The first open of a collection is asynchronous on purpose.
     Reading localStorage is synchronous, but the frame in which
     a list has no data yet is real in any app that will ever
     have a backend, and designing it away here would mean the
     skeleton state existed only in a screenshot.
     --------------------------------------------------------- */

  function hydrate(coll, done) {
    if (loading[coll]) { loading[coll].push(done); return; }
    loading[coll] = [done];

    const finish = function (err, items) {
      const waiting = loading[coll];
      delete loading[coll];
      if (err) failed[coll] = err;
      else cache[coll] = items;
      waiting.forEach(function (fn) { fn(err, items); });
      emit(coll);
    };

    /* A timeout rather than a microtask: a skeleton that appears and
       vanishes inside one frame is a flicker, not a loading state. */
    setTimeout(function () {
      const all = readAll();
      if (all === null) { finish(new Error('corrupt'), null); return; }

      if (all.c[coll]) { finish(null, all.c[coll].items || []); return; }

      /* Never opened before: seed it once, and record that it was seeded so
         a user who empties a collection is not given the samples back. */
      const seeded = (seeds(coll) || []).map(function (fields, i) {
        return stamp(Object.assign({}, fields), coll, i, true);
      });
      all.c[coll] = { items: seeded, seeded: 1 };
      writeAll(all);
      finish(null, seeded);
    }, 220);
  }

  /* `seeded` marks a demonstration record. It matters because a seeded
     record's text is a translation key while a record the user wrote is
     their own words — including words that may begin with "@". Sniffing
     the value would corrupt the second kind in order to translate the
     first, so the record says which it is instead. */
  function stamp(fields, coll, i, seeded) {
    const at = now() - (i || 0) * 1000;
    fields.id = fields.id || newId(coll.slice(0, 3));
    fields._v = 1;
    fields._at = at;
    fields._up = at;
    if (seeded) fields._seed = 1;
    return fields;
  }

  function persist(coll) {
    const all = readAll() || { v: SCHEMA_VERSION, c: {} };
    all.c[coll] = { items: cache[coll] || [], seeded: 1 };
    const ok = writeAll(all);
    emit(coll);
    return ok;
  }

  function emit(coll) {
    listeners.forEach(function (fn) {
      try { fn(coll); } catch (err) {
        if (typeof console !== 'undefined') console.error('records listener failed', err);
      }
    });
  }

  /* ---------------------------------------------------------
     What a caller sees

     One call answers "what should I draw?" — the records, and
     which of the states the guide names the collection is in.
     A screen never assembles that from three separate reads and
     never gets to invent a fourth answer.
     --------------------------------------------------------- */

  function offline() {
    return typeof navigator !== 'undefined' && navigator.onLine === false;
  }

  function view(coll) {
    if (failed[coll]) return { state: 'error', items: [], error: failed[coll] };
    if (cache[coll]) {
      return {
        state: offline() ? 'offline' : 'ready',
        items: cache[coll].slice(),
        offline: offline()
      };
    }
    return { state: 'loading', items: [] };
  }

  /* ---------------------------------------------------------
     The four verbs
     --------------------------------------------------------- */

  function get(coll, id) {
    const items = cache[coll];
    if (!items) return null;
    for (let i = 0; i < items.length; i++) if (items[i].id === id) return items[i];
    return null;
  }

  function indexOf(coll, id) {
    const items = cache[coll] || [];
    for (let i = 0; i < items.length; i++) if (items[i].id === id) return i;
    return -1;
  }

  function create(coll, fields) {
    if (!cache[coll]) cache[coll] = [];
    const record = stamp(Object.assign({}, fields), coll, 0);
    if (offline()) record._queued = 1;
    /* Newest first: a record just created must be visible without
       scrolling, whatever the list's sort happens to be afterwards. */
    cache[coll].unshift(record);
    const ok = persist(coll);
    if (!ok) {
      cache[coll].shift();
      return { ok: false, reason: 'storage' };
    }
    undoable = { kind: 'create', coll: coll, id: record.id };
    return { ok: true, record: record };
  }

  /* `expect` is the version the form was opened against. Passing it is what
     makes a conflict detectable; omitting it is a deliberate overwrite. */
  function update(coll, id, fields, expect) {
    const at = indexOf(coll, id);
    if (at === -1) return { ok: false, reason: 'missing' };

    const before = cache[coll][at];
    if (expect !== undefined && expect !== null && before._v !== expect) {
      return { ok: false, reason: 'conflict', current: before };
    }

    const after = Object.assign({}, before, fields, {
      id: before.id,
      _v: before._v + 1,
      _at: before._at,
      _up: now()
    });
    if (offline()) after._queued = 1; else delete after._queued;

    cache[coll][at] = after;
    const ok = persist(coll);
    if (!ok) {
      cache[coll][at] = before;
      return { ok: false, reason: 'storage' };
    }
    undoable = { kind: 'update', coll: coll, id: id, before: before };
    return { ok: true, record: after };
  }

  function remove(coll, id) {
    const at = indexOf(coll, id);
    if (at === -1) return { ok: false, reason: 'missing' };

    const record = cache[coll][at];
    cache[coll].splice(at, 1);
    const ok = persist(coll);
    if (!ok) {
      cache[coll].splice(at, 0, record);
      return { ok: false, reason: 'storage' };
    }
    undoable = { kind: 'delete', coll: coll, record: record, at: at };
    return { ok: true, record: record };
  }

  /* ---------------------------------------------------------
     Undo

     Reverses the last mutation and nothing else. It returns
     what it did so the caller can say so, and null when there
     is nothing to reverse — which is the honest answer after a
     reload, and the reason a "delete permanently" flow must not
     offer Undo at all (CRUD guide §10).
     --------------------------------------------------------- */

  function undo() {
    const entry = undoable;
    if (!entry) return null;
    undoable = null;

    if (entry.kind === 'create') {
      const at = indexOf(entry.coll, entry.id);
      if (at === -1) return null;
      cache[entry.coll].splice(at, 1);
      persist(entry.coll);
      return { kind: 'create', coll: entry.coll };
    }

    if (entry.kind === 'update') {
      const at = indexOf(entry.coll, entry.id);
      if (at === -1) return null;
      cache[entry.coll][at] = entry.before;
      persist(entry.coll);
      return { kind: 'update', coll: entry.coll, record: entry.before };
    }

    if (entry.kind === 'delete') {
      const items = cache[entry.coll] || (cache[entry.coll] = []);
      items.splice(Math.min(entry.at, items.length), 0, entry.record);
      persist(entry.coll);
      return { kind: 'delete', coll: entry.coll, record: entry.record };
    }

    return null;
  }

  function canUndo() { return !!undoable; }
  function forgetUndo() { undoable = null; }

  return {
    /* Ask for a collection. The return value says what to draw right now;
       the callback runs later, and only if there is a later — a collection
       already in hand resolves through the return value alone.

       That distinction matters: the caller's callback is "re-render", so
       firing it for an already-hydrated collection would re-render from
       inside a render, for ever. */
    open: function (coll, done) {
      if (!cache[coll] && !failed[coll]) hydrate(coll, done || function () {});
      return view(coll);
    },
    view: view,
    list: function (coll) { return (cache[coll] || []).slice(); },
    get: get,
    count: function (coll) { return (cache[coll] || []).length; },

    create: create,
    update: update,
    remove: remove,

    undo: undo,
    canUndo: canUndo,
    forgetUndo: forgetUndo,

    /* After a load error, "Try again" must actually try again rather than
       re-reporting the error it cached. */
    retry: function (coll) {
      delete failed[coll];
      delete cache[coll];
      return view(coll);
    },

    isOffline: offline,
    subscribe: function (fn) {
      listeners.push(fn);
      return function () {
        const at = listeners.indexOf(fn);
        if (at !== -1) listeners.splice(at, 1);
      };
    },

    /* Used by the tests, and by nothing in the application. */
    _reset: function () {
      for (const k in cache) delete cache[k];
      for (const k in failed) delete failed[k];
      undoable = null;
    }
  };
}
