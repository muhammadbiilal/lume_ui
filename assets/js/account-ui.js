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
    var role = '';
    if (o.toggle !== undefined) {
      end = '<span class="switch' + (o.toggle ? ' is-on' : '') + '"><i class="switch__knob"></i></span>';
      /* A row that toggles announces itself as a switch and says which way
         it is set. Without this it read as "Notification previews, button"
         with no state at all (§101). */
      role = ' role="switch" aria-checked="' + (o.toggle ? 'true' : 'false') + '"';
    } else {
      /* An empty string is a value the product holds and knows to be empty;
         undefined is a value it does not have. They are not the same, and
         the row for the first should say so rather than showing a bare
         title (§125). */
      var shown = o.value === '' ? t('a.notSet') : o.value;
      end = (shown !== undefined && shown !== null ? '<span class="srow__value">' + esc(shown) + '</span>' : '') +
        (o.chevron === false ? '' : ico('i-chev-r'));
    }
    var attrs = (o.act ? ' data-act="' + esc(o.act) + '"' : '') + role;
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
    /* Roving tab stop: the group is one stop, and the arrows move within it.
       Declaring role="radio" without this promised a keyboard contract the
       screen did not honour (§101). */
    return '<button class="optrow pressable' + (o.on ? ' is-on' : '') + '"' +
      ' role="radio" aria-checked="' + (o.on ? 'true' : 'false') + '"' +
      ' tabindex="' + (o.on ? '0' : '-1') + '"' +
      (o.act ? ' data-act="' + esc(o.act) + '"' : '') + '>' +
      '<span class="optrow__body">' +
        '<span class="optrow__title">' + esc(o.title) + '</span>' +
        (o.sub ? '<span class="optrow__sub">' + esc(o.sub) + '</span>' : '') +
      '</span>' +
      '<span class="optrow__mark">' + ico('i-check') + '</span>' +
    '</button>';
  }

  function optlist(o) {
    /* If nothing is selected the first option carries the tab stop, so the
       group is always reachable. */
    var items = o.items.slice();
    if (!items.some(function (i) { return i.on; }) && items.length) {
      items[0] = Object.keys(items[0]).reduce(function (acc, k) { acc[k] = items[0][k]; return acc; }, {});
      items[0].tabbable = true;
    }
    return '<div class="list optlist" role="radiogroup" aria-label="' + esc(o.label) + '">' +
      items.map(function (i) {
        var html = optrow(i);
        return i.tabbable ? html.replace('tabindex="-1"', 'tabindex="0"') : html;
      }).join('') + '</div>';
  }

  /* ---------------------------------------------------------
     Forms
     --------------------------------------------------------- */
  var form = { values: {}, errors: {}, valid: {}, touched: {},
               message: null, busy: false, base: {}, dirty: false };

  /* Which password fields the user has chosen to show. Kept here rather than
     in the DOM because every submission repaints the form, and a revealed
     password used to re-mask itself the moment a submission failed — exactly
     when the user most wants to read what they typed. */
  var revealed = {};

  function setRevealed(name, on) { revealed[name] = !!on; }

  function resetForm(values) {
    revealed = {};
    form.values = values || {};
    form.base = JSON.parse(JSON.stringify(form.values));
    form.errors = {};
    /* §126.39 — nothing is judged before the user has touched it. `valid`
       only ever fills in after a field has been left. */
    form.valid = {};
    form.touched = {};
    form.message = null;
    form.busy = false;
    form.dirty = false;
  }

  function val(name) { return form.values[name] === undefined ? '' : form.values[name]; }

  /* §126.14, §126.15 — every input carries all six states, and the line that
     explains it is always in the layout even when it has nothing to say, so
     an error appearing never moves the button the user is reaching for
     (§126.39). */
  function afield(o) {
    var err = form.errors[o.name];
    var filled = String(val(o.name)) !== '';
    var good = !err && !!form.valid[o.name];
    var msgId = 'fm-' + o.name;
    return '<label class="field field--wide' + (err ? ' is-invalid' : '') +
        (good ? ' is-valid' : '') + (filled ? ' is-filled' : '') +
        '" data-field="' + esc(o.name) + '">' +
      '<span class="field__label">' + esc(o.label) +
        (o.optional ? ' <i style="text-transform:none;font-style:normal;font-weight:600">· ' +
          esc(t('a.optional')) + '</i>' : '') + '</span>' +
      '<span class="field__box">' +
        (o.icon ? '<i class="field__affix">' + ico(o.icon) + '</i>' : '') +
        '<input type="' + esc(revealed[o.name] ? 'text' : (o.type || 'text')) + '" data-afield="' + esc(o.name) + '"' +
          ' value="' + esc(val(o.name)) + '"' +
          (o.placeholder ? ' placeholder="' + esc(o.placeholder) + '"' : '') +
          (o.autocomplete ? ' autocomplete="' + esc(o.autocomplete) + '"' : '') +
          (o.inputmode ? ' inputmode="' + esc(o.inputmode) + '"' : '') +
          (o.maxlength ? ' maxlength="' + esc(o.maxlength) + '"' : '') +
          ' aria-describedby="' + msgId + '"' +
          (err ? ' aria-invalid="true"' : '') + '>' +
        /* The tick is a second signal beside the border colour, so a valid
           field does not read by colour alone (§126.15). */
        (good && !o.reveal ? '<span class="field__ok" aria-hidden="true">' + ico('i-check') + '</span>' : '') +
        (o.reveal ? '<button type="button" class="pwtoggle" data-pwtoggle="' + esc(o.name) + '"' +
          ' aria-pressed="' + (revealed[o.name] ? 'true' : 'false') + '"' +
          ' aria-label="' + esc(t(revealed[o.name] ? 'acct.pw.hide' : 'acct.pw.show')) + '">' +
          ico(revealed[o.name] ? 'i-eye-off' : 'i-eye') + '</button>' : '') +
      '</span>' +
      '<span class="field__msg ' + (err ? 'field__err' : 'field__hint') + '" id="' + msgId + '"' +
        (err ? ' role="alert"' : '') + '>' +
        (err ? ico('i-alert') + esc(t(err)) : (o.hint ? esc(o.hint) : '')) +
      '</span>' +
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
        /* A membership date needs the year: dateLong is weekday/day/month,
           so an account created in 2024 read exactly like one created today. */
        meta.push('<span class="tag tag--neutral">' + ico('i-star') + ' ' +
          esc(t('acct.memberSince', { date: L.date(new Date(since),
            { day: 'numeric', month: 'long', year: 'numeric' }) })) + '</span>');
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

    /* §124.14 — an incomplete profile is invited to complete itself, never
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
        /* A guest has a name too, and §124.4 said it could be changed. */
        (authed ? '' : srow({ icon: 'i-user', title: t('acct.f.displayName'),
                              sub: t('acct.nameNote'),
                              value: ACCT.displayName() || '', act: 'acct:edit' })),
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
          srow({ icon: 'i-pin', title: t('pers.city'), value: profile().city || '',
                 act: 'sheet:personalise' }),
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
            sub: c === 'auto' ? t('pers.currencyAuto', { code: home || L.currencyCode() }) : null,
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

  /* The zones Lume's own location database knows, narrowed to the user's
     part of the world. A list of every zone on earth would be a search
     problem; this is the set that is actually reachable from here. */
  function zonesNear(country) {
    var home = (deps.geo.get(country) || {}).tz || 'UTC';
    var area = home.split('/')[0];
    var seen = {}, out = [];
    deps.geo.COUNTRIES.forEach(function (c) {
      if (!c.tz || seen[c.tz]) return;
      if (c.tz.split('/')[0] !== area) return;
      seen[c.tz] = 1;
      out.push(c.tz);
    });
    out.sort();
    return out;
  }

  ROUTES.time = function () {
    var p = profile();
    var home = (deps.geo.get(p.country) || {}).tz || 'UTC';
    var zones = zonesNear(p.country);
    return {
      title: t('acct.timeTitle'),
      sub: L.timezone(),
      body: UI.section({ title: t('acct.clockFormat'), body: optlist({
        label: t('acct.clockFormat'),
        items: [
          { title: t('acct.timezoneAuto'), on: p.clock === 'auto', act: 'acctset:clock:auto' },
          { title: t('acct.clock12'), on: p.clock === '12', act: 'acctset:clock:12' },
          { title: t('acct.clock24'), on: p.clock === '24', act: 'acctset:clock:24' }
        ]
      }) }) +
      UI.section({ title: t('acct.timezoneTitle'), body: optlist({
        label: t('acct.timezoneTitle'),
        items: [{ title: t('acct.timezoneFollowRegion'), sub: home, on: !p.tz,
                  act: 'acctset:tz:auto' }].concat(zones.map(function (z) {
          return { title: z.split('/').slice(1).join(' · ').replace(/_/g, ' '),
                   sub: z, on: p.tz === z, act: 'acctset:tz:' + z };
        }))
      }) }) +
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
             value: L.date(new Date(u.createdAt),
               { day: 'numeric', month: 'long', year: 'numeric' }), chevron: false })
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

  /* §124.4 promised the onboarding name could be changed later, and the only
     screen that changes it required an account — so a guest who gave a name
     could never edit or remove it. The form is the same; a guest simply has
     fewer fields, because a guest has fewer things. */
  ROUTES.edit = function () {
    var u = ACCT.user();
    var guest = !u;
    var photo = (u ? u.photo : profile().photo) || '';
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
          (guest ? '' :
            afield({ name: 'firstName', label: t('acct.f.first'), autocomplete: 'given-name', optional: true }) +
            afield({ name: 'lastName', label: t('acct.f.last'), autocomplete: 'family-name', optional: true }) +
            afield({ name: 'phone', label: t('acct.f.phone'), type: 'tel', autocomplete: 'tel',
                     optional: true, hint: t('acct.phoneNote') })) +
        '</div>' +
        '<div class="btnrow" style="margin-top:18px">' +
          submitButton({ act: 'acctsubmit:edit', label: t('acct.saveChanges'), disabled: !form.dirty }) +
        '</div>' +
        '<p class="field__hint dirtyhint" style="text-align:center;margin-top:8px"' +
          (form.dirty ? ' hidden' : '') + '>' + esc(t('acct.nothingChanged')) + '</p>' }) +
      UI.section({ tight: true, body: '<div class="list">' +
        (guest ? '' : srow({ icon: 'i-mail', title: t('acct.emailTitle'), value: u.email,
                             act: 'acct:email' })) +
        /* §124.14 — country and region belong on this screen, but they are
           chosen in the location picker rather than typed, so the row leads
           there instead of duplicating it. */
        srow({ icon: 'i-globe', title: t('pers.country'), value: L.countryName(profile().country),
               act: 'acct:region' }) +
        srow({ icon: 'i-pin', title: profile().region ? t('pers.region') : t('pers.city'),
               value: profile().region || profile().city || '', act: 'acct:region' }) +
        '</div>' }) +
      (guest ? UI.section({ tight: true, body: UI.noteCard({ icon: 'i-info', tone: 'info',
        title: t('acct.guestBadge'), text: t('acct.guestEditNote') }) }) : ''),
      values: guest
        ? { displayName: profile().displayName || '' }
        : { displayName: u.displayName || '', firstName: u.firstName || '',
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
        UI.noteCard({ icon: 'i-info', tone: 'info', title: t('acct.phoneScope'),
                      text: t('acct.phoneScopeText') }) +
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
      /* §124.13 — what is here is what exists. There is no two-factor
         switch, no biometric unlock and no sign-in alerting in this build,
         so there are no rows for them: a row reading "Off" for something
         that was never built still advertises it. */
      body: UI.section({ body: '<div class="list">' + [
        srow({ icon: 'i-key', tone: 'accent', title: t('acct.changePassword'),
               sub: t('acct.changePasswordSub'), act: 'acct:password' }),
        srow({ icon: 'i-device', title: t('acct.sessionsTitle'),
               sub: t('acct.sessionsSub', { n: L.num(n) }), act: 'acct:sessions' })
      ].join('') + '</div>' }) +
      UI.section({ tight: true, body: UI.noteCard({ icon: 'i-shield', tone: 'info',
        title: t('acct.securityScope'), text: t('acct.securityScopeText') }) }) +
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
        srow({ icon: 'i-sparkles', title: t('acct.helpTour'), sub: t('acct.row.tourSub'),
               act: 'acctdo:tour' }),
        srow({ icon: 'i-shield', title: t('acct.privacyTitle'), sub: t('acct.row.privacySub'),
               act: 'acct:privacy' }),
        srow({ icon: 'i-cloud', title: t('acct.syncTitle'), sub: t('acct.row.syncSub'),
               act: 'acct:sync' })
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
     Authentication  (§126 — the authentication layout system)

     Every screen below is assembled from the same shell in the
     same order: header → brand → visual → heading → supporting
     text → form → primary action → alternates → footer → legal
     (§126.3, §126.44). A screen that needs less leaves a slot
     empty; none of them reorders the slots.
     --------------------------------------------------------- */
  var AUTH = {};
  var authCtx = { pending: null, modal: false, token: null, email: '',
                  step: 1, resendAt: 0, nav: 'fwd' };

  /* §126.7 fixes where a federated provider sits in the composition — below
     the email action, never above it. The list is empty because Lume
     implements no provider, and a button that opens nothing is exactly the
     claim §125 forbids. Add one here and the divider and the buttons appear
     in their defined place; until then the screen says nothing about it. */
  var PROVIDERS = [];

  /* §126.12 — enough of the address to recognise, not enough to hand it to
     whoever is looking over the shoulder. */
  function maskEmail(mail) {
    var s = String(mail || '');
    var at = s.indexOf('@');
    if (at < 1) return s;
    var head = s.slice(0, at);
    var dots = new Array(Math.min(Math.max(head.length - 1, 1), 5) + 1).join('•');
    return head.charAt(0) + dots + s.slice(at);
  }

  var AMBIENT =
    '<div class="auth__ambient" aria-hidden="true">' +
      '<span class="auth__glow auth__glow--a"></span>' +
      '<span class="auth__glow auth__glow--b"></span>' +
      '<span class="auth__spec auth__spec--a"></span>' +
      '<span class="auth__spec auth__spec--b"></span>' +
      '<span class="auth__spec auth__spec--c"></span>' +
    '</div>';

  /* The desktop visual region (§126.41). It carries atmosphere and one line
     of brand message — never a field, never a control, so nothing is lost
     when the composition collapses back to one column on a phone. */
  var ASIDE_ART =
    '<svg viewBox="0 0 400 500" fill="none" aria-hidden="true" preserveAspectRatio="xMidYMid slice">' +
      '<circle cx="316" cy="96" r="120" fill="var(--accent)" opacity=".10"/>' +
      '<circle cx="86" cy="392" r="96" fill="var(--violet)" opacity=".10"/>' +
      '<path d="M300 300h1" stroke="var(--accent)"/>' +
      '<path d="m132 118 4.4 10.6L147 133l-10.6 4.4L132 148l-4.4-10.6L117 133l10.6-4.4z"' +
        ' fill="var(--accent)" opacity=".42"/>' +
      '<circle cx="330" cy="330" r="7" fill="var(--sky)" opacity=".4"/>' +
      '<circle cx="252" cy="188" r="4.5" fill="var(--violet)" opacity=".45"/>' +
    '</svg>';

  function authAside() {
    return '<aside class="auth__aside" aria-hidden="true">' +
      '<div class="auth__asideart">' + ASIDE_ART + '</div>' +
      '<p class="auth__asidemsg">' + esc(t('auth.asideTitle')) + '</p>' +
      '<p class="auth__asidesub">' + esc(t('auth.asideText')) + '</p>' +
    '</aside>';
  }

  /* §126.4 — back inside a flow, a cross only on a surface that interrupted
     something. They are different controls with different meanings, so they
     are never the same button. */
  function authTop(o) {
    var lead = '', trail = '';
    var modal = authCtx.modal && o.dismissible !== false;
    if (modal) {
      trail = '<button class="auth__nav auth__nav--close pressable" data-act="acctdo:authclose"' +
        ' aria-label="' + esc(t('a.close')) + '">' + ico('i-x') + '</button>';
    }
    /* The two controls do different jobs, so a screen that has a step behind
       it keeps its Back even when the whole flow can also be dismissed —
       otherwise step two of a sign-up reached from a deep link has no way
       home to step one. */
    if (o.back !== false && (!modal || o.backAct)) {
      lead = '<button class="auth__nav auth__nav--back pressable"' +
        (o.backAct ? ' data-act="' + esc(o.backAct) + '"' : ' data-tool-back') +
        ' aria-label="' + esc(t('a11y.back')) + '">' + ico('i-chev-l') + '</button>';
    }
    if (o.stepOf) trail = '<span class="auth__step-of">' + esc(o.stepOf) + '</span>' + trail;
    return '<header class="auth__top" data-slot="top">' + lead + '<div class="auth__spacer"></div>' + trail + '</header>';
  }

  /* §126.5 — the mark, at its own size, in air. */
  function authBrand() {
    return '<div class="auth__brand" data-slot="brand">' +
      '<span class="auth__mark">' + ico('i-lume') + '</span>' +
      '<span class="auth__word">Lume</span>' +
    '</div>';
  }

  /* §126.13, §126.35 — the success visual: ring, disc, drawn check, two
     specks. `calm` and `warn` are the same geometry at lower temperature,
     for the screens that are a status rather than a celebration. */
  function seal(icon, tone) {
    return '<div class="auth__visual auth__visual--seal" data-slot="visual">' +
      '<div class="authseal' + (tone ? ' authseal--' + tone : '') + '">' +
        '<span class="authseal__ring"></span>' +
        '<span class="authseal__disc">' + ico(icon) + '</span>' +
        '<span class="authseal__spark authseal__spark--a">' + ico('i-sparkles') + '</span>' +
        '<span class="authseal__spark authseal__spark--b">' + ico('i-sparkles') + '</span>' +
      '</div>' +
    '</div>';
  }

  function arrow() {
    /* `ico` carries fill:none and stroke:currentColor. Without it the sprite
       falls back to the SVG defaults and the arrow renders as a filled
       black blob. */
    return '<svg class="ico btn__arrow" viewBox="0 0 24 24" aria-hidden="true"><use href="#i-arrow-r"/></svg>';
  }

  /* §126.16, §126.33 — the button keeps its width and its height when it
     starts working. The label changes; the layout does not. */
  function authSubmit(o) {
    return '<button class="btn btn--auth pressable' + (form.busy ? ' is-busy' : '') + '"' +
      ' data-act="' + esc(o.act) + '"' + (o.disabled ? ' disabled' : '') + '>' +
      (form.busy
        ? '<i class="btn__spin"></i><span>' + esc(t(o.busyLabel || 'auth.working')) + '</span>'
        : '<span>' + esc(o.label) + '</span>' + arrow()) +
    '</button>';
  }

  function authLink(o) {
    return '<button class="auth__link pressable" data-act="' + esc(o.act) + '">' +
      esc(o.text) + (o.strong ? '<b>' + esc(o.strong) + '</b>' : '') + '</button>';
  }

  /* Where a provider button would go. Nothing renders while the list is
     empty — including the divider, which would otherwise separate the
     primary action from a blank space. */
  function providerBlock() {
    if (!PROVIDERS.length) return '';
    return '<div class="auth__or">' + esc(t('a.or')) + '</div>' +
      '<div class="auth__alt" data-slot="alt">' + PROVIDERS.map(function (p) {
        return '<button class="btn btn--authsec pressable" data-act="' + esc(p.act) + '">' +
          ico(p.icon) + esc(t('auth.continueWith', { provider: p.name })) + '</button>';
      }).join('') + '</div>';
  }

  function mix(a, b) {
    var out = {}, k;
    for (k in a) if (a.hasOwnProperty(k)) out[k] = a[k];
    for (k in b) if (b.hasOwnProperty(k)) out[k] = b[k];
    return out;
  }

  /* The slots carry their name in the DOM. The order below is the one
     recorded in LUME_SPEC.COMPOSITIONS.auth, and it is asserted rather than
     remembered (§123, §126.3). */
  function authScreen(o) {
    var panel =
      authTop(o) +
      (o.brand === false ? '' : authBrand()) +
      (o.visual || '') +
      '<div class="auth__hero" data-slot="hero">' +
        '<h1 class="auth__title">' + esc(o.title) + '</h1>' +
        (o.text ? '<p class="auth__text">' + (o.html ? o.text : esc(o.text)) + '</p>' : '') +
        (o.note ? '<p class="auth__note">' + esc(o.note) + '</p>' : '') +
      '</div>' +
      (o.steps || '') +
      (o.notice || '') +
      (o.form ? '<div class="auth__form" data-slot="form">' + o.form + '</div>' : '') +
      (o.grow ? '<div class="auth__grow"></div>' : '') +
      (o.actions ? '<div class="auth__actions" data-slot="actions">' + o.actions + '</div>' : '') +
      (o.alt || '') +
      (o.foot ? '<div class="auth__foot" data-slot="foot">' + o.foot + '</div>' : '') +
      (o.legal ? '<p class="auth__legal" data-slot="legal">' + o.legal + '</p>' : '');

    return '<div class="auth' + (o.status ? ' auth--status' : '') + '"' +
      ' data-auth="' + esc(o.id) + '" data-nav="' + esc(authCtx.nav) + '">' +
      AMBIENT + authAside() +
      '<div class="auth__region"><div class="auth__panel">' + panel + '</div></div>' +
    '</div>';
  }

  /* §126.9 — the progress indicator: 4px, 150px, and never the only way to
     know where you are. The count is written out beside it. */
  function authSteps(step, total) {
    var segs = '';
    for (var i = 1; i <= total; i++) {
      segs += '<span class="authsteps__seg' + (i <= step ? ' is-on' : '') + '"><i></i></span>';
    }
    return '<div class="authsteps" aria-hidden="true">' + segs + '</div>';
  }

  /* ---- sign in (§126.7) ---------------------------------------------- */
  AUTH.signin = function () {
    return authScreen({
      id: 'signin',
      title: t('auth.signInTitle'),
      text: t('auth.signInText'),
      notice: authCtx.pending
        ? '<div class="formok" role="status" style="margin-top:18px">' + ico('i-lock') +
          '<span>' + esc(t('auth.needAccountText')) + '</span></div>'
        : '',
      form: formError() +
        afield({ name: 'email', label: t('acct.f.email'), type: 'email', inputmode: 'email',
                 autocomplete: 'email', placeholder: t('auth.emailPh') }) +
        afield({ name: 'password', label: t('acct.f.password'), type: 'password',
                 autocomplete: 'current-password', reveal: true }) +
        '<button class="auth__inline pressable" data-act="auth:forgot">' +
          esc(t('auth.forgot')) + '</button>',
      actions: authSubmit({ act: 'acctsubmit:signin', label: t('acct.signIn'),
                            busyLabel: 'auth.signingIn' }),
      alt: providerBlock(),
      foot: (authCtx.modal
        ? '<button class="btn btn--authsec pressable" data-act="acctdo:authclose">' +
          esc(t('auth.continueAsGuest')) + '</button>'
        : '') +
        authLink({ act: 'auth:signup', text: t('auth.noAccount'), strong: t('auth.createOne') })
    });
  };

  /* ---- sign up (§126.8, §126.9) --------------------------------------
     Two steps rather than one tall form: who you are, then how you get back
     in. §126.46 names the composition "progressive form", and the second
     step is where the password rules have room to be read. */
  AUTH.signup = function () {
    var step = authCtx.step === 2 ? 2 : 1;
    var common = {
      id: 'signup',
      steps: authSteps(step, 2),
      stepOf: t('auth.stepOf', { n: step, total: 2 })
    };

    if (step === 1) {
      return authScreen(mix(common, {
        title: t('auth.signUpTitle'),
        text: t('auth.signUpText'),
        form: formError() +
          afield({ name: 'name', label: t('acct.f.name'), autocomplete: 'name', optional: true,
                   maxlength: 40, hint: t('auth.nameHint') }) +
          afield({ name: 'email', label: t('acct.f.email'), type: 'email', inputmode: 'email',
                   autocomplete: 'email', placeholder: t('auth.emailPh') }),
        actions: authSubmit({ act: 'acctsubmit:signupstep', label: t('auth.continue') }),
        foot: authLink({ act: 'auth:signin', text: t('auth.haveAccount'), strong: t('acct.signIn') })
      }));
    }

    return authScreen(mix(common, {
      backAct: 'acctdo:signupback',
      title: t('auth.signUpPwTitle'),
      text: t('auth.signUpPwText'),
      form: formError() +
        afield({ name: 'password', label: t('acct.f.password'), type: 'password',
                 autocomplete: 'new-password', reveal: true }) +
        pwmeter('password') + pwrules('password') +
        afield({ name: 'confirm', label: t('acct.f.confirm'), type: 'password',
                 autocomplete: 'new-password', reveal: true }),
      actions: authSubmit({ act: 'acctsubmit:signup', label: t('acct.create'),
                            busyLabel: 'auth.creating' }),
      /* §126.40 — the link opens a sheet, not a screen: leaving here would
         take the password the user has just typed with it. */
      legal: esc(t('auth.legal')) + ' ' +
        '<button data-act="sheet:authlegal">' + esc(t('auth.legalLink')) + '</button>'
    }));
  };

  /* ---- recovery (§126.10) -------------------------------------------- */
  AUTH.forgot = function () {
    return authScreen({
      id: 'forgot',
      visual: seal('i-key', 'calm'),
      title: t('auth.forgotTitle'),
      text: t('auth.forgotText'),
      form: formError() +
        afield({ name: 'email', label: t('acct.f.email'), type: 'email', inputmode: 'email',
                 autocomplete: 'email', placeholder: t('auth.emailPh') }),
      actions: authSubmit({ act: 'acctsubmit:forgot', label: t('auth.forgotCta') }),
      foot: authLink({ act: 'auth:signin', text: t('auth.rememberPw'), strong: t('acct.signIn') })
    });
  };

  /* The neutral confirmation: identical whether or not the address exists
     (§124.11). Nothing on this screen differs between the two cases. */
  AUTH.sent = function () {
    return authScreen({
      id: 'sent',
      status: true,
      brand: false,
      visual: seal('i-mail', 'calm'),
      title: t('auth.sentTitle'),
      /* The address the user just typed is deliberately not echoed here.
         §126.12 puts the masked address on the verification screen, where it
         is the account's address and the user may not remember it. Here it
         would only add a string that varies with the input — and this screen
         has to be byte-identical whether or not the account exists
         (§124.11). */
      text: t('auth.sentText'),
      note: t('auth.sentNote'),
      grow: true,
      actions: authCtx.token
        ? '<button class="btn btn--auth pressable" data-act="auth:reset">' +
          '<span>' + esc(t('auth.openLink')) + '</span>' + arrow() + '</button>'
        : '',
      foot: authLink({ act: 'auth:signin', text: t('auth.backToSignIn') }) +
        '<p class="auth__link auth__link--quiet">' + esc(t('auth.sentLocal')) + '</p>'
    });
  };

  /* ---- reset (§126.11) ------------------------------------------------ */
  AUTH.reset = function () {
    return authScreen({
      id: 'reset',
      visual: seal('i-shield', 'calm'),
      title: t('auth.resetTitle'),
      text: t('auth.resetText'),
      form: formError() +
        afield({ name: 'password', label: t('acct.f.new'), type: 'password',
                 autocomplete: 'new-password', reveal: true }) +
        pwmeter('password') + pwrules('password') +
        afield({ name: 'confirm', label: t('acct.f.confirm'), type: 'password',
                 autocomplete: 'new-password', reveal: true }),
      actions: authSubmit({ act: 'acctsubmit:reset', label: t('auth.resetCta') })
    });
  };

  AUTH.updated = function () {
    return authScreen({
      id: 'updated',
      status: true,
      brand: false,
      back: false,
      visual: seal('i-check'),
      title: t('auth.updatedTitle'),
      text: t('auth.updatedText'),
      grow: true,
      actions: '<button class="btn btn--auth pressable" data-act="auth:signin">' +
        '<span>' + esc(t('acct.signIn')) + '</span>' + arrow() + '</button>'
    });
  };

  /* ---- account created (§126.13) -------------------------------------
     The account already exists by the time this renders; the screen is the
     designed arrival, not a step that could fail. */
  AUTH.created = function () {
    var who = ACCT.displayName();
    return authScreen({
      id: 'created',
      status: true,
      brand: false,
      back: false,
      dismissible: false,
      visual: seal('i-check'),
      title: t('auth.createdTitle'),
      text: who ? t('auth.createdTextNamed', { name: who }) : t('auth.createdText'),
      grow: true,
      actions: '<button class="btn btn--auth pressable" data-act="acctdo:authdone">' +
        '<span>' + esc(t('auth.enterCta')) + '</span>' + arrow() + '</button>'
    });
  };

  /* ---- session expired (§126.46) -------------------------------------- */
  AUTH.expired = function () {
    var u = ACCT.pendingUser();
    return authScreen({
      id: 'expired',
      status: true,
      brand: false,
      back: false,
      dismissible: false,
      visual: seal('i-clock', 'warn'),
      title: t('auth.expiredTitle'),
      html: true,
      text: esc(t('auth.expiredText')) +
        (u ? '<br><b>' + esc(maskEmail(u.email)) + '</b>' : ''),
      grow: true,
      actions: '<button class="btn btn--auth pressable" data-act="auth:signin">' +
        '<span>' + esc(t('auth.expiredCta')) + '</span>' + arrow() + '</button>',
      foot: authLink({ act: 'acctdo:authclose', text: t('auth.continueAsGuest') })
    });
  };

  /* ---- authentication error (§126.46) --------------------------------
     A failure the user cannot fix by retyping gets a screen and a way out,
     not a red line above a form that will refuse them again (§126.34). */
  AUTH.trouble = function () {
    return authScreen({
      id: 'trouble',
      status: true,
      brand: false,
      visual: seal('i-alert', 'warn'),
      title: t('auth.troubleTitle'),
      text: authCtx.troubleText ? t(authCtx.troubleText) : t('auth.troubleText'),
      grow: true,
      actions: '<button class="btn btn--auth pressable" data-act="auth:forgot">' +
        '<span>' + esc(t('auth.troubleCta')) + '</span>' + arrow() + '</button>',
      foot: authLink({ act: 'auth:signin', text: t('auth.backToSignIn') })
    });
  };

  /* ---- email verification (§126.12) ----------------------------------- */
  AUTH.verify = function () {
    var u = ACCT.user();
    var target = u && u.pendingEmail ? u.pendingEmail : '';
    var left = Math.max(0, Math.ceil((authCtx.resendAt - Date.now()) / 1000));
    return authScreen({
      id: 'verify',
      status: true,
      brand: false,
      visual: seal('i-mail', 'calm'),
      title: t('auth.verifyTitle'),
      html: true,
      text: esc(t('auth.verifyText')) +
        (target ? '<br><b>' + esc(maskEmail(target)) + '</b>' : ''),
      form: formError() +
        afield({ name: 'code', label: t('acct.f.code'), inputmode: 'numeric', maxlength: 6,
                 autocomplete: 'one-time-code' }) +
        (u && u.pendingCode
          ? '<p class="auth__note">' + esc(t('auth.verifyLocal', { code: u.pendingCode })) + '</p>'
          : ''),
      actions: authSubmit({ act: 'acctsubmit:verify', label: t('auth.verifyCta') }),
      foot: '<p class="auth__link auth__link--quiet">' + esc(t('auth.resendNone')) + '</p>' +
        (left > 0
          ? '<p class="auth__link auth__link--quiet" data-resend role="status">' +
            esc(t('auth.resendIn', { s: left })) + '</p>'
          : authLink({ act: 'acctdo:resend', text: '', strong: t('auth.resend') })) +
        authLink({ act: 'acctdo:emailcancel', text: t('a.cancel') })
    });
  };

  return {
    ROUTES: ROUTES, AUTH: AUTH, form: form, authCtx: authCtx,
    resetForm: resetForm, renderProfile: renderProfile, avatar: avatar,
    setRevealed: setRevealed, revealed: function (n) { return !!revealed[n]; },
    srow: srow, pwrules: pwrules, pwmeter: pwmeter, signedOutRoute: signedOutRoute,
    providers: PROVIDERS, maskEmail: maskEmail, afield: afield
  };
};
