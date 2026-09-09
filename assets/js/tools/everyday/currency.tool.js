/* ============================================================
   Lume — currency

   One tool, one module. The composition is the approved one;
   it is moved here rather than rewritten.
   ============================================================ */
import { LUME_UI as UI } from '../../ui/components.js';
import { LUME_DATA as D } from '../../data/tool-data.js';
import { dirOf } from '../shared/direction.js';

export default {
  id: 'currency',

  /* ---------------------------------------------------------
     Currency converter — global, locale-aware
     --------------------------------------------------------- */
  build: function (c) {
    var cv = c.currencyBoard();
    var query = (c.state('q') || '').trim().toLowerCase();
    var popular = cv.popular.filter(function (p) {
      return !query || (p.code + ' ' + p.name).toLowerCase().indexOf(query) !== -1;
    });
    return UI.section({ body: UI.card(
        '<div class="convert">' +
          '<div class="convert__side">' +
            '<span class="convert__code">' + UI.esc(cv.from) + '</span>' +
            '<input class="convert__input" type="number" inputmode="decimal" value="' + cv.amount + '" data-input="cv_amount">' +
            '<span class="convert__name">' + UI.esc(cv.fromName) + '</span>' +
          '</div>' +
          '<button class="convert__swap pressable" data-act="cvswap" aria-label="' + UI.esc(c.t('convert.swap')) + '">' +
            UI.ico('i-swap') + '</button>' +
          '<div class="convert__side convert__side--to">' +
            '<span class="convert__code">' + UI.esc(cv.to) + '</span>' +
            '<span class="convert__out" data-cv-out>' + c.num(cv.result, { maximumFractionDigits: 2 }) + '</span>' +
            '<span class="convert__name">' + UI.esc(cv.toName) + '</span>' +
          '</div>' +
        '</div>' +
        '<p class="convert__rate">1 ' + UI.esc(cv.from) + ' = ' + c.num(cv.rate, { maximumFractionDigits: 4 }) + ' ' + UI.esc(cv.to) + '</p>') }) +
      UI.section({ body: UI.searchBar({ placeholder: c.t('convert.search'), target: 'currency', value: c.state('q') || '' }) }) +
      UI.section({ title: c.t('convert.popular'), body: popular.length ? UI.rows(popular.map(function (p) {
        return UI.richRow({
          logo: p.flag, logoTone: 'var(--tint-neutral)',
          title: p.code, sub: p.name,
          spark: UI.sparkline(D.walk(p.code.charCodeAt(0) * 7, 16, p.rate, 0.006), { tone: dirOf(p.pct) }),
          value: c.num(p.rate, { maximumFractionDigits: 3 }),
          delta: { dir: dirOf(p.pct), text: c.pct(p.pct) },
          act: 'toast:1 ' + cv.from + ' = ' + c.num(p.rate, { maximumFractionDigits: 3 }) + ' ' + p.code
        });
      })) : UI.emptyState({ icon: 'i-currency', title: c.t('rates.noMatch'), text: c.t('rates.noMatchText') }) }) +
      UI.section({ title: c.t('convert.chart', { pair: cv.from + '/' + cv.to }), body: UI.card(
        UI.lineChart({ values: D.walk(4242, 30, cv.rate, 0.006), labels: ['30d', '15d', c.t('common.today')],
          label: cv.from + '/' + cv.to })) }) +
      UI.section({ title: c.t('convert.recent'), body: UI.rows(cv.recent.map(function (r) {
        return UI.compactRow({ icon: 'i-clock', label: r.label, value: r.value });
      })) });
  }
};
