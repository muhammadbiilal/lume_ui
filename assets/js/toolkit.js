/* ============================================================
   Lume — component toolkit  (Master Spec §83, §84, §85, §86)

   One library of composable pieces that every tool screen is
   assembled from. Components return HTML strings so a screen
   builder reads like its own information architecture rather
   than like DOM plumbing.

   The same component adapts to its dataset (§119): a RichRow in
   Markets carries a sparkline and volume, the same row in
   Parcels carries a carrier and an ETA. Consistency without
   making every tool identical.
   ============================================================ */
window.LUME_UI = (function () {
  'use strict';

  function esc(s) {
    return String(s === undefined || s === null ? '' : s).replace(/[&<>"']/g, function (c) {
      return { '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c];
    });
  }

  /* Attribute soup shows up in every component; keep it in one place. */
  function attrs(o) {
    var out = '';
    for (var k in o) {
      if (!Object.prototype.hasOwnProperty.call(o, k)) continue;
      var v = o[k];
      if (v === undefined || v === null || v === false) continue;
      out += ' ' + k + '="' + esc(v === true ? '' : v) + '"';
    }
    return out;
  }

  function ico(name, cls) {
    return '<svg class="' + (cls || 'ico') + '" viewBox="0 0 24 24" aria-hidden="true"><use href="#' + esc(name) + '"/></svg>';
  }

  function cls() {
    var out = [];
    for (var i = 0; i < arguments.length; i++) if (arguments[i]) out.push(arguments[i]);
    return out.join(' ');
  }

  /* An action is the same vocabulary the shell already speaks:
     tool:<id> · sheet:<id> · tab:<id> · toast:<text> · share:<id> */
  function actAttr(act) {
    return act ? ' data-act="' + esc(act) + '"' : '';
  }

  /* ---------------------------------------------------------
     Headers
     --------------------------------------------------------- */

  /* §9 — normal tool screens navigate back. An X is only for a
     surface the user is dismissing, so it never appears here. */
  function toolHeader(o) {
    var right = (o.actions || []).map(function (a) {
      return '<button class="iconbtn pressable"' + actAttr(a.act) +
        attrs({ 'aria-label': a.label, 'data-tool-action': a.id }) + '>' + ico(a.icon) + '</button>';
    }).join('');
    return '<header class="toolbar">' +
      '<button class="iconbtn pressable" data-tool-back aria-label="' + esc(o.backLabel || 'Back') + '">' +
        ico('i-chev-l') + '</button>' +
      '<div class="toolbar__text">' +
        '<h1 class="toolbar__title">' + esc(o.title) + '</h1>' +
        (o.sub ? '<p class="toolbar__sub">' + o.sub + '</p>' : '') +
      '</div>' +
      '<div class="toolbar__actions">' + right + '</div>' +
    '</header>';
  }

  /* Location / account / source strip that sits under the header (§7). */
  function contextBar(items) {
    var body = items.filter(Boolean).map(function (i) {
      if (typeof i === 'string') return '<span class="ctxbar__item">' + i + '</span>';
      return '<' + (i.act ? 'button' : 'span') + ' class="ctxbar__item' + (i.act ? ' pressable' : '') + '"' +
        actAttr(i.act) + '>' +
        (i.icon ? ico(i.icon) : '') + '<span>' + esc(i.label) + '</span>' +
        (i.act ? ico('i-chev-d', 'ico ctxbar__caret') : '') +
        '</' + (i.act ? 'button' : 'span') + '>';
    }).join('<span class="ctxbar__sep"></span>');
    return '<div class="ctxbar">' + body + '</div>';
  }

  function sectionHead(o) {
    if (typeof o === 'string') o = { title: o };
    return '<div class="sect__head">' +
      '<div><h2 class="sect__title">' + esc(o.title) + '</h2>' +
      (o.sub ? '<p class="sect__sub">' + esc(o.sub) + '</p>' : '') + '</div>' +
      (o.link ? '<button class="sect__link pressable"' + actAttr(o.link.act) + '>' + esc(o.link.label) +
        ico('i-chev-r') + '</button>' : '') +
    '</div>';
  }

  function section(o) {
    return '<section class="sect' + (o.tight ? ' sect--tight' : '') + (o.flush ? ' sect--flush' : '') + '"' +
      attrs({ 'data-sect': o.id }) + '>' +
      (o.title ? sectionHead(o) : '') + o.body + '</section>';
  }

  /* ---------------------------------------------------------
     Surfaces
     --------------------------------------------------------- */

  function card(body, o) {
    o = o || {};
    var tag = o.act ? 'button' : 'div';
    return '<' + tag + ' class="' + cls('kard', o.pad !== false && 'kard--pad', o.tone && 'kard--' + o.tone,
      o.act && 'pressable', o.cls) + '"' + actAttr(o.act) + attrs(o.attrs) + '>' + body + '</' + tag + '>';
  }

  /* §85 — a card must carry information, never just a label. */
  function summaryCard(o) {
    var chips = (o.stats || []).map(function (s) {
      return '<div class="summary__stat"><span class="summary__statv">' + s.value + '</span>' +
        '<span class="summary__statl">' + esc(s.label) + '</span></div>';
    }).join('');
    return '<div class="' + cls('summary', o.tone && 'summary--' + o.tone, o.cls) + '">' +
      (o.art || '') +
      '<div class="summary__top">' +
        '<div class="summary__lead">' +
          (o.kicker ? '<p class="summary__kicker">' + esc(o.kicker) + '</p>' : '') +
          '<p class="summary__value">' + o.value + (o.unit ? '<span class="summary__unit">' + esc(o.unit) + '</span>' : '') + '</p>' +
          (o.caption ? '<p class="summary__caption">' + o.caption + '</p>' : '') +
        '</div>' +
        (o.aside ? '<div class="summary__aside">' + o.aside + '</div>' : '') +
      '</div>' +
      (chips ? '<div class="summary__stats">' + chips + '</div>' : '') +
      (o.foot ? '<div class="summary__foot">' + o.foot + '</div>' : '') +
    '</div>';
  }

  function metric(o) {
    return '<' + (o.act ? 'button' : 'div') + ' class="' + cls('metric', o.act && 'pressable', o.cls) + '"' +
      actAttr(o.act) + '>' +
      (o.icon ? '<span class="metric__icon">' + ico(o.icon) + '</span>' : '') +
      '<span class="metric__value">' + o.value + '</span>' +
      '<span class="metric__label">' + esc(o.label) + '</span>' +
      (o.delta ? deltaTag(o.delta) : '') +
    '</' + (o.act ? 'button' : 'div') + '>';
  }

  function metrics(list, columns) {
    return '<div class="metrics" style="--cols:' + (columns || Math.min(list.length, 3)) + '">' +
      list.map(metric).join('') + '</div>';
  }

  /* A signed value with a direction glyph — never colour alone (§101). */
  function deltaTag(d) {
    var dir = d.dir || (d.value > 0 ? 'up' : d.value < 0 ? 'down' : 'flat');
    var sym = dir === 'up' ? '▲' : dir === 'down' ? '▼' : '—';
    return '<span class="delta delta--' + dir + '"><i aria-hidden="true">' + sym + '</i>' + esc(d.text) + '</span>';
  }

  /* ---------------------------------------------------------
     Rows  (§84 rich list row standard)
     --------------------------------------------------------- */

  function rowLead(o) {
    if (o.logo) return '<span class="rrow__logo" style="--logo:' + esc(o.logoTone || 'var(--tint-neutral)') + '">' + esc(o.logo) + '</span>';
    if (o.icon) return '<span class="rrow__icon' + (o.iconTone ? ' rrow__icon--' + o.iconTone : '') + '">' + ico(o.icon) + '</span>';
    if (o.thumb) return '<span class="rrow__thumb">' + o.thumb + '</span>';
    return '';
  }

  /* Rich row: lead · title/ticker · sub · meta line · value stack · trailing viz.
     Everything is optional, so each dataset fills only what it has. */
  function richRow(o) {
    var tag = o.act ? 'button' : 'div';
    return '<' + tag + ' class="' + cls('rrow', o.act && 'pressable', o.cls) + '"' + actAttr(o.act) + attrs(o.attrs) + '>' +
      rowLead(o) +
      '<span class="rrow__body">' +
        '<span class="rrow__titleline">' +
          '<span class="rrow__title">' + esc(o.title) + '</span>' +
          (o.badge ? statusBadge(o.badge) : '') +
        '</span>' +
        (o.sub ? '<span class="rrow__sub">' + esc(o.sub) + '</span>' : '') +
        (o.meta && o.meta.length ? '<span class="rrow__meta">' + o.meta.filter(Boolean).map(function (m) {
          return '<span>' + m + '</span>';
        }).join('<i class="rrow__dot" aria-hidden="true"></i>') + '</span>' : '') +
      '</span>' +
      (o.spark ? '<span class="rrow__spark">' + o.spark + '</span>' : '') +
      (o.value !== undefined || o.delta || o.valueSub ? '<span class="rrow__end">' +
        (o.value !== undefined ? '<span class="rrow__value">' + o.value + '</span>' : '') +
        (o.valueSub ? '<span class="rrow__valuesub">' + o.valueSub + '</span>' : '') +
        (o.delta ? deltaTag(o.delta) : '') +
      '</span>' : '') +
      (o.chevron ? ico('i-chev-r', 'ico rrow__chev') : '') +
    '</' + tag + '>';
  }

  function rows(list, o) {
    o = o || {};
    return '<div class="' + cls('rows', o.flat && 'rows--flat', o.cls) + '">' + list.join('') + '</div>';
  }

  /* Compact row for dense secondary lists. */
  function compactRow(o) {
    var tag = o.act ? 'button' : 'div';
    return '<' + tag + ' class="' + cls('crow', o.act && 'pressable', o.cls) + '"' + actAttr(o.act) + '>' +
      (o.icon ? '<span class="crow__icon">' + ico(o.icon) + '</span>' : '') +
      '<span class="crow__label">' + esc(o.label) + (o.sub ? '<i>' + esc(o.sub) + '</i>' : '') + '</span>' +
      (o.value !== undefined ? '<span class="crow__value">' + o.value + '</span>' : '') +
      (o.act && o.chevron !== false ? ico('i-chev-r', 'ico crow__chev') : '') +
    '</' + tag + '>';
  }

  /* Expandable row — progressive disclosure instead of clutter (§115). */
  function expandRow(o) {
    return '<details class="xrow"' + (o.open ? ' open' : '') + '>' +
      '<summary class="xrow__head">' + o.head + ico('i-chev-d', 'ico xrow__caret') + '</summary>' +
      '<div class="xrow__body">' + o.body + '</div>' +
    '</details>';
  }

  /* ---------------------------------------------------------
     Table (§86) — horizontally scrollable, priority columns
     --------------------------------------------------------- */
  function table(o) {
    var head = '<tr>' + o.cols.map(function (c) {
      return '<th' + attrs({ scope: 'col', class: c.align === 'right' ? 'is-right' : null }) + '>' + esc(c.label) + '</th>';
    }).join('') + '</tr>';
    var body = o.rows.map(function (r) {
      return '<tr' + actAttr(r.act) + (r.act ? ' class="pressable"' : '') + '>' + r.cells.map(function (cell, i) {
        var c = o.cols[i] || {};
        return '<td' + attrs({ class: cls(c.align === 'right' && 'is-right', c.strong && 'is-strong') }) + '>' + cell + '</td>';
      }).join('') + '</tr>';
    }).join('');
    /* Focusable and labelled so a keyboard can scroll a wide table (§86). */
    return '<div class="tablewrap"' + attrs({ 'aria-label': o.label, role: 'region', tabindex: '0' }) +
      '><table class="dtable">' +
      '<thead>' + head + '</thead><tbody>' + body + '</tbody></table></div>';
  }

  /* ---------------------------------------------------------
     Controls
     --------------------------------------------------------- */

  function searchBar(o) {
    o = o || {};
    return '<div class="tsearch"><label class="search">' + ico('i-search') +
      '<input type="search"' + attrs({
        id: o.id, placeholder: o.placeholder || 'Search', value: o.value,
        'data-tool-search': o.target || true, autocomplete: 'off'
      }) + '>' +
    '</label>' + (o.trailing || '') + '</div>';
  }

  function chip(o) {
    return '<button class="' + cls('fchip', o.on && 'is-on', o.cls) + '"' +
      attrs({ 'data-filter': o.group, 'data-value': o.value, 'aria-pressed': o.on ? 'true' : 'false' }) +
      actAttr(o.act) + '>' + (o.icon ? ico(o.icon) : '') + esc(o.label) +
      (o.count !== undefined ? '<i class="fchip__n">' + esc(o.count) + '</i>' : '') + '</button>';
  }

  /* §88 — filters are contextual; a screen passes only what it has. Each
     chip carries the action that writes it back into the tool's state, so a
     filter bar is never decorative (§112). */
  function filterBar(groups, tool) {
    return '<div class="filterbar">' + groups.map(function (g) {
      return '<div class="filterbar__group"' + attrs({ 'data-group': g.id, role: 'group', 'aria-label': g.label }) + '>' +
        g.items.map(function (i) {
          return chip({
            group: g.id, value: i.value, label: i.label, on: i.on, count: i.count, icon: i.icon,
            act: i.act || (tool ? 'toolstate:' + tool + ':' + g.id + ':' + i.value : null)
          });
        }).join('') + '</div>';
    }).join('') + '</div>';
  }

  function segmented(o) {
    return '<div class="segmented" role="group"' + attrs({ 'data-segment': o.id, 'aria-label': o.label }) + '>' +
      o.items.map(function (i) {
        return '<button class="seg' + (i.on ? ' is-on' : '') + '"' +
          attrs({ 'aria-pressed': i.on ? 'true' : 'false', 'data-value': i.value }) +
          actAttr(i.act || (o.tool ? 'toolstate:' + o.tool + ':' + o.id + ':' + i.value : null)) + '>' +
          esc(i.label) + '</button>';
      }).join('') + '</div>';
  }

  /* These re-compose the screen rather than swapping a sibling panel, so
     they are pressed buttons in a named group — not ARIA tabs with no
     tabpanel to point at (§101). */
  function tabs(o) {
    return '<div class="ttabs" role="group"' +
      attrs({ 'data-tabs': o.id, 'aria-label': o.label || o.id }) + '>' +
      o.items.map(function (i) {
        return '<button class="ttab' + (i.on ? ' is-on' : '') + '"' +
          attrs({ 'aria-pressed': i.on ? 'true' : 'false', 'data-value': i.value }) + actAttr(i.act) + '>' +
          esc(i.label) + (i.count !== undefined ? '<i>' + esc(i.count) + '</i>' : '') + '</button>';
      }).join('') + '</div>';
  }

  /* §89 — sorting exposes meaningful dimensions, and tapping one sorts.
     Tapping the active dimension again reverses it. */
  function sortBar(o) {
    return '<div class="sortbar">' +
      '<span class="sortbar__label">' + ico('i-sliders') + esc(o.label || 'Sort') + '</span>' +
      '<div class="sortbar__opts" role="group"' + attrs({ 'aria-label': o.label }) + '>' + o.items.map(function (i) {
        var next = i.on && i.dir === 'desc' ? 'asc' : i.on && i.dir === 'asc' ? 'desc' : (i.dir || 'desc');
        return '<button class="sortopt' + (i.on ? ' is-on' : '') + '"' +
          attrs({
            'data-sort': i.value,
            'aria-pressed': i.on ? 'true' : 'false'
          }) +
          actAttr(o.tool ? 'toolstate:' + o.tool + ':sort:' + i.value + '|' + next : null) + '>' + esc(i.label) +
          (i.on && i.dir ? ico(i.dir === 'asc' ? 'i-arrow-up' : 'i-arrow-down') : '') + '</button>';
      }).join('') + '</div>' +
    '</div>';
  }

  function button(o) {
    return '<button class="' + cls('btn', o.tone ? 'btn--' + o.tone : 'btn--ghost', o.block && 'btn--block',
      o.small && 'btn--sm', o.cls) + '"' + actAttr(o.act) + attrs(o.attrs) + '>' +
      (o.icon ? ico(o.icon) : '') + esc(o.label) + '</button>';
  }

  function buttonRow(list) {
    return '<div class="btnrow">' + list.map(button).join('') + '</div>';
  }

  function field(o) {
    return '<label class="field' + (o.wide ? ' field--wide' : '') + '">' +
      '<span class="field__label">' + esc(o.label) + '</span>' +
      '<span class="field__box">' +
        (o.prefix ? '<i class="field__affix">' + esc(o.prefix) + '</i>' : '') +
        '<input' + attrs({
          type: o.type || 'text', inputmode: o.inputmode || (o.type === 'number' ? 'decimal' : null),
          value: o.value, placeholder: o.placeholder, id: o.id, 'data-input': o.name, step: o.step,
          min: o.min, max: o.max
        }) + '>' +
        (o.suffix ? '<i class="field__affix">' + esc(o.suffix) + '</i>' : '') +
      '</span>' +
      (o.hint ? '<span class="field__hint">' + esc(o.hint) + '</span>' : '') +
    '</label>';
  }

  function selectField(o) {
    return '<label class="field' + (o.wide ? ' field--wide' : '') + '">' +
      '<span class="field__label">' + esc(o.label) + '</span>' +
      '<span class="field__box field__box--select">' +
        '<select' + attrs({ id: o.id, 'data-input': o.name }) + '>' +
          o.options.map(function (op) {
            return '<option' + attrs({ value: op.value, selected: op.value === o.value }) + '>' + esc(op.label) + '</option>';
          }).join('') +
        '</select>' + ico('i-chev-d') +
      '</span>' +
    '</label>';
  }

  function formGrid(fields) {
    return '<div class="fgrid">' + fields.join('') + '</div>';
  }

  function stepper(o) {
    return '<div class="stepper" role="group"' + attrs({ 'aria-label': o.label }) + '>' +
      '<button class="stepper__btn pressable"' +
        attrs({ 'data-step-down': o.name, 'aria-label': (o.less || 'Decrease') + ' ' + o.label }) + '>' +
        ico('i-minus') + '</button>' +
      '<span class="stepper__val" aria-live="polite" data-step-val="' + esc(o.name) + '">' + esc(o.value) + '</span>' +
      '<button class="stepper__btn pressable"' +
        attrs({ 'data-step-up': o.name, 'aria-label': (o.more || 'Increase') + ' ' + o.label }) + '>' +
        ico('i-plus') + '</button>' +
    '</div>';
  }

  /* ---------------------------------------------------------
     Status, freshness and source  (§19, §107, §108)
     --------------------------------------------------------- */

  var BADGE_GLYPH = { live: '●', ok: '✓', warn: '!', late: '▲', off: '—', info: 'i' };

  function statusBadge(b) {
    if (typeof b === 'string') b = { label: b, tone: 'neutral' };
    return '<span class="badge badge--' + esc(b.tone || 'neutral') + '">' +
      (BADGE_GLYPH[b.tone] ? '<i aria-hidden="true">' + BADGE_GLYPH[b.tone] + '</i>' : '') +
      esc(b.label) + '</span>';
  }

  /* Quality is never implied — live, delayed, cached and estimated
     all read differently (§108). */
  function freshness(o) {
    var q = o.quality || 'live';
    return '<span class="fresh fresh--' + esc(q) + '">' +
      '<i class="fresh__dot" aria-hidden="true"></i>' + esc(o.label) + '</span>';
  }

  function sourceLine(o) {
    return '<p class="srcline">' +
      (o.source ? '<span>' + esc(o.source) + '</span>' : '') +
      (o.updated ? '<span>' + esc(o.updated) + '</span>' : '') +
      (o.note ? '<span>' + esc(o.note) + '</span>' : '') +
    '</p>';
  }

  /* ---------------------------------------------------------
     Visualisation  (§18 — every chart answers a question)
     --------------------------------------------------------- */

  function extent(vals) {
    var min = Math.min.apply(null, vals), max = Math.max.apply(null, vals);
    if (min === max) { min -= 1; max += 1; }
    return [min, max];
  }

  function points(vals, w, h, pad) {
    pad = pad === undefined ? 2 : pad;
    var e = extent(vals), min = e[0], span = e[1] - e[0];
    var step = vals.length > 1 ? w / (vals.length - 1) : w;
    return vals.map(function (v, i) {
      return [i * step, pad + (h - pad * 2) * (1 - (v - min) / span)];
    });
  }

  function path(pts) {
    return pts.map(function (p, i) {
      return (i ? 'L' : 'M') + p[0].toFixed(1) + ' ' + p[1].toFixed(1);
    }).join(' ');
  }

  function sparkline(vals, o) {
    o = o || {};
    var w = o.w || 56, h = o.h || 22;
    var pts = points(vals, w, h, 2);
    var up = vals[vals.length - 1] >= vals[0];
    var tone = o.tone || (up ? 'up' : 'down');
    return '<svg class="spark spark--' + tone + '" viewBox="0 0 ' + w + ' ' + h + '" preserveAspectRatio="none" aria-hidden="true">' +
      (o.fill !== false ? '<path class="spark__area" d="' + path(pts) + ' L' + w + ' ' + h + ' L0 ' + h + ' Z"/>' : '') +
      '<path class="spark__line" d="' + path(pts) + '"/>' +
    '</svg>';
  }

  function lineChart(o) {
    var w = 320, h = o.h || 132, padB = 20, padT = 6;
    var vals = o.values, e = extent(vals), min = e[0], span = e[1] - e[0];
    var step = vals.length > 1 ? w / (vals.length - 1) : w;
    var pts = vals.map(function (v, i) {
      return [i * step, padT + (h - padB - padT) * (1 - (v - min) / span)];
    });
    var grid = [0, 0.5, 1].map(function (f) {
      var y = padT + (h - padB - padT) * f;
      return '<line class="chart__grid" x1="0" y1="' + y.toFixed(1) + '" x2="' + w + '" y2="' + y.toFixed(1) + '"/>';
    }).join('');
    var labels = (o.labels || []).map(function (l, i) {
      var x = Math.min(w - 8, Math.max(8, i * (w / Math.max(1, o.labels.length - 1))));
      return '<text class="chart__xlabel" x="' + x.toFixed(0) + '" y="' + (h - 4) + '" text-anchor="' +
        (i === 0 ? 'start' : i === o.labels.length - 1 ? 'end' : 'middle') + '">' + esc(l) + '</text>';
    }).join('');
    var last = pts[pts.length - 1];
    return '<figure class="chart chart--line' + (o.tone ? ' chart--' + o.tone : '') + '"' +
      attrs({ 'aria-label': o.label }) + '>' +
      '<svg viewBox="0 0 ' + w + ' ' + h + '" preserveAspectRatio="none">' + grid +
        '<path class="chart__area" d="' + path(pts) + ' L' + w + ' ' + (h - padB) + ' L0 ' + (h - padB) + ' Z"/>' +
        '<path class="chart__line" d="' + path(pts) + '"/>' +
        '<circle class="chart__dot" cx="' + last[0].toFixed(1) + '" cy="' + last[1].toFixed(1) + '" r="3.2"/>' +
        labels +
      '</svg>' +
      (o.caption ? '<figcaption class="chart__cap">' + o.caption + '</figcaption>' : '') +
    '</figure>';
  }

  function barChart(o) {
    var max = Math.max.apply(null, o.values.concat([o.max || 0])) || 1;
    return '<figure class="chart chart--bar"' + attrs({ 'aria-label': o.label }) + '>' +
      '<div class="bars">' + o.values.map(function (v, i) {
        var pct = Math.round((v / max) * 100);
        var on = o.highlight === i;
        return '<div class="bars__col' + (on ? ' is-on' : '') + '" title="' + esc(o.labels[i] + ': ' + v) + '">' +
          '<span class="bars__bar" data-fill="' + pct + '" style="height:0"></span>' +
          '<span class="bars__label">' + esc(o.labels[i]) + '</span>' +
        '</div>';
      }).join('') + '</div>' +
      (o.caption ? '<figcaption class="chart__cap">' + o.caption + '</figcaption>' : '') +
    '</figure>';
  }

  function donut(o) {
    var total = o.slices.reduce(function (a, s) { return a + s.value; }, 0) || 1;
    var off = 0, r = 42, circ = 2 * Math.PI * r;
    var arcs = o.slices.map(function (s) {
      var frac = s.value / total;
      var seg = '<circle class="donut__seg" r="' + r + '" cx="50" cy="50" fill="none"' +
        ' stroke="' + esc(s.color) + '" stroke-width="14"' +
        ' stroke-dasharray="' + (frac * circ).toFixed(2) + ' ' + circ.toFixed(2) + '"' +
        ' stroke-dashoffset="' + (-off * circ).toFixed(2) + '"/>';
      off += frac;
      return seg;
    }).join('');
    var legend = o.slices.map(function (s) {
      return '<li class="donut__key"><i style="background:' + esc(s.color) + '"></i>' +
        '<span>' + esc(s.label) + '</span><b>' + (s.display || Math.round(s.value / total * 100) + '%') + '</b></li>';
    }).join('');
    return '<div class="donutwrap">' +
      '<figure class="donut"' + attrs({ 'aria-label': o.label }) + '>' +
        '<svg viewBox="0 0 100 100">' + arcs + '</svg>' +
        '<div class="donut__mid"><b>' + o.centre + '</b>' + (o.centreSub ? '<i>' + esc(o.centreSub) + '</i>' : '') + '</div>' +
      '</figure>' +
      '<ul class="donut__legend">' + legend + '</ul>' +
    '</div>';
  }

  function progressRing(o) {
    var r = 30, circ = 2 * Math.PI * r;
    var pct = Math.max(0, Math.min(1, o.value));
    /* The ring shows a value, so it announces that value — role="img" with a
       bare name used to prune the number out of the accessibility tree. */
    return '<div class="pring' + (o.size ? ' pring--' + o.size : '') + '"' + attrs({
        role: 'progressbar',
        'aria-label': o.label,
        'aria-valuemin': '0', 'aria-valuemax': '100',
        'aria-valuenow': Math.round(pct * 100),
        'aria-valuetext': String(o.centre).replace(/<[^>]+>/g, '')
      }) + '>' +
      '<svg viewBox="0 0 72 72">' +
        '<circle class="pring__bg" cx="36" cy="36" r="' + r + '" fill="none" stroke-width="7"/>' +
        '<circle class="pring__fg" cx="36" cy="36" r="' + r + '" fill="none" stroke-width="7"' +
          ' stroke-dasharray="' + circ.toFixed(1) + '" stroke-dashoffset="' + ((1 - pct) * circ).toFixed(1) + '"/>' +
      '</svg>' +
      '<div class="pring__mid"><b>' + o.centre + '</b>' + (o.centreSub ? '<i>' + esc(o.centreSub) + '</i>' : '') + '</div>' +
    '</div>';
  }

  function progressBar(o) {
    return '<div class="pbar' + (o.tone ? ' pbar--' + o.tone : '') + '"' +
      attrs({ role: 'progressbar', 'aria-valuenow': Math.round(o.value * 100), 'aria-label': o.label }) + '>' +
      '<span class="pbar__fill" data-fill="' + Math.round(Math.max(0, Math.min(1, o.value)) * 100) + '" style="width:0"></span>' +
    '</div>';
  }

  function meterRow(o) {
    return '<div class="meter">' +
      '<div class="meter__top"><span class="meter__label">' + esc(o.label) + '</span>' +
        '<span class="meter__value">' + o.value + '</span></div>' +
      progressBar({ value: o.pct, tone: o.tone, label: o.label }) +
      (o.foot ? '<p class="meter__foot">' + o.foot + '</p>' : '') +
    '</div>';
  }

  /* Heatmap — completion calendars for habits, prayer, fasting. */
  function heatmap(o) {
    /* Level is announced as text as well as drawn, and a summary sentence
       gives the whole grid a meaning a cell-by-cell read cannot (§101). */
    var LEVELS = o.levelLabels || ['none', 'some', 'most', 'all'];
    var hit = o.days.filter(function (d) { return d.level > 0; }).length;
    return '<div class="heat" role="group"' + attrs({ 'aria-label': o.label }) + '>' +
      '<span class="sr-only">' + esc(o.summary || (hit + ' / ' + o.days.length)) + '</span>' +
      o.days.map(function (d) {
        var name = (d.title || '') + (d.title ? ' — ' : '') + LEVELS[Math.min(3, d.level)];
        return '<i class="heat__cell heat__cell--l' + d.level + '"' +
          attrs({ title: d.title || null, role: 'img', 'aria-label': name }) + '></i>';
      }).join('') +
      '<div class="heat__key"><span>' + esc(o.less || 'Less') + '</span>' +
        '<i class="heat__cell heat__cell--l0"></i><i class="heat__cell heat__cell--l1"></i>' +
        '<i class="heat__cell heat__cell--l2"></i><i class="heat__cell heat__cell--l3"></i>' +
        '<span>' + esc(o.more || 'More') + '</span></div>' +
    '</div>';
  }

  /* ---------------------------------------------------------
     Timeline  (§22C, §59, §79)
     --------------------------------------------------------- */
  function timeline(items) {
    return '<ol class="tline">' + items.map(function (i) {
      return '<li class="tline__item' + (i.state ? ' is-' + i.state : '') + '">' +
        '<span class="tline__time">' + esc(i.time || '') + '</span>' +
        '<span class="tline__rail"><i class="tline__node">' + (i.icon ? ico(i.icon) : '') + '</i></span>' +
        '<span class="tline__body">' +
          '<span class="tline__title">' + esc(i.title) + '</span>' +
          (i.sub ? '<span class="tline__sub">' + i.sub + '</span>' : '') +
          (i.meta ? '<span class="tline__meta">' + i.meta + '</span>' : '') +
        '</span>' +
        (i.value ? '<span class="tline__value">' + i.value + '</span>' : '') +
      '</li>';
    }).join('') + '</ol>';
  }

  /* Horizontal timeline for a journey: origin → progress → destination. */
  function journey(o) {
    return '<div class="journey">' +
      '<div class="journey__end"><b>' + esc(o.fromCode) + '</b><span>' + esc(o.from) + '</span>' +
        '<i>' + esc(o.fromTime) + '</i></div>' +
      '<div class="journey__track">' +
        '<span class="journey__line"></span>' +
        '<span class="journey__prog" data-fill="' + Math.round(o.progress * 100) + '" style="width:0"></span>' +
        '<span class="journey__craft" style="left:' + Math.round(o.progress * 100) + '%">' + ico(o.icon || 'i-plane') + '</span>' +
        '<span class="journey__dur">' + esc(o.duration) + '</span>' +
      '</div>' +
      '<div class="journey__end journey__end--to"><b>' + esc(o.toCode) + '</b><span>' + esc(o.to) + '</span>' +
        '<i>' + esc(o.toTime) + '</i></div>' +
    '</div>';
  }

  /* ---------------------------------------------------------
     Map — a stylised static map with markers. Real tiles need a
     network; the composition, markers and controls are what the
     spec asks the interface to get right.
     --------------------------------------------------------- */
  function map(o) {
    var markers = (o.markers || []).map(function (m) {
      return '<button class="lmap__pin' + (m.active ? ' is-on' : '') + '" style="left:' + m.x + '%;top:' + m.y + '%"' +
        actAttr(m.act) + attrs({ 'aria-label': m.label }) + '>' +
        (m.icon ? ico(m.icon) : '<i></i>') + (m.label && m.showLabel ? '<b>' + esc(m.label) + '</b>' : '') + '</button>';
    }).join('');
    var route = o.route ? '<svg class="lmap__route" viewBox="0 0 100 100" preserveAspectRatio="none" aria-hidden="true">' +
      '<path d="' + esc(o.route) + '"/></svg>' : '';
    /* A group, not an image: the pins inside are real buttons, and role="img"
       pruned every one of them out of the accessibility tree. */
    return '<div class="lmap' + (o.tall ? ' lmap--tall' : '') + '"' +
      attrs({ 'aria-label': o.label, role: markers ? 'group' : 'img' }) + '>' +
      '<div class="lmap__grid" aria-hidden="true"></div>' + route + markers +
      (o.caption ? '<span class="lmap__cap">' + esc(o.caption) + '</span>' : '') +
      (o.controls ? '<div class="lmap__ctl">' + o.controls + '</div>' : '') +
    '</div>';
  }

  /* ---------------------------------------------------------
     Imagery (§17) — only where the picture carries information.
     Generated gradient art keeps the app dependency-free while
     still giving recognition value to news, recipes and places.
     --------------------------------------------------------- */
  var ART_TONES = {
    accent: ['#10998A', '#34B39D'], violet: ['#6E62E5', '#9A90FF'],
    amber: ['#E0913A', '#F0B96B'], rose: ['#DE6B7A', '#F0919C'],
    sky: ['#3E9BD4', '#6EBAE8'], indigo: ['#3D4BC7', '#7E8AF0'],
    slate: ['#4A5560', '#7C8794'], green: ['#3E9B62', '#69C48C']
  };

  function art(o) {
    var t = ART_TONES[o.tone] || ART_TONES.accent;
    var seed = o.seed || 1;
    var id = 'g' + Math.abs(seed * 7919 % 99991);
    return '<span class="artimg' + (o.cls ? ' ' + o.cls : '') + '" aria-hidden="true">' +
      '<svg viewBox="0 0 120 80" preserveAspectRatio="xMidYMid slice">' +
        '<defs><linearGradient id="' + id + '" x1="0" y1="0" x2="1" y2="1">' +
          '<stop offset="0" stop-color="' + t[0] + '"/><stop offset="1" stop-color="' + t[1] + '"/>' +
        '</linearGradient></defs>' +
        '<rect width="120" height="80" fill="url(#' + id + ')"/>' +
        '<circle cx="' + (20 + seed * 13 % 80) + '" cy="' + (18 + seed * 7 % 40) + '" r="' + (16 + seed * 5 % 18) + '" fill="rgba(255,255,255,.16)"/>' +
        '<circle cx="' + (80 + seed * 11 % 30) + '" cy="' + (56 + seed * 3 % 20) + '" r="' + (12 + seed * 9 % 14) + '" fill="rgba(0,0,0,.10)"/>' +
        (o.glyph ? '<text x="60" y="48" text-anchor="middle" font-size="28" fill="rgba(255,255,255,.9)">' + esc(o.glyph) + '</text>' : '') +
      '</svg>' +
    '</span>';
  }

  function imageCard(o) {
    return '<' + (o.act ? 'button' : 'div') + ' class="' + cls('imgcard', o.act && 'pressable', o.wide && 'imgcard--wide') + '"' +
      actAttr(o.act) + '>' +
      '<span class="imgcard__art">' + art({ tone: o.tone, seed: o.seed, glyph: o.glyph }) +
        (o.overlay ? '<span class="imgcard__overlay">' + o.overlay + '</span>' : '') + '</span>' +
      '<span class="imgcard__body">' +
        (o.kicker ? '<span class="imgcard__kicker">' + esc(o.kicker) + '</span>' : '') +
        '<span class="imgcard__title">' + esc(o.title) + '</span>' +
        (o.meta ? '<span class="imgcard__meta">' + o.meta + '</span>' : '') +
      '</span>' +
    '</' + (o.act ? 'button' : 'div') + '>';
  }

  function hscroll(items, o) {
    o = o || {};
    return '<div class="hstrip' + (o.cls ? ' ' + o.cls : '') + '">' + items.join('') + '</div>';
  }

  /* ---------------------------------------------------------
     States  (§90–§93)
     --------------------------------------------------------- */

  function emptyState(o) {
    return '<div class="state state--empty">' +
      '<span class="state__art">' + ico(o.icon || 'i-sparkles') + '</span>' +
      '<p class="state__title">' + esc(o.title) + '</p>' +
      (o.text ? '<p class="state__text">' + esc(o.text) + '</p>' : '') +
      (o.action ? button({ label: o.action.label, tone: 'accent', act: o.action.act, icon: o.action.icon }) : '') +
    '</div>';
  }

  function errorState(o) {
    return '<div class="state state--error" role="alert">' +
      '<span class="state__art">' + ico('i-alert') + '</span>' +
      '<p class="state__title">' + esc(o.title) + '</p>' +
      (o.text ? '<p class="state__text">' + esc(o.text) + '</p>' : '') +
      '<div class="btnrow">' +
        button({ label: o.retry || 'Retry', tone: 'accent', act: o.act, icon: 'i-refresh' }) +
      '</div>' +
      (o.cached ? '<p class="state__cached">' + esc(o.cached) + '</p>' : '') +
    '</div>';
  }

  function offlineBanner(o) {
    return '<div class="obanner" role="status">' + ico('i-wifi') +
      '<span><b>' + esc(o.title) + '</b>' + (o.text ? '<i>' + esc(o.text) + '</i>' : '') + '</span>' +
    '</div>';
  }

  function skeleton(kind, n) {
    var one = {
      metric: '<div class="sk sk--metric"></div>',
      row: '<div class="sk sk--row"></div>',
      chart: '<div class="sk sk--chart"></div>',
      card: '<div class="sk sk--card"></div>'
    }[kind] || '<div class="sk sk--row"></div>';
    var out = '';
    for (var i = 0; i < (n || 3); i++) out += one;
    return '<div class="skgroup">' + out + '</div>';
  }

  /* ---------------------------------------------------------
     Related tools (§97) — what makes Lume one ecosystem
     --------------------------------------------------------- */
  function relatedTools(list) {
    if (!list.length) return '';
    return '<div class="related">' + list.map(function (r) {
      return '<button class="related__item pressable" data-act="tool:' + esc(r.id) + '">' +
        '<span class="related__icon">' + ico(r.icon) + '</span>' +
        '<span class="related__label">' + esc(r.name) + '</span>' +
      '</button>';
    }).join('') + '</div>';
  }

  function noteCard(o) {
    return '<div class="notecard notecard--' + esc(o.tone || 'info') + '">' +
      ico(o.icon || 'i-info') + '<div><b>' + esc(o.title) + '</b>' +
      (o.text ? '<p>' + esc(o.text) + '</p>' : '') + '</div>' +
    '</div>';
  }

  function fab(o) {
    return '<button class="fab pressable"' + actAttr(o.act) + attrs({ 'aria-label': o.label }) + '>' +
      ico(o.icon || 'i-plus') + (o.label && o.showLabel ? '<span>' + esc(o.label) + '</span>' : '') + '</button>';
  }

  return {
    esc: esc, ico: ico, attrs: attrs, cls: cls,
    toolHeader: toolHeader, contextBar: contextBar, sectionHead: sectionHead, section: section,
    card: card, summaryCard: summaryCard, metric: metric, metrics: metrics, delta: deltaTag,
    richRow: richRow, rows: rows, compactRow: compactRow, expandRow: expandRow, table: table,
    searchBar: searchBar, chip: chip, filterBar: filterBar, segmented: segmented, tabs: tabs,
    sortBar: sortBar, button: button, buttonRow: buttonRow, field: field, selectField: selectField,
    formGrid: formGrid, stepper: stepper,
    statusBadge: statusBadge, freshness: freshness, sourceLine: sourceLine,
    sparkline: sparkline, lineChart: lineChart, barChart: barChart, donut: donut,
    progressRing: progressRing, progressBar: progressBar, meterRow: meterRow, heatmap: heatmap,
    timeline: timeline, journey: journey, map: map,
    art: art, imageCard: imageCard, hscroll: hscroll,
    emptyState: emptyState, errorState: errorState, offlineBanner: offlineBanner, skeleton: skeleton,
    relatedTools: relatedTools, noteCard: noteCard, fab: fab
  };
})();
