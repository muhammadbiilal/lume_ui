/* ============================================================
   Lume — the CRUD engine  (CRUD guide, whole document)

   One engine builds list, detail, create, edit and delete for
   every record family, from the family's schema. That is the
   point: the guide describes one set of behaviours, and twelve
   separate implementations of it would be twelve chances to get
   the validation lifecycle subtly different.

   What it owns:

     the operation model   which of the five views is showing,
                           and what "open a record" means at
                           this width — a push on a phone, a
                           selection in a pane on a tablet (§2);

     the validation
     lifecycle             do not judge an untouched field;
                           validate independent rules on blur;
                           validate everything on submit, focus
                           the first error and keep every value
                           the user typed (§10);

     the states            empty, loading, offline, save
                           failure, delete, conflict — each one
                           reachable for real, none of them
                           mocked;

     the dirty guard       leaving a changed form asks first.

   What it does not own: what a record *is*. That is the schema,
   in data/record-schemas.js, and this file never mentions an
   amount, a due date or a dose.
   ============================================================ */
import { LUME_UI } from '../ui/components.js';
import { LUME_CRUD_UI } from '../ui/crud.js';
import { schemaFor, isRecordTool, txt, resolve, sentence } from '../data/record-schemas.js';

export const LUME_CRUD = (function () {
  'use strict';

  var UI = LUME_UI;
  var K = LUME_CRUD_UI;

  /* Per-tool form state. It lives here rather than in the tool context
     because it is the engine's, and because a draft must survive the
     re-renders that happen while the user types. */
  var FORMS = {};

  function formFor(id) { return FORMS[id] || (FORMS[id] = blankForm()); }
  function blankForm() {
    return { values: {}, touched: {}, errors: {}, submitted: false, busy: false,
             failure: null, conflict: null, mode: null, rec: null, base: null, dirty: false };
  }
  function clearForm(id) { delete FORMS[id]; }

  /* ---------------------------------------------------------
     Which view is showing

     '' or 'list' is the collection. The others are the guide's
     four remaining operations. Kept in the tool's own scratch
     state so the existing back stack releases it for free.
     --------------------------------------------------------- */

  function view(c) { return c.state('view') || 'list'; }
  function selected(c) { return c.state('rec') || ''; }

  /* True when the engine owns the whole screen rather than one section of
     it. The list lives inside the tool's own composition; a detail, a form
     or a confirmation replaces it. */
  function active(c) {
    if (!isRecordTool(c.id)) return false;
    var v = view(c);
    return v === 'detail' || v === 'new' || v === 'edit';
  }

  /* ---------------------------------------------------------
     Reading the collection
     --------------------------------------------------------- */

  function collection(c) {
    /* open() starts hydration if it has not started and returns what to
       draw now. The callback re-renders when the records arrive, which is
       what turns the skeleton into the list. */
    return c.records.open(c.id, function () {
      if (typeof c.rerender === 'function') c.rerender();
    });
  }

  function query(c) { return String(c.state('q') || '').trim().toLowerCase(); }

  /* A record, ready to be shown. Every projection below goes through this,
     so no schema has to remember that a seeded string is a key. */
  function shown(c, r) { return resolve(c.t, r); }

  /* A noun at the head of a line. The dictionaries hold nouns in the form
     they take inside a sentence; this is the one place they are raised. */
  function head(c, key, vars) { return sentence(c.L.lang(), c.t(key, vars)); }

  /* Search over whatever the row projection shows, so a user searching for
     what they can see finds it. */
  function matches(schema, r, c, q) {
    if (!q) return true;
    var row = schema.row(shown(c, r), c);
    return [row.title, row.sub, (row.meta || []).join(' '), row.value]
      .filter(Boolean).join(' ').toLowerCase().indexOf(q) !== -1;
  }

  function filtered(c, schema, items) {
    var q = query(c);
    var chosen = c.state('cfil') || 'all';
    var filters = schema.filters ? schema.filters(c) : [];
    var active = filters.filter(function (f) { return f.value === chosen; })[0];
    return items.filter(function (r) {
      if (active && !active.test(r)) return false;
      return matches(schema, r, c, q);
    });
  }

  /* ---------------------------------------------------------
     The list
     --------------------------------------------------------- */

  /* The condition of the collection, for the line under the tool's name.
     It is the header's, not the section's, because the header is where the
     reference visual puts it — and because a section that repeats the
     header is a section with nothing to say. */
  function headerSub(c) {
    var schema = schemaFor(c.id);
    if (!schema) return null;
    var state = c.records.view(c.id);
    if (state.state === 'loading') return null;
    if (state.state === 'error') return c.t('rec.couldNotRefresh');
    if (!state.items.length) return c.t('rec.noneYet');
    return c.t('rec.count', { n: c.num(state.items.length) });
  }

  /* `bare` drops the section's own head, for the placement where the
     header is already carrying it. */
  function listSection(c, opts) {
    var schema = schemaFor(c.id);
    if (!schema) return '';
    var bare = !!(opts && opts.bare);

    var state = collection(c);
    var title = bare ? null : head(c, schema.noun + 'Plural');

    if (state.state === 'loading') {
      return UI.section({ id: 'records', title: title, body: K.loadingRows(4) });
    }

    if (state.state === 'error') {
      return UI.section({ id: 'records', title: title, body: K.loadError({
        title: c.t('rec.loadError', { noun: c.t(schema.noun + 'Plural') }),
        text: c.t('rec.loadErrorText'),
        retry: { label: c.t('a.tryAgain'), act: 'rec:retry:' + c.id },
        cached: { label: c.t('rec.viewCached'), act: 'rec:retry:' + c.id }
      }) });
    }

    var all = state.items;

    if (!all.length) {
      return UI.section({ id: 'records', title: title, body: K.emptyCollection({
        icon: schema.icon,
        title: c.t(schema.empty.title),
        text: c.t(schema.empty.text),
        cta: { label: head(c, 'rec.addFirst', { noun: c.t(schema.noun) }), act: 'rec:new:' + c.id },
        foot: c.t('rec.importLater')
      }) });
    }

    var rows = filtered(c, schema, all);
    var body =
      (state.offline ? K.offlineNotice({
        title: c.t('rec.offline'), text: c.t('rec.offlineText')
      }) : '') +
      UI.searchBar({ placeholder: c.t('rec.search', { noun: c.t(schema.noun + 'Plural') }),
        target: c.id, value: c.state('q') || '' }) +
      chipRow(c, schema, all) +
      (rows.length
        ? K.recordRows(rows.map(function (r) { return rowFor(c, schema, r); }))
        : K.noMatches({
            title: c.t('rec.noMatch'), text: c.t('rec.noMatchText'),
            clear: { label: c.t('a.clear'), act: 'rec:clear:' + c.id }
          })) +
      (schema.bulk && all.filter(schema.bulk.test).length
        ? '<div class="cbulk">' + UI.button({
            label: c.t(schema.bulk.label, { n: all.filter(schema.bulk.test).length }),
            icon: 'i-trash', act: 'rec:bulk:' + c.id
          }) + '</div>'
        : '');

    /* At expanded width the list and a detail share the screen. Below it,
       the list is the screen and the detail is the next one (§8). */
    var pane = c.bp && c.bp.hasDetailPane();
    var inner = pane ? K.panes({ list: body, detail: detailPane(c, schema) }) : body;
    /* The tool host reads this to widen the sections that follow, so the
       whole screen shares one left edge rather than stepping in. */
    if (pane) c.setState('panes', '1'); else c.setState('panes', '');

    return UI.section({
      id: 'records',
      title: title,
      sub: title ? c.t('rec.count', { n: c.num(all.length) }) : null,
      link: title ? { label: head(c, 'rec.add', { noun: c.t(schema.noun) }), act: 'rec:new:' + c.id } : null,
      cls: pane ? 'is-wide' : '',
      tight: bare,
      body: inner
    });
  }

  function chipRow(c, schema, all) {
    if (!schema.filters) return '';
    var chosen = c.state('cfil') || 'all';
    var items = [{ value: 'all', label: c.t('common.all'), count: all.length }]
      .concat(schema.filters(c).map(function (f) {
        return { value: f.value, label: f.label, count: all.filter(f.test).length };
      }));
    return K.filterChips(items.map(function (i) {
      return { label: i.label, count: i.count, on: i.value === chosen,
        act: 'rec:filter:' + c.id + ':' + i.value };
    }));
  }

  function rowFor(c, schema, r) {
    var row = schema.row(shown(c, r), c);
    return K.recordRow({
      initial: row.initial, title: row.title, sub: row.sub, meta: row.meta,
      value: row.value, badge: row.badge, done: row.done,
      queued: r._queued, queuedLabel: c.t('rec.queued'),
      selected: selected(c) === r.id && c.bp && c.bp.hasDetailPane(),
      /* A completion toggle is the one write that does not open a form:
         these families log faster than they edit (guide §11). */
      check: row.done !== undefined ? 'rec:toggle:' + c.id + ':' + r.id : null,
      act: 'rec:open:' + c.id + ':' + r.id
    });
  }

  /* ---------------------------------------------------------
     The detail
     --------------------------------------------------------- */

  function detailBody(c, schema, record) {
    var r = shown(c, record);
    var hero = schema.hero(r, c);
    return K.recordHero(hero) +
      UI.sectionHead({ title: c.t('rec.details') }) +
      K.factCard(schema.facts(r, c)) +
      (schema.note ? UI.noteCard({ tone: 'lock', icon: 'i-info',
        title: c.t('rec.safety'), text: c.t(schema.note) }) : '') +
      K.detailActions({
        edit: { label: head(c, 'rec.edit', { noun: c.t(schema.noun) }), act: 'rec:edit:' + c.id + ':' + r.id },
        remove: { label: head(c, 'rec.delete', { noun: c.t(schema.noun) }), act: 'rec:askdelete:' + c.id + ':' + r.id }
      }) +
      K.recordId(c.t('rec.recordId', { id: String(r.id).toUpperCase() }));
  }

  /* The second pane at expanded width: the selected record, or an
     invitation to select one. */
  function detailPane(c, schema) {
    var id = selected(c);
    var r = id ? c.records.get(c.id, id) : null;
    if (!r) {
      return K.noSelection({
        icon: schema.icon,
        title: c.t('rec.selectTitle'),
        text: c.t('rec.selectText', { noun: c.t(schema.noun) })
      });
    }
    return detailBody(c, schema, r);
  }

  /* ---------------------------------------------------------
     The form

     Values live in the draft, never read back off the DOM, so a
     re-render cannot lose what was typed and a failed save
     cannot clear it (§10).
     --------------------------------------------------------- */

  function startCreate(c) {
    var schema = schemaFor(c.id);
    var form = FORMS[c.id] = blankForm();
    form.mode = 'new';
    schema.fields.forEach(function (f) {
      form.values[f.name] = defaultFor(f, c);
    });
    c.setState('view', 'new');
  }

  function startEdit(c, id) {
    var schema = schemaFor(c.id);
    var r = c.records.get(c.id, id);
    if (!r) return false;
    var form = FORMS[c.id] = blankForm();
    form.mode = 'edit';
    form.rec = id;
    r = shown(c, r);
    /* The version this form was opened against. A save that finds a
       different one has a conflict rather than a right to overwrite. */
    form.base = r._v;
    schema.fields.forEach(function (f) {
      var v = r[f.name];
      form.values[f.name] = v === undefined ? defaultFor(f, c) : v;
    });
    c.setState('view', 'edit');
    c.setState('rec', id);
    return true;
  }

  function defaultFor(f, c) {
    if (f.kind === 'check') return false;
    if (f.kind === 'date') {
      var d = new Date();
      return d.getFullYear() + '-' +
        String(d.getMonth() + 1).padStart(2, '0') + '-' +
        String(d.getDate()).padStart(2, '0');
    }
    if (f.kind === 'time') {
      var n = new Date();
      return String(n.getHours()).padStart(2, '0') + ':' + String(n.getMinutes()).padStart(2, '0');
    }
    if (f.kind === 'select') {
      var opts = optionsFor(c, f);
      return opts.length ? opts[0].value : '';
    }
    return '';
  }

  function optionsFor(c, f) {
    var schema = schemaFor(c.id);
    var source = schema.options && schema.options[f.options];
    return source ? source(c) : [];
  }

  /* ---- validation ---------------------------------------- */

  /* One field, one rule set. Called on blur for that field alone and for
     every field on submit — the same function, so the two can never
     disagree about what "valid" means. */
  function errorFor(c, f, value) {
    if (f.required) {
      var empty = value === '' || value === null || value === undefined;
      if (empty) return c.t('rec.err.required', { field: c.t(f.label) });
    }
    if (f.rule && value !== '' && value !== null && value !== undefined) {
      if (!f.rule.test(value)) return c.t(f.rule.key, { field: c.t(f.label) });
    }
    return null;
  }

  function validateField(c, name) {
    var schema = schemaFor(c.id);
    var form = formFor(c.id);
    var f = schema.fields.filter(function (x) { return x.name === name; })[0];
    if (!f) return;
    var err = errorFor(c, f, form.values[name]);
    if (err) form.errors[name] = err; else delete form.errors[name];
  }

  function validateAll(c) {
    var schema = schemaFor(c.id);
    var form = formFor(c.id);
    form.errors = {};
    schema.fields.forEach(function (f) {
      var err = errorFor(c, f, form.values[f.name]);
      if (err) form.errors[f.name] = err;
    });
    return Object.keys(form.errors).length === 0;
  }

  /* An error is shown once the field has been left, or once the form has
     been submitted. Never before either: "do not judge untouched fields". */
  /* The verdict on one field, for a caller that wants to repaint just that
     field rather than the whole form. */
  function fieldError(c, name) {
    var form = FORMS[c.id];
    if (!form) return null;
    return shownError(form, name);
  }

  function shownError(form, name) {
    if (!form.errors[name]) return null;
    if (form.submitted || form.touched[name]) return form.errors[name];
    return null;
  }

  function formBody(c) {
    var schema = schemaFor(c.id);
    var form = formFor(c.id);
    var creating = form.mode === 'new';

    var fields = schema.fields.map(function (f) {
      return K.formField({
        name: f.name, kind: f.kind, label: c.t(f.label),
        value: form.values[f.name],
        ph: f.ph ? c.t(f.ph) : null,
        rows: f.rows,
        required: !!f.required,
        optional: !!f.optional,
        optionalLabel: c.t('rec.optional'),
        options: f.kind === 'select' ? optionsFor(c, f) : null,
        wide: !!f.wide,
        hint: f.hint ? c.t(f.hint) : null,
        error: shownError(form, f.name),
        attachLabel: c.t('rec.attach'),
        attachedLabel: c.t('rec.attached'),
        act: f.kind === 'attach' ? 'rec:attach:' + c.id + ':' + f.name : null
      });
    });

    /* Two columns only where the fields are short and related, and only
       when there is a second column to have (§9). */
    var pair = c.bp && c.bp.hasDetailPane();

    return (form.conflict ? K.conflictNotice({
        title: c.t('rec.conflict'), text: c.t('rec.conflictText'),
        review: { label: c.t('rec.review'), act: 'rec:review:' + c.id },
        reload: { label: c.t('rec.reload'), act: 'rec:reload:' + c.id }
      }) : '') +
      (form.failure ? K.saveError({
        title: c.t('rec.saveFailed'), text: c.t('rec.saveFailedText'),
        retry: { label: c.t('a.tryAgain'), act: 'rec:save:' + c.id }
      }) : '') +
      (c.records.isOffline() ? K.offlineNotice({
        title: c.t('rec.offline'), text: c.t('rec.offlineQueued')
      }) : '') +
      (pair
        ? K.formCard({ title: head(c, 'rec.information', { noun: c.t(schema.noun) }),
            body: K.formGrid(fields, { pair: true }) +
              K.submitBar({
                label: head(c, creating ? 'rec.save' : 'rec.update', { noun: c.t(schema.noun) }),
                busyLabel: c.t('rec.saving'), busy: form.busy,
                act: 'rec:save:' + c.id,
                cancel: { label: c.t('rec.cancel'), act: 'rec:cancel:' + c.id }
              }) })
        : K.formGrid(fields) +
          K.submitBar({
            label: head(c, creating ? 'rec.save' : 'rec.update', { noun: c.t(schema.noun) }),
            busyLabel: c.t('rec.saving'), busy: form.busy,
            act: 'rec:save:' + c.id,
            note: c.t('rec.confirmNote')
          }));
  }

  /* ---------------------------------------------------------
     What the tool host draws when the engine owns the screen
     --------------------------------------------------------- */

  function screen(c) {
    var schema = schemaFor(c.id);
    var v = view(c);

    if (v === 'detail') {
      var r = c.records.get(c.id, selected(c));
      if (!r) return { body: UI.section({ body: K.noMatches({
        title: c.t('rec.gone'), text: c.t('rec.goneText'),
        clear: { label: head(c, 'rec.backToList', { noun: c.t(schema.noun + 'Plural') }), act: 'rec:list:' + c.id }
      }) }) };
      return { body: UI.section({ body: detailBody(c, schema, r) }) };
    }

    return { body: UI.section({ body: formBody(c) }) };
  }

  /* The header a CRUD view replaces the tool's own with: the operation, the
     record's condition, and the one action that belongs at the top. */
  function header(c) {
    var schema = schemaFor(c.id);
    var v = view(c);
    if (v === 'new') {
      return {
        title: head(c, 'rec.add', { noun: c.t(schema.noun) }),
        sub: c.t('rec.newRecord'),
        actions: [{ id: 'save', label: c.t('a.save'), text: c.t('a.save'), act: 'rec:save:' + c.id }]
      };
    }
    if (v === 'edit') {
      return {
        title: head(c, 'rec.edit', { noun: c.t(schema.noun) }),
        sub: c.t('rec.editing'),
        actions: [{ id: 'save', label: c.t('a.save'), text: c.t('a.save'), act: 'rec:save:' + c.id }]
      };
    }
    var r = c.records.get(c.id, selected(c));
    return {
      title: head(c, 'rec.detailTitle', { noun: c.t(schema.noun) }),
      sub: r ? createdLabel(c, r) : '',
      actions: r ? [
        { id: 'edit', icon: 'i-note', label: head(c, 'rec.edit', { noun: c.t(schema.noun) }),
          act: 'rec:edit:' + c.id + ':' + r.id }
      ] : []
    };
  }

  /* "Created today", not "Created Today": the relative day is part of the
     sentence, so it has its own phrasing rather than a capitalised word
     borrowed from a list of chips. */
  function createdLabel(c, r) {
    var d = new Date(r._at);
    var today = new Date(); today.setHours(0, 0, 0, 0);
    var days = Math.round((new Date(d).setHours(0, 0, 0, 0) - today) / 86400000);
    if (days === 0) return c.t('rec.createdToday');
    if (days === -1) return c.t('rec.createdYesterday');
    return c.t('rec.created', { when: c.dateShort(d) });
  }

  /* ---------------------------------------------------------
     The delete confirmation

     Names the record, states the consequence, and says whether
     it can be recovered — because the guide asks that the
     behaviour match the truth (§10).
     --------------------------------------------------------- */

  function deletePrompt(c, id) {
    var schema = schemaFor(c.id);
    var r = c.records.get(c.id, id);
    if (!r) return null;
    var row = schema.row(shown(c, r), c);
    return {
      title: head(c, 'rec.deleteAsk', { noun: c.t(schema.noun) }),
      text: c.t(schema.recoverable ? 'rec.deleteTextUndo' : 'rec.deleteTextFinal', { name: row.title }),
      confirm: head(c, 'rec.delete', { noun: c.t(schema.noun) }),
      cancel: c.t('rec.cancel'),
      act: 'rec:delete:' + c.id + ':' + id
    };
  }

  /* ---------------------------------------------------------
     Writes
     --------------------------------------------------------- */

  /* Deferred on purpose. A save that lands in the same tick can never show
     progress, can never be double-submitted, and can never fail — so the
     three behaviours the guide asks for would exist only in a screenshot.
     The delay is the write, not a decoration on it. */
  var SAVE_MS = 320;

  function save(c, done) {
    var schema = schemaFor(c.id);
    var form = formFor(c.id);

    /* Prevent duplicate submission while a request is active. */
    if (form.busy) return { status: 'busy' };

    form.submitted = true;
    form.failure = null;
    form.conflict = null;

    if (!validateAll(c)) {
      /* Focus the first error and retain every value (§10). */
      var first = schema.fields.filter(function (f) { return form.errors[f.name]; })[0];
      return { status: 'invalid', focus: first ? first.name : null };
    }

    form.busy = true;

    setTimeout(function () {
      form.busy = false;
      var payload = {};
      schema.fields.forEach(function (f) {
        var v = form.values[f.name];
        payload[f.name] = f.kind === 'money' || f.kind === 'number'
          ? (v === '' || v === null || v === undefined ? '' : Number(v))
          : v;
      });
      /* What is stored now is what the user typed, in the language they
         typed it. A record that started as a seeded key is theirs from
         here on, and is never re-translated under them. */
      payload._seed = 0;

      var result = form.mode === 'new'
        ? c.records.create(c.id, payload)
        : c.records.update(c.id, form.rec, payload, form.base);

      if (!result.ok) {
        if (result.reason === 'conflict') {
          form.conflict = result.current;
          done({ status: 'conflict' });
          return;
        }
        form.failure = result.reason || 'storage';
        done({ status: 'failed' });
        return;
      }

      var record = result.record;
      clearForm(c.id);
      done({ status: 'saved', record: record, mode: form.mode, schema: schema });
    }, SAVE_MS);

    return { status: 'saving' };
  }

  /* ---- draft edits --------------------------------------- */

  function setValue(c, name, value) {
    var form = formFor(c.id);
    form.values[name] = value;
    form.dirty = true;
    /* Re-validating a field the user is still typing in would move the
       error under them. It is re-checked when they leave it. */
    if (form.submitted || form.touched[name]) validateField(c, name);
  }

  function touch(c, name) {
    var form = formFor(c.id);
    form.touched[name] = true;
    validateField(c, name);
  }

  function isDirty(c) {
    var form = FORMS[c.id];
    return !!(form && form.dirty && !form.busy);
  }

  function discard(c) { clearForm(c.id); }

  /* Conflict, resolved the two ways the guide allows. Review keeps what the
     user wrote and re-bases it on the newer version so the next save is a
     deliberate overwrite; Reload throws the draft away for the newer one. */
  function reviewConflict(c) {
    var form = formFor(c.id);
    if (!form.conflict) return;
    form.base = form.conflict._v;
    form.conflict = null;
  }

  function reloadConflict(c) {
    var form = formFor(c.id);
    var id = form.rec;
    clearForm(c.id);
    if (id) startEdit(c, id);
  }

  return {
    /* queries */
    active: active, view: view, selected: selected, isRecordTool: isRecordTool,
    schemaFor: schemaFor, isDirty: isDirty,

    /* composition */
    listSection: listSection, headerSub: headerSub,
    screen: screen, header: header, deletePrompt: deletePrompt,

    /* transitions */
    startCreate: startCreate, startEdit: startEdit, discard: discard,

    /* the form */
    setValue: setValue, touch: touch, save: save, fieldError: fieldError,
    reviewConflict: reviewConflict, reloadConflict: reloadConflict,

    /* for the tests */
    _forms: FORMS, _saveMs: SAVE_MS
  };
})();
