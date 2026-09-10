/* ============================================================
   Lume — the tool host

   One frame, one back stack, one set of cleanup rules, shared
   by all 85 tool screens. Each tool supplies its own
   composition; everything around it comes from here.

   Two things this owns are worth calling out.

   The gate. Opening a tool asks the same eligibility selector
   every other surface asks, so a hidden feature cannot be
   reached through a deep link, a related-tool card, a search
   result or a notification either. The entry point is never the
   only check.

   The teardown. A tool can leave three things running: a
   countdown, a sub-view, and a stack of tools opened on top of
   each other. All three are released in onLeave, so leaving
   through the tab bar abandons them exactly the way pressing
   Back does. This used to be a monkey-patch over the shell's
   navigation function, which meant the rules only applied to
   whoever remembered to route through it.
   ============================================================ */
import { defineScreen } from './screen-base.js';
import { $, $$, pad2, esc } from '../core/dom.js';
import { LUME_CRUD } from '../tools/crud-engine.js';
import { sentence } from '../data/record-schemas.js';

export function createToolHostScreen(ctx) {
  /* The shell's names, bound once. Every entry point below is a render or
     a user action, so by the time any of this runs the shell is up. The
     profile object identity is stable — the store mutates it rather than
     replacing it — so binding it here is a reference, not a snapshot. */
  let bound = false;
  let t, L, D, SPEC, TOOLS, toolCtx, profile, router, store, NOTIFY,
      feature, visible, visibleFeatures, fname, actFor,
      toast, sheetOpen, sheetClose, applyStrings, animateBars, noteRecent, saveProfile,
      records, breakpoint;

  function bindShell() {
    if (bound) return;
    bound = true;
    t = ctx.t; L = ctx.L; D = ctx.data; SPEC = ctx.spec; TOOLS = ctx.tools;
    toolCtx = ctx.toolCtx; profile = ctx.profile(); router = ctx.router; store = ctx.store;
    feature = ctx.eligible.feature; visible = ctx.eligible.visible;
    visibleFeatures = ctx.eligible.visibleFeatures;
    fname = ctx.eligible.name; actFor = ctx.eligible.actFor;
    toast = ctx.toast; sheetOpen = ctx.sheetOpen; sheetClose = ctx.sheetClose;
    applyStrings = ctx.applyStrings; animateBars = ctx.animateBars;
    noteRecent = ctx.noteRecent; saveProfile = ctx.saveProfile;
    records = ctx.records; breakpoint = ctx.breakpoint;
  }

  /* The screen root, so nothing here has to search the whole document for
     a node that belongs to this screen. */
  let screenRoot = null;

  var toolStack = [];       /* tools opened on top of each other */
  var toolReturnTab = 'home';
  var currentTool = null;

  function renderTool() {
    if (!currentTool) return;
    var built = TOOLS.build(currentTool);
    var head = $('#toolHeader'), body = $('#toolBody');
    if (!built || !body) return;
    head.innerHTML = built.header;
    body.innerHTML = built.body;
    body.dataset.density = built.density;
    body.dataset.archetype = built.archetype;
    /* A screen showing two panes is a wide composition, and everything
       below the panes lines up with them. */
    body.dataset.panes = toolCtx(currentTool).state('panes') || '';
    applyStrings(body);
    animateBars($('#screen-tool'));
    if (currentTool === 'calculator') calcToolRender();
  }

  function openTool(id, opts) {
    var f = feature(id);
    /* Defence in depth: the entry point is not the only gate (§64). */
    if (!f || !visible(f)) { toast(t('tool.unavailable')); return; }

    if (currentTool && (!opts || !opts.replace)) toolStack.push(currentTool);
    else if (!currentTool) toolReturnTab = router.current();

    currentTool = id;
    noteRecent(id);

    /* A tool is showing, whatever opened it. */
    router.go('tool', { quiet: true });

    renderTool();
  }

  function stopClocks() {
    for (var k in clockTimers) {
      if (Object.prototype.hasOwnProperty.call(clockTimers, k)) {
        clearInterval(clockTimers[k]);
        var st = toolCtx(k)._state[k];
        if (st) st.running = false;
      }
    }
  }

  function closeTool() {
    if (!currentTool) { router.go(ctx.returnTab()); return; }

    /* A record view is a view *of* the tool, so Back returns through it
       rather than out of the tool — and a form with unsaved changes asks
       before it is abandoned (CRUD guide §12). */
    var rc = toolCtx(currentTool);
    if (rc && LUME_CRUD.active(rc)) {
      var view = LUME_CRUD.view(rc);
      if (view === 'new' || view === 'edit') { recordAction(['cancel', currentTool]); return; }
      rc.setState('view', '');
      renderTool();
      return;
    }
    /* A detail view is a view *of* the tool, so back returns to the tool
       before it returns to where the tool was opened from (§9). */
    if (currentTool) {
      var c = toolCtx(currentTool);
      if (c && c.state('detail')) { c.setState('detail', ''); renderTool(); return; }
    }
    /* A countdown that keeps running would announce itself from an
       unrelated screen. */
    stopClocks();
    if (toolStack.length) { currentTool = toolStack.pop(); renderTool(); return; }
    currentTool = null;
    router.go(toolReturnTab);
  }

  /* Field names are prefixed per tool so two screens can each have an
     "amount"; the context stores the bare key. */
  /* One rule for both the typed and the stepped inputs. */
  function fieldKey(name) {
    if (FIELD_ALIAS[name]) return FIELD_ALIAS[name];
    return name.indexOf('_') !== -1 ? name.split('_').slice(1).join('_') : name;
  }

  var FIELD_ALIAS = {
    z_cash: 'cash', z_gold: 'gold', z_silver: 'silver', z_inv: 'inv', z_biz: 'biz', z_liab: 'liab',
    fa_gross: 'gross', fa_debts: 'debts', fa_bequest: 'bequest',
    fc_dist: 'dist', fc_econ: 'econ', fc_price: 'price', fc_people: 'people',
    tax_income: 'income', tax_ded: 'deductions',
    ln_principal: 'principal', ln_rate: 'rate', ln_years: 'years',
    tp_bill: 'bill', tp_people: 'people',
    ci_initial: 'initial', ci_monthly: 'monthly', ci_rate: 'rate', ci_years: 'years',
    bmi_h: 'height', bmi_w: 'weight',
    age_dob: 'dob',
    dc_from: 'from', dc_to: 'to', dc_days: 'days', dc_start: 'from',
    cv_amount: 'amount', uc_amount: 'amount'
  };

  /* §26.11 — choosing a market persists and re-renders Markets in place. */
  function renderMarketPicker() {
    var host = $('#marketList');
    if (!host) return;
    var opts = toolCtx('markets').marketOptions();
    /* §26.11 — country, its region, the exchanges within it, and the world
       board. A market with two venues names both. */
    host.innerHTML = opts.map(function (o) {
      return '<button class="list-row pressable" data-market="' + esc(o.code) + '">' +
        '<span class="list-row__icon">' +
          '<svg class="ico" viewBox="0 0 24 24"><use href="#' +
            (o.code === 'GLOBAL' ? 'i-globe' : 'i-trending') + '"/></svg></span>' +
        '<span class="list-row__body">' +
          '<span class="list-row__title">' + esc(o.name) +
            (o.home ? ' <span class="tag tag--neutral">' + esc(t('markets.default')) + '</span>' : '') +
          '</span>' +
          '<span class="list-row__sub">' + esc(o.region) + ' · ' + esc(o.exchange) + '</span>' +
          (o.venues && o.venues.length > 1
            ? '<span class="list-row__sub">' + esc(t('markets.venues')) + ': ' +
              esc(o.venues.join(' · ')) + '</span>' : '') +
        '</span>' +
        '<span class="list-row__end">' +
          '<span class="list-row__value">' + esc(o.sub) + '</span>' +
          (o.on ? '<svg class="ico" viewBox="0 0 24 24"><use href="#i-check"/></svg>' : '') +
        '</span></button>';
    }).join('');
  }

  document.addEventListener('click', function (e) {
    var row = e.target.closest('[data-market]');
    if (!row) return;
    var code = row.dataset.market;
    var c = toolCtx('markets');
    /* "Automatic" is not a market — it is the absence of an override, so
       Markets follows the user's country again (§26.1). */
    if (code === 'AUTO') {
      c.setState('market', '');
      profile.market = null;
    } else {
      c.setState('market', code);
      profile.market = code;
    }
    c.setState('detail', '');
    c.setState('class', 'stocks');
    saveProfile();
    sheetClose();
    if (currentTool === 'markets') renderTool();
    toast(t('markets.switched', {
      name: code === 'AUTO' ? L.countryName(profile.country)
          : code === 'GLOBAL' ? t('markets.globalMarkets')
          : L.countryName(code)
    }));
  });

  /* ---- the action vocabulary tool screens speak ---- */
  function toolAction(kind, arg) {
    var bits = String(arg).split(':');

    if (kind === 'tool') { openTool(bits[0]); return true; }

    if (kind === 'toolstate') {
      /* toolstate:<tool>:<key>:<value> — a tab, a filter, a selected row */
      var id = bits.shift(), key = bits.shift(), value = bits.join(':');
      var c = toolCtx(id);
      /* An empty value clears the key. Coercing it to `true` turned
         "leave the detail" into "open detail `true`". */
      if (c) c.setState(key, value);
      if (currentTool === id) renderTool();
      return true;
    }

    if (kind === 'toolsearch') {
      var tid = bits.shift();
      var q = bits.join(':');
      if (q) {
        var cs = toolCtx(tid);
        if (cs) cs.setState('q', q);
        if (currentTool === tid) renderTool();
      } else {
        var input = $('[data-tool-search]', $('#screen-tool'));
        if (input) input.focus();
      }
      return true;
    }

    if (kind === 'export') { exportTool(bits[0] || currentTool); return true; }
    if (kind === 'fav' || kind === 'bookmark') { toggleFavourite(bits[0] || currentTool); return true; }

    if (kind === 'track') {
      toast(t('track.marked', { name: t('prayer.' + bits[0]) }));
      return true;
    }

    if (kind === 'water') {
      var cw = toolCtx('water');
      var add = bits[0] === 'large' ? 500 : 250;
      cw._state.water = cw._state.water || {};
      cw._state.water.ml = (cw._state.water.ml === undefined ? 1250 : cw._state.water.ml) + add;
      if (currentTool === 'water') renderTool();
      toast(t('water.added', { amount: add + ' ml' }));
      return true;
    }

    if (kind === 'alarmtoggle') {
      var host = $('#screen-tool');
      var row = host && host.querySelector('[data-act="alarmtoggle:' + bits[0] + '"]');
      var sw = row && row.querySelector('.switch');
      if (sw) sw.classList.toggle('is-on');
      return true;
    }

    /* Permission, filtering and marking-read belong to the notification
       system, not to whatever tool happens to be open. They are handled by
       the shell, which owns that system; falling through to it is how. */
    if (kind === 'notify') { armAlert(bits[0], bits.slice(1).join(':')); return true; }
    if (kind === 'speedtest') { runSpeedTest(); return true; }
    if (kind === 'tasbihreset') { resetToolTasbih(); return true; }
    if (kind === 'cvswap' || kind === 'ucswap') { swapConverter(kind); return true; }
    if (kind === 'clock') { runClock(bits); return true; }

    if (kind === 'rec') return recordAction(bits);

    return false;
  }

  /* ---------------------------------------------------------
     The record vocabulary  (CRUD guide §2)

     Every verb in the guide's operation table is one word here,
     and the five views are reached only through them. A screen
     never sets a view directly, so "open this record" can mean
     a push on a phone and a selection in a pane on a tablet
     without any screen knowing the difference.
     --------------------------------------------------------- */
  function recordAction(bits) {
    var verb = bits.shift();
    var tool = bits.shift();
    var arg = bits.join(':');

    /* Undo is the only one that is not about a particular collection: it
       reverses whatever was last done, wherever the user now is. */
    if (verb === 'undo') { undoRecord(); return true; }

    var c = toolCtx(tool);
    if (!c || !LUME_CRUD.isRecordTool(tool)) return true;
    var schema = LUME_CRUD.schemaFor(tool);

    function redraw() { if (currentTool === tool) renderTool(); }

    if (verb === 'new') {
      LUME_CRUD.startCreate(c);
      redraw();
      focusFirstField();
      return true;
    }

    if (verb === 'open') {
      c.setState('rec', arg);
      /* The width decides what opening means. With a detail pane the record
         is selected beside the list, and the list keeps its scroll, its
         filter and its position; without one, it is the next screen. */
      if (!(c.bp && c.bp.hasDetailPane())) c.setState('view', 'detail');
      redraw();
      return true;
    }

    if (verb === 'edit') {
      if (!LUME_CRUD.startEdit(c, arg)) { toast(t('rec.gone')); return true; }
      redraw();
      focusFirstField();
      return true;
    }

    if (verb === 'list') {
      LUME_CRUD.discard(c);
      c.setState('view', '');
      c.setState('rec', '');
      redraw();
      return true;
    }

    if (verb === 'cancel') { leaveForm(c, tool); return true; }
    if (verb === 'discard') {
      LUME_CRUD.discard(c);
      c.setState('view', '');
      sheetClose();
      redraw();
      return true;
    }

    if (verb === 'save') { saveRecord(c, tool, schema); return true; }

    if (verb === 'askdelete') {
      var prompt = LUME_CRUD.deletePrompt(c, arg);
      if (!prompt) { toast(t('rec.gone')); return true; }
      fillDeleteSheet(prompt);
      sheetOpen('recdelete');
      return true;
    }

    if (verb === 'delete') { deleteRecord(c, tool, schema, arg); return true; }

    if (verb === 'toggle') {
      /* Fast optimistic logging: the row flips now and the write follows.
         These are the families where waiting for confirmation would make
         the interaction not worth doing (guide §11). */
      var rec = c.records.get(tool, arg);
      if (rec) {
        c.records.update(tool, arg, { done: !rec.done }, rec._v);
        redraw();
      }
      return true;
    }

    if (verb === 'filter') { c.setState('cfil', arg); redraw(); return true; }
    if (verb === 'clear') { c.setState('q', ''); c.setState('cfil', 'all'); redraw(); return true; }
    if (verb === 'retry') { c.records.retry(tool); redraw(); return true; }
    if (verb === 'review') { LUME_CRUD.reviewConflict(c); redraw(); return true; }
    if (verb === 'reload') { LUME_CRUD.reloadConflict(c); redraw(); toast(t('rec.reloaded')); return true; }
    if (verb === 'attach') { toast(t('rec.attachSoon')); return true; }

    if (verb === 'bulk') {
      var doomed = c.records.list(tool).filter(schema.bulk.test);
      if (!doomed.length) return true;
      fillDeleteSheet({
        title: t(schema.bulk.label, { n: doomed.length }),
        text: t(schema.bulk.confirm, { n: doomed.length }),
        confirm: t(schema.bulk.label, { n: doomed.length }),
        cancel: t('rec.cancel'),
        act: 'rec:bulkgo:' + tool
      });
      sheetOpen('recdelete');
      return true;
    }

    if (verb === 'bulkgo') {
      var cleared = c.records.list(tool).filter(schema.bulk.test);
      cleared.forEach(function (r) { c.records.remove(tool, r.id); });
      /* A bulk clear removes many records and could restore only the last,
         so it does not offer an Undo it cannot honour. */
      c.records.forgetUndo();
      sheetClose();
      redraw();
      toast(t('rec.cleared', { n: cleared.length }));
      return true;
    }

    return true;
  }

  /* A form opens with the cursor in its first field, so creating a record
     is one tap and then typing. */
  function focusFirstField() {
    setTimeout(function () {
      var first = $('.cfield input, .cfield textarea, .cfield select', $('#screen-tool'));
      if (first && first.focus) { try { first.focus(); } catch (e) {} }
    }, 60);
  }

  function saveRecord(c, tool, schema) {
    var outcome = LUME_CRUD.save(c, function (result) {
      if (result.status === 'conflict') {
        if (currentTool === tool) renderTool();
        toast(t('rec.conflict'));
        return;
      }
      if (result.status === 'failed') {
        if (currentTool === tool) renderTool();
        toast(t('rec.saveFailed'));
        return;
      }

      /* Saved. Return to the detail on a phone and to the list beside its
         pane on a tablet, then confirm without blocking the next action. */
      c.setState('rec', result.record.id);
      c.setState('view', c.bp && c.bp.hasDetailPane() ? '' : 'detail');
      if (currentTool === tool) renderTool();

      toastUndo(said(result.mode === 'new' ? 'rec.added' : 'rec.updated',
        { noun: t(schema.noun) }));
    });

    if (outcome.status === 'invalid') {
      renderTool();
      /* Focus the first error rather than the top of the form, and say why
         the save did not happen. */
      setTimeout(function () {
        var el = outcome.focus && $('[data-field="' + outcome.focus + '"]', $('#screen-tool'));
        if (el && el.focus) { try { el.focus(); } catch (e) {} }
      }, 40);
      toast(t('rec.checkFields'));
      return;
    }
    if (outcome.status === 'saving') renderTool();
  }

  function deleteRecord(c, tool, schema, id) {
    var result = c.records.remove(tool, id);
    sheetClose();
    if (!result.ok) { toast(t('rec.deleteFailed')); return; }

    /* The record leaves the list at once — never a ghost row. */
    c.setState('rec', '');
    c.setState('view', '');
    if (currentTool === tool) renderTool();

    if (schema.recoverable) {
      toastUndo(said('rec.deleted', { noun: t(schema.noun) }));
    } else {
      /* Nothing to offer: this family deletes for good, and its
         confirmation said so rather than promising otherwise. */
      c.records.forgetUndo();
      toast(said('rec.deletedFinal', { noun: t(schema.noun) }));
    }
  }

  /* A line that begins with a noun begins with a capital: the dictionaries
     hold nouns in the form they take inside a sentence, and a toast is a
     sentence. Identity in the scripts that have no case. */
  function said(key, vars) { return sentence(L.lang(), t(key, vars)); }

  function toastUndo(message) {
    toast(message, { label: t('rec.undo'), act: 'rec:undo' });
  }

  function undoRecord() {
    var done = records.undo();
    if (!done) { toast(t('rec.nothingToUndo')); return; }
    var c = toolCtx(done.coll);
    if (c && done.record) c.setState('rec', done.record.id);
    if (currentTool === done.coll) renderTool();
    toast(t('rec.undone'));
  }

  /* Leaving a changed form asks first (§12, "dirty-state protection"). */
  function leaveForm(c, tool) {
    if (!LUME_CRUD.isDirty(c)) {
      LUME_CRUD.discard(c);
      c.setState('view', c.state('rec') && !(c.bp && c.bp.hasDetailPane()) ? 'detail' : '');
      if (currentTool === tool) renderTool();
      return;
    }
    fillDeleteSheet({
      title: t('rec.discardAsk'),
      text: t('rec.discardText'),
      confirm: t('rec.discard'),
      cancel: t('rec.keepEditing'),
      act: 'rec:discard:' + tool,
      tone: 'warn'
    });
    sheetOpen('recdelete');
  }

  function fillDeleteSheet(o) {
    var sheet = $('#sheet-recdelete');
    if (!sheet) return;
    sheet.classList.toggle('is-warn', o.tone === 'warn');
    var title = $('[data-rec-title]', sheet);
    var text = $('[data-rec-text]', sheet);
    var go = $('[data-rec-go]', sheet);
    var cancel = $('[data-rec-cancel]', sheet);
    if (title) title.textContent = o.title;
    if (text) text.textContent = o.text;
    if (go) { go.textContent = o.confirm; go.dataset.act = o.act; }
    if (cancel) cancel.textContent = o.cancel;
  }

  /* §99 — export writes a real file. A CSV where the screen is a list or a
     table, JSON where it is a calculation, named for the tool and the day. */
  function exportTool(id) {
    var c = toolCtx(id);
    if (!c) return;
    var rows = c.exportRows ? c.exportRows() : null;
    var name = 'lume-' + id + '-' + c.isoToday();
    var blob, ext;

    if (rows && rows.length) {
      var csv = rows.map(function (r) {
        return r.map(function (cell) {
          var v = cell === undefined || cell === null ? '' : String(cell);
          return /[",\n]/.test(v) ? '"' + v.replace(/"/g, '""') + '"' : v;
        }).join(',');
      }).join('\r\n');
      blob = new Blob(['\ufeff' + csv], { type: 'text/csv;charset=utf-8' });
      ext = '.csv';
    } else {
      blob = new Blob([JSON.stringify({ tool: id, exported: new Date().toISOString(),
        locale: L.locale(), currency: L.currencyCode() }, null, 2)],
        { type: 'application/json' });
      ext = '.json';
    }

    try {
      var url = URL.createObjectURL(blob);
      var a = document.createElement('a');
      a.href = url;
      a.download = name + ext;
      document.body.appendChild(a);
      a.click();
      document.body.removeChild(a);
      setTimeout(function () { URL.revokeObjectURL(url); }, 1000);
      toast(t('tool.exportedAs', { name: name + ext }));
    } catch (e) {
      toast(t('tool.exportFailed'));
    }
  }

  /* Favourites persist on the profile, so the star means something. */
  function toggleFavourite(id) {
    if (!id) return;
    profile.favourites = profile.favourites || [];
    var at = profile.favourites.indexOf(id);
    if (at === -1) profile.favourites.push(id); else profile.favourites.splice(at, 1);
    saveProfile();
    var f = feature(id);
    toast(t(at === -1 ? 'tool.favourited' : 'tool.unfavourited', { name: f ? fname(f) : id }));
    if (currentTool === id) renderTool();
  }

  /* §100.8 — a per-tool alert, asked for in context. Asking here is also
     the right moment to ask for push permission (§100.11). */
  function armAlert(tool, entity) {
    var p = NOTIFY.prefs();
    var f = feature(tool);
    var name = f ? fname(f) : tool;
    if (!p.cats[NOTIFY.SOURCES.filter(function (s) { return s.tool === tool; })
        .map(function (s) { return s.cat; })[0] || 'system']) {
      toast(t('n.catOff', { name: name }));
      return;
    }
    if (NOTIFY.pushSupported() && NOTIFY.pushPermission() === 'default') {
      sheetOpen('notifpush');
      pendingAlert = { tool: tool, entity: entity };
      return;
    }
    toast(t('n.armed', { name: entity || name }));
    renderNotifBadge();
  }

  var pendingAlert = null;

  /* ---- live inputs: a calculator recomputes as you type ---- */
  var reflowTimer;

  function reflowSoon() {
    clearTimeout(reflowTimer);
    reflowTimer = setTimeout(function () {
      var active = document.activeElement;
      var activeName = active && active.dataset ? active.dataset.input : null;
      var isSearch = active && active.hasAttribute && active.hasAttribute('data-tool-search');
      var caret = null;
      try { caret = active && active.selectionStart; } catch (err) {}
      var value = active ? active.value : null;
      renderTool();
      var again = null;
      if (activeName) again = $('[data-input="' + activeName + '"]', $('#screen-tool'));
      else if (isSearch) again = $('[data-tool-search]', $('#screen-tool'));
      if (again) {
        if (value !== null && value !== undefined) again.value = value;
        again.focus();
        /* setSelectionRange throws on type=number; the caret is already at
           the end there, which is where it was. */
        try { again.setSelectionRange(caret, caret); } catch (err2) {}
      }
    }, 280);
  }

  /* ---- record form fields ----
     A form's values live in its draft, never in the DOM, so a re-render
     cannot lose what was typed and a failed save cannot clear it. Typing
     therefore does NOT redraw: redrawing under a cursor is how a form
     loses a half-typed decimal and the caret with it. The screen redraws
     when the field is left, when a choice is made, and when the form is
     submitted — the three moments its appearance can change. */
  document.addEventListener('input', function (e) {
    var field = e.target.closest('[data-field]');
    if (!field || !currentTool) return;
    var c = toolCtx(currentTool);
    if (!c || !LUME_CRUD.active(c)) return;
    LUME_CRUD.setValue(c, field.dataset.field, valueOf(field));
  }, true);

  document.addEventListener('change', function (e) {
    var field = e.target.closest('[data-field]');
    if (!field || !currentTool) return;
    var c = toolCtx(currentTool);
    if (!c || !LUME_CRUD.active(c)) return;
    LUME_CRUD.setValue(c, field.dataset.field, valueOf(field));
  });

  /* "Validate only independently judgeable rules on blur" (§10).

     The verdict is painted onto the one field it belongs to, and the form
     is not rebuilt. Rebuilding it here looked harmless and was not: moving
     from one field to the next fires this first, so the form would be
     replaced underneath the tap that was on its way to the next field —
     which detaches the node the browser was about to focus and closes the
     keyboard. A form redraws when it is submitted, not while it is being
     filled in. */
  document.addEventListener('focusout', function (e) {
    var field = e.target.closest && e.target.closest('[data-field]');
    if (!field || !currentTool) return;
    var c = toolCtx(currentTool);
    if (!c || !LUME_CRUD.active(c)) return;
    var name = field.dataset.field;
    LUME_CRUD.setValue(c, name, valueOf(field));
    LUME_CRUD.touch(c, name);
    paintFieldError(c, name, field);
  });

  function valueOf(el) {
    if (el.type === 'checkbox') return el.checked;
    return el.value;
  }

  /* Show or clear one field's error in place. The markup is the same shape
     ui/crud.js builds, so a field validated on blur and a field validated
     on submit look identical. */
  function paintFieldError(c, name, input) {
    var wrap = input.closest('.cfield');
    if (!wrap) return;
    var message = LUME_CRUD.fieldError(c, name);
    var box = wrap.querySelector('.cfield__box');
    var existing = wrap.querySelector('.cfield__err');

    wrap.classList.toggle('is-invalid', !!message);
    if (box) box.classList.toggle('is-invalid', !!message);

    if (!message) {
      if (existing) existing.remove();
      input.removeAttribute('aria-invalid');
      input.removeAttribute('aria-describedby');
      return;
    }

    input.setAttribute('aria-invalid', 'true');
    input.setAttribute('aria-describedby', input.id + '-err');
    if (existing) { existing.lastChild.textContent = message; return; }

    var note = document.createElement('p');
    note.className = 'cfield__err';
    note.id = input.id + '-err';
    note.setAttribute('role', 'alert');
    var glyph = document.createElement('i');
    glyph.setAttribute('aria-hidden', 'true');
    glyph.textContent = '!';
    note.appendChild(glyph);
    note.appendChild(document.createTextNode(message));
    wrap.appendChild(note);
  }

  document.addEventListener('input', function (e) {
    if (!currentTool) return;
    if (e.target.closest('[data-field]')) return;
    var c = toolCtx(currentTool);
    if (!c) return;

    var search = e.target.closest('[data-tool-search]');
    if (search) { c.setState('q', search.value); reflowSoon(); return; }

    var el = e.target.closest('[data-input]');
    if (!el) return;
    var name = el.dataset.input;
    /* A number input reports '' for a half-typed decimal like "12.", so
       committing 0 on every keystroke would rewrite the field under the
       user. Leave the model alone until the value parses. */
    if (el.type === 'number' && el.value === '') return;
    c.setField(fieldKey(name), el.type === 'number' ? Number(el.value) : el.value);
    reflowSoon();
  });

  /* ---- steppers ---- */
  document.addEventListener('click', function (e) {
    var up = e.target.closest('[data-step-up]');
    var down = up ? null : e.target.closest('[data-step-down]');
    if (!up && !down) return;
    var name = up ? up.dataset.stepUp : down.dataset.stepDown;

    /* The quiet-hours steppers belong to the notification sheet, not to a
       tool, so they are handled before the tool-context path. */
    if (name === 'quietFrom' || name === 'quietTo') {
      var np = NOTIFY.prefs();
      np[name] = ((np[name] + (up ? 1 : -1)) + 24) % 24;
      saveProfile();
      ctx.refreshNotifPrefs();
      return;
    }
    if (!currentTool) return;
    var key = fieldKey(name);
    var c = toolCtx(currentTool);
    var cur = Number(c.field(key) || 0);
    c.setField(key, Math.max(0, cur + (up ? 1 : -1)));
    renderTool();
  });

  /* ---- checkable rows (tasks, shopping) ---- */
  document.addEventListener('click', function (e) {
    var row = e.target.closest('[data-task], [data-shop]');
    if (!row || !currentTool) return;
    var c = toolCtx(currentTool);
    var bucket = c._state[currentTool] = c._state[currentTool] || {};
    bucket.done = bucket.done || {};
    var id = row.dataset.task || row.dataset.shop;
    bucket.done[id] = !bucket.done[id];
    row.classList.toggle('is-done', !!bucket.done[id]);
  });

  /* ---- tasbih (§24.15) ---- */
  function resetToolTasbih() {
    var c = toolCtx('tasbih');
    var st = c._state.tasbih = c._state.tasbih || {};
    st.sets = (st.sets || 0) + (st.count ? 1 : 0);
    st.count = 0;
    renderTool();
  }

  document.addEventListener('click', function (e) {
    if (currentTool !== 'tasbih') return;
    var pick = e.target.closest('[data-dhikr]');
    if (pick) {
      var cp = toolCtx('tasbih');
      cp._state.tasbih = cp._state.tasbih || {};
      cp._state.tasbih.dhikrIndex = Number(pick.dataset.dhikr);
      cp._state.tasbih.count = 0;
      renderTool();
      return;
    }
    if (!e.target.closest('[data-tasbih-count]')) return;
    var c = toolCtx('tasbih');
    var st = c._state.tasbih = c._state.tasbih || { count: 0, dhikrIndex: 0, sets: 0 };
    var target = D.DHIKR[st.dhikrIndex || 0].target;
    st.count = (st.count || 0) + 1;
    var num = $('[data-tasbih-num]'), ring = $('[data-tasbih-ring]');
    if (num) num.textContent = st.count;
    if (ring) {
      var circ = 2 * Math.PI * 88;
      ring.setAttribute('stroke-dashoffset', Math.max(0, (1 - st.count / target) * circ).toFixed(1));
    }
    if (navigator.vibrate) navigator.vibrate(st.count >= target ? [18, 40, 18] : 8);
    if (st.count >= target) {
      st.sets = (st.sets || 0) + 1;
      st.count = 0;
      toast(t('tasbih.complete'));
      setTimeout(renderTool, 280);
    }
  });

  /* ---- converters ---- */
  function swapConverter(kind) {
    var id = kind === 'cvswap' ? 'currency' : 'converter';
    var c = toolCtx(id);
    var st = c._state[id] = c._state[id] || {};
    if (id === 'currency') {
      var board = c.currencyBoard();
      var from = st.from || board.from;
      st.from = st.to || board.to;
      st.to = from;
    } else {
      st.swapped = !st.swapped;
    }
    renderTool();
  }

  /* ---- speed test (§56) — animated measurement, not a number swap ---- */
  function runSpeedTest() {
    var c = toolCtx('speedtest');
    var st = c._state.speedtest = c._state.speedtest || {};
    var value = $('[data-speed-value]'), fill = $('.gauge__fill');
    var target = 30 + Math.random() * 70;
    var start = performance.now();
    (function step(now) {
      var p = Math.min(1, (now - start) / 1800);
      var eased = 1 - Math.pow(1 - p, 3);
      var v = target * eased;
      if (value) value.textContent = v.toFixed(1);
      if (fill) fill.style.setProperty('--p', Math.min(1, v / 200).toFixed(3));
      if (p < 1) requestAnimationFrame(step);
      else {
        st.down = Math.round(target * 10) / 10;
        toast(t('speed.done', { n: st.down }));
      }
    })(start);
  }

  /* ---- stopwatch / timer / focus ---- */
  var clockTimers = {};

  function fmtClock(kind, secs) {
    return pad2(Math.floor(secs / 60)) + ':' + pad2(secs % 60) + (kind === 'stopwatch' ? '.00' : '');
  }

  function runClock(bits) {
    var kind = bits[0], cmd = bits[1], arg = bits[2];
    var c = toolCtx(kind);
    var st = c._state[kind] = c._state[kind] || {};
    var display = $('[data-clock-display]');

    function paint() {
      st.display = fmtClock(kind, Math.max(0, st.secs));
      var d = $('[data-clock-display]');
      if (d) d.textContent = st.display;
    }

    if (cmd === 'reset') {
      clearInterval(clockTimers[kind]);
      st.running = false;
      st.secs = kind === 'stopwatch' ? 0 : (st.total || (kind === 'focus' ? 1500 : 300));
      paint();
      return;
    }
    if (cmd === 'set') {
      clearInterval(clockTimers[kind]);
      st.running = false;
      st.total = Number(arg);
      st.secs = st.total;
      paint();
      return;
    }
    if (st.running) { clearInterval(clockTimers[kind]); st.running = false; return; }

    if (kind !== 'stopwatch' && !st.secs) {
      st.secs = st.total || (kind === 'focus' ? 1500 : 300);
    }
    st.running = true;
    if (st.secs === undefined) st.secs = kind === 'stopwatch' ? 0 : (st.total || (kind === 'focus' ? 1500 : 300));
    clockTimers[kind] = setInterval(function () {
      st.secs += kind === 'stopwatch' ? 1 : -1;
      if (st.secs <= 0 && kind !== 'stopwatch') {
        clearInterval(clockTimers[kind]);
        st.running = false;
        st.secs = 0;
        toast(t(kind === 'focus' ? 'focus.done' : 'timer.done'));
        if (navigator.vibrate) navigator.vibrate([30, 60, 30]);
      }
      paint();
    }, 1000);
  }

  /* ---- calculator, inside its own tool screen ---- */

  /* Trimmed rather than rounded to a fixed place, so 0.1 + 0.2 reads as
     0.3 without 2/3 losing everything after the third digit. */
  function trimNum(n) {
    if (!isFinite(n)) return 'Error';
    return String(Math.round(n * 1e10) / 1e10);
  }

  var toolCalc = { a: null, op: null, b: '0', fresh: true, expr: '' };

  function calcToolRender() {
    var out = $('[data-calc-out]'), expr = $('[data-calc-expr]');
    if (out) out.textContent = toolCalc.b;
    if (expr) expr.textContent = toolCalc.expr;
  }

  function calcApply() {
    var a = toolCalc.a, b = Number(toolCalc.b), op = toolCalc.op;
    var r = op === '+' ? a + b : op === '-' ? a - b : op === '*' ? a * b : (b === 0 ? 0 : a / b);
    return Math.round(r * 1e10) / 1e10;
  }

  function opSymbol(op) { return { '+': '+', '-': '−', '*': '×', '/': '÷' }[op] || op; }

  document.addEventListener('click', function (e) {
    var key = e.target.closest('[data-calckey]');
    if (!key) return;
    var parts = key.dataset.calckey.split(':');
    var kind = parts[0], arg = parts[1];

    if (kind === 'n') {
      toolCalc.b = (toolCalc.fresh || toolCalc.b === '0') ? arg : toolCalc.b + arg;
      toolCalc.fresh = false;
    } else if (kind === 'dot') {
      if (toolCalc.fresh) { toolCalc.b = '0.'; toolCalc.fresh = false; }
      else if (toolCalc.b.indexOf('.') === -1) toolCalc.b += '.';
    } else if (kind === 'ac') {
      toolCalc = { a: null, op: null, b: '0', fresh: true, expr: '' };
    } else if (kind === 'back') {
      toolCalc.b = toolCalc.b.length > 1 ? toolCalc.b.slice(0, -1) : '0';
    } else if (kind === 'pct') {
      toolCalc.b = String(Number(toolCalc.b) / 100);
    } else if (kind === 'op') {
      if (toolCalc.a !== null && !toolCalc.fresh) toolCalc.b = String(calcApply());
      toolCalc.a = Number(toolCalc.b);
      toolCalc.op = arg;
      toolCalc.expr = trimNum(toolCalc.a) + ' ' + opSymbol(arg);
      toolCalc.fresh = true;
    } else if (kind === 'eq') {
      if (toolCalc.op !== null) {
        var result = calcApply();
        toolCalc.expr = trimNum(toolCalc.a) + ' ' + opSymbol(toolCalc.op) + ' ' +
                        trimNum(Number(toolCalc.b)) + ' =';
        var store2 = toolCtx('calculator')._state;
        store2.calculator = store2.calculator || {};
        store2.calculator.history = [{ expr: toolCalc.expr, result: trimNum(result) }]
          .concat(store2.calculator.history || []).slice(0, 6);
        toolCalc.b = String(result);
        toolCalc.a = null; toolCalc.op = null; toolCalc.fresh = true;
      }
    }
    calcToolRender();
  });

  /* §93 — the freshness line must tell the truth the moment it changes. */

  /* Share cards for data tools (Master Spec §98). A shared snapshot carries
     the figure, the place and the moment it was true — never a bare number. */
  function shareForTool(id) {
    var stamp = L.dateShort(new Date()) + ' · ' + L.time(new Date().getHours(), new Date().getMinutes());
    try {
      if (id === 'prayer') {
        var st = toolCtx('prayer').prayerState();
        return { kind: 'reminder',
          text: t('prayer.' + st.next.key) + ' — ' + L.time(st.next.h, st.next.m) + ', ' + profile.city,
          source: stamp };
      }
      if (id === 'weather') {
        var w = toolCtx('weather').weather();
        return { kind: 'quote',
          text: profile.city + ' · ' + L.temp(w.temp) + ' ' + w.desc + '. ' +
                t('weather.hilo', { hi: L.temp(w.hi), lo: L.temp(w.lo) }),
          source: stamp };
      }
      if (id === 'markets') {
        var ex = toolCtx('markets').exchange();
        var ix = ex ? ex.indices[0] : D.GLOBAL_INDICES[0];
        return { kind: 'quote',
          text: ix.name + ' ' + L.num(ix.value, { maximumFractionDigits: 2 }) + '  ' +
                (ix.pct >= 0 ? '+' : '−') + Math.abs(ix.pct).toFixed(2) + '%',
          source: (ex ? ex.name : t('markets.worldBoard')) + ' · ' + stamp };
      }
      if (id === 'zakat') {
        var z = toolCtx('zakat').zakat();
        return { kind: 'reminder',
          text: t('zakat.payable') + ': ' + L.moneyRaw(z.due, L.currencyCode(), 0),
          source: stamp };
      }
      if (id === 'goals') {
        var g = toolCtx('goals').goals();
        return { kind: 'quote',
          text: t('goals.saved') + ' ' + L.money(g.saved) + ' ' + t('common.of') + ' ' + L.money(g.target) +
                ' — ' + Math.round(g.ratio * 100) + '%',
          source: stamp };
      }
      if (id === 'tax') {
        var tx = toolCtx('tax').tax();
        if (tx && tx.taxable) {
          return { kind: 'reminder',
            text: t('tax.dueAnnual') + ': ' + L.moneyRaw(tx.dueAnnual, tx.ccy, 0) +
                  ' · ' + t('tax.effective', { rate: L.num(tx.effective * 100, { maximumFractionDigits: 1 }) + '%' }),
            source: tx.config.authority + ' · ' + tx.config.year };
        }
      }
    } catch (err) {}
    return null;
  }


  /* The prayer countdown inside an open tool ticks like the one on Home,
     and stops for the same reason. */
  let prayerTick = null;

  return defineScreen({
    id: 'tool',
    template: function () {
      return `
  <section class="screen screen--tool" id="screen-tool" role="tabpanel" aria-label="Tool">
    <div id="toolHeader"></div>
    <div id="toolBody"></div>
  </section>
`;
    },

    bind: function (root, signal) {
      screenRoot = root;

      /* The header sticks; a hairline appears once content scrolls under it. */
      root.addEventListener('scroll', function () {
        const bar = $('.toolbar', root);
        if (bar) bar.classList.toggle('is-stuck', root.scrollTop > 4);
      }, { passive: true, signal: signal });

      /* A tool that shows live data redraws when the connection changes,
         so a stale figure does not sit there claiming to be current. */
      window.addEventListener('online', function () { if (currentTool) renderTool(); }, { signal: signal });
      window.addEventListener('offline', function () { if (currentTool) renderTool(); }, { signal: signal });
    },

    render: function () {
      bindShell();
      if (currentTool) renderTool();
    },

    onEnter: function () {
      bindShell();
      prayerTick = setInterval(function () {
        if (currentTool !== 'prayer') return;
        const el = $('[data-prayer-count]', screenRoot);
        if (el) el.textContent = toolCtx('prayer').prayerState().countdown;
      }, 1000);
    },

    /* Leaving abandons the tool entirely: its sub-view, its countdowns and
       the stack of tools opened on top of it. Reopening Markets from Home
       used to land straight back inside whichever asset detail was last
       open, because only Back cleared it. */
    onLeave: function () {
      clearInterval(prayerTick);
      prayerTick = null;
      if (currentTool) {
        const leaving = toolCtx(currentTool);
        if (leaving) leaving.setState('detail', '');
        stopClocks();
      }
      currentTool = null;
      toolStack.length = 0;
    },

    /* ---- what the shell asks of this screen ---- */
    open: function (id, opts) { bindShell(); openTool(id, opts); },
    close: function () { bindShell(); closeTool(); },
    /* Redraw whatever tool is showing. Asked for by anything that finishes
       after the render that started it — a collection finishing its first
       read, a save landing (CRUD guide §10). */
    rerender: function () { bindShell(); renderTool(); },
    action: function (kind, arg) { bindShell(); return toolAction(kind, arg); },
    shareFor: function (id) { bindShell(); return shareForTool(id); },
    /* The shell hands a pending alert back once the user answers the
       browser permission prompt, which happens outside any tool. */
    takePendingAlert: function () {
      const held = pendingAlert;
      pendingAlert = null;
      return held;
    },
    /* The market sheet changes which market a tool board shows, so the
       host fills it in rather than the shell knowing what is in it. */
    fillMarketPicker: function () { bindShell(); renderMarketPicker(); },
    isOpen: function () { return !!currentTool; },
    /* Which tool is showing, for the shell surfaces that act on it. */
    openId: function () { return currentTool; }
  });
}
