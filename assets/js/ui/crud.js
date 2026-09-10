/* ============================================================
   Lume — the CRUD vocabulary  (CRUD guide §3-§10)

   The reference visuals in the guide are eight screens of one
   system, not eight designs: a list of rows with an initial, a
   detail with a gradient hero over a card of facts, a form with
   the label above and the error directly below its field, a
   confirmation that names the record and its consequence, and
   five states that are shaped like the content they stand in
   for.

   This module is that system as markup. It reaches for the
   existing component set wherever one already exists — buttons,
   sections, cards, skeletons, the empty and error states — and
   adds only what a record flow needs and the app did not have.

   Nothing here decides anything. It takes resolved, formatted,
   translated values and returns HTML. The engine decides.
   ============================================================ */
import { LUME_UI } from './components.js';

export const LUME_CRUD_UI = (function () {
  'use strict';

  var UI = LUME_UI;
  var esc = UI.esc;
  var ico = UI.ico;

  function actAttr(act) { return act ? ' data-act="' + esc(act) + '"' : ''; }

  /* ---------------------------------------------------------
     The list
     --------------------------------------------------------- */

  /* One row. The initial in a jade disc is the reference visual's own
     device for making a list of names scannable without an icon per record
     — records are the user's words, and we have no icon for those. */
  function recordRow(o) {
    var tag = o.act ? 'button' : 'div';
    return '<' + tag + ' class="rrec' +
        (o.selected ? ' is-selected' : '') +
        (o.done ? ' is-done' : '') +
        (o.act ? ' pressable' : '') + '"' +
        actAttr(o.act) +
        (o.selected ? ' aria-current="true"' : '') + '>' +
      (o.check
        ? '<span class="rrec__check' + (o.done ? ' is-on' : '') + '"' + actAttr(o.check) +
            ' role="checkbox" aria-checked="' + (o.done ? 'true' : 'false') + '">' +
            ico('i-check') + '</span>'
        : '<span class="rrec__disc" aria-hidden="true">' + esc(o.initial || '·') + '</span>') +
      '<span class="rrec__body">' +
        '<span class="rrec__titleline">' +
          '<span class="rrec__title">' + esc(o.title) + '</span>' +
          (o.badge ? UI.statusBadge(o.badge) : '') +
        '</span>' +
        (o.sub ? '<span class="rrec__sub">' + esc(o.sub) + '</span>' : '') +
        (o.meta && o.meta.length
          ? '<span class="rrec__meta">' + o.meta.filter(Boolean).map(function (m, i) {
              return (i ? '<i class="rrec__dot"></i>' : '') + '<span>' + esc(m) + '</span>';
            }).join('') + '</span>'
          : '') +
      '</span>' +
      '<span class="rrec__end">' +
        (o.value ? '<span class="rrec__value num">' + esc(o.value) + '</span>' : '') +
        (o.queued ? '<span class="rrec__queued">' + esc(o.queuedLabel || '') + '</span>' : '') +
        (o.act ? ico('i-chev-r', 'ico rrec__chev') : '') +
      '</span>' +
    '</' + tag + '>';
  }

  function recordRows(rows) {
    return '<div class="rrecs">' + rows.join('') + '</div>';
  }

  /* The count line under a list title: "12 records", "No records yet",
     "Could not refresh" — the reference visual puts the collection's
     condition here rather than in a banner. */
  function listCount(label) {
    return '<span class="crud__count">' + esc(label) + '</span>';
  }

  /* Filter chips carrying their own counts, as the reference visual does. */
  function filterChips(items) {
    return '<div class="cchips" role="group">' + items.map(function (i) {
      return '<button class="cchip' + (i.on ? ' is-on' : '') + ' pressable"' + actAttr(i.act) +
        ' aria-pressed="' + (i.on ? 'true' : 'false') + '">' +
        '<span>' + esc(i.label) + '</span>' +
        (i.count !== undefined && i.count !== null
          ? '<i class="cchip__n num">' + esc(String(i.count)) + '</i>' : '') +
        '</button>';
    }).join('') + '</div>';
  }

  /* ---------------------------------------------------------
     The detail
     --------------------------------------------------------- */

  /* The gradient hero the reference detail leads with: the value large,
     the record's name under it, its kicker above and its date beneath. */
  function recordHero(o) {
    return '<div class="chero summary--' + esc(o.tone || 'accent') + '">' +
      (o.kicker ? '<p class="chero__kicker">' + esc(o.kicker) + '</p>' : '') +
      '<p class="chero__value num">' + esc(o.value) + '</p>' +
      (o.title ? '<p class="chero__title">' + esc(o.title) + '</p>' : '') +
      (o.caption ? '<p class="chero__caption">' + esc(o.caption) + '</p>' : '') +
    '</div>';
  }

  /* Label left, value right, hairline between. A long value — a note —
     wraps under its label instead of squeezing into a column. */
  function factCard(list) {
    return '<div class="cfacts">' + list.filter(Boolean).map(function (f) {
      return '<div class="cfact' + (f.block ? ' cfact--block' : '') + '">' +
        '<span class="cfact__label">' + esc(f.label) + '</span>' +
        '<span class="cfact__value">' + esc(f.value) + '</span>' +
      '</div>';
    }).join('') + '</div>';
  }

  /* Edit is an ordinary action on a tinted surface; delete is a danger
     action on a rose surface. Neither is a filled button, because neither
     is the primary action of a screen whose primary action is reading. */
  function detailActions(o) {
    return '<div class="cacts">' +
      '<button class="cact cact--edit pressable"' + actAttr(o.edit.act) + '>' +
        ico('i-note') + esc(o.edit.label) + '</button>' +
      (o.remove
        ? '<button class="cact cact--danger pressable"' + actAttr(o.remove.act) + '>' +
            esc(o.remove.label) + '</button>'
        : '') +
    '</div>';
  }

  function recordId(label) {
    return '<p class="crud__id">' + esc(label) + '</p>';
  }

  /* ---------------------------------------------------------
     The form
     --------------------------------------------------------- */

  /* Label above, helper below, error directly below its own field and
     paired with a glyph rather than carried by colour alone (§8, §9). */
  function formField(o) {
    var invalid = !!o.error;
    var id = 'f-' + o.name;
    var described = [];
    if (invalid) described.push(id + '-err');
    else if (o.hint) described.push(id + '-hint');

    var control;
    var attrs = {
      id: id, 'data-field': o.name,
      'aria-invalid': invalid ? 'true' : null,
      'aria-describedby': described.length ? described.join(' ') : null,
      'aria-required': o.required ? 'true' : null
    };

    if (o.kind === 'textarea') {
      control = '<textarea' + UI.attrs(Object.assign({}, attrs, {
        rows: o.rows || 3, placeholder: o.ph
      })) + '>' + esc(o.value || '') + '</textarea>';
    } else if (o.kind === 'select') {
      control = '<span class="cfield__select">' +
        '<select' + UI.attrs(attrs) + '>' +
          (o.options || []).map(function (op) {
            return '<option' + UI.attrs({ value: op.value, selected: String(op.value) === String(o.value) }) + '>' +
              esc(op.label) + '</option>';
          }).join('') +
        '</select>' + ico('i-chev-d') + '</span>';
    } else if (o.kind === 'check') {
      return '<label class="cfield cfield--check">' +
        '<input type="checkbox"' + UI.attrs(Object.assign({}, attrs, { checked: !!o.value })) + '>' +
        '<span class="cfield__checkbox" aria-hidden="true">' + ico('i-check') + '</span>' +
        '<span class="cfield__label">' + esc(o.label) + '</span>' +
      '</label>';
    } else if (o.kind === 'attach') {
      return '<div class="cfield cfield--wide">' +
        '<span class="cfield__label">' + esc(o.label) +
          (o.optional ? '<i class="cfield__opt">' + esc(o.optionalLabel) + '</i>' : '') + '</span>' +
        '<button class="cattach pressable" type="button"' + actAttr(o.act) + '>' +
          ico(o.value ? 'i-check-circle' : 'i-camera') +
          esc(o.value ? o.attachedLabel : o.attachLabel) + '</button>' +
      '</div>';
    } else {
      /* The right keyboard for the value (§8): a decimal pad for money, a
         date picker for a date, a numeric pad for a count. */
      var type = o.kind === 'money' || o.kind === 'number' ? 'number'
               : o.kind === 'date' ? 'date'
               : o.kind === 'time' ? 'time' : 'text';
      control = '<span class="cfield__box' + (invalid ? ' is-invalid' : '') + '">' +
        (o.prefix ? '<i class="cfield__affix">' + esc(o.prefix) + '</i>' : '') +
        '<input' + UI.attrs(Object.assign({}, attrs, {
          type: type,
          inputmode: o.kind === 'money' ? 'decimal' : o.kind === 'number' ? 'numeric' : null,
          value: o.value === undefined || o.value === null ? '' : String(o.value),
          placeholder: o.ph,
          min: o.kind === 'money' || o.kind === 'number' ? '0' : null,
          step: o.kind === 'money' ? 'any' : null
        })) + '>' +
      '</span>';
    }

    return '<div class="cfield' + (o.wide ? ' cfield--wide' : '') + (invalid ? ' is-invalid' : '') + '">' +
      '<label class="cfield__label" for="' + esc(id) + '">' + esc(o.label) +
        (o.optional ? '<i class="cfield__opt">' + esc(o.optionalLabel) + '</i>' : '') + '</label>' +
      (o.kind === 'select' || o.kind === 'textarea'
        ? '<span class="cfield__box' + (invalid ? ' is-invalid' : '') + '">' + control + '</span>'
        : control) +
      (invalid
        ? '<p class="cfield__err" id="' + esc(id) + '-err" role="alert">' +
            '<i aria-hidden="true">!</i>' + esc(o.error) + '</p>'
        : o.hint ? '<p class="cfield__hint" id="' + esc(id) + '-hint">' + esc(o.hint) + '</p>' : '') +
    '</div>';
  }

  /* Two columns only for related short fields; anything wide spans both,
     and the grid collapses to one column below expanded (§9). */
  function formGrid(fields, o) {
    var opts = o || {};
    return '<div class="cform' + (opts.pair ? ' fgrid--pair' : '') + '">' + fields.join('') + '</div>';
  }

  function formCard(o) {
    return '<div class="cformcard">' +
      (o.title ? '<h2 class="cformcard__title">' + esc(o.title) + '</h2>' : '') +
      o.body +
    '</div>';
  }

  /* The submit area. A busy action does not become a spinner in place of
     its label — it keeps the label and says what it is doing, so the
     button does not change size under the user's thumb (§7, §8). */
  function submitBar(o) {
    return '<div class="csubmit">' +
      '<button class="btn btn--accent btn--block' + (o.busy ? ' is-busy' : '') + '"' +
        actAttr(o.busy ? null : o.act) +
        (o.busy ? ' aria-busy="true" disabled' : '') + '>' +
        (o.busy ? '<i class="btn__spin" aria-hidden="true"></i>' : '') +
        esc(o.busy ? o.busyLabel : o.label) +
      '</button>' +
      (o.cancel
        ? '<button class="btn btn--ghost btn--block"' + actAttr(o.cancel.act) + '>' +
            esc(o.cancel.label) + '</button>'
        : '') +
      (o.note ? '<p class="csubmit__note">' + esc(o.note) + '</p>' : '') +
    '</div>';
  }

  /* A save that failed keeps every value the user typed and says what to do
     next. It is a card above the form, not a toast, because it must not
     disappear while they are reading it (§10). */
  function saveError(o) {
    return '<div class="cnotice cnotice--error" role="alert">' +
      ico('i-alert') +
      '<span class="cnotice__body">' +
        '<b>' + esc(o.title) + '</b>' +
        '<i>' + esc(o.text) + '</i>' +
      '</span>' +
      '<button class="cnotice__act pressable"' + actAttr(o.retry.act) + '>' + esc(o.retry.label) + '</button>' +
    '</div>';
  }

  /* A newer version exists. Review or Reload — never a silent overwrite. */
  function conflictNotice(o) {
    return '<div class="cnotice cnotice--warn" role="alert">' +
      ico('i-refresh') +
      '<span class="cnotice__body">' +
        '<b>' + esc(o.title) + '</b>' +
        '<i>' + esc(o.text) + '</i>' +
      '</span>' +
      '<span class="cnotice__acts">' +
        '<button class="cnotice__act pressable"' + actAttr(o.review.act) + '>' + esc(o.review.label) + '</button>' +
        '<button class="cnotice__act pressable"' + actAttr(o.reload.act) + '>' + esc(o.reload.label) + '</button>' +
      '</span>' +
    '</div>';
  }

  /* Cached records, an offline label, and queued writes shown as queued
     rather than as current (§10). */
  function offlineNotice(o) {
    return '<div class="cnotice cnotice--offline" role="status">' +
      ico('i-wifi') +
      '<span class="cnotice__body"><b>' + esc(o.title) + '</b><i>' + esc(o.text) + '</i></span>' +
    '</div>';
  }

  /* ---------------------------------------------------------
     States
     --------------------------------------------------------- */

  /* Skeletons shaped like the final content, never a spinner over the
     whole list (§10). */
  function loadingRows(n) {
    var out = '';
    for (var i = 0; i < (n || 5); i++) {
      out += '<div class="csk" aria-hidden="true">' +
        '<span class="csk__disc sk"></span>' +
        '<span class="csk__body"><span class="sk csk__l1"></span><span class="sk csk__l2"></span></span>' +
        '<span class="sk csk__val"></span>' +
      '</div>';
    }
    return '<div class="csks" role="status" aria-live="polite" aria-busy="true">' + out + '</div>';
  }

  /* Reason, next step, one primary call to action — never a blank card. */
  function emptyCollection(o) {
    return '<div class="cstate">' +
      '<span class="cstate__art" aria-hidden="true">' + ico(o.icon || 'i-sparkles') + '</span>' +
      '<p class="cstate__title">' + esc(o.title) + '</p>' +
      '<p class="cstate__text">' + esc(o.text) + '</p>' +
      '<button class="btn btn--accent cstate__cta pressable"' + actAttr(o.cta.act) + '>' +
        esc(o.cta.label) + '</button>' +
      (o.foot ? '<p class="cstate__foot">' + esc(o.foot) + '</p>' : '') +
    '</div>';
  }

  /* A load that failed offers the retry first and the cached records
     second, and says the saved data is still safe. */
  function loadError(o) {
    return '<div class="cstate cstate--error" role="alert">' +
      '<span class="cstate__art cstate__art--error" aria-hidden="true">' + ico('i-alert') + '</span>' +
      '<p class="cstate__title">' + esc(o.title) + '</p>' +
      '<p class="cstate__text">' + esc(o.text) + '</p>' +
      '<button class="btn btn--accent cstate__cta pressable"' + actAttr(o.retry.act) + '>' +
        esc(o.retry.label) + '</button>' +
      (o.cached
        ? '<button class="btn btn--ghost cstate__cta pressable"' + actAttr(o.cached.act) + '>' +
            esc(o.cached.label) + '</button>'
        : '') +
    '</div>';
  }

  /* Search found nothing, which is not the same as having nothing. */
  function noMatches(o) {
    return '<div class="cstate cstate--quiet">' +
      '<p class="cstate__title">' + esc(o.title) + '</p>' +
      '<p class="cstate__text">' + esc(o.text) + '</p>' +
      '<button class="btn btn--ghost cstate__cta pressable"' + actAttr(o.clear.act) + '>' +
        esc(o.clear.label) + '</button>' +
    '</div>';
  }

  /* ---------------------------------------------------------
     Master-detail
     --------------------------------------------------------- */

  /* Two panes at expanded width, one at every other. The list pane keeps
     its own scroll so selecting a record does not move it (§8). */
  function panes(o) {
    return '<div class="panes">' +
      '<div class="panes__list">' + o.list + '</div>' +
      '<div class="panes__detail" data-when="expanded">' + o.detail + '</div>' +
    '</div>';
  }

  /* What the detail pane shows before a record is chosen. */
  function noSelection(o) {
    return '<div class="cstate cstate--quiet cstate--pane">' +
      '<span class="cstate__art" aria-hidden="true">' + ico(o.icon || 'i-list') + '</span>' +
      '<p class="cstate__title">' + esc(o.title) + '</p>' +
      '<p class="cstate__text">' + esc(o.text) + '</p>' +
    '</div>';
  }

  return {
    recordRow: recordRow, recordRows: recordRows, listCount: listCount, filterChips: filterChips,
    recordHero: recordHero, factCard: factCard, detailActions: detailActions, recordId: recordId,
    formField: formField, formGrid: formGrid, formCard: formCard, submitBar: submitBar,
    saveError: saveError, conflictNotice: conflictNotice, offlineNotice: offlineNotice,
    loadingRows: loadingRows, emptyCollection: emptyCollection, loadError: loadError,
    noMatches: noMatches, panes: panes, noSelection: noSelection
  };
})();
