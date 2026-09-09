/* ============================================================
   Lume — converter

   One tool, one module. The composition is the approved one;
   it is moved here rather than rewritten.
   ============================================================ */
import { LUME_UI as UI } from '../../toolkit.js';

export default {
  id: 'converter',

  /* ---------------------------------------------------------
     §47 Unit converter
     --------------------------------------------------------- */
  build: function (c) {
    var u = c.converter();
    return UI.section({ flush: true, body: '<div class="chips chips--scroll">' +
        u.categories.map(function (cat) {
          return '<button class="chip' + (cat.id === u.category ? ' is-on' : '') +
            '" data-act="toolstate:converter:cat:' + cat.id + '">' + UI.ico(cat.icon) + UI.esc(cat.label) + '</button>';
        }).join('') + '</div>' }) +
      UI.section({ body: UI.card(
        '<div class="convert">' +
          '<div class="convert__side">' +
            '<span class="convert__code">' + UI.esc(u.from.short) + '</span>' +
            '<input class="convert__input" type="number" inputmode="decimal" value="' + u.amount + '" data-input="uc_amount">' +
            '<span class="convert__name">' + UI.esc(u.from.label) + '</span>' +
          '</div>' +
          '<button class="convert__swap pressable" data-act="ucswap" aria-label="' + UI.esc(c.t('convert.swap')) + '">' +
            UI.ico('i-swap') + '</button>' +
          '<div class="convert__side convert__side--to">' +
            '<span class="convert__code">' + UI.esc(u.to.short) + '</span>' +
            '<span class="convert__out" data-uc-out>' + c.num(u.result, { maximumFractionDigits: 4 }) + '</span>' +
            '<span class="convert__name">' + UI.esc(u.to.label) + '</span>' +
          '</div>' +
        '</div>') }) +
      UI.section({ title: c.t('convert.allUnits'), body: UI.rows(u.units.map(function (x) {
        return UI.compactRow({ label: x.label, sub: x.short, value: c.num(u.amount * u.from.factor / x.factor, { maximumFractionDigits: 4 }) });
      })) }) +
      UI.section({ title: c.t('convert.recent'), body: UI.rows(u.recent.map(function (r) {
        return UI.compactRow({ icon: 'i-clock', label: r.label, value: r.value });
      })) });
  }
};
