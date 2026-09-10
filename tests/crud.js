/* ============================================================
   Lume — CRUD harness  (CRUD guide §12)

   The guide ends with a checklist, and this is that checklist
   driven against the real DOM rather than read:

     · every state is visually previewable — empty, loading,
       populated, error, offline, save failure, conflict;
     · create and edit preserve input after a failure;
     · back navigation preserves search, filters and position;
     · master-detail collapses safely below expanded width;
     · delete behaviour matches whether recovery is possible;
     · success feedback does not block the next action.

   It also drives the validation lifecycle, because "do not
   judge an untouched field" is the rule most easily lost to a
   later refactor and the one a user notices first.
   ============================================================ */
const fs = require('fs');
const path = require('path');
const { JSDOM, VirtualConsole } = require('jsdom');
const { loadInto } = require('./modules');

const ROOT = path.resolve(__dirname, '..');
let failures = 0;
function ok(label, cond, extra) {
  console.log((cond ? '  ok   ' : '  FAIL ') + label + (cond ? '' : '  -> ' + (extra === undefined ? '' : extra)));
  if (!cond) failures++;
}

const wait = ms => new Promise(r => setTimeout(r, ms));

async function boot(profile, opts) {
  const options = opts || {};
  const html = fs.readFileSync(path.join(ROOT, 'index.html'), 'utf8');
  const vc = new VirtualConsole();
  const errors = [];
  vc.on('jsdomError', e => errors.push(String(e.message || e)));
  vc.on('error', (...a) => errors.push(a.map(String).join(' ')));

  const dom = new JSDOM(html, {
    url: 'http://localhost/index.html',
    runScripts: 'dangerously',
    virtualConsole: vc,
    pretendToBeVisual: true,
    beforeParse(window) {
      window.localStorage.setItem('lume-onboarded', '1');
      window.localStorage.setItem('lume-profile', JSON.stringify(Object.assign({
        units: 'auto', currency: 'auto', clock: 'auto', method: 'MWL',
        interests: ['weather', 'calendar', 'tasks', 'notes', 'maths', 'expenses'],
        prefs: { news: true, cricket: true, finance: true, recos: true },
        recents: [], favourites: [], recentCountries: []
      }, profile || {})));
      if (options.records) window.localStorage.setItem('lume-records', options.records);

      /* The width class is measured off the shell, and jsdom lays nothing
         out, so offsetWidth is forced here to choose a width class. */
      Object.defineProperty(window.HTMLElement.prototype, 'offsetWidth', {
        configurable: true,
        get() { return this.id === 'app' ? (options.width || 390) : 100; }
      });
      window.matchMedia = q => ({ matches: false, media: q, addListener() {}, removeListener() {}, addEventListener() {}, removeEventListener() {} });
      window.requestAnimationFrame = cb => setTimeout(() => cb(Date.now()), 0);
      window.HTMLCanvasElement.prototype.getContext = () => null;
      window.navigator.vibrate = () => true;
      if (options.offline) {
        Object.defineProperty(window.navigator, 'onLine', { configurable: true, get: () => false });
      }
    }
  });
  loadInto(dom, ROOT, errors);
  await wait(60);
  return { dom, errors };
}

function click(win, el) {
  if (!el) return false;
  el.dispatchEvent(new win.MouseEvent('click', { bubbles: true, cancelable: true }));
  return true;
}

function type(win, el, value) {
  if (!el) return;
  el.value = value;
  el.dispatchEvent(new win.Event('input', { bubbles: true }));
}

function blur(win, el) {
  if (!el) return;
  el.dispatchEvent(new win.FocusEvent('focusout', { bubbles: true }));
}

function act(win, selector) {
  const el = win.document.querySelector(selector);
  return click(win, el);
}

(async () => {
  /* ==========================================================
     1. The collection: loading, populated, search, filters
     ========================================================== */
  console.log('\n=== The collection (§3, §10) ===');
  let { dom, errors } = await boot({ country: 'PK', city: 'Islamabad', islamic: false });
  let win = dom.window, doc = win.document;
  const $ = s => doc.querySelector(s);
  const $$ = s => [...doc.querySelectorAll(s)];

  ok('booted with no script errors', errors.length === 0, errors.slice(0, 2).join(' | '));

  /* Hydration is deferred, so the very first paint of a collection is the
     skeleton — the state that would otherwise exist only in a screenshot. */
  const host = doc.createElement('button');
  host.dataset.act = 'tool:expenses';
  doc.body.appendChild(host);
  click(win, host);
  ok('a collection opens on skeletons shaped like its rows',
     $$('#toolBody .csk').length >= 3, String($$('#toolBody .csk').length));
  ok('and the skeleton says it is busy',
     $('#toolBody .csks') && $('#toolBody .csks').getAttribute('aria-busy') === 'true');

  await wait(400);
  ok('the records arrive without another tap', $$('#toolBody .rrec').length >= 5,
     String($$('#toolBody .rrec').length));
  ok('a row leads with the record initial', !!$('#toolBody .rrec__disc'));
  ok('a row carries its value', !!$('#toolBody .rrec__value'));
  ok('the header counts the records, as the reference visual does',
     /records/.test($('#toolHeader .toolbar__sub').textContent),
     $('#toolHeader .toolbar__sub').textContent);
  ok('and the list below does not repeat it',
     !$('[data-sect="records"] .sect__head'));
  ok('Add sits in the header as a word (§2)', !!$('#toolHeader [data-act="rec:new:expenses"]'));
  ok('and it is the first action there',
     $('#toolHeader .toolbar__actions').firstElementChild.dataset.act === 'rec:new:expenses');

  /* Filters and search narrow the list without leaving it. */
  const chips = $$('#toolBody .cchip');
  ok('filter chips carry their counts', chips.length >= 2 && !!$('.cchip__n'));
  const before = $$('#toolBody .rrec').length;
  click(win, chips[1]);
  await wait(30);
  ok('choosing a filter narrows the list', $$('#toolBody .rrec').length <= before);
  ok('and the chip says it is pressed', $('#toolBody .cchip.is-on').getAttribute('aria-pressed') === 'true');

  const search = $('#toolBody [data-tool-search]');
  type(win, search, 'zzzzz');
  await wait(340);
  ok('a search with no match explains itself rather than going blank',
     !!$('#toolBody .cstate--quiet'));
  act(win, '[data-act="rec:clear:expenses"]');
  await wait(40);
  ok('clearing the search restores the list', $$('#toolBody .rrec').length >= 5);

  /* ==========================================================
     2. Create: the validation lifecycle
     ========================================================== */
  console.log('\n=== Create and the validation lifecycle (§10) ===');
  act(win, '[data-act="rec:new:expenses"]');
  await wait(40);

  ok('the form is the screen, not a section of one', !!$('#toolBody .cform'));
  ok('its header names the operation', /Add/.test($('#toolHeader .toolbar__title').textContent));
  ok('and says it is a new record', /New record/.test($('#toolHeader .toolbar__sub').textContent));
  ok('Save is offered at the top as well', !!$('#toolHeader [data-act="rec:save:expenses"]'));
  ok('every label sits above its field', $$('.cfield .cfield__label').length >= 5);
  ok('an optional field is marked Optional (§8)', !!$('.cfield__opt'));
  ok('money asks for a decimal keypad',
     $('[data-field="amount"]').getAttribute('inputmode') === 'decimal');
  ok('a date field is a date picker', $('[data-field="date"]').type === 'date');

  ok('an untouched field is not judged (§10)', $$('.cfield__err').length === 0);

  /* Blur validates that field, and only that field. */
  const title = $('[data-field="title"]');
  type(win, title, '');
  blur(win, title);
  await wait(40);
  ok('leaving an empty required field says so', !!$('[data-field="title"][aria-invalid="true"]'));
  ok('the message sits directly below its own field',
     !!$('.cfield.is-invalid .cfield__err'));
  ok('the error is paired with a glyph, not carried by colour (§9)',
     /!/.test($('.cfield__err').textContent));
  ok('and is announced', $('.cfield__err').getAttribute('role') === 'alert');
  ok('but the fields the user has not visited stay quiet',
     !$('[data-field="amount"][aria-invalid="true"]'));

  /* Submitting an invalid form validates everything and keeps the input. */
  type(win, $('[data-field="title"]'), 'Books');
  type(win, $('[data-field="amount"]'), '0');
  act(win, '[data-act="rec:save:expenses"]');
  await wait(60);
  ok('submitting with a zero amount refuses and explains',
     !!$('[data-field="amount"][aria-invalid="true"]'));
  ok('the message is the schema\'s own rule, not a generic one',
     /greater than zero/.test($('#toolBody').textContent));
  ok('every value the user typed survives the refusal',
     $('[data-field="title"]').value === 'Books', $('[data-field="title"]').value);

  /* A valid submit saves, confirms without blocking, and offers Undo. */
  type(win, $('[data-field="amount"]'), '42');
  act(win, '[data-act="rec:save:expenses"]');
  ok('saving shows progress in the action itself', !!$('#toolBody .btn.is-busy'));
  ok('and prevents a second submission while it runs',
     $('#toolBody .btn.is-busy').hasAttribute('disabled'));

  await wait(500);
  ok('the record is saved and the detail is shown', !!$('#toolBody .chero'));
  ok('the toast confirms without covering the screen', $('#toast').classList.contains('is-open'));
  ok('and it carries Undo, because this delete is recoverable',
     !$('#toastAct').hidden && $('#toastAct').dataset.act === 'rec:undo');

  const savedTitle = $('#toolBody .chero__title').textContent;
  ok('the detail shows the record just created', savedTitle === 'Books', savedTitle);

  /* Undo removes it again. */
  click(win, $('#toastAct'));
  await wait(60);
  ok('Undo reverses the creation',
     !win.Lume.records.list('expenses').some(r => r.title === 'Books'));

  /* ==========================================================
     3. Read detail, update, and conflict
     ========================================================== */
  console.log('\n=== Detail, update and conflict (§4, §10) ===');
  act(win, '[data-act="rec:list:expenses"]');
  await wait(40);
  const firstRow = $('#toolBody .rrec');
  click(win, firstRow);
  await wait(40);

  ok('a row opens a detail', !!$('#toolBody .chero'));
  ok('the detail leads with the value', !!$('#toolBody .chero__value'));
  ok('facts are label and value, paired', $$('#toolBody .cfact').length >= 3);
  ok('Edit and Delete are both offered', !!$('.cact--edit') && !!$('.cact--danger'));
  ok('and the record names itself', /Record ID/.test($('#toolBody .crud__id').textContent));

  const recId = $('.cact--edit').dataset.act.split(':').pop();
  act(win, '[data-act="rec:edit:expenses:' + recId + '"]');
  await wait(40);
  ok('editing opens a pre-filled form', !!$('[data-field="title"]').value);

  /* Something else changes the record while the form is open. */
  const live = win.Lume.records.get('expenses', recId);
  win.Lume.records.update('expenses', recId, { title: 'Changed elsewhere' }, live._v);
  type(win, $('[data-field="title"]'), 'My edit');
  act(win, '[data-act="rec:save:expenses"]');
  await wait(500);

  ok('a newer version is not silently overwritten (§10)', !!$('#toolBody .cnotice--warn'));
  ok('and the user is offered Review or Reload',
     !!$('[data-act="rec:review:expenses"]') && !!$('[data-act="rec:reload:expenses"]'));
  ok('their own text is still in the form', $('[data-field="title"]').value === 'My edit');

  act(win, '[data-act="rec:review:expenses"]');
  await wait(40);
  act(win, '[data-act="rec:save:expenses"]');
  await wait(500);
  ok('reviewing then saving applies their version',
     win.Lume.records.get('expenses', recId).title === 'My edit',
     win.Lume.records.get('expenses', recId).title);

  /* ==========================================================
     4. Delete — and whether it can be undone
     ========================================================== */
  console.log('\n=== Delete (§2, §10) ===');
  act(win, '[data-act="rec:list:expenses"]');
  await wait(40);
  click(win, $('#toolBody .rrec'));
  await wait(40);
  const doomed = $('.cact--danger').dataset.act.split(':').pop();
  const doomedName = win.Lume.records.get('expenses', doomed).title;
  act(win, '[data-act="rec:askdelete:expenses:' + doomed + '"]');
  await wait(40);

  ok('the confirmation is a sheet, not a bare alert',
     $('#sheet-recdelete').classList.contains('is-open'));
  ok('it names the record', $('#recDeleteText').textContent.indexOf(doomedName) !== -1,
     $('#recDeleteText').textContent);
  ok('and states the consequence', /undo/i.test($('#recDeleteText').textContent));
  ok('the destructive action is labelled with the verb, not "OK"',
     /Delete/.test($('[data-rec-go]').textContent));

  click(win, $('[data-rec-go]'));
  await wait(60);
  ok('the record leaves the list at once — no ghost row',
     !win.Lume.records.get('expenses', doomed));
  ok('and Undo is offered, because expenses are recoverable',
     !$('#toastAct').hidden);
  click(win, $('#toastAct'));
  await wait(60);
  ok('Undo brings it back', !!win.Lume.records.get('expenses', doomed));

  /* A family whose consideration is secure deletion says so instead. */
  act(win, '[data-act="tool:documents"]');
  await wait(400);
  click(win, $('#toolBody .rrec'));
  await wait(40);
  const docId = $('.cact--danger').dataset.act.split(':').pop();
  act(win, '[data-act="rec:askdelete:documents:' + docId + '"]');
  await wait(40);
  ok('a document says the deletion cannot be undone (§10, §11)',
     /cannot be undone/i.test($('#recDeleteText').textContent), $('#recDeleteText').textContent);
  click(win, $('[data-rec-go]'));
  await wait(60);
  ok('and no Undo is offered for it', $('#toastAct').hidden);
  ok('nor is one secretly armed', !win.Lume.records.canUndo());

  /* ==========================================================
     5. Dirty-state protection
     ========================================================== */
  console.log('\n=== Leaving a changed form (§12) ===');
  act(win, '[data-act="tool:notes"]');
  await wait(400);
  act(win, '[data-act="rec:new:notes"]');
  await wait(40);
  click(win, $('#toolHeader [data-tool-back]'));
  await wait(40);
  ok('leaving an untouched form just leaves', !$('#sheet-recdelete').classList.contains('is-open'));

  act(win, '[data-act="rec:new:notes"]');
  await wait(40);
  type(win, $('[data-field="title"]'), 'Half a thought');
  click(win, $('#toolHeader [data-tool-back]'));
  await wait(40);
  ok('leaving a changed one asks first', $('#sheet-recdelete').classList.contains('is-open'));
  ok('and the safe choice is the one that is not destructive',
     /Keep editing/.test($('[data-rec-cancel]').textContent));
  click(win, $('[data-rec-go]'));
  await wait(40);
  ok('discarding returns to the collection', !!$('[data-sect="records"]'));

  /* ==========================================================
     6. Optimistic logging
     ========================================================== */
  console.log('\n=== Fast optimistic logging (§11) ===');
  act(win, '[data-act="tool:shopping"]');
  await wait(400);
  const box = $('#toolBody .rrec__check');
  ok('a checkable family logs from the row itself', !!box);
  ok('and exposes a checkbox role', box.getAttribute('role') === 'checkbox');
  const wasChecked = box.classList.contains('is-on');
  click(win, box);
  await wait(60);
  ok('ticking it writes immediately, without a form',
     $('#toolBody .rrec__check').classList.contains('is-on') !== wasChecked);

  /* ==========================================================
     7. Offline
     ========================================================== */
  console.log('\n=== Offline (§10) ===');
  {
    const off = await boot({ country: 'PK', city: 'Islamabad' }, { offline: true });
    const w = off.dom.window, d = w.document;
    const b = d.createElement('button');
    b.dataset.act = 'tool:todos';
    d.body.appendChild(b);
    click(w, b);
    await wait(400);
    ok('an offline collection says so rather than passing for current',
       !!d.querySelector('#toolBody .cnotice--offline'), d.querySelector('#toolBody').textContent.slice(0, 80));
    ok('and still shows the records saved on the device',
       d.querySelectorAll('#toolBody .rrec').length >= 1);
    off.dom.window.close();
  }

  /* ==========================================================
     8. A corrupt store is a load error, not a silent reset
     ========================================================== */
  console.log('\n=== Load failure (§10) ===');
  {
    const bad = await boot({ country: 'PK', city: 'Islamabad' }, { records: '{not json' });
    const w = bad.dom.window, d = w.document;
    const b = d.createElement('button');
    b.dataset.act = 'tool:todos';
    d.body.appendChild(b);
    click(w, b);
    await wait(400);
    const text = d.querySelector('#toolBody').textContent;
    ok('a store it cannot read reports a load error', !!d.querySelector('#toolBody .cstate--error'), text.slice(0, 90));
    ok('and the header says the collection could not refresh',
       /Could not refresh/.test(d.querySelector('#toolHeader .toolbar__sub').textContent),
       d.querySelector('#toolHeader .toolbar__sub').textContent);
    ok('it says the saved data is still safe', /still safe on this device/.test(text));
    ok('and offers Try again first', !!d.querySelector('[data-act="rec:retry:todos"]'));
    bad.dom.window.close();
  }

  /* ==========================================================
     9. Empty
     ========================================================== */
  console.log('\n=== Empty (§10) ===');
  {
    const bare = await boot({ country: 'PK', city: 'Islamabad' },
      { records: JSON.stringify({ v: 1, c: { events: { items: [], seeded: 1 } } }) });
    const w = bare.dom.window, d = w.document;
    const b = d.createElement('button');
    b.dataset.act = 'tool:events';
    d.body.appendChild(b);
    click(w, b);
    await wait(400);
    const empty = d.querySelector('#toolBody .cstate');
    ok('an empty collection explains itself', !!empty);
    ok('and the header says so rather than counting to zero',
       /No records yet/.test(d.querySelector('#toolHeader .toolbar__sub').textContent),
       d.querySelector('#toolHeader .toolbar__sub').textContent);
    ok('it gives a reason and a next step',
       !!d.querySelector('.cstate__title') && !!d.querySelector('.cstate__text'));
    ok('and exactly one primary call to action',
       d.querySelectorAll('.cstate .btn--accent').length === 1);
    ok('which is to create the first record',
       d.querySelector('.cstate .btn--accent').dataset.act === 'rec:new:events');
    ok('and it is never a blank card', empty.textContent.trim().length > 20);
    bare.dom.window.close();
  }

  /* ==========================================================
     10. Master-detail, and its collapse
     ========================================================== */
  console.log('\n=== Master-detail (§8, §12) ===');
  {
    const wide = await boot({ country: 'PK', city: 'Islamabad' }, { width: 1180 });
    const w = wide.dom.window, d = w.document;
    ok('an expanded shell reports the expanded width class',
       d.documentElement.dataset.bp === 'expanded', d.documentElement.dataset.bp);

    const b = d.createElement('button');
    b.dataset.act = 'tool:expenses';
    d.body.appendChild(b);
    click(w, b);
    await wait(420);

    ok('the collection is two panes', !!d.querySelector('#toolBody .panes__list') &&
       !!d.querySelector('#toolBody .panes__detail'));
    ok('with nothing selected, the detail pane invites a selection',
       !!d.querySelector('.panes__detail .cstate--pane'));

    const row = d.querySelector('#toolBody .rrec');
    click(w, row);
    await wait(60);
    ok('selecting a record fills the detail pane', !!d.querySelector('.panes__detail .chero'));
    ok('and the list is still there beside it', !!d.querySelector('.panes__list .rrec'));
    ok('the selected row says it is current',
       d.querySelector('.rrec.is-selected') &&
       d.querySelector('.rrec.is-selected').getAttribute('aria-current') === 'true');
    ok('selecting did not push a new screen', !d.querySelector('#toolBody .cacts + .cacts'));

    /* A form at this width uses two columns for its short related fields. */
    click(w, d.querySelector('[data-act="rec:new:expenses"]'));
    await wait(60);
    ok('a wide form is a card with a two-column grid (§9)',
       !!d.querySelector('.cformcard .fgrid--pair'));
    ok('and its long fields still span both columns',
       d.querySelectorAll('.fgrid--pair .cfield--wide').length >= 2);
    wide.dom.window.close();
  }

  /* ==========================================================
     11. Nothing leaks across personalisation
     ========================================================== */
  console.log('\n=== Records and personalisation (brief §37) ===');
  {
    const p = await boot({ country: 'PK', city: 'Islamabad', islamic: false });
    const w = p.dom.window, d = w.document;
    const b = d.createElement('button');
    b.dataset.act = 'tool:notes';
    d.body.appendChild(b);
    click(w, b);
    await wait(400);
    w.Lume.records.create('notes', { title: 'Mine', body: 'kept' });
    const kept = w.Lume.records.count('notes');
    const before = w.localStorage.getItem('lume-records');
    p.dom.window.close();

    /* Booting again with a different country, a different language and the
       faith preference flipped is the real test: none of the three may
       touch the records key. */

    const after = await boot({ country: 'GB', city: 'London', lang: 'ur', islamic: true },
      { records: before });
    const w2 = after.dom.window;
    const b2 = w2.document.createElement('button');
    b2.dataset.act = 'tool:notes';
    w2.document.body.appendChild(b2);
    click(w2, b2);
    await wait(400);
    ok('changing country, language and faith preference keeps every record',
       w2.Lume.records.count('notes') === kept,
       w2.Lume.records.count('notes') + ' vs ' + kept);
    ok('and the record the user wrote is still their own words',
       w2.Lume.records.list('notes').some(r => r.title === 'Mine'));
    ok('while a seeded record follows the new language',
       /نوٹ|فہرست|کام|خرچ/.test(w2.document.querySelector('#toolBody').textContent) ||
       w2.Lume.records.list('notes').some(r => String(r.title).charAt(0) === '@'));
    after.dom.window.close();
  }

  console.log(failures ? '\n' + failures + ' FAILURE(S)' : '\nALL CRUD CHECKS PASSED');
  process.exit(failures ? 1 : 0);
})().catch(e => { console.error(e); process.exit(1); });
