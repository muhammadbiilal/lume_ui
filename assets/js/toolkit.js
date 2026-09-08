/* ============================================================
   Lume — tool journeys
   One shell that every tool passes through, so discovery, gates,
   loading, empty, error, offline, permission, sign-in, results,
   persistence, sharing and the way back are designed once and
   behave identically in all 79 tools.

   A tool contributes a *shape* (see toolspec.js) or a bespoke
   view. It never implements its own gating, freshness or states.
   ============================================================ */
window.LUME_TOOLKIT = function (ctx) {
  'use strict';

  var $ = ctx.$, $$ = ctx.$$, esc = ctx.esc, t = ctx.t, L = ctx.L;
  var SPEC = window.LUME_TOOLSPEC;

  var current = null;          /* { id, feature, spec, state, data } */
  var returnTo = 'home';       /* where Back goes — the return context */

  /* ---------------------------------------------------------
     Per-tool storage
     --------------------------------------------------------- */
  function key(id, kind) { return 'lume-' + kind + '-' + id; }
  function load(id, kind, fallback) {
    var raw = ctx.store.get(key(id, kind));
    if (!raw) return fallback;
    try { return JSON.parse(raw); } catch (e) { return fallback; }
  }
  function save(id, kind, value) { ctx.store.set(key(id, kind), JSON.stringify(value)); }
  function drop(id, kind) { ctx.store.set(key(id, kind), ''); }

  /* ---------------------------------------------------------
     Freshness — never dress cached data as live
     --------------------------------------------------------- */
  function freshnessChip(spec, state) {
    if (state === 'offline') return { cls: 'is-stale', label: 'Offline · showing last saved' };
    if (state === 'stale')   return { cls: 'is-stale', label: 'Cached · may be out of date' };
    if (spec.fresh === 'computed') return { cls: 'is-calc', label: 'Calculated on your device' };
    if (spec.fresh === 'local')    return { cls: 'is-calc', label: 'Saved on this device' };
    if (spec.fresh === 'static')   return { cls: '', label: spec.updated || 'Bundled content' };
    return { cls: 'is-live', label: spec.updated || 'Live' };
  }

  function statusBar(spec, state) {
    var chip = freshnessChip(spec, state);
    var bits = [];
    bits.push('<span class="fresh ' + chip.cls + '">' +
      (chip.cls === 'is-live' ? '<span class="live"></span>' : '') + esc(chip.label) + '</span>');
    if (spec.reqCity) {
      bits.push('<button class="toolcity pressable" data-tool-city>' +
        '<svg class="ico" viewBox="0 0 24 24"><use href="#i-pin"/></svg>' +
        esc(ctx.profile.city) + '</button>');
    }
    if (spec.source) bits.push('<span class="toolsrc">' + esc(spec.source) + '</span>');
    return '<div class="toolstatus__row">' + bits.join('') + '</div>';
  }

  /* ---------------------------------------------------------
     Shared state screens
     --------------------------------------------------------- */
  function stateBlock(o) {
    return '<div class="toolstate">' +
      '<span class="toolstate__art" aria-hidden="true">' +
        '<svg viewBox="0 0 96 72" fill="none">' +
          '<circle cx="48" cy="34" r="24" stroke="var(--border-2)" stroke-width="2" stroke-dasharray="5 7"/>' +
          '<circle cx="20" cy="14" r="3" fill="var(--accent)" opacity=".4"/>' +
          '<circle cx="78" cy="18" r="4" fill="var(--accent)" opacity=".22"/>' +
          (o.glyph || '') +
        '</svg></span>' +
      '<p class="toolstate__title">' + esc(o.title) + '</p>' +
      '<p class="toolstate__text">' + esc(o.text) + '</p>' +
      (o.actions || []).map(function (a) {
        return '<button class="btn ' + (a.primary ? 'btn--accent' : 'btn--ghost') +
          ' pressable toolstate__btn" data-tool-act="' + a.act + '">' + esc(a.label) + '</button>';
      }).join('') +
    '</div>';
  }

  function skeleton(rows) {
    var out = '';
    for (var i = 0; i < (rows || 4); i++) {
      out += '<div class="card card--pad skel-row">' +
        '<span class="skeleton skel-line" style="width:' + (48 + (i % 3) * 14) + '%"></span>' +
        '<span class="skeleton skel-line skel-line--sm" style="width:' + (28 + (i % 2) * 12) + '%"></span>' +
      '</div>';
    }
    return '<div class="row-gap">' + out + '</div>';
  }

  /* ---------------------------------------------------------
     Gates — country, account, permission, city
     --------------------------------------------------------- */
  function gate(feature, spec) {
    if (!ctx.visible(feature)) {
      return { kind: 'unavailable', html: stateBlock({
        title: 'Not available here',
        text: feature.countries
          ? feature.n + ' is only available in ' + feature.countries.map(L.countryName).join(', ') +
            '. Change your country in Personalisation if you have moved.'
          : feature.n + ' is part of the Islamic experience, which is switched off.',
        actions: [{ label: t('profile.personalisation'), act: 'personalise', primary: 1 }]
      }) };
    }

    if (spec.auth === 'account' && !ctx.profile.account) {
      return { kind: 'signedout', html: stateBlock({
        title: 'Sign in to use ' + feature.n,
        text: spec.sensitive
          ? 'This is private information, so it is kept to your account and encrypted on the device. Nothing is shared.'
          : 'Signing in keeps this in sync and lets Lume remember it for you.',
        actions: [{ label: 'Sign in', act: 'signin', primary: 1 },
                  { label: 'Not now', act: 'back' }]
      }) };
    }

    var need = (spec.perms || []).filter(function (p) {
      return (ctx.profile.perms || {})[p] !== 'granted';
    });
    if (need.length) {
      var p = need[0];
      var denied = (ctx.profile.perms || {})[p] === 'denied';
      return { kind: 'permission', html: stateBlock({
        title: denied ? 'Permission is switched off' : 'Lume needs your ' + p,
        text: denied
          ? 'You previously refused access to the ' + p + '. Turn it back on in your device settings, then try again.'
          : (spec.why || 'This tool needs access to your ' + p + ' to work.'),
        actions: denied
          ? [{ label: 'Open settings', act: 'settings', primary: 1 }, { label: 'Try again', act: 'perm:' + p }]
          : [{ label: 'Continue', act: 'perm:' + p, primary: 1 }, { label: 'Not now', act: 'back' }]
      }) };
    }

    if (spec.reqCity && !ctx.profile.city) {
      return { kind: 'nocity', html: stateBlock({
        title: 'Choose a city first',
        text: feature.n + ' works from your city. Pick one — Lume does not need GPS for this.',
        actions: [{ label: 'Choose a city', act: 'personalise', primary: 1 }]
      }) };
    }
    return null;
  }

  /* ---------------------------------------------------------
     Shape: calculator
     --------------------------------------------------------- */
  function viewCalculator(f, spec, host) {
    if (f.id === 'calculator') {
      /* The keypad lives in a sheet so it is reachable from Home too. The tool
         page stays underneath, so closing the pad lands here, not on Home. */
      host.innerHTML =
        '<div class="toolstate"><span class="toolstate__art" aria-hidden="true">' +
        '<svg viewBox="0 0 96 72" fill="none"><rect x="34" y="10" width="28" height="52" rx="8" ' +
        'stroke="var(--border-2)" stroke-width="2"/><path d="M41 22h14M41 34h.01M48 34h.01M55 34h.01' +
        'M41 44h.01M48 44h.01M55 44h.01" stroke="var(--accent)" stroke-width="2.4" stroke-linecap="round"/>' +
        '</svg></span><p class="toolstate__title">Keypad</p>' +
        '<p class="toolstate__text">Standard arithmetic, with your keyboard if you have one.</p>' +
        '<button class="btn btn--accent pressable toolstate__btn" data-tool-act="pad">Open the keypad</button></div>';
      current.actions = { pad: function () { ctx.sheetOpen('calculator'); } };
      setTimeout(function () { if (current && current.id === 'calculator') ctx.sheetOpen('calculator'); }, 120);
      return;
    }

    var draft = load(f.id, 'draft', null);
    var values = {};
    (spec.fields || []).forEach(function (fl) {
      values[fl.id] = draft && draft[fl.id] !== undefined ? draft[fl.id] : defaultOf(fl);
    });

    function defaultOf(fl) {
      if (fl.type === 'currency') return fl.def || L.currencyCode();
      if (fl.type === 'date') {
        var d = new Date();
        if (fl.def === 'today') return iso(d);
        if (typeof fl.def === 'string' && fl.def.charAt(0) === '+') {
          d.setDate(d.getDate() + parseInt(fl.def.slice(1), 10)); return iso(d);
        }
        return fl.def;
      }
      return fl.def;
    }
    function iso(d) { return d.toISOString().slice(0, 10); }

    function fieldHtml(fl) {
      var v = values[fl.id];
      var err = errors[fl.id];
      var input;
      if (fl.type === 'choice') {
        input = '<select class="tfield__input" data-f="' + fl.id + '">' +
          fl.options.map(function (o) {
            return '<option' + (o === v ? ' selected' : '') + '>' + esc(o) + '</option>';
          }).join('') + '</select>';
      } else if (fl.type === 'currency') {
        var codes = ['USD', 'EUR', 'GBP', 'PKR', 'INR', 'AED', 'SAR', 'JPY', L.currencyCode()];
        codes = codes.filter(function (c, i, a) { return a.indexOf(c) === i; });
        input = '<select class="tfield__input" data-f="' + fl.id + '">' +
          codes.map(function (o) {
            return '<option' + (o === (v || L.currencyCode()) ? ' selected' : '') + '>' + esc(o) + '</option>';
          }).join('') + '</select>';
      } else if (fl.type === 'date') {
        input = '<input class="tfield__input" type="date" data-f="' + fl.id + '" value="' + esc(v || '') + '">';
      } else {
        input = '<input class="tfield__input num" type="text" inputmode="decimal" ' +
          'data-f="' + fl.id + '" value="' + esc(v === null || v === undefined ? '' : v) + '">';
      }
      return '<label class="tfield' + (err ? ' is-invalid' : '') + '">' +
        '<span class="tfield__label">' + esc(fl.label) +
          (fl.unit ? ' <i>' + esc(fl.unit) + '</i>' : '') + '</span>' +
        input +
        (err ? '<span class="tfield__err" role="alert">' + esc(err) + '</span>' : '') +
      '</label>';
    }

    var errors = {};

    function validate() {
      errors = {};
      var ok = true;
      (spec.fields || []).forEach(function (fl) {
        var v = values[fl.id];
        if (fl.type === 'number' || fl.type === 'money') {
          /* A malformed number must never quietly become zero. */
          if (v === '' || v === null || v === undefined) {
            errors[fl.id] = fl.label + ' is needed.'; ok = false; return;
          }
          var n = Number(String(v).replace(/[, ]/g, ''));
          if (!isFinite(n)) { errors[fl.id] = 'Enter a number.'; ok = false; return; }
          if (fl.min !== undefined && n < fl.min) {
            errors[fl.id] = 'Must be at least ' + L.num(fl.min) + (fl.unit ? ' ' + fl.unit : '');
            ok = false; return;
          }
          if (fl.max !== undefined && n > fl.max) {
            errors[fl.id] = 'That looks too large — check the value.'; ok = false; return;
          }
          values[fl.id] = n;
        }
      });
      return ok;
    }

    function result() {
      if (!spec.compute) return null;
      return spec.compute(values);
    }

    function render(showResult) {
      var r = showResult && validate() ? result() : null;
      var restored = draft && !host.dataset.draftShown;

      host.innerHTML =
        (restored ? '<div class="draftbar">Draft restored' +
          '<button class="draftbar__x pressable" data-tool-act="discard-draft">Discard</button></div>' : '') +
        (spec.intro ? '<p class="toolintro">' + esc(spec.intro) + '</p>' : '') +
        (r && r.error ? '<div class="toolerr" role="alert">' + esc(r.error) + '</div>' : '') +
        (r && !r.error ? resultCard(r) : '') +
        '<div class="tform">' + (spec.fields || []).map(fieldHtml).join('') + '</div>' +
        '<div class="tactions">' +
          '<button class="btn btn--ghost pressable" data-tool-act="reset">Reset</button>' +
          '<button class="btn btn--accent pressable" data-tool-act="calc">Calculate</button>' +
        '</div>' +
        (spec.note ? '<p class="toolnote">' + esc(spec.note) + '</p>' : '') +
        historyBlock();
      if (restored) host.dataset.draftShown = '1';
    }

    function money(v) { return L.moneyRaw(Math.round(v), null, 0); }

    function resultCard(r) {
      var main = r.money ? money(r.value)
        : L.num(r.value, { maximumFractionDigits: r.decimals === undefined ? 2 : r.decimals }) +
          (r.unit ? ' ' + r.unit : '');
      var extra = (r.extra || []).map(function (e) {
        return '<span><b>' + esc(e[2] ? money(e[1]) : String(e[1])) + '</b>' + esc(e[0]) + '</span>';
      }).join('');
      var note = r.note ? String(r.note).replace('{take}', money(r.take || 0)) : '';
      /* Zakat compares against nisab, which moves with the silver rate. */
      if (f.id === 'zakat' && r.nisabUsd !== undefined) {
        var nis = r.nisabUsd * (L.RATES[L.currencyCode()] || 1);
        note = r.net >= nis
          ? 'Above nisab (' + money(nis) + '), so zakat is due.'
          : 'Below nisab (' + money(nis) + ') — no zakat is due on this amount.';
      }
      return '<div class="tresult">' +
        '<p class="tresult__label">Result</p>' +
        '<p class="tresult__value num">' + esc(main) + '</p>' +
        (note ? '<p class="tresult__note">' + esc(note) + '</p>' : '') +
        (extra ? '<div class="tresult__split">' + extra + '</div>' : '') +
        '<div class="tresult__acts">' +
          (spec.canSave ? '<button class="btn btn--ghost pressable" data-tool-act="save-calc">Save</button>' : '') +
          (spec.canShare ? '<button class="btn btn--ghost pressable" data-tool-act="share-calc">' +
            '<svg class="ico" viewBox="0 0 24 24"><use href="#i-share"/></svg>Share</button>' : '') +
        '</div>' +
      '</div>';
    }

    function historyBlock() {
      var hist = load(f.id, 'hist', []);
      if (!hist.length) return '';
      return '<p class="group-label" style="padding:0;margin:22px 0 9px">Saved</p>' +
        '<div class="list list--flat">' + hist.slice(0, 5).map(function (h, i) {
          return '<div class="list-row"><span class="list-row__body">' +
            '<span class="list-row__title">' + esc(h.label) + '</span>' +
            '<span class="list-row__sub">' + esc(h.when) + '</span></span>' +
            '<span class="list-row__end"><button class="ghostbtn pressable" data-tool-act="del-hist:' + i + '" ' +
            'aria-label="Delete"><svg class="ico" viewBox="0 0 24 24"><use href="#i-x"/></svg></button></span></div>';
        }).join('') + '</div>';
    }

    host.addEventListener('input', function (e) {
      var el = e.target.closest('[data-f]');
      if (!el) return;
      values[el.dataset.f] = el.value;
      save(f.id, 'draft', values);          /* autosave: reopening restores it */
    });
    host.addEventListener('change', function (e) {
      var el = e.target.closest('[data-f]');
      if (el) { values[el.dataset.f] = el.value; save(f.id, 'draft', values); }
    });

    current.actions = {
      calc: function () { render(true); },
      reset: function () {
        (spec.fields || []).forEach(function (fl) { values[fl.id] = defaultOf(fl); });
        drop(f.id, 'draft'); draft = null; delete host.dataset.draftShown;
        render(false); ctx.toast('Reset');
      },
      'discard-draft': function () {
        drop(f.id, 'draft'); draft = null; delete host.dataset.draftShown;
        (spec.fields || []).forEach(function (fl) { values[fl.id] = defaultOf(fl); });
        render(false);
      },
      'save-calc': function () {
        var r = result();
        if (!r || r.error) return;
        var hist = load(f.id, 'hist', []);
        hist.unshift({
          label: (r.money ? money(r.value) : L.num(r.value, { maximumFractionDigits: 2 })) +
                 (r.unit ? ' ' + r.unit : ''),
          when: L.dateShort(new Date())
        });
        save(f.id, 'hist', hist.slice(0, 20));
        render(true);
        ctx.toast('Saved');
      },
      'share-calc': function () {
        var r = result();
        if (!r || r.error) return;
        ctx.openShareData({
          kind: 'quote',
          text: ctx.fname(f) + ': ' + (r.money ? money(r.value)
            : L.num(r.value, { maximumFractionDigits: 2 }) + (r.unit ? ' ' + r.unit : '')),
          source: spec.source || 'Calculated in Lume'
        });
      }
    };
    (spec.fields || []).forEach(function () {});
    for (var i = 0; i < 20; i++) {
      (function (n) { current.actions['del-hist:' + n] = function () { confirmDeleteHist(f, n, render); }; })(i);
    }

    render(false);
  }

  function confirmDeleteHist(f, index, render) {
    ctx.confirm({
      title: 'Delete this saved result?',
      text: 'It will be removed from this tool only.',
      danger: 'Delete',
      onYes: function () {
        var hist = load(f.id, 'hist', []);
        var removed = hist.splice(index, 1)[0];
        save(f.id, 'hist', hist);
        render(false);
        ctx.undo('Deleted', function () {
          var h = load(f.id, 'hist', []);
          h.splice(index, 0, removed);
          save(f.id, 'hist', h);
          render(false);
        });
      }
    });
  }

  /* ---------------------------------------------------------
     Shape: data
     --------------------------------------------------------- */
  function viewData(f, spec, host) {
    host.innerHTML = skeleton(4);

    setTimeout(function () {
      if (!current || current.id !== f.id) return;
      if (!navigator.onLine) {
        var cached = load(f.id, 'cache', null);
        current.state = 'offline';
        setStatus(spec, 'offline');
        host.innerHTML = cached
          ? renderRows(cached) + offlineNote()
          : stateBlock({
              title: 'You are offline',
              text: 'Lume has no saved copy of ' + f.n.toLowerCase() + ' yet. Reconnect and try again.',
              actions: [{ label: t('a.tryAgain'), act: 'reload', primary: 1 }]
            });
        return;
      }
      if (current.forceState === 'error') {
        setStatus(spec, 'stale');
        host.innerHTML = stateBlock({
          title: 'Something went wrong',
          text: 'We could not reach ' + (spec.source || 'the service') + '. It is usually brief.',
          actions: [{ label: t('a.tryAgain'), act: 'reload', primary: 1 }]
        });
        return;
      }
      var rows = spec.rows || [];
      if (spec.custom === 'schedule') { host.innerHTML = loadshedView(); setStatus(spec, 'live'); return; }
      if (!rows.length) {
        host.innerHTML = stateBlock({
          title: 'Nothing to show yet',
          text: spec.searchable
            ? 'Enter ' + spec.searchable.toLowerCase() + ' to look something up.'
            : 'There is no data for ' + ctx.profile.city + ' right now.',
          actions: spec.searchable ? [{ label: 'Look up', act: 'lookup', primary: 1 }] : []
        });
        setStatus(spec, 'live');
        return;
      }
      save(f.id, 'cache', rows);
      setStatus(spec, 'live');
      host.innerHTML = renderRows(rows);
    }, 620);

    function offlineNote() {
      return '<p class="toolnote">Saved copy from the last time you were online.</p>';
    }

    function renderRows(rows) {
      var money = spec.unit === '% a year' || f.id === 'natsavings';
      return '<div class="row-gap"><div class="list">' + rows.map(function (r) {
        var val = r[1];
        var shown = typeof val === 'number'
          ? (money ? L.num(val, { maximumFractionDigits: 2 }) + '%' : L.moneyRaw(val, null, val < 1000 ? 2 : 0))
          : String(val);
        if (val === 0 && !money) shown = '';
        var dir = /^\+/.test(r[2]) ? 'is-up' : /^−|^-/.test(r[2]) ? 'is-down' : '';
        return '<div class="list-row">' +
          '<span class="list-row__icon"><svg class="ico" viewBox="0 0 24 24"><use href="#' + f.i + '"/></svg></span>' +
          '<span class="list-row__body"><span class="list-row__title">' + esc(r[0]) + '</span>' +
          (spec.unit ? '<span class="list-row__sub">' + esc(spec.unit) + '</span>' : '') + '</span>' +
          '<span class="list-row__end">' +
            (shown ? '<span class="list-row__value num">' + esc(shown) + '</span>' : '') +
            (r[2] ? '<span class="delta ' + dir + '">' + esc(r[2]) + '</span>' : '') +
          '</span></div>';
      }).join('') + '</div></div>' +
      '<div class="tactions"><button class="btn btn--ghost pressable" data-tool-act="reload">' +
        '<svg class="ico" viewBox="0 0 24 24"><use href="#i-refresh"/></svg>' + esc(t('a.refresh')) + '</button>' +
        (spec.canShare ? '<button class="btn btn--accent pressable" data-tool-act="share-data">' +
          '<svg class="ico" viewBox="0 0 24 24"><use href="#i-share"/></svg>' + esc(t('a.share')) + '</button>' : '') +
      '</div>';
    }

    function loadshedView() {
      var slots = [['06:00', '08:00', 'done'], ['14:00', '16:00', 'next'], ['22:00', '23:00', 'later']];
      return '<article class="card card--pad" style="display:flex;align-items:center;gap:14px;margin:0 var(--pad)">' +
        '<span class="stat-row__icon" style="background:var(--tint-accent);color:var(--accent)">' +
        '<svg class="ico" viewBox="0 0 24 24"><use href="#i-bolt"/></svg></span>' +
        '<div style="flex:1"><p class="progress-card__title">Power is on</p>' +
        '<p class="progress-card__meta">Next outage in about 2 hours</p></div></article>' +
        '<div class="row-gap" style="margin-top:14px"><div class="list">' + slots.map(function (s) {
          return '<div class="list-row"><span class="list-row__icon"' +
            (s[2] === 'next' ? ' style="background:var(--tint-accent);color:var(--accent)"' : '') + '>' +
            '<svg class="ico" viewBox="0 0 24 24"><use href="#i-clock"/></svg></span>' +
            '<span class="list-row__body"><span class="list-row__title num">' + s[0] + ' – ' + s[1] + '</span>' +
            '<span class="list-row__sub">' + (s[2] === 'done' ? 'Completed' : s[2] === 'next' ? 'Next' : 'Scheduled') +
            '</span></span></div>';
        }).join('') + '</div></div>' +
        '<p class="toolnote">Schedules can change at short notice.</p>';
    }

    current.actions = {
      reload: function () { current.forceState = null; open(f.id, { keepReturn: 1 }); },
      lookup: function () { ctx.toast('Enter ' + (spec.searchable || 'a value')); },
      'share-data': function () {
        var rows = spec.rows || [];
        ctx.openShareData({
          kind: 'quote',
          text: ctx.fname(f) + ' — ' + rows.slice(0, 2).map(function (r) {
            return r[0] + ' ' + (typeof r[1] === 'number' ? L.moneyRaw(r[1], null, 0) : r[1]);
          }).join(', '),
          source: spec.source || ''
        });
      }
    };
  }

  /* ---------------------------------------------------------
     Shape: list
     --------------------------------------------------------- */
  function viewList(f, spec, host) {
    var items = load(f.id, 'items', null);
    if (items === null) { items = (spec.seed || []).map(function (s) { return { t: s[0], m: s[1] }; }); }

    function persist() { save(f.id, 'items', items); }

    function render() {
      if (!items.length) {
        host.innerHTML = stateBlock({
          title: 'No ' + spec.noun + 's yet',
          text: 'Add your first ' + spec.noun + ' and it will stay on this device.',
          actions: [{ label: 'Add a ' + spec.noun, act: 'add', primary: 1 }]
        });
        return;
      }
      host.innerHTML =
        '<div class="row-gap"><div class="list">' + items.map(function (it, i) {
          return '<div class="list-row' + (it.done ? ' is-done-row' : '') + '">' +
            '<button class="task__box tlist__box pressable" data-tool-act="toggle:' + i + '" ' +
              'aria-label="Mark done"><svg class="ico" viewBox="0 0 24 24"><use href="#i-check"/></svg></button>' +
            '<span class="list-row__body"><span class="list-row__title">' + esc(it.t) + '</span>' +
            (it.m ? '<span class="list-row__sub">' + esc(it.m) + '</span>' : '') + '</span>' +
            '<span class="list-row__end">' +
              '<button class="ghostbtn pressable" data-tool-act="del:' + i + '" aria-label="Delete">' +
              '<svg class="ico" viewBox="0 0 24 24"><use href="#i-x"/></svg></button></span></div>';
        }).join('') + '</div></div>' +
        '<div class="tactions">' +
          (spec.canExport ? '<button class="btn btn--ghost pressable" data-tool-act="export">' +
            '<svg class="ico" viewBox="0 0 24 24"><use href="#i-download"/></svg>Export</button>' : '') +
          '<button class="btn btn--accent pressable" data-tool-act="add">' +
          '<svg class="ico" viewBox="0 0 24 24"><use href="#i-plus"/></svg>Add ' + esc(spec.noun) + '</button>' +
        '</div>' +
        (spec.sensitive ? '<p class="toolnote"><svg class="ico" viewBox="0 0 24 24" style="width:13px;height:13px;display:inline;vertical-align:-2px"><use href="#i-lock"/></svg> Private to you. Never shown on Home or in notification previews.</p>' : '');
    }

    var acts = {
      add: function () {
        ctx.prompt({
          title: 'New ' + spec.noun,
          label: spec.noun.charAt(0).toUpperCase() + spec.noun.slice(1),
          onOk: function (value) {
            if (!value) return;
            items.unshift({ t: value, m: L.dateShort(new Date()) });
            persist(); render(); ctx.toast('Added');
          }
        });
      },
      export: function () {
        ctx.toast('Exported — your copy stays readable outside Lume');
      }
    };
    for (var i = 0; i < 200; i++) {
      (function (n) {
        acts['toggle:' + n] = function () {
          if (!items[n]) return;
          items[n].done = !items[n].done; persist(); render();
        };
        acts['del:' + n] = function () {
          var it = items[n];
          if (!it) return;
          ctx.confirm({
            title: 'Delete “' + it.t + '”?',
            text: (spec.writesTo || []).indexOf('calendar') !== -1
              ? 'It will also disappear from your calendar.'
              : 'This removes it from ' + f.n + '.',
            danger: 'Delete',
            onYes: function () {
              items.splice(n, 1); persist(); render();
              ctx.undo('Deleted', function () { items.splice(n, 0, it); persist(); render(); });
            }
          });
        };
      })(i);
    }
    current.actions = acts;
    render();
  }

  /* ---------------------------------------------------------
     Shape: tracker
     --------------------------------------------------------- */
  function viewTracker(f, spec, host) {
    var saved = load(f.id, 'state', null);
    var value = saved !== null ? saved : (spec.current || 0);
    var target = spec.target || 7;

    function render() {
      var pct = Math.max(0, Math.min(1, value / target));
      var circ = 2 * Math.PI * 42;
      host.innerHTML =
        '<div class="row-gap"><article class="card ring-card">' +
          '<div class="ring"><svg viewBox="0 0 100 100" aria-hidden="true">' +
            '<circle class="ring__bg" cx="50" cy="50" r="42" fill="none" stroke-width="9"/>' +
            '<circle class="ring__fg" cx="50" cy="50" r="42" fill="none" stroke-width="9" ' +
            'stroke-dasharray="' + circ.toFixed(1) + '" stroke-dashoffset="' + (circ * (1 - pct)).toFixed(1) + '"/>' +
          '</svg><div class="ring__label"><span class="ring__value num">' + L.num(value) + '</span>' +
          '<span class="ring__unit">of ' + L.num(target) + '</span></div></div>' +
          '<div class="ring-card__body"><h2 class="ring-card__title">' +
            esc(value >= target ? 'Target reached' : L.num(target - value) + ' ' + spec.unitLabel +
              (target - value === 1 ? '' : 's') + ' to go') + '</h2>' +
          '<p class="ring-card__text">' + esc(spec.unitLabel.charAt(0).toUpperCase() + spec.unitLabel.slice(1) +
            's logged today. Kept on this device.') + '</p></div>' +
        '</article></div>' +
        '<div class="tactions">' +
          '<button class="btn btn--ghost pressable" data-tool-act="minus">−1</button>' +
          '<button class="btn btn--accent pressable" data-tool-act="plus">+1 ' + esc(spec.unitLabel) + '</button>' +
        '</div>' +
        '<div class="row-gap" style="margin-top:6px"><div class="card habits">' +
          [0, 1, 2, 3, 4, 5, 6].map(function (d) { return ''; }).join('') +
          '<div class="habit"><span class="habit__name">Last 7</span><span class="habit__days">' +
            [1, 1, 0, 1, 1, 1, 1].map(function (on, i) {
              return '<i class="habit__day' + (on ? ' is-on' : '') + (i === 6 ? ' is-today' : '') + '"></i>';
            }).join('') + '</span>' +
          '<span class="habit__streak"><svg class="ico" viewBox="0 0 24 24"><use href="#i-flame"/></svg>' +
            L.num(value) + '</span></div></div></div>' +
        (spec.sensitive ? '<p class="toolnote">Private to you and never shown on Home.</p>' : '');
    }

    current.actions = {
      plus: function () { value = Math.min(target * 3, value + 1); save(f.id, 'state', value); render(); },
      minus: function () { value = Math.max(0, value - 1); save(f.id, 'state', value); render(); }
    };
    render();
  }

  /* ---------------------------------------------------------
     Shape: reader
     --------------------------------------------------------- */
  function viewReader(f, spec, host) {
    if (spec.searchable) {
      host.innerHTML =
        '<label class="search search--sm" style="margin:0 var(--pad)">' +
          '<svg class="ico" viewBox="0 0 24 24"><use href="#i-search"/></svg>' +
          '<input type="search" id="readerSearch" placeholder="' + esc(spec.searchable) + '">' +
        '</label>' +
        '<div class="row-gap" style="margin-top:14px"><div class="list">' +
          (spec.results || []).map(function (r) {
            return '<button class="list-row pressable" data-tool-act="open-quran">' +
              '<span class="list-row__icon"><svg class="ico" viewBox="0 0 24 24"><use href="#i-book"/></svg></span>' +
              '<span class="list-row__body"><span class="list-row__title">' + esc(r[0]) + '</span>' +
              '<span class="list-row__sub">' + esc(r[1]) + '</span></span>' +
              '<span class="list-row__end"><svg class="ico" viewBox="0 0 24 24"><use href="#i-chev-r"/></svg></span></button>';
          }).join('') + '</div></div>';
      current.actions = { 'open-quran': function () { open('quran'); } };
      return;
    }

    var marked = load(f.id, 'mark', false);
    function render() {
      host.innerHTML =
        '<div class="row-gap"><article class="card card--pad">' +
          (spec.arabic ? '<p class="arabic" dir="rtl" lang="ar">' + esc(spec.arabic) + '</p>' : '') +
          '<p class="body">' + esc(spec.text) + '</p>' +
          '<div class="card__foot"><p class="quote__by">' + esc(spec.ref || spec.sub || '') + '</p>' +
          '<div class="card__actions">' +
            '<button class="ghostbtn pressable' + (marked ? ' is-on' : '') + '" data-tool-act="mark" ' +
              'aria-label="' + esc(t('a.bookmark')) + '"><svg class="ico" viewBox="0 0 24 24"><use href="#i-bookmark"/></svg></button>' +
            '<button class="ghostbtn pressable" data-tool-act="share-read" aria-label="' + esc(t('a.share')) + '">' +
              '<svg class="ico" viewBox="0 0 24 24"><use href="#i-share"/></svg></button>' +
          '</div></div>' +
        '</article></div>' +
        (spec.progress !== undefined
          ? '<div class="row-gap" style="margin-top:12px"><div class="card card--pad">' +
            '<p class="progress-card__meta">' + esc(spec.sub) + '</p>' +
            '<span class="bar" style="margin-top:10px"><span class="bar__fill" data-fill="' + spec.progress + '"></span></span>' +
            '</div></div>' +
            '<div class="tactions"><button class="btn btn--accent btn--block pressable" data-tool-act="continue">' +
            '<svg class="ico" viewBox="0 0 24 24"><use href="#i-play"/></svg>' + esc(t('a.continue')) + '</button></div>'
          : '');
      ctx.animateBars(host);
    }
    current.actions = {
      mark: function () {
        marked = !marked; save(f.id, 'mark', marked); render();
        ctx.toast(marked ? 'Saved to your bookmarks' : 'Removed from bookmarks');
      },
      'share-read': function () {
        ctx.openShareData({
          kind: spec.shareKind || 'quote', arabic: spec.arabic,
          text: spec.text, source: spec.ref || ''
        });
      },
      continue: function () { ctx.toast('Reading on'); }
    };
    render();
  }

  /* ---------------------------------------------------------
     Shape: scanner
     --------------------------------------------------------- */
  function viewScanner(f, spec, host) {
    host.innerHTML =
      '<div class="scanstage"><div class="scanstage__frame" aria-hidden="true">' +
        '<span></span><span></span><span></span><span></span>' +
        '<svg class="ico scanstage__icon" viewBox="0 0 24 24"><use href="#' + f.i + '"/></svg>' +
      '</div><p class="scanstage__hint">' + esc(spec.action || 'Point the camera at the subject') + '</p></div>' +
      '<div class="tactions">' +
        '<button class="btn btn--ghost pressable" data-tool-act="pick">Choose from photos</button>' +
        '<button class="btn btn--accent pressable" data-tool-act="capture">' + esc(spec.action || 'Capture') + '</button>' +
      '</div>' +
      '<p class="toolnote">Captured on your device. Nothing is uploaded unless you share it.</p>';

    current.actions = {
      capture: function () {
        host.querySelector('.scanstage').classList.add('is-busy');
        setTimeout(function () {
          if (!current || current.id !== f.id) return;
          host.innerHTML = stateBlock({
            title: f.id === 'qr' ? 'Code read' : 'Captured',
            text: f.id === 'qr' ? 'lume.app/invite/8f2c — open it, or copy the text.'
                                : 'One page ready. Add more pages or finish now.',
            actions: [{ label: f.id === 'qr' ? 'Open link' : 'Finish', act: 'finish', primary: 1 },
                      { label: 'Scan again', act: 'again' }]
          });
        }, 900);
      },
      again: function () { open(f.id, { keepReturn: 1 }); },
      pick: function () { ctx.toast('Photo picker — falls back when the camera is unavailable'); },
      finish: function () { ctx.toast('Saved'); back(); }
    };
  }

  /* ---------------------------------------------------------
     Shape: timer
     --------------------------------------------------------- */
  function viewTimer(f, spec, host) {
    if (f.id === 'tasbih') {
      host.innerHTML =
        '<div class="toolstate"><span class="toolstate__art" aria-hidden="true">' +
        '<svg viewBox="0 0 96 72" fill="none"><circle cx="48" cy="36" r="22" stroke="var(--accent)" ' +
        'stroke-width="2.4"/><circle cx="48" cy="14" r="5" fill="var(--accent)"/></svg></span>' +
        '<p class="toolstate__title">Tasbih</p>' +
        '<p class="toolstate__text">Count to 33 and back, with a gentle buzz at each round.</p>' +
        '<button class="btn btn--accent pressable toolstate__btn" data-tool-act="pad">Start counting</button></div>';
      current.actions = { pad: function () { ctx.sheetOpen('tasbeeh'); } };
      setTimeout(function () { if (current && current.id === 'tasbih') ctx.sheetOpen('tasbeeh'); }, 120);
      return;
    }
    var running = false, seconds = spec.mode === 'countdown' ? 300 : 0, tick = null;

    function fmt(s) {
      var m = Math.floor(Math.abs(s) / 60), r = Math.abs(s) % 60;
      return (s < 0 ? '−' : '') + m + ':' + (r < 10 ? '0' : '') + r;
    }
    function render() {
      host.innerHTML =
        '<div class="timerface"><p class="timerface__value num">' + esc(fmt(seconds)) + '</p>' +
        '<p class="timerface__mode">' + esc(spec.mode === 'countdown' ? 'Countdown' : 'Elapsed') + '</p></div>' +
        (spec.presets ? '<div class="chips chips--wrap" style="justify-content:center;padding:0 var(--pad)">' +
          spec.presets.map(function (m) {
            return '<button class="chip" data-tool-act="preset:' + m + '">' + L.num(m) + ' min</button>';
          }).join('') + '</div>' : '') +
        '<div class="tactions">' +
          '<button class="btn btn--ghost pressable" data-tool-act="reset">Reset</button>' +
          '<button class="btn btn--accent pressable" data-tool-act="toggle">' +
            (running ? 'Pause' : 'Start') + '</button>' +
        '</div>';
    }
    function stop() { if (tick) { clearInterval(tick); tick = null; } running = false; }

    var acts = {
      toggle: function () {
        running = !running;
        if (running) {
          tick = setInterval(function () {
            seconds += spec.mode === 'countdown' ? -1 : 1;
            if (spec.mode === 'countdown' && seconds === 0) { stop(); ctx.toast('Time is up'); }
            render();
          }, 1000);
        } else { stop(); }
        render();
      },
      reset: function () { stop(); seconds = spec.mode === 'countdown' ? 300 : 0; render(); }
    };
    (spec.presets || []).forEach(function (m) {
      acts['preset:' + m] = function () { stop(); seconds = m * 60; render(); };
    });
    current.actions = acts;
    current.cleanup = stop;
    render();
  }

  /* ---------------------------------------------------------
     Bespoke journeys
     --------------------------------------------------------- */
  var BESPOKE = {
    prayer: function (f, spec, host) {
      var st = ctx.prayerState();
      host.innerHTML =
        '<div class="row-gap"><article class="card card--pad nextprayer">' +
          '<p class="nextprayer__label">' + esc(t('home.nextPrayer')) + '</p>' +
          '<p class="nextprayer__name">' + esc(st.next.name) + '</p>' +
          '<p class="nextprayer__time num">' + esc(ctx.hhmm(st.next)) + '</p>' +
          '<span class="bar" style="margin-top:14px"><span class="bar__fill" data-fill="' +
            Math.round(st.progress * 100) + '"></span></span>' +
        '</article></div>' +
        '<div class="row-gap" style="margin-top:12px"><div class="list">' +
          st.list.map(function (p) {
            var isNext = p.name === st.next.name;
            return '<div class="list-row' + (isNext ? ' is-next' : '') + '">' +
              '<span class="list-row__icon"' + (isNext ? ' style="background:var(--tint-accent);color:var(--accent)"' : '') + '>' +
              '<svg class="ico" viewBox="0 0 24 24"><use href="#' + (p.minor ? 'i-sun' : 'i-prayer') + '"/></svg></span>' +
              '<span class="list-row__body"><span class="list-row__title">' + esc(p.name) + '</span>' +
              '<span class="list-row__sub">' + (p.minor ? 'Not a prayer' : isNext ? 'Next' : 'Reminder on') + '</span></span>' +
              '<span class="list-row__end"><span class="list-row__value num">' + esc(ctx.hhmm(p)) + '</span></span></div>';
          }).join('') + '</div></div>' +
        '<div class="tactions">' +
          '<button class="btn btn--ghost pressable" data-tool-act="method">Method</button>' +
          '<button class="btn btn--accent pressable" data-tool-act="log">Log this prayer</button>' +
        '</div>' +
        '<p class="toolnote">Computed for ' + esc(ctx.profile.city) + ' using ' + esc(ctx.profile.method) +
        '. Change the method if your mosque follows another.</p>';
      ctx.animateBars(host);
      current.actions = {
        log: function () { open('praytrack'); },
        method: function () { ctx.methodSheet(); }
      };
    },

    qibla: function (f, spec, host) {
      var deg = ctx.qiblaDeg();
      host.innerHTML =
        '<div class="qibla"><div class="qibla__dial"><svg viewBox="0 0 200 200">' +
          '<circle cx="100" cy="100" r="94" fill="none" stroke="var(--border)" stroke-width="1.5"/>' +
          '<circle cx="100" cy="100" r="76" fill="none" stroke="var(--border)" stroke-width="1.5" stroke-dasharray="2 8" stroke-linecap="round"/>' +
          '<circle cx="100" cy="100" r="58" fill="var(--tint-neutral)" opacity=".55"/>' +
          '<text x="100" y="22" text-anchor="middle" font-size="12" font-weight="700" fill="var(--text-3)">N</text>' +
          '<text x="182" y="105" text-anchor="middle" font-size="12" font-weight="700" fill="var(--text-3)">E</text>' +
          '<text x="100" y="188" text-anchor="middle" font-size="12" font-weight="700" fill="var(--text-3)">S</text>' +
          '<text x="18" y="105" text-anchor="middle" font-size="12" font-weight="700" fill="var(--text-3)">W</text>' +
          '<g class="qibla__needle" style="transform:rotate(' + deg + 'deg)">' +
            '<path d="M100 30 112 108 100 100 88 108z" fill="var(--accent)"/>' +
            '<path d="M100 170 88 100 100 108 112 100z" fill="var(--text-3)" opacity=".45"/>' +
            '<circle cx="100" cy="30" r="9" fill="var(--accent)"/>' +
          '</g>' +
          '<circle cx="100" cy="100" r="6" fill="var(--card)" stroke="var(--border-2)" stroke-width="1.5"/>' +
        '</svg></div>' +
        '<p class="qibla__deg num">' + L.num(deg) + '° ' + window.LUME_SOLAR.compassPoint(deg) + '</p>' +
        '<p class="qibla__hint">From ' + esc(ctx.profile.city) + '. Hold the phone flat and turn until the<br>marker points straight up.</p></div>' +
        '<div class="tactions">' +
          '<button class="btn btn--ghost pressable" data-tool-act="bearing">Show bearing only</button>' +
          '<button class="btn btn--accent pressable" data-tool-act="calib">Recalibrate</button>' +
        '</div>' +
        '<p class="toolnote">If the compass is unavailable, the bearing above still works with any compass.</p>';
      current.actions = {
        calib: function () { ctx.toast('Move the phone in a figure of eight'); },
        bearing: function () { ctx.toast(L.num(deg) + '° from true north'); }
      };
    },

    calendar: function (f, spec, host) {
      /* An aggregation layer: it shows what other tools own, and never
         invents a second copy of their data. */
      var sources = [
        { id: 'todos', label: 'Tasks', icon: 'i-check-square' },
        { id: 'bills', label: 'Bills', icon: 'i-receipt' },
        { id: 'installments', label: 'Instalments', icon: 'i-calendar' },
        { id: 'committee', label: 'Committee', icon: 'i-users' },
        { id: 'meds', label: 'Medication', icon: 'i-pill' },
        { id: 'birthdays', label: 'Birthdays', icon: 'i-cake' },
        { id: 'prayer', label: 'Prayers', icon: 'i-prayer' }
      ].filter(function (s) {
        var feat = ctx.feature(s.id);
        return feat && ctx.visible(feat);        /* hidden tools leak nothing here */
      });

      var today = new Date();
      var days = [];
      for (var i = 0; i < 7; i++) {
        var d = new Date(today); d.setDate(today.getDate() + i);
        days.push(d);
      }
      host.innerHTML =
        '<div class="calstrip">' + days.map(function (d, i) {
          return '<button class="calday' + (i === 0 ? ' is-today' : '') + '" data-tool-act="day:' + i + '">' +
            '<span class="calday__dow">' + esc(L.date(d, { weekday: 'short' })) + '</span>' +
            '<span class="calday__num num">' + L.num(d.getDate()) + '</span>' +
            (i % 2 === 0 ? '<span class="calday__dot"></span>' : '') +
          '</button>';
        }).join('') + '</div>' +
        (ctx.profile.islamic ? '<p class="toolintro">' + esc(L.dateLong(today)) + ' · 15 Rabi’ al-Awwal</p>'
                             : '<p class="toolintro">' + esc(L.dateLong(today)) + '</p>') +
        '<div class="row-gap"><div class="list">' +
          '<button class="list-row pressable" data-tool-act="src:todos"><span class="list-row__icon">' +
            '<svg class="ico" viewBox="0 0 24 24"><use href="#i-check-square"/></svg></span>' +
            '<span class="list-row__body"><span class="list-row__title">Finish the Q3 summary</span>' +
            '<span class="list-row__sub">Task · 15:00</span></span>' +
            '<span class="list-row__end"><svg class="ico" viewBox="0 0 24 24"><use href="#i-chev-r"/></svg></span></button>' +
          '<button class="list-row pressable" data-tool-act="src:events"><span class="list-row__icon">' +
            '<svg class="ico" viewBox="0 0 24 24"><use href="#i-list"/></svg></span>' +
            '<span class="list-row__body"><span class="list-row__title">Design review</span>' +
            '<span class="list-row__sub">Event · 14:00 · Studio 2</span></span>' +
            '<span class="list-row__end"><svg class="ico" viewBox="0 0 24 24"><use href="#i-chev-r"/></svg></span></button>' +
        '</div></div>' +
        '<p class="group-label" style="padding:0 var(--pad);margin:22px 0 9px">Showing on your calendar</p>' +
        '<div class="row-gap"><div class="list">' + sources.map(function (s) {
          return '<button class="list-row pressable" data-tool-act="src:' + s.id + '">' +
            '<span class="list-row__icon"><svg class="ico" viewBox="0 0 24 24"><use href="#' + s.icon + '"/></svg></span>' +
            '<span class="list-row__body"><span class="list-row__title">' + esc(s.label) + '</span>' +
            '<span class="list-row__sub">Owned by ' + esc(ctx.fname(ctx.feature(s.id))) + '</span></span>' +
            '<span class="list-row__end"><svg class="ico" viewBox="0 0 24 24"><use href="#i-arrow-ur"/></svg></span></button>';
        }).join('') + '</div></div>' +
        '<p class="toolnote">Every entry opens the tool that owns it. Calendar never keeps a second copy.</p>';

      var acts = {};
      sources.concat([{ id: 'events' }]).forEach(function (s) {
        acts['src:' + s.id] = function () { open(s.id); };
      });
      for (var n = 0; n < 7; n++) acts['day:' + n] = function () {};
      current.actions = acts;
    },

    parcel: function (f, spec, host) {
      var steps = [['6 Sep', 'Picked up', 'Lahore · 18:40', 1],
                   ['7 Sep', 'In transit', 'Sukkur hub · 04:15', 1],
                   ['8 Sep', 'Out for delivery', 'Karachi · rider assigned', 2],
                   ['Today', 'Delivery expected', 'Between 14:00 and 18:00', 0]];
      host.innerHTML =
        '<div class="row-gap"><article class="card card--pad">' +
          '<div class="live-train__head"><span class="live-train__no num">TCS</span>' +
          '<div class="live-train__title"><p class="live-train__name">4820 9931 22</p>' +
          '<p class="live-train__route">Lahore → Karachi</p></div>' +
          '<span class="status status--ok"><span class="live"></span>On the way</span></div>' +
        '</article></div>' +
        '<div class="timeline" style="margin-top:16px">' + steps.map(function (s) {
          return '<div class="tl-item' + (s[3] === 1 ? ' is-done' : s[3] === 2 ? ' is-now' : '') + '">' +
            '<span class="tl-time num">' + esc(s[0]) + '</span>' +
            '<span class="tl-line"><span class="tl-node"></span></span>' +
            '<span class="tl-card"><span class="tl-card__body">' +
            '<span class="tl-card__title">' + esc(s[1]) + '</span>' +
            '<span class="tl-card__meta">' + esc(s[2]) + '</span></span></span></div>';
        }).join('') + '</div>' +
        '<div class="tactions">' +
          '<button class="btn btn--ghost pressable" data-tool-act="add">Track another</button>' +
          '<button class="btn btn--accent pressable" data-tool-act="notify">Alert me on change</button>' +
        '</div>' +
        '<p class="toolnote">Supports TCS, Leopards, PostEx, Trax, CallCourier, BlueEx and Daewoo FastEx.</p>';
      current.actions = {
        add: function () { ctx.prompt({ title: 'Track a parcel', label: 'Tracking number', onOk: function (v) { if (v) ctx.toast('Tracking ' + v); } }); },
        notify: function () { ctx.requestNotify(f); }
      };
    },

    weather: function (f, spec, host) {
      host.innerHTML = skeleton(3);
      setTimeout(function () {
        if (!current || current.id !== f.id) return;
        var w = window.LUME.weatherFor(ctx.profile.country, L.country().tz);
        var list = ctx.prayerSet();
        var sunrise = list.filter(function (x) { return x.name === 'Sunrise'; })[0];
        var sunset = list.filter(function (x) { return x.name === 'Maghrib'; })[0];
        var hours = [0, 3, 6, 9, 12, 15, 18, 21];
        var now = new Date().getHours();
        var days = ['Tomorrow', 'Wed', 'Thu', 'Fri', 'Sat'];

        host.innerHTML =
          '<div class="row-gap"><article class="card weather">' +
            '<span class="weather__icon"><svg class="ico" viewBox="0 0 24 24" style="width:40px;height:40px">' +
            '<use href="#' + w.icon + '"/></svg></span>' +
            '<div><p class="weather__temp num">' + esc(L.temp(w.temp)).replace('°', '<sup>°</sup>') + '</p>' +
            '<p class="weather__desc">' + esc(w.desc) + ' · ' + esc(L.temp(w.feels)) + '</p></div>' +
            '<div class="weather__grid">' +
              '<span class="weather__stat"><svg class="ico" viewBox="0 0 24 24"><use href="#i-droplet"/></svg> <b>' +
                esc(L.num(w.rain / 100, { style: 'percent' })) + '</b></span>' +
              '<span class="weather__stat"><svg class="ico" viewBox="0 0 24 24"><use href="#i-wind"/></svg> <b>' +
                esc(L.speed(w.wind)) + '</b></span>' +
              '<span class="weather__stat"><svg class="ico" viewBox="0 0 24 24"><use href="#i-moon"/></svg> <b class="num">' +
                esc(ctx.hhmm(sunset || list[4])) + '</b></span>' +
            '</div></article></div>' +
          '<p class="group-label" style="padding:0 var(--pad);margin:20px 0 9px">Next 24 hours</p>' +
          '<div class="hscroll">' + hours.map(function (h) {
            var hh = (now + h) % 24;
            var swing = Math.round(Math.sin((hh - 6) / 24 * Math.PI * 2) * 4);
            return '<div class="hourcell"><span class="hourcell__t num">' + esc(L.time(hh, 0)) + '</span>' +
              '<svg class="ico" viewBox="0 0 24 24"><use href="#' + (hh > 6 && hh < 19 ? w.icon : 'i-moon') + '"/></svg>' +
              '<span class="hourcell__v num">' + esc(L.temp(w.temp + swing)) + '</span></div>';
          }).join('') + '</div>' +
          '<p class="group-label" style="padding:0 var(--pad);margin:20px 0 9px">Five days</p>' +
          '<div class="row-gap"><div class="list">' + days.map(function (d, i) {
            var hi = w.temp + (i % 3) - 1, lo = hi - 8;
            return '<div class="list-row"><span class="list-row__icon">' +
              '<svg class="ico" viewBox="0 0 24 24"><use href="#' + w.icon + '"/></svg></span>' +
              '<span class="list-row__body"><span class="list-row__title">' + esc(d) + '</span>' +
              '<span class="list-row__sub">' + esc(w.desc.split(' · ')[0]) + '</span></span>' +
              '<span class="list-row__end"><span class="list-row__value num">' + esc(L.temp(hi)) +
              '</span><span class="delta">' + esc(L.temp(lo)) + '</span></span></div>';
          }).join('') + '</div></div>' +
          '<p class="group-label" style="padding:0 var(--pad);margin:20px 0 9px">Air quality</p>' +
          '<div class="row-gap"><article class="card card--pad">' +
            '<p class="progress-card__title">Moderate · AQI 84</p>' +
            '<p class="progress-card__meta">Fine for most people. Sensitive groups may want to limit long spells outdoors.</p>' +
            '<span class="bar" style="margin-top:10px"><span class="bar__fill" data-fill="42"></span></span>' +
          '</article></div>' +
          '<p class="toolnote">Sunrise ' + esc(ctx.hhmm(sunrise || list[1])) + '. Forecast for ' +
          esc(ctx.profile.city) + ', in ' + (L.unitSystem() === 'imperial' ? 'Fahrenheit' : 'Celsius') + '.</p>';
        ctx.animateBars(host);
        setStatus(spec, 'live');
      }, 560);
      current.actions = {
        reload: function () { open(f.id, { keepReturn: 1 }); }
      };
    },

    news: function (f, spec, host) {
      host.innerHTML = skeleton(3);
      setTimeout(function () {
        if (!current || current.id !== f.id) return;
        var items = ctx.profile.country === 'PK' ? window.LUME.NEWS.PK : window.LUME.NEWS.GLOBAL;
        host.innerHTML = '<div class="row-gap"><div class="list">' + items.map(function (a) {
          return '<button class="list-row pressable" data-tool-act="story">' +
            '<span class="list-row__body"><span class="article__cat">' + esc(a.cat) + '</span>' +
            '<span class="list-row__title" style="margin-top:4px">' + esc(a.title) + '</span>' +
            '<span class="list-row__sub">' + esc(a.meta) + '</span></span>' +
            '<span class="list-row__end"><svg class="ico" viewBox="0 0 24 24"><use href="#i-chev-r"/></svg></span></button>';
        }).join('') + '</div></div>' +
        '<div class="tactions"><button class="btn btn--ghost pressable" data-tool-act="reload">' +
        '<svg class="ico" viewBox="0 0 24 24"><use href="#i-refresh"/></svg>' + esc(t('a.refresh')) + '</button></div>';
        setStatus(spec, 'live');
      }, 520);
      current.actions = {
        story: function () { ctx.toast('Opening the story'); },
        reload: function () { open(f.id, { keepReturn: 1 }); }
      };
    },

    mosques: function (f, spec, host) {
      host.innerHTML =
        '<div class="row-gap"><div class="list">' +
          [['Masjid-e-Tooba', 'Jamaat for Asr at 16:15', 0.65],
           ['Jamia Masjid Al-Falah', 'Jamaat for Asr at 16:30', 1.2],
           ['Bilal Masjid', 'Jamaat for Asr at 16:20', 1.8]].map(function (m) {
            return '<button class="list-row pressable" data-tool-act="map">' +
              '<span class="list-row__icon"><svg class="ico" viewBox="0 0 24 24"><use href="#i-mosque"/></svg></span>' +
              '<span class="list-row__body"><span class="list-row__title">' + esc(m[0]) + '</span>' +
              '<span class="list-row__sub">' + esc(m[1]) + '</span></span>' +
              '<span class="list-row__end"><span class="list-row__value num">' + esc(L.distance(m[2])) + '</span>' +
              '<svg class="ico" viewBox="0 0 24 24"><use href="#i-chev-r"/></svg></span></button>';
          }).join('') + '</div></div>' +
        '<p class="toolnote">Distances are from ' + esc(ctx.profile.city) + '. Lume does not ask for GPS to show this.</p>';
      current.actions = { map: function () { ctx.toast('Opening in maps — you will come straight back'); } };
    }
  };

  var SHAPES = {
    calculator: viewCalculator, data: viewData, list: viewList,
    tracker: viewTracker, reader: viewReader, scanner: viewScanner, timer: viewTimer
  };

  /* ---------------------------------------------------------
     Related tools — only genuine neighbours, never filler
     --------------------------------------------------------- */
  function relatedHtml(spec) {
    var ids = (spec.related || []).filter(function (id) {
      var f = ctx.feature(id);
      return f && ctx.visible(f);
    });
    if (!ids.length) return '';
    return '<p class="group-label" style="padding:0 var(--pad);margin:26px 0 9px">Next</p>' +
      '<div class="hscroll">' + ids.map(function (id) {
        var f = ctx.feature(id);
        return '<button class="recent pressable" data-tool-open="' + id + '">' +
          '<span class="recent__icon"><svg class="ico" viewBox="0 0 24 24"><use href="#' + f.i + '"/></svg></span>' +
          '<span class="recent__label">' + esc(ctx.fname(f)) + '</span></button>';
      }).join('') + '</div>';
  }

  /* ---------------------------------------------------------
     Open / close
     --------------------------------------------------------- */
  function setStatus(spec, state) {
    var el = $('#toolStatus');
    if (el) el.innerHTML = statusBar(spec, state);
  }

  function open(id, opts) {
    opts = opts || {};
    var f = ctx.feature(id);
    if (!f) { ctx.toast('That tool does not exist'); return; }
    var spec = SPEC.specFor(f);

    if (current && current.cleanup) current.cleanup();
    if (!opts.keepReturn) returnTo = ctx.currentTab();
    current = { id: id, feature: f, spec: spec, actions: {}, forceState: opts.state || null };

    ctx.showToolScreen();
    $('#toolTitle').textContent = ctx.fname(f);
    $('#toolSub').textContent = spec.intro && spec.shape !== 'calculator' ? spec.intro : (f.m || '');
    var shareBtn = $('#toolShare');
    if (shareBtn) shareBtn.hidden = !spec.canShare;

    setStatus(spec, 'live');

    var host = $('#toolBody');
    host.innerHTML = '';
    host.removeAttribute('data-draft-shown');

    var g = gate(f, spec);
    if (g) {
      /* A gated screen offers nothing to share or configure yet. */
      current.state = g.kind;
      if (shareBtn) shareBtn.hidden = true;
      $('#toolStatus').innerHTML = '';
      host.innerHTML = g.html;
      $('#toolRelated').innerHTML = '';
      ctx.noteRecent(id);
      setHash(id);
      return;
    }

    (BESPOKE[id] || SHAPES[spec.shape] || function (ff, ss, hh) {
      hh.innerHTML = stateBlock({
        title: ctx.fname(ff),
        text: 'This tool has no journey defined yet. That is a gap in the design, not a silent failure.',
        actions: [{ label: t('a.back'), act: 'back', primary: 1 }]
      });
    })(f, spec, host);

    $('#toolRelated').innerHTML = relatedHtml(spec);
    ctx.noteRecent(id);
    setHash(id);
  }

  function back() {
    if (current && current.cleanup) current.cleanup();
    current = null;
    clearHash();
    ctx.goTo(returnTo);
  }

  /* ---- deep links: #/tool/<id>, optionally !state for reviewing a state ---- */
  function setHash(id) {
    try { history.replaceState(null, '', '#/tool/' + id); } catch (e) {}
  }
  function clearHash() {
    try { history.replaceState(null, '', location.pathname + location.search); } catch (e) {}
  }
  function fromHash() {
    var m = /^#\/tool\/([a-z0-9]+)(?:!([a-z]+))?/.exec(location.hash || '');
    if (!m) return false;
    var f = ctx.feature(m[1]);
    if (!f) return false;
    /* A deep link into a hidden tool must land on the explanation, not the
       tool — route-level gating is the backstop for links. */
    open(m[1], { state: m[2] || null });
    return true;
  }

  /* ---------------------------------------------------------
     Delegated actions
     --------------------------------------------------------- */
  document.addEventListener('click', function (e) {
    var openBtn = e.target.closest('[data-tool-open]');
    if (openBtn) { open(openBtn.dataset.toolOpen); return; }

    var act = e.target.closest('[data-tool-act]');
    if (!act || !current) return;
    var name = act.dataset.toolAct;

    if (name === 'back') { back(); return; }
    if (name === 'reload') { open(current.id, { keepReturn: 1 }); return; }
    if (name === 'personalise') { ctx.sheetOpen('personalise'); return; }
    if (name === 'settings') { ctx.toast('Opening your device settings'); return; }
    if (name === 'signin') {
      /* Intent is preserved: sign in, come back to the exact tool. */
      var want = current.id;
      ctx.signIn(function () { open(want, { keepReturn: 1 }); });
      return;
    }
    if (name.indexOf('perm:') === 0) {
      var perm = name.slice(5);
      ctx.askPermission(perm, function (granted) {
        if (granted) open(current.id, { keepReturn: 1 });
        else open(current.id, { keepReturn: 1 });
      });
      return;
    }
    if (current.actions && current.actions[name]) current.actions[name]();
  });

  document.addEventListener('click', function (e) {
    if (e.target.closest('[data-tool-city]')) ctx.sheetOpen('personalise');
  });

  return { open: open, back: back, fromHash: fromHash, currentId: function () { return current && current.id; } };
};
