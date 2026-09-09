/* ============================================================
   Lume — tool screen engine  (Master Spec §7, §8, §109, §113)

   Every tool gets a full screen composed from its own
   information architecture, not a shared template. This module
   owns:

     · the registry screens are registered into
     · the context object a builder is handed (locale, data,
       profile, spec) so no screen formats anything itself
     · the archetype fallbacks, so a tool without a bespoke
       screen still lands on a composition appropriate to its
       kind rather than a generic card stack
     · the standard closing sections every screen shares:
       source/freshness and related tools

   Builders are registered from tools-*.js.
   ============================================================ */
import { LUME_DATA } from './tooldata.js';
import { LUME_SPEC } from './toolspec.js';
import { LUME_UI } from './toolkit.js';
export const LUME_TOOLS = (function () {
  'use strict';

  var UI = LUME_UI;
  var D = LUME_DATA;
  var SPEC = LUME_SPEC;

  var REG = {};
  var ctxFactory = null;

  function register(id, fn) { REG[id] = fn; }
  function registerMany(map) { for (var k in map) if (map.hasOwnProperty(k)) REG[k] = map[k]; }
  function has(id) { return !!REG[id]; }

  /* app.js installs the factory once it owns a profile and a locale. */
  function init(factory) { ctxFactory = factory; }

  /* ---------------------------------------------------------
     Shared building blocks every screen may reach for
     --------------------------------------------------------- */

  /* This line appears on every tool screen, so it is a key, not a string. */
  var FRESH_TEXT = {
    live: { quality: 'live', key: 'fresh.live' },
    cached: { quality: 'cached', key: 'fresh.cached' },
    delayed: { quality: 'delayed', key: 'fresh.delayed' },
    daily: { quality: 'cached', key: 'fresh.daily' },
    weekly: { quality: 'cached', key: 'fresh.weekly' },
    annual: { quality: 'cached', key: 'fresh.annual' },
    draw: { quality: 'cached', key: 'fresh.draw' },
    computed: { quality: 'computed', key: 'fresh.computed' },
    static: { quality: 'cached', key: 'fresh.static' },
    local: { quality: 'local', key: 'fresh.local' }
  };

  function freshnessOf(spec, t) {
    var f = FRESH_TEXT[spec.freshness] || FRESH_TEXT.local;
    return { quality: f.quality, label: t ? t(f.key) : f.key };
  }

  /* §107 — source is discoverable but never dominant. */
  /* §19 — "Live" alone is not freshness. A live or delayed feed says when it
     last moved; a computed or local one says what it is instead. */
  function updatedLabel(c) {
    var f = c.spec.freshness;
    if (f === 'live') return c.t('fresh.agoSec', { n: 30 });
    if (f === 'delayed') return c.t('fresh.agoMin', { n: 15 });
    if (f === 'daily' || f === 'draw') return c.t('fresh.at', { time: c.time(6, 0) });
    if (f === 'weekly' || f === 'annual') return c.t('fresh.on', { date: c.dateShort(new Date()) });
    if (f === 'computed') return c.t('fresh.forCity', { city: c.profile.city });
    return null;
  }

  function sourceSection(c) {
    var offline = typeof navigator !== 'undefined' && navigator.onLine === false;
    var networked = c.spec.freshness !== 'local' && c.spec.freshness !== 'static';
    return (offline && networked
      ? UI.section({ body: UI.offlineBanner({
          title: c.t('state.offline.title'),
          text: c.spec.supports.offline ? c.t('state.offline.cached') : c.t('state.offline.text')
        }) })
      : '') +
      UI.section({
        id: 'source',
        body: '<div class="srcbar">' +
          UI.freshness(offline && networked
            ? { quality: 'cached', label: c.t('fresh.offline') }
            : freshnessOf(c.spec, c.t)) +
          UI.sourceLine({
            source: c.t('src.' + c.spec.id) !== 'src.' + c.spec.id ? c.t('src.' + c.spec.id) : c.spec.source,
            updated: offline && networked ? c.t('fresh.lastSync') : updatedLabel(c)
          }) +
        '</div>'
      });
  }

  /* §97 — the links that make Lume one ecosystem instead of 80 apps. */
  function relatedSection(c) {
    var items = c.spec.related.map(c.featureFor).filter(Boolean).filter(c.isVisible).map(function (f) {
      return { id: f.id, icon: f.i, name: c.fname(f) };
    });
    if (!items.length) return '';
    return UI.section({ id: 'related', title: c.t('tool.related'), body: UI.relatedTools(items) });
  }

  /* Sensitive tools say so plainly rather than hiding it (§104, §62). */
  function privacyNote(c) {
    if (!c.spec.sensitive) return '';
    return UI.section({
      body: UI.noteCard({
        tone: 'lock', icon: 'i-lock',
        title: c.t('tool.private.title'),
        text: c.t('tool.private.text')
      })
    });
  }

  /* ---------------------------------------------------------
     Archetype fallbacks (§22)
     A tool whose bespoke screen has not been written still gets
     a composition shaped by its archetype and its own metadata,
     never a blank surface and never a generic dashboard.
     --------------------------------------------------------- */

  function contractCard(c) {
    var s = c.spec;
    var flags = [];
    if (s.supports.search) flags.push(c.t('cap.search'));
    if (s.supports.filters) flags.push(c.t('cap.filters'));
    if (s.supports.sorting) flags.push(c.t('cap.sorting'));
    if (s.supports.history) flags.push(c.t('cap.history'));
    if (s.supports.notifications) flags.push(c.t('cap.notifications'));
    if (s.supports.offline) flags.push(c.t('cap.offline'));
    if (s.supports.sharing) flags.push(c.t('cap.sharing'));
    if (s.supports.export) flags.push(c.t('cap.export'));
    return UI.card(
      '<p class="kard__lead">' + UI.esc(c.t('tool.preview.lead')) + '</p>' +
      '<div class="taglist">' + flags.map(function (f) {
        return '<span class="tag tag--neutral">' + UI.esc(f) + '</span>';
      }).join('') + '</div>', { tone: 'quiet' });
  }

  var FALLBACKS = {
    manager: function (c) {
      return UI.section({ id: 'summary', body:
        UI.summaryCard({ kicker: c.fname(c.f), value: c.f.m || '—', caption: c.t('tool.preview.records') }) }) +
        (c.spec.supports.search ? UI.section({ body: UI.searchBar({ placeholder: c.t('search.in', { name: c.fname(c.f) }) }) }) : '') +
        UI.section({ title: c.t('tool.preview.title'), body: contractCard(c) });
    },
    calculator: function (c) {
      return UI.section({ id: 'inputs', title: c.t('tool.inputs'), body:
        UI.formGrid([UI.field({ label: c.t('tool.value'), name: 'a', type: 'number', value: '' })]) }) +
        UI.section({ title: c.t('tool.preview.title'), body: contractCard(c) });
    },
    dashboard: function (c) {
      return UI.section({ id: 'summary', body:
        UI.summaryCard({ kicker: c.fname(c.f), value: c.f.m || '—' }) }) +
        UI.section({ title: c.t('tool.preview.title'), body: contractCard(c) });
    }
  };

  function fallback(c) {
    var a = c.spec.archetype;
    var fn = FALLBACKS[a] || FALLBACKS.manager;
    return fn(c);
  }

  /* ---------------------------------------------------------
     Build
     --------------------------------------------------------- */

  function build(id) {
    if (!ctxFactory) return null;
    var c = ctxFactory(id);
    if (!c) return null;

    var body;
    try {
      body = REG[id] ? REG[id](c) : fallback(c);
    } catch (err) {
      /* A screen that throws must degrade to an error state, never to a
         blank tool (§92). */
      if (window.console) console.error('Lume tool "' + id + '" failed to build', err);
      body = UI.section({ body: UI.errorState({
        title: c.t('state.error.title'),
        text: c.t('state.error.text'),
        act: 'tool:' + id
      }) });
    }

    return {
      header: UI.toolHeader({
        title: c.fname(c.f),
        sub: c.headerSub || archetypeLine(c),
        backLabel: c.t('a11y.back'),
        actions: headerActions(c)
      }),
      body: body + sourceSection(c) + privacyNote(c) + relatedSection(c),
      density: c.spec.density,
      archetype: c.spec.archetype
    };
  }

  function archetypeLine(c) {
    var s = c.spec;
    var bits = [];
    if (s.aware.city && c.profile.city) bits.push(c.profile.city);
    else if (s.aware.country) bits.push(c.L.countryName(c.profile.country));
    bits.push(c.t('archetype.' + s.archetype));
    return UI.esc(bits.filter(Boolean).join(' · '));
  }

  /* Sharing and export are declared capabilities, so they get a place in the
     header rather than being cut by a slice (§98, §99). Search comes last
     because every screen that declares it also renders a search field. */
  function headerActions(c) {
    var s = c.spec, out = [];
    if (s.supports.sharing) out.push({ id: 'share', icon: 'i-share', label: c.t('a11y.share'), act: 'share:' + s.id });
    if (s.supports.export) out.push({ id: 'export', icon: 'i-download', label: c.t('a11y.export'), act: 'export:' + s.id });
    if (s.supports.favorites && out.length < 3) out.push({ id: 'fav', icon: 'i-bookmark', label: c.t('a11y.favourite'), act: 'fav:' + s.id });
    if (s.supports.search && out.length < 3) out.push({ id: 'search', icon: 'i-search', label: c.t('a11y.search'), act: 'toolsearch:' + s.id });
    return out.slice(0, 3);
  }

  return {
    register: register, registerMany: registerMany, has: has, init: init, build: build,
    freshnessOf: freshnessOf, contractCard: contractCard
  };
})();
