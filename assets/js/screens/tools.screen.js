/* ============================================================
   Lume — Tools screen

   One searchable catalogue of every utility this user can
   actually reach. Which tools those are is not decided here:
   the screen asks the same eligibility selector every other
   surface asks, so a hidden feature cannot reappear through the
   catalogue, its category counts, its search or its recents.

   Three things narrow what is shown, and they compose in a
   deliberate order:

     · search, which always looks across the whole visible
       catalogue — being on "For you" must never stop someone
       finding a tool by name;
     · the category chips;
     · "For you", which is a shortlist rather than a
       straitjacket: an interest match, something reached for
       recently, or a tool nearly everyone wants.
   ============================================================ */
import { defineScreen } from './screen-base.js';
import { $, $$ } from '../core/dom.js';

export function createToolsScreen(ctx) {

  /* Which chip is active. Kept on the screen because it is presentation
     state: nothing outside Tools has an opinion about it. */
  let filter = 'foryou';

  function renderChips(root) {
    const host = $('#toolChips', root);
    if (!host) return;
    const t = ctx.t, esc = ctx.ui.esc, profile = ctx.profile();

    const chips = [
      { id: 'foryou', label: t('tools.forYou'), icon: 'i-sparkles' },
      { id: 'all', label: t('a.all') }
    ];
    ctx.catalogue.CATEGORIES.forEach(function (cat) {
      if (cat.faith && !profile.islamic) return;
      chips.push({ id: cat.id, label: t('cat.' + cat.id) });
    });
    /* The faith category can disappear underneath the chip that selected
       it, and a filter nothing can satisfy would show an empty screen. */
    if (!chips.some(function (c) { return c.id === filter; })) filter = 'foryou';

    host.innerHTML = chips.map(function (c) {
      return '<button class="chip' + (c.id === filter ? ' is-active' : '') + '" data-filter="' + c.id + '">' +
        (c.icon ? '<svg class="ico" viewBox="0 0 24 24"><use href="#' + c.icon + '"/></svg> ' : '') +
        esc(c.label) + '</button>';
    }).join('');
  }

  /* A count where a count means something, and nowhere else. */
  function badgeCount(id) {
    try {
      if (id === 'bills') return ctx.toolCtx('bills').bills().overdueCount || 0;
      if (id === 'documents') {
        const d = ctx.toolCtx('documents').documents();
        return (d.expiring || 0) + (d.expired || 0);
      }
    } catch (e) { /* a tool that cannot answer simply has no badge */ }
    return 0;
  }

  function toolCard(f) {
    const t = ctx.t, esc = ctx.ui.esc;
    let badge = '';
    const n = badgeCount(f.id);
    if (n) badge += '<span class="cat-tool__count" aria-label="' +
      esc(t('n.needsAttention', { n: n })) + '">' + esc(n > 9 ? '9+' : n) + '</span>';
    if (f.sens) badge = '<span class="cat-tool__flag" aria-label="Private"><svg class="ico" viewBox="0 0 24 24"><use href="#i-lock"/></svg></span>';
    else if (f.loc) badge = '<span class="cat-tool__pin" aria-label="Local service"></span>';
    return '<button class="cat-tool pressable" data-act="' + ctx.eligible.actFor(f) + '" data-fid="' + f.id + '" ' +
      'data-hay="' + esc((f.n + ' ' + (f.kw || '')).toLowerCase()) + '" ' +
      (f.staple ? 'data-staple="1" ' : '') +
      'data-ints="' + esc((f.ints || []).join(' ')) + '">' +
      badge +
      '<span class="cat-tool__icon"><svg class="ico" viewBox="0 0 24 24"><use href="#' + f.i + '"/></svg></span>' +
      '<span class="cat-tool__label">' + esc(ctx.eligible.name(f)) + '</span>' +
      '<span class="cat-tool__meta">' + esc(f.m || '') + '</span></button>';
  }

  function renderCatalogue(root) {
    const host = $('#toolCats', root);
    if (!host) return;
    const t = ctx.t, esc = ctx.ui.esc, profile = ctx.profile();
    const list = ctx.eligible.visibleFeatures();

    host.innerHTML = ctx.catalogue.CATEGORIES.map(function (cat) {
      if (cat.faith && !profile.islamic) return '';
      const items = list.filter(function (f) { return f.c === cat.id; });
      if (!items.length) return '';
      return '<section class="cat" data-cat="' + cat.id + '">' +
        '<div class="cat__head">' +
          '<span class="cat__dot"><svg class="ico" viewBox="0 0 24 24"><use href="#' + cat.icon + '"/></svg></span>' +
          '<div><h2 class="cat__title">' + esc(t('cat.' + cat.id)) + '</h2>' +
          '<p class="cat__sub">' + esc(t('cat.' + cat.id + 'Sub')) + '</p></div>' +
          '<span class="cat__count">' + items.length + '</span>' +
        '</div>' +
        '<div class="cat-grid">' + items.map(toolCard).join('') + '</div>' +
      '</section>';
    }).join('');

    /* The count in the heading is the count of what is actually reachable,
       so it agrees with the catalogue below it in every market. */
    const sub = $('#toolSub', root);
    if (sub) sub.textContent = t('tools.sub', { n: ctx.L.num(list.length) });

    const search = $('#toolSearch', root);
    if (search) {
      search.setAttribute('placeholder', t('tools.searchPlaceholder', {
        example: profile.country === 'PK' ? 'petrol' : 'currency'
      }));
    }

    applyFilter(root);
  }

  function applyFilter(root) {
    const t = ctx.t, profile = ctx.profile();
    const input = $('#toolSearch', root);
    const q = ((input && input.value) || '').trim().toLowerCase();
    let anyVisible = false;

    $$('#toolCats .cat', root).forEach(function (cat) {
      const searching = !!q;
      const forYou = !searching && filter === 'foryou' && profile.interests.length > 0;
      const catMatch = searching || filter === 'all' || forYou || cat.dataset.cat === filter;
      let shown = 0;

      $$('.cat-tool', cat).forEach(function (tool) {
        let match = catMatch && (!q || tool.dataset.hay.indexOf(q) !== -1);
        if (match && forYou) {
          match = (tool.dataset.ints || '').split(/\s+/).some(function (id) { return id && ctx.hasInterest(id); }) ||
                  tool.dataset.staple === '1' ||
                  profile.recents.indexOf(tool.dataset.fid) !== -1;
        }
        tool.classList.toggle('is-hidden', !match);
        if (match) shown++;
      });

      cat.style.display = shown ? '' : 'none';
      const count = $('.cat__count', cat);
      if (count) count.textContent = shown;
      if (shown) anyVisible = true;
    });

    /* Two different kinds of nothing, and they need different words:
       a search that matched nothing, and a shortlist that is still empty. */
    const empty = $('#toolEmpty', root);
    if (empty) {
      empty.classList.toggle('is-shown', !anyVisible);
      const title = $('.empty__title', empty), text = $('.empty__text', empty);
      if (title && text) {
        if (!q && filter === 'foryou') {
          title.textContent = t('tools.nothingYet');
          text.textContent = t('tools.nothingYetSub');
        } else {
          title.textContent = t('tools.noMatch');
          text.textContent = t('tools.noMatchSub');
        }
      }
    }
  }

  /* Recently used. A hidden feature must not resurface through history,
     so the list is filtered on the way out as well as on the way in. */
  function renderRecents(root) {
    const wrap = $('#toolRecent', root), host = $('#toolRecentList', root);
    if (!wrap || !host) return;
    const esc = ctx.ui.esc;
    const items = ctx.profile().recents
      .map(ctx.eligible.feature)
      .filter(function (f) { return f && ctx.eligible.visible(f); });
    wrap.hidden = items.length < 2;
    host.innerHTML = items.map(function (f) {
      return '<button class="recent pressable" data-act="' + ctx.eligible.actFor(f) + '" data-fid="' + f.id + '">' +
        '<span class="recent__icon"><svg class="ico" viewBox="0 0 24 24"><use href="#' + f.i + '"/></svg></span>' +
        '<span class="recent__label">' + esc(ctx.eligible.name(f)) + '</span></button>';
    }).join('');
  }

  return defineScreen({
    id: 'tools',
    template: function () {
      return `
  <section class="screen" id="screen-tools" role="tabpanel" aria-label="Tools">

    <div class="page-head">
      <div class="page-head__bar">
        <div>
          <h1 class="page-head__title" data-i18n="tools.title">Tools</h1>
          <p class="page-head__sub" id="toolSub">79 utilities, neatly sorted</p>
        </div>
        <button class="iconbtn pressable" data-sheet="personalise" aria-label="Personalise">
          <svg class="ico" viewBox="0 0 24 24"><use href="#i-sliders"/></svg>
        </button>
      </div>
    </div>

    <div class="section" style="margin-top:16px">
      <label class="search">
        <svg class="ico" viewBox="0 0 24 24"><use href="#i-search"/></svg>
        <input type="search" id="toolSearch" placeholder="Search tools — try “petrol”" aria-label="Search tools">
      </label>
    </div>

    <div class="section" style="margin-top:14px">
      <div class="chips" id="toolChips"></div>
    </div>

    <!-- Recently used — can only ever show what this user is allowed to see -->
    <div class="section" id="toolRecent" hidden>
      <div class="section__head">
        <div>
          <h2 class="section__title" data-i18n="tools.recent">Recently used</h2>
          <p class="section__sub" data-i18n="tools.recentSub">Straight back to where you were</p>
        </div>
      </div>
      <div class="hscroll" id="toolRecentList"></div>
    </div>

    <div id="toolCats"></div>

    <div class="empty" id="toolEmpty">
      <svg width="88" height="66" viewBox="0 0 88 66" fill="none" aria-hidden="true">
        <circle cx="44" cy="30" r="22" stroke="var(--border-2)" stroke-width="2" stroke-dasharray="5 7"/>
        <path d="m58 44 12 12" stroke="var(--border-2)" stroke-width="2.4" stroke-linecap="round"/>
        <circle cx="20" cy="14" r="3" fill="var(--accent)" opacity=".4"/>
        <circle cx="72" cy="18" r="4" fill="var(--accent)" opacity=".25"/>
      </svg>
      <p class="empty__title">No tools match</p>
      <p class="empty__text">Try a different word — or browse a category above.</p>
    </div>

  </section>
`;
    },

    bind: function (root, signal) {
      const search = $('#toolSearch', root);
      if (search) search.addEventListener('input', function () { applyFilter(root); }, { signal: signal });

      /* Chip selection is delegated from this screen's root rather than the
         document, so it cannot fire for a chip on another screen. */
      root.addEventListener('click', function (e) {
        const chip = e.target.closest('#toolChips .chip');
        if (!chip) return;
        $$('#toolChips .chip', root).forEach(function (c) { c.classList.remove('is-active'); });
        chip.classList.add('is-active');
        filter = chip.dataset.filter;
        applyFilter(root);
      }, { signal: signal });
    },

    /* Opening a tool anywhere in the app writes it to recents, and every
       arrival on this screen re-renders it, so there is nothing to
       subscribe to: being shown is the notification. */
    render: function (root) {
      renderChips(root);
      renderCatalogue(root);
      renderRecents(root);
    }
  });
}
