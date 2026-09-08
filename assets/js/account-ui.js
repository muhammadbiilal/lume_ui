/* ============================================================
   Lume — account, profile and settings surfaces  (Spec §124)

   The engine in account.js answers what Lume knows. This turns
   those answers into screens — including the answer "nothing",
   which has a designed shape here rather than a plausible
   stand-in (§125).

   Nothing in this file is a tool: it never enters the
   catalogue, search, Quick Actions or the tool router.
   ============================================================ */
window.LUME_ACCOUNT_UI = function (deps) {
  'use strict';

  var t = deps.t, L = deps.L, UI = deps.UI, ACCT = deps.account, NOTIFY = deps.notify;
  var esc = UI.esc;
  var ico = UI.ico;
  var profile = deps.profile;

  /* ---------------------------------------------------------
     Small components (§124.30)
     --------------------------------------------------------- */

  /* The settings row standard: icon, title, description, value, chevron.
     It is the existing list row — a settings screen does not get its own
     visual language (§119). */
  function srow(o) {
    var end = '';
    if (o.toggle !== undefined) {
      end = '<span class="switch' + (o.toggle ? ' is-on' : '') + '"><i class="switch__knob"></i></span>';
    } else {
      end = (o.value ? '<span class="srow__value">' + esc(o.value) + '</span>' : '') +
        (o.chevron === false ? '' : ico('i-chev-r'));
    }
    var attrs = o.act ? ' data-act="' + esc(o.act) + '"' : '';
    var tag = o.act ? 'button' : 'div';
    return '<' + tag + ' class="list-row' + (o.act ? ' pressable' : '') + (o.cls ? ' ' + o.cls : '') + '"' + attrs + '>' +
      (o.icon ? '<span class="list-row__icon"' +
        (o.tone === 'accent' ? ' style="background:var(--tint-accent);color:var(--accent)"' : '') +
        '>' + ico(o.icon) + '</span>' : '') +
      '<span class="list-row__body">' +
        '<span class="list-row__title">' + esc(o.title) + '</span>' +
        (o.sub ? '<span class="list-row__sub list-row__sub--wrap">' + esc(o.sub) + '</span>' : '') +
      '</span>' +
      '<span class="list-row__end">' + end + '</span>' +
    '</' + tag + '>';
  }

  function group(o) {
    return UI.section({
      id: o.id,
      body: '<p class="group-label" style="padding:0;margin:0 0 9px">' + esc(o.label) + '</p>' +
        '<div class="list">' + o.rows.join('') + '</div>'
    });
  }

  /* A choice, with the current state visible without opening anything. */
  function optrow(o) {
    return '<button class="optrow pressable' + (o.on ? ' is-on' : '') + '"' +
      ' role="radio" aria-checked="' + (o.on ? 'true' : 'false') + '"' +
      (o.act ? ' data-act="' + esc(o.act) + '"' : '') + '>' +
      '<span class="optrow__body">' +
        '<span class="optrow__title">' + esc(o.title) + '</span>' +
        (o.sub ? '<span class="optrow__sub">' + esc(o.sub) + '</span>' : '') +
      '</span>' +
      '<span class="optrow__mark">' + ico('i-check') + '</span>' +
    '</button>';
  }

  function optlist(o) {
    return '<div class="list" role="radiogroup" aria-label="' + esc(o.label) + '">' +
      o.items.map(optrow).join('') + '</div>';
  }

  /* ---------------------------------------------------------
     Forms
     --------------------------------------------------------- */
  var form = { values: {}, errors: {}, message: null, busy: false, base: {}, dirty: false };

  function resetForm(values) {
    form.values = values || {};
    form.base = JSON.parse(JSON.stringify(form.values));
    form.errors = {};
    form.message = null;
    form.busy = false;
    form.dirty = false;
  }

  function val(name) { return form.values[name] === undefined ? '' : form.values[name]; }

  function afield(o) {
    var err = form.errors[o.name];
    return '<label class="field field--wide' + (err ? ' is-invalid' : '') + '">' +
      '<span class="field__label">' + esc(o.label) +
        (o.optional ? ' <i style="text-transform:none;font-style:normal;font-weight:600">· ' +
          esc(t('a.optional')) + '</i>' : '') + '</span>' +
      '<span class="field__box">' +
        (o.icon ? '<i class="field__affix">' + ico(o.icon) + '</i>' : '') +
        '<input type="' + esc(o.type || 'text') + '" data-afield="' + esc(o.name) + '"' +
          ' value="' + esc(val(o.name)) + '"' +
          (o.placeholder ? ' placeholder="' + esc(o.placeholder) + '"' : '') +
          (o.autocomplete ? ' autocomplete="' + esc(o.autocomplete) + '"' : '') +
          (o.inputmode ? ' inputmode="' + esc(o.inputmode) + '"' : '') +
          (o.maxlength ? ' maxlength="' + esc(o.maxlength) + '"' : '') +
          (err ? ' aria-invalid="true"' : '') + '>' +
        (o.reveal ? '<button type="button" class="pwtoggle" data-pwtoggle="' + esc(o.name) + '"' +
          ' aria-label="' + esc(t('acct.pw.show')) + '">' + ico('i-eye') + '</button>' : '') +
      '</span>' +
      (err ? '<span class="field__err" role="alert">' + ico('i-alert') + esc(t(err)) + '</span>'
           : (o.hint ? '<span class="field__hint">' + esc(o.hint) + '</span>' : '')) +
    '</label>';
  }

  /* The checklist the screen shows is the rule the engine enforces — one
     array, read twice (§124.9). */
  function pwrules(name) {
    var checks = ACCT.passwordChecks(val(name));
    return '<div class="pwrules" data-pwrules="' + esc(name) + '">' +
      '<p class="pwrules__title">' + esc(t('acct.pw.title')) + '</p>' +
      checks.map(function (c) {
        return '<span class="pwrule' + (c.ok ? ' is-ok' : '') + '" data-rule="' + esc(c.id) + '">' +
          '<i class="pwrule__mark">' + ico('i-check') + '</i>' + esc(t(c.key)) + '</span>';
      }).join('') +
    '</div>';
  }

  function pwmeter(name) {
    var s = ACCT.passwordStrength(val(name));
    var segs = '';
    for (var i = 1; i <= 4; i++) segs += '<i class="pwmeter__seg' + (i <= s.score ? ' is-on' : '') + '"></i>';
    return '<div class="pwmeter" data-pwmeter="' + esc(name) + '" data-tone="' + esc(s.tone) + '">' +
      '<span class="pwmeter__track">' + segs + '</span>' +
      '<span class="pwmeter__label">' + esc(t(s.key)) + '</span>' +
    '</div>';
  }

  function formError() {
    if (!form.message || form.message.tone !== 'error') return '';
    return '<div class="formerr" role="alert">' + ico('i-alert') + '<span>' + esc(t(form.message.key)) + '</span></div>';
  }

  function formNote() {
    if (!form.message || form.message.tone === 'error') return '';
    return '<div class="formok" role="status">' + ico(form.message.icon || 'i-info') +
      '<span>' + esc(form.message.text || t(form.message.key)) + '</span></div>';
  }

  function submitButton(o) {
    return '<button class="btn btn--accent btn--block pressable' + (form.busy ? ' is-busy' : '') + '"' +
      ' data-act="' + esc(o.act) + '"' + (o.disabled ? ' disabled' : '') + '>' +
      (form.busy ? '<i class="btn__spin"></i>' + esc(t(o.busyLabel || 'auth.working')) : esc(o.label)) +
    '</button>';
  }

  /* ---------------------------------------------------------
     Identity  (§124.3, §124.14)
     --------------------------------------------------------- */

  /* A photo, or initials from a real name, or a neutral glyph. Never an
     invented set of letters. */
  function avatar(cls) {
    var photo = ACCT.photo();
    var inits = ACCT.initials();
    if (photo) {
      return '<span class="pavatar ' + (cls || '') + '"><img src="' + esc(photo) + '" alt=""></span>';
    }
    if (inits) return '<span class="pavatar ' + (cls || '') + '">' + esc(inits) + '</span>';
    return '<span class="pavatar pavatar--anon ' + (cls || '') + '" aria-hidden="true">' + ico('i-user') + '</span>';
  }

  var HEAD_ART =
    '<div class="phead__art" aria-hidden="true"><svg viewBox="0 0 350 150" preserveAspectRatio="xMidYMid slice">' +
      '<circle cx="322" cy="12" r="58" fill="var(--accent)" opacity=".07"/>' +
      '<circle cx="26" cy="140" r="42" fill="var(--violet)" opacity=".06"/>' +
      '<path d="m286 30 2.4 5.8 5.8 2.4-5.8 2.4-2.4 5.8-2.4-5.8-5.8-2.4 5.8-2.4z" fill="var(--accent)" opacity=".22"/>' +
    '</svg></div>';

  function identitySection() {
    var authed = ACCT.isAuthed();
    var expired = ACCT.isExpired();
    var stale = expired ? ACCT.pendingUser() : null;
    var name = authed ? ACCT.fullName() : null;
    var mail = ACCT.email();

    var lines;
    if (authed) {
      /* With no name, the address is the identity — there is nothing to
         invent and nothing to apologise for. */
      lines = '<p class="phead__name">' + esc(name || mail) + '</p>' +
        (name && mail ? '<p class="phead__mail">' + esc(mail) + '</p>' : '');
    } else if (expired) {
      /* §124.2 lists four states, and this is the third. It used to render
         as the second: the returning holder's own name sitting above "you're
         using Lume as a guest". */
      lines = '<p class="phead__name">' + esc(t('auth.expiredTitle')) + '</p>' +
        '<p class="phead__mail">' + esc(stale ? t('acct.signedInAs', { email: stale.email })
                                              : t('auth.expiredText')) + '</p>';
    } else {
      /* A guest may still have named this device in onboarding. */
      lines = '<p class="phead__name">' + esc(ACCT.displayName() || t('acct.guestTitle')) + '</p>' +
        '<p class="phead__mail">' + esc(t('acct.guestText')) + '</p>';
    }

    var meta = [];
    if (authed) {
      var since = ACCT.memberSince();
      if (since) {
        meta.push('<span class="tag tag--neutral">' + ico('i-star') + ' ' +
          esc(t('acct.memberSince', { date: L.dateLong(new Date(since)) })) + '</span>');
      }
      var u = ACCT.user();
      if (u && u.status && u.status !== 'active') {
        meta.push(UI.statusBadge({ label: t('acct.statusLocked'), tone: 'late' }));
      }
    } else if (expired) {
      meta.push(UI.statusBadge({ label: t('auth.expiredTitle'), tone: 'warn' }));
    } else {
      meta.push('<span class="tag tag--neutral">' + esc(t('acct.guestBadge')) + '</span>');
    }

    var acts = authed
      ? '<button class="btn btn--ghost pressable" data-act="acct:edit">' + ico('i-user') +
          esc(t('acct.editProfile')) + '</button>'
      : expired
      ? '<button class="btn btn--accent pressable" data-act="auth:signin">' + ico('i-login') +
          esc(t('auth.expiredCta')) + '</button>'
      : '<button class="btn btn--accent pressable" data-act="auth:signup">' + ico('i-user') +
          esc(t('acct.create')) + '</button>' +
        '<button class="btn btn--ghost pressable" data-act="auth:signin">' + ico('i-login') +
          esc(t('acct.signIn')) + '</button>';

    var why = (authed || expired) ? '' :
      '<div class="guestwhy">' +
        '<p class="guestwhy__title">' + esc(t('acct.guestWhy')) + '</p>' +
        '<ul>' +
          ['acct.guestWhy1', 'acct.guestWhy2', 'acct.guestWhy3'].map(function (k) {
            return '<li>' + ico('i-check') + '<span>' + esc(t(k)) + '</span></li>';
          }).join('') +
        '</ul>' +
      '</div>';

    /* §124.47 — an incomplete profile is invited to complete itself, never
       forced to. */
    var complete = (authed && !ACCT.fullName())
      ? UI.section({ tight: true, body: UI.noteCard({
          icon: 'i-sparkles', tone: 'info',
          title: t('acct.completeTitle'), text: t('acct.completeText') }) +
          '<div class="btnrow" style="margin-top:10px">' +
          UI.button({ label: t('acct.completeCta'), tone: 'ghost', act: 'acct:edit', icon: 'i-user' }) +
          '</div>' })
      : '';

    return '<section class="sect sect--flush" data-sect="identity">' +
      '<div class="phead">' + HEAD_ART +
        '<div class="phead__id">' + avatar() + '<div>' + lines + '</div>' +
          (meta.length ? '<div class="phead__meta">' + meta.join('') + '</div>' : '') +
        '</div>' +
        why +
        '<div class="phead__acts">' + acts + '</div>' +
      '</div>' + complete +
    '</section>';
  }

  /* ---------------------------------------------------------
     Profile — the approved composition (§124.7, §123)
     identity → lume → account → support
     --------------------------------------------------------- */
  function regionValue() {
    return [L.countryName(profile().country), profile().city].filter(Boolean).join(' · ') +
      ' · ' + L.currencyCode();
  }

  function themeMode() {
    var stored = deps.storedTheme();
    return stored === 'light' || stored === 'dark' ? stored : 'system';
  }

  function themeLabel() {
    var m = themeMode();
    return t(m === 'light' ? 'acct.appearanceLight'
      : m === 'dark' ? 'acct.appearanceDark' : 'acct.appearanceSystem');
  }

  function notifValue() {
    var p = NOTIFY.prefs();
    var on = NOTIFY.CATEGORIES.filter(function (c) { return p.cats[c.id] !== false; }).length;
    return t('acct.catsOn', { n: L.num(on), total: L.num(NOTIFY.CATEGORIES.length) });
  }

  function renderProfile() {
    var authed = ACCT.isAuthed();

    var lume = group({
      id: 'lume', label: t('acct.yourLume'), rows: [
        srow({ icon: 'i-sliders', tone: 'accent', title: t('acct.row.preferences'),
               sub: t('acct.row.preferencesSub'), act: 'acct:prefs' }),
        srow({ icon: 'i-bell-ring', title: t('acct.row.notifications'),
               sub: t('acct.row.notificationsSub'), value: notifValue(), act: 'acct:notifications' }),
        srow({ icon: themeMode() === 'dark' ? 'i-moon' : 'i-sun', title: t('acct.row.appearance'),
               sub: t('acct.row.appearanceSub'), value: themeLabel(), act: 'acct:appearance' }),
        srow({ icon: 'i-globe', title: t('acct.row.language'),
               sub: t('acct.languageNote'), value: L.languageName(L.lang()) || L.lang(),
               act: 'acct:language' }),
        srow({ icon: 'i-pin', title: t('acct.row.region'),
               sub: t('acct.row.regionSub'), value: regionValue(), act: 'acct:region' }),
        srow({ icon: 'i-sparkles', title: t('acct.row.interests'),
               sub: t('acct.row.interestsSub'), value: L.num(profile().interests.length),
               act: 'sheet:personalise' }),
        srow({ icon: 'i-bookmark', title: t('acct.row.library'),
               sub: t('acct.row.librarySub'), value: L.num(deps.favourites().length),
               act: 'acct:library' })
      ]
    });

    var expired = ACCT.isExpired();
    var accountRows = authed
      ? [
          srow({ icon: 'i-user', tone: 'accent', title: t('acct.row.personal'),
                 sub: t('acct.row.personalSub'), act: 'acct:account' }),
          srow({ icon: 'i-shield', title: t('acct.row.security'),
                 sub: t('acct.row.securitySub'), act: 'acct:security' }),
          srow({ icon: 'i-lock', title: t('acct.row.privacy'),
                 sub: t('acct.row.privacySub'), act: 'acct:privacy' }),
          srow({ icon: 'i-cloud', title: t('acct.row.sync'),
                 sub: t('acct.row.syncSub'), act: 'acct:sync' })
        ]
      : [
          expired
            ? srow({ icon: 'i-login', tone: 'accent', title: t('auth.expiredCta'),
                     sub: t('auth.expiredText'), act: 'auth:signin' })
            : srow({ icon: 'i-user', tone: 'accent', title: t('acct.create'),
                     sub: t('acct.guestWhy1'), act: 'auth:signup' }),
          expired
            ? srow({ icon: 'i-user', title: t('acct.create'), sub: t('acct.guestWhy1'),
                     act: 'auth:signup' })
            : srow({ icon: 'i-login', title: t('acct.signIn'),
                     sub: t('auth.signInText'), act: 'auth:signin' }),
          srow({ icon: 'i-lock', title: t('acct.row.privacy'),
                 sub: t('acct.row.privacySub'), act: 'acct:privacy' }),
          srow({ icon: 'i-cloud', title: t('acct.row.sync'),
                 sub: t('acct.row.syncSub'), act: 'acct:sync' })
        ];

    var support = group({
      id: 'support', label: t('acct.support'), rows: [
        srow({ icon: 'i-help', title: t('acct.row.help'), sub: t('acct.row.helpSub'), act: 'acct:help' }),
        srow({ icon: 'i-info', title: t('acct.row.about'), sub: t('acct.row.aboutSub'), act: 'acct:about' }),
        srow({ icon: 'i-sparkles', title: t('acct.row.tour'), sub: t('acct.row.tourSub'),
               act: 'acctdo:tour' })
      ]
    });

    var session = authed
      ? '<section class="sect" data-sect="session"><div class="list">' +
          srow({ icon: 'i-logout', title: t('acct.signOut'),
                 sub: t('acct.signedInAs', { email: ACCT.email() }), act: 'acctdo:logout' }) +
        '</div></section>'
      : '';

    return identitySection() + lume +
      group({ id: 'account', label: t('acct.account'), rows: accountRows }) +
      support + session +
      '<p class="meta" style="text-align:center;margin-top:22px">Lume · ' +
        esc(t('acct.version')) + ' ' + esc(deps.version) + '</p>';
  }

  /* ---------------------------------------------------------
     Account routes  (§124.31)
     --------------------------------------------------------- */
  var ROUTES = {};

  ROUTES.prefs = function () {
    var p = profile();
    return {
      title: t('acct.prefsTitle'),
      body: UI.section({ body: '<div class="list">' + [
        srow({ icon: 'i-globe', title: t('acct.languageTitle'),
               value: L.languageName(L.lang()) || L.lang(), act: 'acct:language' }),
        srow({ icon: 'i-pin', title: t('acct.regionTitle'), value: regionValue(), act: 'acct:region' }),
        srow({ icon: 'i-currency', title: t('acct.currencyTitle'),
               value: p.currency === 'auto' ? t('pers.currencyAuto', { code: L.currencyCode() }) : p.currency,
               act: 'acct:currency' }),
        srow({ icon: 'i-ruler', title: t('acct.unitsTitle'),
               value: t(p.units === 'auto' ? 'pers.unitsAuto'
                 : p.units === 'imperial' ? 'pers.unitsImperial' : 'pers.unitsMetric'),
               act: 'acct:units' }),
        srow({ icon: 'i-clock', title: t('acct.timezoneTitle'),
               value: p.clock === 'auto' ? t('pers.unitsAuto')
                 : t(p.clock === '12' ? 'pers.time12' : 'pers.time24'),
               act: 'acct:time' }),
        srow({ icon: themeMode() === 'dark' ? 'i-moon' : 'i-sun', title: t('acct.appearanceTitle'),
               value: themeLabel(), act: 'acct:appearance' }),
        srow({ icon: 'i-bell-ring', title: t('acct.row.notifications'),
               value: notifValue(), act: 'acct:notifications' })
      ].join('') + '</div>' })
    };
  };

  ROUTES.language = function () {
    var cur = L.lang();
    return {
      title: t('acct.languageTitle'),
      sub: t('acct.languageNote'),
      body: UI.section({ body: optlist({
        label: t('acct.languageTitle'),
        items: deps.langs().map(function (l) {
          return { title: l.native, sub: l.code === 'en' ? 'English' : null,
                   on: l.code === cur, act: 'acctset:lang:' + l.code };
        })
      }) }) +
      UI.section({ tight: true, body: UI.noteCard({
        icon: 'i-info', tone: 'info', title: t('acct.languageTitle'), text: t('acct.languageNote') }) })
    };
  };

  ROUTES.region = function () {
    return {
      title: t('acct.regionTitle'),
      sub: regionValue(),
      /* §124.17 — say what will change before it changes. */
      body: UI.section({ body: UI.noteCard({
        icon: 'i-alert', tone: 'warn', title: t('acct.regionTitle'), text: t('acct.regionWarn') }) }) +
        UI.section({ tight: true, body: '<div class="list">' + [
          srow({ icon: 'i-globe', title: t('pers.country'), value: L.countryName(profile().country),
                 act: 'sheet:personalise' }),
          srow({ icon: 'i-pin', title: t('pers.city'), value: profile().city, act: 'sheet:personalise' }),
          srow({ icon: 'i-currency', title: t('acct.currencyTitle'), value: L.currencyCode(),
                 act: 'acct:currency' })
        ].join('') + '</div>' }) +
        UI.section({ tight: true, body: '<div class="btnrow">' +
          UI.button({ label: t('acct.regionChange'), tone: 'accent', icon: 'i-globe',
                      act: 'sheet:personalise' }) + '</div>' })
    };
  };

  ROUTES.currency = function () {
    var p = profile();
    var home = (deps.geo.get(p.country) || {}).currency;
    var codes = ['auto', home, 'USD', 'EUR', 'GBP', 'AED', 'SAR', 'INR', 'JPY']
      .filter(function (c, i, a) { return c && a.indexOf(c) === i; });
    return {
      title: t('acct.currencyTitle'),
      sub: t('acct.currencyNote'),
      body: UI.section({ body: optlist({
        label: t('acct.currencyTitle'),
        items: codes.map(function (c) {
          return {
            title: c === 'auto' ? t('acct.currencyAuto') : c,
            sub: c === 'auto' ? t('pers.currencyAuto', { code: home || '' }) : null,
            on: p.currency === c, act: 'acctset:currency:' + c
          };
        })
      }) })
    };
  };

  ROUTES.units = function () {
    var p = profile();
    return {
      title: t('acct.unitsTitle'),
      body: UI.section({ body: optlist({
        label: t('acct.unitsTitle'),
        items: [
          { title: t('acct.unitsAuto'), sub: t('pers.unitsAuto'), on: p.units === 'auto', act: 'acctset:units:auto' },
          { title: t('acct.unitsMetric'), sub: 'km · °C · kg', on: p.units === 'metric', act: 'acctset:units:metric' },
          { title: t('acct.unitsImperial'), sub: 'mi · °F · lb', on: p.units === 'imperial', act: 'acctset:units:imperial' }
        ]
      }) })
    };
  };

  ROUTES.time = function () {
    var p = profile();
    return {
      title: t('acct.timezoneTitle'),
      sub: L.timezone(),
      body: UI.section({ body: optlist({
        label: t('acct.timezoneTitle'),
        items: [
          { title: t('acct.timezoneAuto'), on: p.clock === 'auto', act: 'acctset:clock:auto' },
          { title: t('acct.clock12'), on: p.clock === '12', act: 'acctset:clock:12' },
          { title: t('acct.clock24'), on: p.clock === '24', act: 'acctset:clock:24' }
        ]
      }) }) +
      UI.section({ tight: true, body: '<div class="list">' +
        srow({ icon: 'i-globe', title: t('acct.timezoneTitle'), value: L.timezone(), chevron: false }) +
        '</div>' }) +
      UI.section({ tight: true, body: UI.noteCard({
        icon: 'i-info', tone: 'info', title: t('acct.timezoneTitle'), text: t('acct.timezoneNote') }) })
    };
  };

  ROUTES.appearance = function () {
    var m = themeMode();
    return {
      title: t('acct.appearanceTitle'),
      body: UI.section({ body: optlist({
        label: t('acct.appearanceTitle'),
        items: [
          { title: t('acct.appearanceSystem'), on: m === 'system', act: 'acctset:theme:system' },
          { title: t('acct.appearanceLight'), on: m === 'light', act: 'acctset:theme:light' },
          { title: t('acct.appearanceDark'), on: m === 'dark', act: 'acctset:theme:dark' }
        ]
      }) })
    };
  };

  /* One preference store, two doors (§124.18). */
  ROUTES.notifications = function () {
    return {
      title: t('acct.row.notifications'),
      sub: NOTIFY.pushEnabled() ? t('n.push.on') : t('n.push.off'),
      body: '<div class="sect" id="acctNotifPrefs"></div>',
      after: function () { deps.renderNotifPrefs(document.getElementById('acctNotifPrefs')); }
    };
  };

  ROUTES.library = function () {
    var favs = deps.favourites();
    var recents = deps.recents();
    return {
      title: t('acct.row.library'),
      sub: t('acct.row.librarySub'),
      body: (favs.length
        ? UI.section({ title: t('acct.favourites'), body: UI.rows(favs.map(function (f) {
            /* A catalogue record spells these `i` and `c` (§19). Asking for
               `.icon`/`.cat` rendered an unresolved icon and the literal
               string "cat.undefined" — a leaked key on screen (§125). */
            return UI.richRow({ icon: f.i, title: deps.fname(f), sub: t('cat.' + f.c),
                                act: 'tool:' + f.id, chevron: true });
          })) })
        : UI.section({ body: UI.emptyState({ icon: 'i-bookmark', title: t('acct.noFavourites'),
            text: t('acct.noFavouritesText') }) })) +
        (recents.length
          ? UI.section({ title: t('tools.recent'), body: UI.rows(recents.map(function (f) {
              return UI.compactRow({ icon: f.i, label: deps.fname(f), act: 'tool:' + f.id });
            })) })
          : '')
    };
  };

  /* ---- account ------------------------------------------------------- */
  ROUTES.account = function () {
    var u = ACCT.user();
    if (!u) return signedOutRoute(t('acct.personalTitle'));
    var rows = [
      srow({ icon: 'i-user', title: t('acct.f.displayName'), value: u.displayName || t('a.notSet'),
             act: 'acct:edit' }),
      srow({ icon: 'i-mail', title: t('acct.emailTitle'), value: u.email, act: 'acct:email' }),
      srow({ icon: 'i-phone', title: t('acct.phoneTitle'), value: u.phone || t('a.notSet'),
             act: 'acct:phone' }),
      srow({ icon: 'i-pin', title: t('acct.regionTitle'), value: regionValue(), act: 'acct:region' }),
      srow({ icon: 'i-check-circle', title: t('acct.status'),
             value: t(u.status === 'locked' ? 'acct.statusLocked' : 'acct.statusActive'), chevron: false }),
      srow({ icon: 'i-calendar', title: t('acct.since'),
             value: L.dateLong(new Date(u.createdAt)), chevron: false })
    ];
    return {
      title: t('acct.personalTitle'),
      body: UI.section({ body: '<div class="list">' + rows.join('') + '</div>' }) +
        (u.pendingEmail ? UI.section({ tight: true, body: UI.noteCard({
          icon: 'i-mail', tone: 'warn', title: t('acct.emailPending'),
          text: t('acct.emailPendingText', { email: u.pendingEmail }) }) }) : '') +
        /* §124.22 — its own block, its own tone, never adjacent to a
           routine row. */
        '<div class="danger"><p class="danger__label">' + esc(t('acct.dangerZone')) + '</p>' +
          '<div class="danger__card">' +
            '<p class="danger__text">' + esc(t('acct.deleteRowSub')) + '</p>' +
            '<button class="btn btn--dangerghost btn--block pressable" data-act="acct:delete">' +
              ico('i-trash') + esc(t('acct.deleteRow')) + '</button>' +
          '</div></div>'
    };
  };

  ROUTES.edit = function () {
    var u = ACCT.user();
    if (!u) return signedOutRoute(t('acct.editTitle'));
    var photo = u.photo || '';
    return {
      title: t('acct.editTitle'),
      body: UI.section({ body:
        '<div class="kard kard--pad" style="display:flex;align-items:center;gap:14px">' +
          avatar('pavatar--sm') +
          '<div style="flex:1;min-width:0">' +
            '<p style="font-size:13px;font-weight:700">' + esc(t('acct.photo')) + '</p>' +
            '<p class="field__hint">' + esc(t('acct.photoNote')) + '</p>' +
            '<div class="btnrow" style="margin-top:10px">' +
              '<button class="btn btn--ghost btn--sm pressable" data-act="acctdo:photo">' +
                ico('i-camera') + esc(t(photo ? 'acct.photoReplace' : 'acct.photoAdd')) + '</button>' +
              (photo ? '<button class="btn btn--ghost btn--sm pressable" data-act="acctdo:photoclear">' +
                ico('i-trash') + esc(t('acct.photoRemove')) + '</button>' : '') +
            '</div>' +
          '</div>' +
        '</div>' }) +
      UI.section({ tight: true, body:
        formNote() + formError() +
        '<div class="fgrid">' +
          afield({ name: 'displayName', label: t('acct.f.displayName'), autocomplete: 'nickname',
                   maxlength: 40, hint: t('acct.nameNote') }) +
          afield({ name: 'firstName', label: t('acct.f.first'), autocomplete: 'given-name', optional: true }) +
          afield({ name: 'lastName', label: t('acct.f.last'), autocomplete: 'family-name', optional: true }) +
          afield({ name: 'phone', label: t('acct.f.phone'), type: 'tel', autocomplete: 'tel',
                   optional: true, hint: t('acct.phoneNote') }) +
        '</div>' +
        '<div class="btnrow" style="margin-top:18px">' +
          submitButton({ act: 'acctsubmit:edit', label: t('acct.saveChanges'), disabled: !form.dirty }) +
        '</div>' +
        (form.dirty ? '' : '<p class="field__hint" style="text-align:center;margin-top:8px">' +
          esc(t('acct.nothingChanged')) + '</p>') }) +
      UI.section({ tight: true, body: '<div class="list">' +
        srow({ icon: 'i-mail', title: t('acct.emailTitle'), value: u.email, act: 'acct:email' }) +
        '</div>' }),
      values: { displayName: u.displayName || '', firstName: u.firstName || '',
                lastName: u.lastName || '', phone: u.phone || '' }
    };
  };

  ROUTES.email = function () {
    var u = ACCT.user();
    if (!u) return signedOutRoute(t('acct.emailTitle'));
    return {
      title: t('acct.emailTitle'),
      sub: u.email,
      body: UI.section({ body: formNote() + formError() +
        '<div class="list">' +
          srow({ icon: 'i-mail', title: t('acct.emailTitle'), value: u.email, chevron: false }) +
        '</div>' }) +
        (u.pendingEmail
          ? UI.section({ tight: true, body: UI.noteCard({ icon: 'i-mail', tone: 'warn',
              title: t('acct.emailPending'),
              text: t('acct.emailPendingText', { email: u.pendingEmail }) }) +
              '<div class="btnrow" style="margin-top:12px">' +
                UI.button({ label: t('a.verify'), tone: 'accent', icon: 'i-check',
                            act: 'auth:verify' }) +
                UI.button({ label: t('a.cancel'), tone: 'ghost', act: 'acctdo:emailcancel' }) +
              '</div>' })
          : UI.section({ tight: true, body:
              afield({ name: 'email', label: t('acct.f.newEmail'), type: 'email',
                       autocomplete: 'email', inputmode: 'email' }) +
              '<div class="btnrow" style="margin-top:16px">' +
                submitButton({ act: 'acctsubmit:email', label: t('a.change') }) +
              '</div>' })),
      values: { email: '' }
    };
  };

  ROUTES.phone = function () {
    var u = ACCT.user();
    if (!u) return signedOutRoute(t('acct.phoneTitle'));
    /* §124.16 — the placeholder follows the user's country, never +92. */
    var dial = deps.geo.dial(profile().country) || '';
    return {
      title: t('acct.phoneTitle'),
      body: UI.section({ body: formNote() + formError() +
        afield({ name: 'phone', label: t('acct.f.phone'), type: 'tel', autocomplete: 'tel',
                 inputmode: 'tel', placeholder: dial ? dial + ' ' : '', hint: t('acct.phoneNote') }) +
        '<div class="btnrow" style="margin-top:16px">' +
          submitButton({ act: 'acctsubmit:phone', label: t('a.save') }) +
          (u.phone ? UI.button({ label: t('a.remove'), tone: 'ghost', act: 'acctdo:phoneclear' }) : '') +
        '</div>' }),
      values: { phone: u.phone || '' }
    };
  };

  /* ---- security ------------------------------------------------------ */
  ROUTES.security = function () {
    var u = ACCT.user();
    if (!u) return signedOutRoute(t('acct.securityTitle'));
    var n = ACCT.sessions().length;
    return {
      title: t('acct.securityTitle'),
      body: UI.section({ body: '<div class="list">' + [
        srow({ icon: 'i-key', tone: 'accent', title: t('acct.changePassword'),
               sub: t('acct.changePasswordSub'), act: 'acct:password' }),
        srow({ icon: 'i-device', title: t('acct.sessionsTitle'),
               sub: t('acct.sessionsSub', { n: L.num(n) }), act: 'acct:sessions' }),
        srow({ icon: 'i-bell-ring', title: t('acct.securityNotify'),
               sub: t('acct.securityNotifySub'),
               toggle: NOTIFY.prefs().cats.system !== false, act: 'accttoggle:cat:system' })
      ].join('') + '</div>' }) +
      /* §124.13 — only what exists is listed, and what does not exist says
         so rather than pretending. */
      UI.section({ tight: true, body: '<div class="list">' + [
        srow({ icon: 'i-lock', title: t('acct.twoFactor'), sub: t('acct.twoFactorSub'),
               value: t('n.push.off'), chevron: false }),
        srow({ icon: 'i-scan', title: t('acct.biometric'), sub: t('acct.biometricSub'),
               value: t('n.push.off'), chevron: false })
      ].join('') + '</div>' }) +
      UI.section({ tight: true, body: '<div class="btnrow">' +
        UI.button({ label: t('acct.signOutOthers'), tone: 'ghost', icon: 'i-logout',
                    act: 'acctdo:signoutothers' }) + '</div>' })
    };
  };

  ROUTES.password = function () {
    if (!ACCT.isAuthed()) return signedOutRoute(t('acct.changePassword'));
    return {
      title: t('acct.changePassword'),
      body: UI.section({ body: formNote() + formError() +
        afield({ name: 'current', label: t('acct.f.current'), type: 'password',
                 autocomplete: 'current-password', reveal: true }) +
        '<div style="height:14px"></div>' +
        afield({ name: 'password', label: t('acct.f.new'), type: 'password',
                 autocomplete: 'new-password', reveal: true }) +
        pwmeter('password') + pwrules('password') +
        '<div style="height:14px"></div>' +
        afield({ name: 'confirm', label: t('acct.f.confirmNew'), type: 'password',
                 autocomplete: 'new-password', reveal: true }) +
        '<div class="btnrow" style="margin-top:18px">' +
          submitButton({ act: 'acctsubmit:password', label: t('auth.resetCta') }) +
        '</div>' }),
      values: { current: '', password: '', confirm: '' }
    };
  };

  ROUTES.sessions = function () {
    if (!ACCT.isAuthed()) return signedOutRoute(t('acct.sessionsTitle'));
    var list = ACCT.sessions();
    return {
      title: t('acct.sessionsTitle'),
      sub: t('acct.sessionsSub', { n: L.num(list.length) }),
      body: UI.section({ body: '<div class="list">' + list.map(function (s) {
        var when = s.lastSeen ? new Date(s.lastSeen) : null;
        return '<div class="list-row sessrow">' +
          '<span class="list-row__icon">' + ico('i-device') + '</span>' +
          '<span class="list-row__body">' +
            '<span class="list-row__title">' + esc(s.label) +
              (s.current ? ' <i class="sessrow__here">' + esc(t('acct.thisDevice')) + '</i>' : '') + '</span>' +
            '<span class="list-row__sub list-row__sub--wrap">' +
              esc([s.place, when ? t('acct.lastSeen', {
                when: L.dateShort(when) + ' · ' + L.time(when.getHours(), when.getMinutes())
              }) : ''].filter(Boolean).join(' · ')) + '</span>' +
          '</span>' +
          (s.current ? '' : '<button class="sessrow__out pressable" data-act="acctdo:revoke:' +
            esc(s.id) + '">' + esc(t('acct.signOutDevice')) + '</button>') +
        '</div>';
      }).join('') + '</div>' }) +
      (list.length > 1
        ? UI.section({ tight: true, body: '<div class="btnrow">' +
            UI.button({ label: t('acct.signOutOthers'), tone: 'ghost', icon: 'i-logout',
                        act: 'acctdo:signoutothers' }) + '</div>' })
        : UI.section({ tight: true, body: UI.noteCard({ icon: 'i-info', tone: 'info',
            title: t('acct.sessionsTitle'), text: t('acct.noOtherDevices') }) }))
    };
  };

  /* ---- privacy, data, help, about ------------------------------------ */
  ROUTES.privacy = function () {
    var p = NOTIFY.prefs();
    return {
      title: t('acct.privacyTitle'),
      body: UI.section({ body: '<div class="list">' + [
        srow({ icon: 'i-eye', title: t('acct.privacyPreview'), sub: t('acct.privacyPreviewSub'),
               toggle: p.preview, act: 'accttoggle:preview' }),
        srow({ icon: 'i-lock', title: t('acct.privacySensitive'), sub: t('acct.privacySensitiveSub'),
               toggle: !p.sensitivePreview, act: 'accttoggle:sensitivePreview' }),
        srow({ icon: 'i-sparkles', title: t('acct.privacyPersonal'), sub: t('acct.privacyPersonalSub'),
               toggle: profile().prefs.recos !== false, act: 'accttoggle:recos' })
      ].join('') + '</div>' }) +
      UI.section({ tight: true, body: UI.noteCard({ icon: 'i-shield', tone: 'info',
        title: t('acct.privacyAnalytics'), text: t('acct.privacyAnalyticsSub') }) }) +
      UI.section({ tight: true, body: '<div class="list">' +
        srow({ icon: 'i-cloud', title: t('acct.syncTitle'), sub: t('acct.row.syncSub'), act: 'acct:sync' }) +
        '</div>' })
    };
  };

  ROUTES.sync = function () {
    var s = ACCT.storage();
    return {
      title: t('acct.syncTitle'),
      body: UI.section({ body:
        '<div class="storegroup"><p class="storegroup__label">' + ico('i-device') +
          esc(t('acct.syncDevice')) + '</p>' +
          '<div class="list">' + s.device.map(function (d) {
            return srow({ icon: 'i-check', title: t(d.key), chevron: false });
          }).join('') + '</div></div>' }) +
      UI.section({ tight: true, body:
        '<div class="storegroup"><p class="storegroup__label">' + ico('i-cloud') +
          esc(t('acct.syncSynced')) + '</p>' +
          (s.synced.length
            ? '<div class="list">' + s.synced.map(function (d) {
                return srow({ icon: 'i-cloud', title: t(d.key), chevron: false });
              }).join('') + '</div>'
            : UI.emptyState({ icon: 'i-cloud', title: t('acct.syncSynced'), text: t('acct.syncNone') })) +
        '</div>' })
    };
  };

  ROUTES.help = function () {
    return {
      title: t('acct.helpTitle'),
      body: UI.section({ body: UI.noteCard({ icon: 'i-help', tone: 'info',
        title: t('acct.helpTitle'), text: t('acct.helpText') }) }) +
      UI.section({ tight: true, body: '<div class="list">' + [
        srow({ icon: 'i-sparkles', title: t('acct.helpTour'), act: 'acctdo:tour' }),
        srow({ icon: 'i-message', title: t('acct.helpContact'), act: 'acctdo:feedback' }),
        srow({ icon: 'i-shield', title: t('acct.privacyTitle'), act: 'acct:privacy' })
      ].join('') + '</div>' })
    };
  };

  ROUTES.about = function () {
    return {
      title: t('acct.aboutTitle'),
      body: UI.section({ body:
        '<div class="kard kard--pad" style="text-align:center">' +
          '<span class="auth__mark" style="margin:0 auto 12px">' + ico('i-lume') + '</span>' +
          '<p style="font-size:17px;font-weight:800;letter-spacing:-.03em">Lume</p>' +
          '<p class="field__hint" style="margin-top:6px">' + esc(t('acct.aboutText')) + '</p>' +
        '</div>' }) +
      UI.section({ tight: true, body: '<div class="list">' + [
        srow({ icon: 'i-info', title: t('acct.version'), value: deps.version, chevron: false }),
        srow({ icon: 'i-globe', title: t('acct.languageTitle'),
               value: L.languageName(L.lang()) || L.lang(), chevron: false }),
        srow({ icon: 'i-pin', title: t('acct.regionTitle'), value: regionValue(), chevron: false })
      ].join('') + '</div>' })
    };
  };

  /* ---- deletion (§124.22) -------------------------------------------- */
  ROUTES.delete = function () {
    if (!ACCT.isAuthed()) return signedOutRoute(t('acct.deleteTitle'));
    return {
      title: t('acct.deleteTitle'),
      body: UI.section({ body:
        '<div class="danger__card">' +
          '<p class="storegroup__label" style="margin-bottom:10px">' + ico('i-alert') +
            esc(t('acct.deleteWhat')) + '</p>' +
          '<ul class="conseq conseq--lose">' +
            ['acct.deleteW1', 'acct.deleteW2', 'acct.deleteW3'].map(function (k) {
              return '<li>' + ico('i-x') + '<span>' + esc(t(k)) + '</span></li>';
            }).join('') +
          '</ul>' +
        '</div>' }) +
      UI.section({ tight: true, body:
        '<p class="storegroup__label">' + ico('i-check') + esc(t('acct.deleteKeeps')) + '</p>' +
        '<ul class="conseq conseq--keep"><li>' + ico('i-check') + '<span>' +
          esc(t('acct.deleteK1')) + '</span></li></ul>' }) +
      UI.section({ tight: true, body: formError() +
        '<p class="fieldlabel">' + esc(t('acct.deleteConfirmTitle')) + '</p>' +
        '<p class="field__hint" style="margin-bottom:10px">' + esc(t('acct.deleteConfirmText')) + '</p>' +
        afield({ name: 'current', label: t('acct.f.password'), type: 'password',
                 autocomplete: 'current-password', reveal: true }) +
        '<div class="btnrow" style="margin-top:18px">' +
          '<button class="btn btn--danger btn--block pressable' + (form.busy ? ' is-busy' : '') + '"' +
            ' data-act="acctsubmit:delete">' + ico('i-trash') + esc(t('acct.deleteCta')) + '</button>' +
        '</div>' }),
      values: { current: '' }
    };
  };

  function signedOutRoute(title) {
    return {
      title: title,
      body: UI.section({ body: UI.emptyState({
        icon: 'i-lock', title: t('auth.needAccount'), text: t('acct.err.signedOut'),
        action: { label: t('acct.signIn'), act: 'auth:signin', icon: 'i-login' } }) })
    };
  }

  /* ---------------------------------------------------------
     Authentication routes  (§124.8 – §124.12, §124.26)
     --------------------------------------------------------- */
  var AUTH = {};
  var authCtx = { pending: null, modal: false, token: null, email: '' };

  function authTop() {
    /* §124.25 — back within the flow. A cross only where the flow was put in
       front of something the user was already doing. */
    return '<div class="auth__top">' +
      (authCtx.modal
        ? '<div class="auth__spacer"></div><button class="iconbtn pressable" data-act="acctdo:authclose"' +
          ' aria-label="' + esc(t('a.close')) + '">' + ico('i-x') + '</button>'
        : '<button class="iconbtn iconbtn--back pressable" data-tool-back aria-label="' +
          esc(t('a11y.back')) + '">' + ico('i-chev-l') + '</button>') +
    '</div>';
  }

  function authBrand() {
    return '<div class="auth__brand">' +
      '<span class="auth__mark">' + ico('i-lume') + '</span>' +
      '<span class="auth__word">Lume<span>' + esc(t('app.tagline')) + '</span></span>' +
    '</div>';
  }

  function authHead(title, text) {
    return '<h1 class="auth__title">' + esc(title) + '</h1>' +
      (text ? '<p class="auth__text">' + esc(text) + '</p>' : '');
  }

  AUTH.signin = function () {
    return authTop() + authBrand() +
      authHead(t('auth.signInTitle'), t('auth.signInText')) +
      (authCtx.pending
        ? '<div class="formok" role="status" style="margin-top:16px">' + ico('i-lock') +
          '<span>' + esc(t('auth.needAccountText')) + '</span></div>'
        : '') +
      '<div class="auth__form">' +
        formError() +
        afield({ name: 'email', label: t('acct.f.email'), type: 'email', inputmode: 'email',
                 autocomplete: 'email' }) +
        afield({ name: 'password', label: t('acct.f.password'), type: 'password',
                 autocomplete: 'current-password', reveal: true }) +
        '<button class="auth__inline pressable" data-act="auth:forgot">' + esc(t('auth.forgot')) + '</button>' +
      '</div>' +
      '<div class="auth__foot">' +
        submitButton({ act: 'acctsubmit:signin', label: t('acct.signIn'), busyLabel: 'auth.signingIn' }) +
        (authCtx.modal
          ? '<div class="auth__or">' + esc(t('a.or') === 'a.or' ? 'or' : t('a.or')) + '</div>' +
            '<button class="btn btn--ghost btn--block pressable" data-act="acctdo:authclose">' +
              esc(t('auth.continueAsGuest')) + '</button>'
          : '') +
        '<button class="auth__link pressable" data-act="auth:signup">' +
          esc(t('auth.noAccount')) + ' <b>' + esc(t('auth.createOne')) + '</b></button>' +
      '</div>';
  };

  AUTH.signup = function () {
    return authTop() + authBrand() +
      authHead(t('auth.signUpTitle'), t('auth.signUpText')) +
      '<div class="auth__form">' +
        formError() +
        afield({ name: 'name', label: t('acct.f.name'), autocomplete: 'name', optional: true,
                 maxlength: 40 }) +
        afield({ name: 'email', label: t('acct.f.email'), type: 'email', inputmode: 'email',
                 autocomplete: 'email' }) +
        afield({ name: 'password', label: t('acct.f.password'), type: 'password',
                 autocomplete: 'new-password', reveal: true }) +
        pwmeter('password') + pwrules('password') +
        afield({ name: 'confirm', label: t('acct.f.confirm'), type: 'password',
                 autocomplete: 'new-password', reveal: true }) +
      '</div>' +
      '<div class="auth__foot">' +
        submitButton({ act: 'acctsubmit:signup', label: t('acct.create'), busyLabel: 'auth.creating' }) +
        '<button class="auth__link pressable" data-act="auth:signin">' +
          esc(t('auth.haveAccount')) + ' <b>' + esc(t('acct.signIn')) + '</b></button>' +
      '</div>';
  };

  AUTH.forgot = function () {
    return authTop() + authBrand() +
      authHead(t('auth.forgotTitle'), t('auth.forgotText')) +
      '<div class="auth__form">' +
        formError() +
        afield({ name: 'email', label: t('acct.f.email'), type: 'email', inputmode: 'email',
                 autocomplete: 'email' }) +
      '</div>' +
      '<div class="auth__foot">' +
        submitButton({ act: 'acctsubmit:forgot', label: t('auth.forgotCta') }) +
        '<button class="auth__link pressable" data-act="auth:signin">' +
          esc(t('auth.backToSignIn')) + '</button>' +
      '</div>';
  };

  /* The neutral confirmation: identical whether or not the address exists. */
  AUTH.sent = function () {
    return authTop() +
      '<div class="auth__art">' + sealArt('i-mail') + '</div>' +
      authHead(t('auth.sentTitle'), t('auth.sentText')) +
      '<p class="auth__text" style="font-size:12.5px;color:var(--text-3);margin-top:10px">' +
        esc(t('auth.sentNote')) + '</p>' +
      '<div class="auth__grow"></div>' +
      '<div class="auth__foot">' +
        (authCtx.token
          ? '<button class="btn btn--accent btn--block pressable" data-act="auth:reset">' +
            esc(t('auth.openLink')) + '</button>'
          : '') +
        '<button class="auth__link pressable" data-act="auth:signin">' +
          esc(t('auth.backToSignIn')) + '</button>' +
        '<p class="auth__link auth__link--quiet">' + esc(t('auth.sentLocal')) + '</p>' +
      '</div>';
  };

  AUTH.reset = function () {
    return authTop() + authBrand() +
      authHead(t('auth.resetTitle'), t('auth.resetText')) +
      '<div class="auth__form">' +
        formError() +
        afield({ name: 'password', label: t('acct.f.new'), type: 'password',
                 autocomplete: 'new-password', reveal: true }) +
        pwmeter('password') + pwrules('password') +
        afield({ name: 'confirm', label: t('acct.f.confirm'), type: 'password',
                 autocomplete: 'new-password', reveal: true }) +
      '</div>' +
      '<div class="auth__foot">' +
        submitButton({ act: 'acctsubmit:reset', label: t('auth.resetCta') }) +
      '</div>';
  };

  AUTH.updated = function () {
    return authTop() +
      '<div class="auth__art">' + sealArt('i-check') + '</div>' +
      authHead(t('auth.updatedTitle'), t('auth.updatedText')) +
      '<div class="auth__grow"></div>' +
      '<div class="auth__foot">' +
        '<button class="btn btn--accent btn--block pressable" data-act="auth:signin">' +
          esc(t('acct.signIn')) + '</button>' +
      '</div>';
  };

  AUTH.expired = function () {
    var u = ACCT.pendingUser();
    return '<div class="auth__top"></div>' +
      '<div class="auth__art">' + sealArt('i-clock') + '</div>' +
      authHead(t('auth.expiredTitle'), t('auth.expiredText')) +
      (u ? '<p class="auth__text" style="margin-top:8px">' +
        esc(t('acct.signedInAs', { email: u.email })) + '</p>' : '') +
      '<div class="auth__grow"></div>' +
      '<div class="auth__foot">' +
        '<button class="btn btn--accent btn--block pressable" data-act="auth:signin">' +
          esc(t('auth.expiredCta')) + '</button>' +
        '<button class="auth__link pressable" data-act="acctdo:authclose">' +
          esc(t('auth.continueAsGuest')) + '</button>' +
      '</div>';
  };

  AUTH.verify = function () {
    var u = ACCT.user();
    var target = u && u.pendingEmail ? u.pendingEmail : '';
    return authTop() +
      '<div class="auth__art">' + sealArt('i-mail') + '</div>' +
      authHead(t('auth.verifyTitle'), t('auth.verifyText', { email: target })) +
      '<div class="auth__form">' +
        formError() +
        afield({ name: 'code', label: t('acct.f.code'), inputmode: 'numeric', maxlength: 6 }) +
        (u && u.pendingCode
          ? '<p class="field__hint">' + esc(t('auth.verifyLocal', { code: u.pendingCode })) + '</p>'
          : '') +
      '</div>' +
      '<div class="auth__foot">' +
        submitButton({ act: 'acctsubmit:verify', label: t('auth.verifyCta') }) +
        '<button class="auth__link pressable" data-act="acctdo:emailcancel">' +
          esc(t('a.cancel')) + '</button>' +
      '</div>';
  };

  function sealArt(icon) {
    return '<svg viewBox="0 0 240 150" fill="none" aria-hidden="true">' +
      '<circle cx="120" cy="72" r="58" fill="var(--accent)" opacity=".07"/>' +
      '<circle cx="120" cy="72" r="38" fill="var(--tint-accent)"/>' +
      '<g transform="translate(102 54) scale(1.5)" stroke="var(--accent)" stroke-width="1.6"' +
        ' fill="none" stroke-linecap="round" stroke-linejoin="round">' +
        '<use href="#' + esc(icon) + '" width="24" height="24"/></g>' +
      '<path d="m40 34 2.4 5.8 5.8 2.4-5.8 2.4L40 50l-2.4-5.8-5.8-2.4 5.8-2.4z" fill="var(--accent)" opacity=".5"/>' +
      '<circle cx="196" cy="46" r="4.5" fill="var(--violet)" opacity=".45"/>' +
      '<circle cx="188" cy="112" r="3.5" fill="var(--sky)" opacity=".45"/>' +
    '</svg>';
  }

  return {
    ROUTES: ROUTES, AUTH: AUTH, form: form, authCtx: authCtx,
    resetForm: resetForm, renderProfile: renderProfile, avatar: avatar,
    srow: srow, pwrules: pwrules, pwmeter: pwmeter, signedOutRoute: signedOutRoute
  };
};
