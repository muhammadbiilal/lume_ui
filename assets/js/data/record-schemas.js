/* ============================================================
   Lume — record schemas  (CRUD guide §11)

   The guide's own table is the shape of this file: nine record
   families, each with a record, a list emphasis and a special
   consideration. Twelve tools carry them, because tasks and
   reminders are two tools with one shape, and so are habits and
   water, and events and birthdays.

   A schema says what a record *is* — its fields, how a row
   reads, what the detail shows, what the empty collection
   should offer, whether deleting one can be undone. The CRUD
   engine reads that and builds list, detail, create, edit and
   delete from it. No tool writes its own form, and no tool gets
   to have a different idea of what "required" means.

   Two conventions worth stating.

   A seed string that begins with "@" is a translation key, not
   text. Seed records are demonstration content from the string
   packs, so freezing the user's first language into their store
   would leave a Karachi user's sample task in English forever
   after they switched to Urdu. What the *user* types is stored
   exactly as typed and never re-translated — it is theirs.

   `recoverable` is not decoration. The guide asks that delete
   behaviour match whether recovery is possible, so documents
   and health records — the two families whose consideration is
   secure deletion and consent — say no, and their confirmation
   says so instead of offering an Undo that would be a lie.
   ============================================================ */

/* Resolve a seeded key, or pass a user's own text straight through.
   Callers hand this text that has already been through resolve() below, so
   in practice it is a no-op on anything the user wrote. */
export function txt(t, v) {
  if (typeof v !== 'string') return v;
  return v.charAt(0) === '@' ? t(v.slice(1)) : v;
}

/* A record as it should be displayed. A seeded record's strings are
   translation keys and become text in the user's current language; a
   record the user wrote is returned untouched, so a note that opens with
   "@" survives being read back. */
export function resolve(t, r) {
  if (!r || !r._seed) return r;
  const out = {};
  for (const k in r) {
    if (!Object.prototype.hasOwnProperty.call(r, k)) continue;
    out[k] = typeof r[k] === 'string' ? txt(t, r[k]) : r[k];
  }
  return out;
}

/* Sentence-initial capitalisation, in the user's language. Arabic, Urdu,
   Hindi and the CJK scripts have no case, so this is identity there, and
   Turkish gets its dotted capital I. That is why it is one helper rather
   than a capitalised copy of every noun in three dictionaries. */
export function sentence(lang, s) {
  if (!s) return s;
  return s.charAt(0).toLocaleUpperCase(lang || 'en') + s.slice(1);
}

/* The first letter of the record's name, for the list avatar in the
   reference visual. Uses the resolved text so an Urdu row gets an Urdu
   initial rather than a Latin one. */
function initial(s) {
  return String(s || '?').trim().charAt(0).toLocaleUpperCase();
}

function iso(d) {
  const x = d instanceof Date ? d : new Date(d);
  return x.getFullYear() + '-' +
    String(x.getMonth() + 1).padStart(2, '0') + '-' +
    String(x.getDate()).padStart(2, '0');
}

function daysFromNow(n) {
  const d = new Date();
  d.setDate(d.getDate() + n);
  return iso(d);
}

/* A stored ISO date, shown the way the user's locale writes dates. An
   unparseable one is shown as it was stored rather than as "Invalid Date". */
function showDate(c, v) {
  if (!v) return '—';
  const d = new Date(v + (String(v).length === 10 ? 'T00:00:00' : ''));
  return isNaN(d.getTime()) ? String(v) : c.dateShort(d);
}

function relDays(v) {
  if (!v) return null;
  const d = new Date(v + (String(v).length === 10 ? 'T00:00:00' : ''));
  if (isNaN(d.getTime())) return null;
  const today = new Date();
  today.setHours(0, 0, 0, 0);
  return Math.round((d - today) / 86400000);
}

/* "Today", "Yesterday", "in 4 days" — the list emphasis every family in the
   guide's table asks for in one form or another. */
function whenLabel(c, v) {
  const n = relDays(v);
  if (n === null) return showDate(c, v);
  if (n === 0) return c.t('common.today');
  if (n === 1) return c.t('common.tomorrow');
  if (n === -1) return c.t('common.yesterday');
  if (n > 1 && n <= 30) return c.t('common.inDays', { n: n });
  if (n < -1 && n >= -30) return c.t('rec.daysAgo', { n: Math.abs(n) });
  return showDate(c, v);
}

/* ------------------------------------------------------------
   Field kinds

   text · textarea · number · money · date · time · select · check

   Every one is validated by the engine, not by the schema: a
   schema declares `required` and an optional `rule`, and the
   engine owns when validation runs (CRUD guide §10).
   ------------------------------------------------------------ */

const positive = { test: function (v) { return Number(v) > 0; }, key: 'rec.err.positive' };

export const RECORD_SCHEMAS = {

  /* ---- Tasks and reminders ------------------------------- */
  /* Guide: "Due state and completion" · "Undo and recurrence" */

  todos: {
    coll: 'todos', icon: 'i-check-square', noun: 'rec.todos.noun', recoverable: true,
    fields: [
      { name: 'label', kind: 'text', label: 'rec.f.task', required: true, ph: 'rec.todos.ph' },
      { name: 'list', kind: 'select', label: 'rec.f.list', options: 'lists' },
      { name: 'due', kind: 'date', label: 'rec.f.due', optional: true },
      { name: 'priority', kind: 'select', label: 'rec.f.priority', options: 'priority' },
      { name: 'done', kind: 'check', label: 'rec.f.completed' },
      { name: 'notes', kind: 'textarea', label: 'rec.f.notes', optional: true, wide: true }
    ],
    options: {
      lists: function (c) {
        return ['@todos.listWork', '@todos.listHome', '@todos.listPersonal']
          .map(function (k) { return { value: k, label: txt(c.t, k) }; });
      },
      priority: function (c) {
        return [
          { value: 'normal', label: c.t('rec.priority.normal') },
          { value: 'high', label: c.t('rec.priority.high') }
        ];
      }
    },
    row: function (r, c) {
      const name = txt(c.t, r.label);
      return {
        initial: initial(name), title: name, done: !!r.done,
        sub: [txt(c.t, r.list), r.due ? whenLabel(c, r.due) : null].filter(Boolean).join(' · '),
        badge: r.priority === 'high' ? { label: c.t('rec.priority.high'), tone: 'warn' } : null,
        overdue: !r.done && relDays(r.due) !== null && relDays(r.due) < 0
      };
    },
    hero: function (r, c) {
      return {
        kicker: txt(c.t, r.list) || c.t('rec.todos.noun'),
        value: txt(c.t, r.label),
        caption: r.due ? whenLabel(c, r.due) : c.t('rec.noDue'),
        tone: r.done ? 'sport' : 'accent'
      };
    },
    facts: function (r, c) {
      return [
        { label: c.t('rec.f.list'), value: txt(c.t, r.list) || '—' },
        { label: c.t('rec.f.due'), value: r.due ? showDate(c, r.due) : c.t('rec.noDue') },
        { label: c.t('rec.f.priority'), value: c.t(r.priority === 'high' ? 'rec.priority.high' : 'rec.priority.normal') },
        { label: c.t('common.status'), value: c.t(r.done ? 'rec.done' : 'rec.open') },
        { label: c.t('rec.f.notes'), value: r.notes || c.t('rec.none') }
      ];
    },
    filters: function (c) {
      return [
        { value: 'open', label: c.t('rec.open'), test: function (r) { return !r.done; } },
        { value: 'done', label: c.t('rec.done'), test: function (r) { return !!r.done; } }
      ];
    },
    empty: { title: 'rec.todos.emptyTitle', text: 'rec.todos.emptyText' },
    seeds: function () {
      return [
        { label: '@todos.item1', list: '@todos.listWork', due: daysFromNow(0), priority: 'high' },
        { label: '@todos.item2', list: '@todos.listHome', due: daysFromNow(0) },
        { label: '@todos.item3', list: '@todos.listWork', due: daysFromNow(1) },
        { label: '@todos.item4', list: '@todos.listPersonal', done: true }
      ];
    }
  },

  reminders: {
    coll: 'reminders', icon: 'i-bell', noun: 'rec.reminders.noun', recoverable: true,
    fields: [
      { name: 'label', kind: 'text', label: 'rec.f.remindMe', required: true, ph: 'rec.reminders.ph' },
      { name: 'at', kind: 'time', label: 'rec.f.time', required: true },
      { name: 'repeat', kind: 'select', label: 'rec.f.repeat', options: 'repeat' },
      { name: 'notes', kind: 'textarea', label: 'rec.f.notes', optional: true, wide: true }
    ],
    options: {
      repeat: function (c) {
        return [
          { value: '@reminders.once', label: c.t('reminders.once') },
          { value: '@reminders.daily', label: c.t('reminders.daily') },
          { value: '@reminders.weekly', label: c.t('reminders.weekly') }
        ];
      }
    },
    row: function (r, c) {
      const name = txt(c.t, r.label);
      return {
        initial: initial(name), title: name,
        sub: txt(c.t, r.repeat) || c.t('reminders.once'),
        value: r.at || '—'
      };
    },
    hero: function (r, c) {
      return { kicker: txt(c.t, r.repeat) || c.t('reminders.once'), value: r.at || '—',
        title: txt(c.t, r.label), tone: 'accent' };
    },
    facts: function (r, c) {
      return [
        { label: c.t('rec.f.time'), value: r.at || '—' },
        { label: c.t('rec.f.repeat'), value: txt(c.t, r.repeat) || c.t('reminders.once') },
        { label: c.t('rec.f.notes'), value: r.notes || c.t('rec.none') }
      ];
    },
    empty: { title: 'rec.reminders.emptyTitle', text: 'rec.reminders.emptyText' },
    seeds: function () {
      return [
        { label: '@reminders.r1', at: '09:00', repeat: '@reminders.daily' },
        { label: '@reminders.r2', at: '14:00', repeat: '@reminders.once' },
        { label: '@reminders.r3', at: '18:30', repeat: '@reminders.weekly' },
        { label: '@reminders.r4', at: '21:00', repeat: '@reminders.daily' }
      ];
    }
  },

  /* ---- Notes --------------------------------------------- */
  /* Guide: "Title, excerpt and modified date" · "Autosave and conflict" */

  notes: {
    coll: 'notes', icon: 'i-note', noun: 'rec.notes.noun', recoverable: true,
    fields: [
      { name: 'title', kind: 'text', label: 'rec.f.title', required: true, ph: 'rec.notes.ph' },
      { name: 'body', kind: 'textarea', label: 'rec.f.note', wide: true, rows: 6 },
      { name: 'folder', kind: 'select', label: 'rec.f.folder', options: 'folders' },
      { name: 'pinned', kind: 'check', label: 'rec.f.pinned' }
    ],
    options: {
      folders: function (c) {
        return ['@notes.fWork', '@notes.fPersonal', '@notes.fIdeas']
          .map(function (k) { return { value: k, label: txt(c.t, k) }; });
      }
    },
    row: function (r, c) {
      const title = txt(c.t, r.title);
      const body = txt(c.t, r.body) || '';
      return {
        initial: initial(title), title: title,
        sub: body.length > 62 ? body.slice(0, 62) + '…' : body,
        meta: [txt(c.t, r.folder), whenLabel(c, iso(new Date(r._up || r._at)))].filter(Boolean),
        badge: r.pinned ? { label: c.t('rec.pinned'), tone: 'info' } : null
      };
    },
    hero: function (r, c) {
      return { kicker: txt(c.t, r.folder) || c.t('rec.notes.noun'), value: txt(c.t, r.title),
        caption: c.t('rec.modified', { when: whenLabel(c, iso(new Date(r._up || r._at))) }), tone: 'night' };
    },
    facts: function (r, c) {
      return [
        { label: c.t('rec.f.note'), value: txt(c.t, r.body) || c.t('rec.none'), block: true },
        { label: c.t('rec.f.folder'), value: txt(c.t, r.folder) || '—' },
        { label: c.t('rec.f.pinned'), value: c.t(r.pinned ? 'common.yes' : 'common.no') }
      ];
    },
    empty: { title: 'rec.notes.emptyTitle', text: 'rec.notes.emptyText' },
    seeds: function () {
      return [
        { title: '@notes.n1', body: '@notes.n1x', folder: '@notes.fWork', pinned: true },
        { title: '@notes.n2', body: '@notes.n2x', folder: '@notes.fPersonal', pinned: true },
        { title: '@notes.n3', body: '@notes.n3x', folder: '@notes.fIdeas' },
        { title: '@notes.n4', body: '@notes.n4x', folder: '@notes.fWork' }
      ];
    }
  },

  /* ---- Expenses ------------------------------------------ */
  /* Guide: "Amount, category and date" · "Currency, receipt, privacy"
     This is the family the reference visuals were drawn from, so it is the
     one the engine is measured against. */

  expenses: {
    coll: 'expenses', icon: 'i-wallet', noun: 'rec.expenses.noun', recoverable: true, money: true,
    fields: [
      { name: 'title', kind: 'text', label: 'rec.f.title', required: true, ph: 'rec.expenses.ph' },
      { name: 'amount', kind: 'money', label: 'rec.f.amount', required: true, rule: positive },
      { name: 'cat', kind: 'select', label: 'rec.f.category', options: 'cats' },
      { name: 'date', kind: 'date', label: 'rec.f.date', required: true },
      { name: 'method', kind: 'select', label: 'rec.f.payment', options: 'methods' },
      { name: 'notes', kind: 'textarea', label: 'rec.f.notes', optional: true, wide: true },
      { name: 'receipt', kind: 'attach', label: 'rec.f.receipt', optional: true, wide: true }
    ],
    options: {
      cats: function (c) {
        return c.D.EXPENSE_CATEGORIES.map(function (x) {
          return { value: x.id, label: x.label, icon: x.icon };
        });
      },
      methods: function (c) {
        return ['cash', 'card', 'transfer', 'wallet'].map(function (k) {
          return { value: k, label: c.t('rec.pay.' + k) };
        });
      }
    },
    catOf: function (r, c) {
      const found = c.D.EXPENSE_CATEGORIES.filter(function (x) { return x.id === r.cat; })[0];
      return found || c.D.EXPENSE_CATEGORIES[c.D.EXPENSE_CATEGORIES.length - 1];
    },
    row: function (r, c) {
      const cat = RECORD_SCHEMAS.expenses.catOf(r, c);
      const title = txt(c.t, r.title);
      return {
        initial: initial(title), title: title,
        sub: [whenLabel(c, r.date), cat.label].filter(Boolean).join(' · '),
        value: c.moneyRaw(Math.abs(Number(r.amount) || 0), null, 0)
      };
    },
    hero: function (r, c) {
      const cat = RECORD_SCHEMAS.expenses.catOf(r, c);
      return {
        kicker: cat.label,
        value: c.moneyRaw(Math.abs(Number(r.amount) || 0), null, 0),
        title: txt(c.t, r.title),
        caption: showDate(c, r.date),
        tone: 'accent'
      };
    },
    facts: function (r, c) {
      const cat = RECORD_SCHEMAS.expenses.catOf(r, c);
      return [
        { label: c.t('expenses.category'), value: cat.label },
        { label: c.t('rec.f.payment'), value: c.t('rec.pay.' + (r.method || 'cash')) },
        { label: c.t('rec.f.notes'), value: r.notes || c.t('rec.none') },
        { label: c.t('rec.f.receipt'), value: c.t(r.receipt ? 'rec.attached' : 'rec.notAttached') }
      ];
    },
    filters: function (c) {
      const month = new Date().getMonth();
      return [{
        value: 'month', label: c.t('common.thisMonth'),
        test: function (r) {
          const d = new Date(r.date + 'T00:00:00');
          return !isNaN(d.getTime()) && d.getMonth() === month;
        }
      }].concat(c.D.EXPENSE_CATEGORIES.slice(0, 3).map(function (x) {
        return { value: x.id, label: x.label, test: function (r) { return r.cat === x.id; } };
      }));
    },
    sorts: {
      date: function (r) { return r.date || ''; },
      amount: function (r) { return Math.abs(Number(r.amount) || 0); },
      cat: function (r) { return r.cat || ''; }
    },
    total: function (items) {
      return items.reduce(function (a, r) { return a + Math.abs(Number(r.amount) || 0); }, 0);
    },
    empty: { title: 'rec.expenses.emptyTitle', text: 'rec.expenses.emptyText' },
    seeds: function () {
      return [
        { title: '@rec.seed.groceries', amount: 34, cat: 'groceries', date: daysFromNow(0), method: 'card', notes: '@rec.seed.groceriesNote' },
        { title: '@rec.seed.taxi', amount: 9, cat: 'transport', date: daysFromNow(-1), method: 'cash' },
        { title: '@rec.seed.internet', amount: 28, cat: 'bills', date: daysFromNow(-3), method: 'transfer' },
        { title: '@rec.seed.coffee', amount: 7, cat: 'eating', date: daysFromNow(-4), method: 'cash' },
        { title: '@rec.seed.pharmacy', amount: 17, cat: 'health', date: daysFromNow(-6), method: 'card' }
      ];
    }
  },

  /* ---- Medication ---------------------------------------- */
  /* Guide: "Next dose and adherence" · "Safety wording" */

  meds: {
    coll: 'meds', icon: 'i-pill', noun: 'rec.meds.noun', recoverable: true, sensitive: true,
    fields: [
      { name: 'name', kind: 'text', label: 'common.name', required: true, ph: 'rec.meds.ph' },
      { name: 'dose', kind: 'text', label: 'rec.f.dose', required: true, ph: 'rec.meds.dosePh' },
      { name: 'when', kind: 'select', label: 'rec.f.schedule', options: 'schedule' },
      { name: 'at', kind: 'time', label: 'rec.f.firstDose' },
      { name: 'left', kind: 'number', label: 'rec.f.dosesLeft', optional: true },
      { name: 'notes', kind: 'textarea', label: 'rec.f.notes', optional: true, wide: true }
    ],
    options: {
      schedule: function (c) {
        return ['daily', 'twice', 'weekly', 'needed'].map(function (k) {
          return { value: k, label: c.t('rec.sched.' + k) };
        });
      }
    },
    row: function (r, c) {
      const name = txt(c.t, r.name);
      return {
        initial: initial(name), title: name,
        sub: [r.dose, c.t('rec.sched.' + (r.when || 'daily'))].filter(Boolean).join(' · '),
        value: r.at || '—',
        badge: Number(r.left) > 0 && Number(r.left) <= 3
          ? { label: c.t('rec.meds.low'), tone: 'warn' } : null
      };
    },
    hero: function (r, c) {
      return { kicker: c.t('rec.sched.' + (r.when || 'daily')), value: txt(c.t, r.name),
        title: r.dose, caption: r.at ? c.t('rec.nextAt', { time: r.at }) : '', tone: 'sky' };
    },
    facts: function (r, c) {
      return [
        { label: c.t('rec.f.dose'), value: r.dose || '—' },
        { label: c.t('rec.f.schedule'), value: c.t('rec.sched.' + (r.when || 'daily')) },
        { label: c.t('rec.f.firstDose'), value: r.at || '—' },
        { label: c.t('rec.f.dosesLeft'), value: r.left === undefined || r.left === '' ? '—' : c.num(Number(r.left)) },
        { label: c.t('rec.f.notes'), value: r.notes || c.t('rec.none') }
      ];
    },
    /* §11 of the guide asks for safety wording on this family specifically. */
    note: 'rec.meds.safety',
    empty: { title: 'rec.meds.emptyTitle', text: 'rec.meds.emptyText' },
    seeds: function () {
      return [
        { name: '@rec.seed.vitd', dose: '50,000 IU', when: 'weekly', at: '09:00', left: 3 },
        { name: '@rec.seed.metformin', dose: '500 mg', when: 'twice', at: '08:00', left: 22 },
        { name: '@rec.seed.cetirizine', dose: '10 mg', when: 'needed', at: '', left: 9 }
      ];
    }
  },

  /* ---- Documents ----------------------------------------- */
  /* Guide: "Type, expiry and lock state" · "Encryption and secure deletion"
     Secure deletion is why this family cannot be undone. */

  documents: {
    coll: 'documents', icon: 'i-folder', noun: 'rec.documents.noun',
    recoverable: false, sensitive: true,
    fields: [
      { name: 'name', kind: 'text', label: 'common.name', required: true, ph: 'rec.documents.ph' },
      { name: 'cat', kind: 'select', label: 'rec.f.category', options: 'cats' },
      { name: 'num', kind: 'text', label: 'rec.f.reference', optional: true },
      { name: 'expires', kind: 'date', label: 'rec.f.expiry', optional: true },
      { name: 'holder', kind: 'text', label: 'rec.f.holder', optional: true },
      { name: 'notes', kind: 'textarea', label: 'rec.f.notes', optional: true, wide: true }
    ],
    options: {
      cats: function (c) {
        return ['identity', 'vehicle', 'insurance', 'property', 'education', 'other']
          .map(function (k) { return { value: k, label: c.t('rec.doc.' + k) }; });
      }
    },
    row: function (r, c) {
      const name = txt(c.t, r.name);
      const n = relDays(r.expires);
      return {
        initial: initial(name), title: name,
        sub: [c.t('rec.doc.' + (r.cat || 'other')), r.expires ? showDate(c, r.expires) : c.t('docs.noExpiry')]
          .filter(Boolean).join(' · '),
        badge: n === null ? null
             : n < 0 ? { label: c.t('docs.expired'), tone: 'late' }
             : n < 45 ? { label: c.t('docs.expiringSoonShort'), tone: 'warn' }
             : { label: c.t('docs.valid'), tone: 'ok' }
      };
    },
    hero: function (r, c) {
      return { kicker: c.t('rec.doc.' + (r.cat || 'other')), value: txt(c.t, r.name),
        caption: r.expires ? c.t('rec.expiresOn', { date: showDate(c, r.expires) }) : c.t('docs.noExpiry'),
        tone: 'lock' };
    },
    facts: function (r, c) {
      return [
        { label: c.t('docs.category'), value: c.t('rec.doc.' + (r.cat || 'other')) },
        { label: c.t('rec.f.reference'), value: r.num || '—' },
        { label: c.t('docs.expiry'), value: r.expires ? showDate(c, r.expires) : c.t('docs.noExpiry') },
        { label: c.t('rec.f.holder'), value: r.holder || '—' },
        { label: c.t('rec.f.notes'), value: r.notes || c.t('rec.none') }
      ];
    },
    empty: { title: 'rec.documents.emptyTitle', text: 'rec.documents.emptyText' },
    seeds: function () {
      return [
        { name: '@rec.seed.passport', cat: 'identity', num: 'AB••••42', expires: daysFromNow(918), holder: '@rec.seed.you' },
        { name: '@rec.seed.nid', cat: 'identity', num: '61101-•••••••-3', expires: daysFromNow(440), holder: '@rec.seed.you' },
        { name: '@rec.seed.licence', cat: 'vehicle', num: 'DL-••••-118', expires: daysFromNow(25), holder: '@rec.seed.you' },
        { name: '@rec.seed.insurance', cat: 'insurance', num: 'POL-••••-7781', expires: daysFromNow(115), holder: '@rec.seed.family' }
      ];
    }
  },

  /* ---- Health records ------------------------------------ */
  /* Guide: "Date, value and source" · "Consent and export audit" */

  health: {
    coll: 'health', icon: 'i-pulse', noun: 'rec.health.noun',
    recoverable: false, sensitive: true,
    fields: [
      { name: 'title', kind: 'text', label: 'rec.f.title', required: true, ph: 'rec.health.ph' },
      { name: 'kind', kind: 'select', label: 'rec.f.recordType', options: 'kinds' },
      { name: 'date', kind: 'date', label: 'rec.f.date', required: true },
      { name: 'who', kind: 'text', label: 'rec.f.source', optional: true, ph: 'rec.health.whoPh' },
      { name: 'value', kind: 'text', label: 'rec.f.value', optional: true },
      { name: 'notes', kind: 'textarea', label: 'rec.f.notes', optional: true, wide: true }
    ],
    options: {
      kinds: function (c) {
        return ['appointment', 'report', 'prescription', 'vaccination', 'measurement']
          .map(function (k) { return { value: k, label: c.t('rec.health.' + k) }; });
      }
    },
    row: function (r, c) {
      const title = txt(c.t, r.title);
      return {
        initial: initial(title), title: title,
        sub: [c.t('rec.health.' + (r.kind || 'report')), whenLabel(c, r.date)].filter(Boolean).join(' · '),
        value: r.value || ''
      };
    },
    hero: function (r, c) {
      return { kicker: c.t('rec.health.' + (r.kind || 'report')), value: r.value || txt(c.t, r.title),
        title: r.value ? txt(c.t, r.title) : '', caption: showDate(c, r.date), tone: 'prayer' };
    },
    facts: function (r, c) {
      return [
        { label: c.t('health.recordType'), value: c.t('rec.health.' + (r.kind || 'report')) },
        { label: c.t('common.date'), value: showDate(c, r.date) },
        { label: c.t('rec.f.source'), value: txt(c.t, r.who) || '—' },
        { label: c.t('common.value'), value: r.value || '—' },
        { label: c.t('rec.f.notes'), value: r.notes || c.t('rec.none') }
      ];
    },
    empty: { title: 'rec.health.emptyTitle', text: 'rec.health.emptyText' },
    seeds: function () {
      return [
        { title: '@rec.seed.physical', kind: 'appointment', date: daysFromNow(8), who: '@rec.seed.clinic' },
        { title: '@rec.seed.lipid', kind: 'report', date: daysFromNow(-39), who: '@rec.seed.lab', value: '4.9 mmol/L' },
        { title: '@rec.seed.weight', kind: 'measurement', date: daysFromNow(-2), value: '75 kg' }
      ];
    }
  },

  /* ---- Habits and water ---------------------------------- */
  /* Guide: "Progress and streak" · "Fast optimistic logging"
     These two are the families whose writes do not wait for confirmation:
     tapping a habit must feel instant or nobody taps it. */

  habits: {
    coll: 'habits', icon: 'i-flame', noun: 'rec.habits.noun', recoverable: true, optimistic: true,
    fields: [
      { name: 'name', kind: 'text', label: 'common.name', required: true, ph: 'rec.habits.ph' },
      { name: 'target', kind: 'select', label: 'rec.f.frequency', options: 'freq' },
      { name: 'streak', kind: 'number', label: 'rec.f.streak', optional: true },
      { name: 'notes', kind: 'textarea', label: 'rec.f.notes', optional: true, wide: true }
    ],
    options: {
      freq: function (c) {
        return ['daily', 'weekdays', 'weekly'].map(function (k) {
          return { value: k, label: c.t('rec.freq.' + k) };
        });
      }
    },
    row: function (r, c) {
      const name = txt(c.t, r.name);
      return {
        initial: initial(name), title: name,
        sub: c.t('rec.freq.' + (r.target || 'daily')),
        value: c.t('rec.dayStreak', { n: c.num(Number(r.streak) || 0) })
      };
    },
    hero: function (r, c) {
      return { kicker: c.t('rec.freq.' + (r.target || 'daily')),
        value: c.num(Number(r.streak) || 0), title: txt(c.t, r.name),
        caption: c.t('habits.currentStreak'), tone: 'flame' };
    },
    facts: function (r, c) {
      return [
        { label: c.t('rec.f.frequency'), value: c.t('rec.freq.' + (r.target || 'daily')) },
        { label: c.t('habits.currentStreak'), value: c.t('rec.dayStreak', { n: c.num(Number(r.streak) || 0) }) },
        { label: c.t('rec.f.notes'), value: r.notes || c.t('rec.none') }
      ];
    },
    empty: { title: 'rec.habits.emptyTitle', text: 'rec.habits.emptyText' },
    seeds: function () {
      return [
        { name: '@habits.h1', target: 'daily', streak: 4 },
        { name: '@habits.h2', target: 'daily', streak: 2 },
        { name: '@habits.h3', target: 'weekdays', streak: 0 },
        { name: '@habits.h4', target: 'daily', streak: 12 }
      ];
    }
  },

  water: {
    coll: 'water', icon: 'i-droplet', noun: 'rec.water.noun', recoverable: true, optimistic: true,
    fields: [
      { name: 'ml', kind: 'number', label: 'rec.f.amountMl', required: true, rule: positive },
      { name: 'kind', kind: 'select', label: 'rec.f.drink', options: 'kinds' },
      { name: 'at', kind: 'time', label: 'rec.f.time', required: true }
    ],
    options: {
      kinds: function (c) {
        return [
          { value: '@water.kindWater', label: c.t('water.kindWater') },
          { value: '@water.kindTea', label: c.t('water.kindTea') }
        ];
      }
    },
    row: function (r, c) {
      const kind = txt(c.t, r.kind) || c.t('water.kindWater');
      return {
        initial: initial(kind), title: kind, sub: r.at || '',
        value: c.volume ? c.volume(Number(r.ml) || 0) : c.num(Number(r.ml) || 0) + ' ml'
      };
    },
    hero: function (r, c) {
      return { kicker: txt(c.t, r.kind) || c.t('water.kindWater'),
        value: c.volume ? c.volume(Number(r.ml) || 0) : c.num(Number(r.ml) || 0) + ' ml',
        caption: r.at || '', tone: 'sky' };
    },
    facts: function (r, c) {
      return [
        { label: c.t('rec.f.drink'), value: txt(c.t, r.kind) || c.t('water.kindWater') },
        { label: c.t('rec.f.time'), value: r.at || '—' }
      ];
    },
    empty: { title: 'rec.water.emptyTitle', text: 'rec.water.emptyText' },
    seeds: function () {
      return [
        { ml: 250, kind: '@water.kindWater', at: '08:10' },
        { ml: 500, kind: '@water.kindWater', at: '10:30' },
        { ml: 250, kind: '@water.kindTea', at: '13:05' },
        { ml: 250, kind: '@water.kindWater', at: '15:40' }
      ];
    }
  },

  /* ---- Shopping ------------------------------------------ */
  /* Guide: "Checked state and quantity" · "Confirmed bulk clear" */

  shopping: {
    coll: 'shopping', icon: 'i-cart', noun: 'rec.shopping.noun', recoverable: true, optimistic: true,
    fields: [
      { name: 'label', kind: 'text', label: 'rec.f.item', required: true, ph: 'rec.shopping.ph' },
      { name: 'qty', kind: 'text', label: 'rec.f.quantity', optional: true, ph: 'rec.shopping.qtyPh' },
      { name: 'group', kind: 'select', label: 'rec.f.aisle', options: 'groups' },
      { name: 'price', kind: 'money', label: 'rec.f.estimate', optional: true },
      { name: 'done', kind: 'check', label: 'rec.f.inBasket' }
    ],
    options: {
      groups: function (c) {
        return ['@shop.gProduce', '@shop.gDairy', '@shop.gHousehold']
          .map(function (k) { return { value: k, label: txt(c.t, k) }; });
      }
    },
    row: function (r, c) {
      const name = txt(c.t, r.label);
      return {
        initial: initial(name), title: name, done: !!r.done,
        sub: [r.qty, txt(c.t, r.group)].filter(Boolean).join(' · '),
        value: r.price ? c.moneyRaw(Number(r.price), null, 0) : ''
      };
    },
    hero: function (r, c) {
      return { kicker: txt(c.t, r.group) || c.t('rec.shopping.noun'), value: txt(c.t, r.label),
        caption: r.qty || '', tone: r.done ? 'sport' : 'accent' };
    },
    facts: function (r, c) {
      return [
        { label: c.t('rec.f.quantity'), value: r.qty || '—' },
        { label: c.t('rec.f.aisle'), value: txt(c.t, r.group) || '—' },
        { label: c.t('rec.f.estimate'), value: r.price ? c.moneyRaw(Number(r.price), null, 0) : '—' },
        { label: c.t('common.status'), value: c.t(r.done ? 'rec.f.inBasket' : 'rec.toBuy') }
      ];
    },
    filters: function (c) {
      return [
        { value: 'todo', label: c.t('rec.toBuy'), test: function (r) { return !r.done; } },
        { value: 'done', label: c.t('rec.f.inBasket'), test: function (r) { return !!r.done; } }
      ];
    },
    /* The guide's special consideration for this family. */
    bulk: { act: 'clear', label: 'rec.shopping.clear', confirm: 'rec.shopping.clearConfirm',
      test: function (r) { return !!r.done; } },
    empty: { title: 'rec.shopping.emptyTitle', text: 'rec.shopping.emptyText' },
    seeds: function () {
      return [
        { label: '@shop.i1', qty: '2 kg', price: 4, group: '@shop.gProduce' },
        { label: '@shop.i2', qty: '1 L', price: 2, group: '@shop.gDairy' },
        { label: '@shop.i3', qty: '500 g', price: 6, group: '@shop.gDairy', done: true },
        { label: '@shop.i4', qty: '1', price: 3, group: '@shop.gProduce' },
        { label: '@shop.i5', qty: '2', price: 8, group: '@shop.gHousehold' }
      ];
    }
  },

  /* ---- Events and birthdays ------------------------------ */
  /* Guide: "Date and recurrence" · "Timezone and permissions" */

  events: {
    coll: 'events', icon: 'i-calendar', noun: 'rec.events.noun', recoverable: true,
    fields: [
      { name: 'title', kind: 'text', label: 'rec.f.title', required: true, ph: 'rec.events.ph' },
      { name: 'date', kind: 'date', label: 'rec.f.date', required: true },
      { name: 'at', kind: 'time', label: 'rec.f.time' },
      { name: 'where', kind: 'text', label: 'rec.f.where', optional: true },
      { name: 'people', kind: 'number', label: 'rec.f.people', optional: true },
      { name: 'notes', kind: 'textarea', label: 'rec.f.notes', optional: true, wide: true }
    ],
    row: function (r, c) {
      const title = txt(c.t, r.title);
      return {
        initial: initial(title), title: title,
        sub: [whenLabel(c, r.date), txt(c.t, r.where)].filter(Boolean).join(' · '),
        value: r.at || ''
      };
    },
    hero: function (r, c) {
      return { kicker: whenLabel(c, r.date), value: txt(c.t, r.title),
        title: txt(c.t, r.where) || '', caption: r.at || '', tone: 'night' };
    },
    facts: function (r, c) {
      return [
        { label: c.t('common.date'), value: showDate(c, r.date) },
        { label: c.t('rec.f.time'), value: r.at || '—' },
        { label: c.t('rec.f.where'), value: txt(c.t, r.where) || '—' },
        { label: c.t('rec.f.people'), value: r.people ? c.num(Number(r.people)) : '—' },
        /* §16 — a time-sensitive record says which clock it is on. */
        { label: c.t('rec.f.timezone'), value: c.L.country().tz },
        { label: c.t('rec.f.notes'), value: r.notes || c.t('rec.none') }
      ];
    },
    sorts: { date: function (r) { return r.date || ''; }, title: function (r) { return r.title || ''; } },
    empty: { title: 'rec.events.emptyTitle', text: 'rec.events.emptyText' },
    seeds: function () {
      return [
        { title: '@events.e2', date: daysFromNow(2), at: '19:00', where: '@events.w2', people: 12 },
        { title: '@events.e3', date: daysFromNow(5), at: '11:00', where: '@events.w3', people: 3 }
      ];
    }
  },

  birthdays: {
    coll: 'birthdays', icon: 'i-cake', noun: 'rec.birthdays.noun', recoverable: true,
    fields: [
      { name: 'name', kind: 'text', label: 'common.name', required: true, ph: 'rec.birthdays.ph' },
      { name: 'kind', kind: 'select', label: 'rec.f.occasion', options: 'kinds' },
      { name: 'date', kind: 'date', label: 'rec.f.date', required: true },
      { name: 'notes', kind: 'textarea', label: 'rec.f.notes', optional: true, wide: true }
    ],
    options: {
      kinds: function (c) {
        return [
          { value: 'birthday', label: c.t('birthdays.birthday') },
          { value: 'anniversary', label: c.t('birthdays.anniversary') }
        ];
      }
    },
    /* A birthday recurs, so what matters is the next one, not the year it
       started. Ages and countdowns are computed from that. */
    nextOn: function (r) {
      const d = new Date(r.date + 'T00:00:00');
      if (isNaN(d.getTime())) return null;
      const today = new Date(); today.setHours(0, 0, 0, 0);
      const next = new Date(today.getFullYear(), d.getMonth(), d.getDate());
      if (next < today) next.setFullYear(next.getFullYear() + 1);
      return next;
    },
    row: function (r, c) {
      const name = txt(c.t, r.name);
      const next = RECORD_SCHEMAS.birthdays.nextOn(r);
      const days = next ? Math.round((next - new Date().setHours(0, 0, 0, 0)) / 86400000) : null;
      return {
        initial: initial(name), title: name,
        sub: [c.t('birthdays.' + (r.kind || 'birthday')), next ? c.dateShort(next) : null]
          .filter(Boolean).join(' · '),
        value: days === null ? '' : days === 0 ? c.t('common.today') : c.t('common.inDays', { n: days })
      };
    },
    hero: function (r, c) {
      const next = RECORD_SCHEMAS.birthdays.nextOn(r);
      return { kicker: c.t('birthdays.' + (r.kind || 'birthday')), value: txt(c.t, r.name),
        caption: next ? c.dateLong(next) : '', tone: 'night' };
    },
    facts: function (r, c) {
      const next = RECORD_SCHEMAS.birthdays.nextOn(r);
      const born = new Date(r.date + 'T00:00:00');
      const turning = next && !isNaN(born.getTime()) ? next.getFullYear() - born.getFullYear() : null;
      return [
        { label: c.t('rec.f.occasion'), value: c.t('birthdays.' + (r.kind || 'birthday')) },
        { label: c.t('common.date'), value: showDate(c, r.date) },
        { label: c.t('rec.nextOne'), value: next ? c.dateLong(next) : '—' },
        { label: c.t('rec.turning'), value: turning && turning > 0 ? c.num(turning) : '—' },
        { label: c.t('rec.f.notes'), value: r.notes || c.t('rec.none') }
      ];
    },
    empty: { title: 'rec.birthdays.emptyTitle', text: 'rec.birthdays.emptyText' },
    seeds: function () {
      return [
        { name: 'Ayesha', kind: 'birthday', date: '1997-' + daysFromNow(4).slice(5) },
        { name: '@rec.seed.ourAnniversary', kind: 'anniversary', date: '2020-' + daysFromNow(18).slice(5) },
        { name: 'Musa', kind: 'birthday', date: '2021-' + daysFromNow(51).slice(5) }
      ];
    }
  }
};

/* Which tools are record tools, asked as a question rather than repeated as
   a list. The CRUD engine, the tool engine and the tests all ask this. */
export function isRecordTool(id) {
  return Object.prototype.hasOwnProperty.call(RECORD_SCHEMAS, id);
}

export function schemaFor(id) {
  return RECORD_SCHEMAS[id] || null;
}

/* The seed callback the record store is constructed with. */
export function seedsFor(coll) {
  const schema = RECORD_SCHEMAS[coll];
  return schema && schema.seeds ? schema.seeds() : null;
}

export const RECORD_TOOLS = Object.keys(RECORD_SCHEMAS);

export const helpers = { txt: txt, initial: initial, iso: iso, showDate: showDate, whenLabel: whenLabel, relDays: relDays };
