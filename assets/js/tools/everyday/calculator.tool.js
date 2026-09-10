/* ============================================================
   Lume — calculator

   One tool, one module. The composition is the approved one;
   it is moved here rather than rewritten.
   ============================================================ */
import { LUME_UI as UI } from '../../ui/components.js';

export default {
  id: 'calculator',

  build: function (c) {
    var KEYS = [
      ['AC', 'ac'], ['÷', 'op:/'], ['×', 'op:*'], ['⌫', 'back'],
      ['7', 'n:7'], ['8', 'n:8'], ['9', 'n:9'], ['−', 'op:-'],
      ['4', 'n:4'], ['5', 'n:5'], ['6', 'n:6'], ['+', 'op:+'],
      ['1', 'n:1'], ['2', 'n:2'], ['3', 'n:3'], ['%', 'pct'],
      ['0', 'n:0'], ['.', 'dot'], ['=', 'eq']
    ];
    return '<div class="calc">' +
        '<div class="calc__screen"><p class="calc__expr" data-calc-expr></p>' +
          '<p class="calc__out" data-calc-out>0</p></div>' +
        '<div class="calc__keys">' + KEYS.map(function (k) {
          var kind = k[1].split(':')[0];
          var cls = kind === 'n' || kind === 'dot' ? 'calc__key' :
                    kind === 'eq' ? 'calc__key calc__key--eq' :
                    kind === 'op' ? 'calc__key calc__key--op' : 'calc__key calc__key--fn';
          return '<button class="' + cls + (k[0] === '0' ? ' calc__key--wide' : '') +
            '" data-calckey="' + UI.esc(k[1]) + '">' + UI.esc(k[0]) + '</button>';
        }).join('') + '</div>' +
      '</div>' +
      UI.section({ title: c.t('common.history'), body: UI.rows(c.calcHistory().map(function (h) {
        return UI.compactRow({ label: h.expr, value: h.result });
      })) });
  }
};
