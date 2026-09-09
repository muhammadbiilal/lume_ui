/* ============================================================
   Lume — fasting

   One tool, one module. The composition is the approved one;
   it is moved here rather than rewritten.
   ============================================================ */
import { LUME_UI as UI } from '../../ui/components.js';

export default {
  id: 'fasting',

  /* ---------------------------------------------------------
     24.6 Fasting Tracker
     --------------------------------------------------------- */
  build: function (c) {
    var f = c.fasting();
    var kind = c.filter('kind', 'all');
    return UI.section({ body: UI.summaryCard({
        kicker: c.t('fast.thisMonth'),
        value: f.kept + ' <small>' + UI.esc(c.t('fast.days')) + '</small>',
        caption: c.t('fast.streak', { n: f.streak }),
        aside: UI.progressRing({ value: f.kept / f.target, centre: f.kept + '/' + f.target, label: c.t('fast.progress') }),
        stats: [
          { value: f.voluntary, label: c.t('fast.voluntary') },
          { value: f.obligatory, label: c.t('fast.obligatory') },
          { value: f.missed, label: c.t('fast.missed') }
        ]
      }) }) +
      UI.section({ body: UI.filterBar([{ id: 'kind', label: c.t('fast.kind'), items: [
        { value: 'all', label: c.t('common.all'), on: kind === 'all' },
        { value: 'sunnah', label: c.t('fast.sunnah'), on: kind === 'sunnah' },
        { value: 'qada', label: c.t('fast.qada'), on: kind === 'qada' }
      ] }], 'fasting') }) +
      UI.section({ title: c.t('fast.calendar'), body: UI.card(
        UI.heatmap({ days: f.heat, label: c.t('fast.calendar'), less: c.t('common.less'), more: c.t('common.more') })) }) +
      UI.section({ title: c.t('fast.recent'), body: UI.rows(f.recent.filter(function (d) {
        return kind === 'all' || d.kind === c.t('fast.' + kind);
      }).map(function (d) {
        return UI.richRow({
          icon: d.kept ? 'i-check-circle' : 'i-x', iconTone: d.kept ? 'accent' : null,
          title: d.label, sub: d.kind,
          value: UI.statusBadge({ label: d.kept ? c.t('fast.kept') : c.t('fast.notkept'), tone: d.kept ? 'ok' : 'neutral' })
        });
      })) }) +
      UI.section({ body: UI.buttonRow([
        { label: c.t('fast.log'), tone: 'accent', icon: 'i-plus', act: 'toast:' + c.t('fast.logged') }]) });
  }
};
