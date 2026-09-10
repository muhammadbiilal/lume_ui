/* ============================================================
   Lume — Sheets

   A sheet is a temporary surface over whichever screen is
   showing, which is why it belongs to the shell rather than to
   any screen: the screen behind it may change while it is up,
   and it must survive that.

   Three things it gets right that a plain show/hide would not.
   While a modal sheet is up the screen behind it is hidden from
   assistive technology, so it is not somewhere to tab into —
   but only if the visibility system has not already hidden it,
   because restoring blindly would un-hide a gated screen.
   Focus starts inside the dialog rather than on whichever
   destructive button it happens to contain first. And closing
   returns focus to whatever opened it.
   ============================================================ */
import { $, $$ } from '../core/dom.js';

export function createSheets(deps) {
  const animateBars = deps.animateBars || function () {};
  const onOpen = deps.onOpen || function () {};

  const scrim = $('#scrim');
  let openSheet = null;
  /* What was focused before the sheet rose, and which screen was hidden
     from assistive technology while it is up. */
  let sheetOpener = null, sheetHid = null;

  function sheetOpen(name) {
    var sheet = $('#sheet-' + name);
    if (!sheet) return;
    if (openSheet && openSheet !== sheet) openSheet.classList.remove('is-open');
    sheet.classList.add('is-open');
    scrim.classList.add('is-open');
    openSheet = sheet;

    /* §101 — while a modal sheet is up, the screen behind it is not a place
       to tab into, and focus starts inside the dialog rather than on the
       destructive button it happens to contain first. */
    var behind = $('.screen.is-active');
    /* Only if the visibility system has not already hidden it for its own
       reasons — restoring blindly would un-hide a gated screen (§64). */
    if (behind && !behind.hasAttribute('aria-hidden')) {
      behind.setAttribute('aria-hidden', 'true');
      sheetHid = behind;
    }
    sheetOpener = document.activeElement;

    onOpen(name);
    animateBars(sheet);
    setTimeout(function () {
      var first = $('[data-close], .btn--ghost, button', sheet);
      if (first && first.focus) { try { first.focus(); } catch (e) {} }
    }, 60);
  }


  function sheetClose() {
    if (openSheet) openSheet.classList.remove('is-open');
    openSheet = null;
    scrim.classList.remove('is-open');
    if (sheetHid) { sheetHid.removeAttribute('aria-hidden'); sheetHid = null; }
    if (sheetOpener && sheetOpener.focus) { try { sheetOpener.focus(); } catch (e) {} }
    sheetOpener = null;
  }

  scrim.addEventListener('click', sheetClose);
  document.addEventListener('keydown', function (e) {
    if (e.key === 'Escape' && openSheet) sheetClose();
  });
  $$('[data-close]').forEach(function (b) { b.addEventListener('click', sheetClose); });

  /* Swipe a sheet down to dismiss */
  $$('.sheet').forEach(function (sheet) {
    var startY = 0, dy = 0, dragging = false;
    var handles = [$('.sheet__grab', sheet), $('.sheet__head', sheet)].filter(Boolean);

    function down(y) { startY = y; dy = 0; dragging = true; sheet.style.transition = 'none'; }
    function move(y) {
      if (!dragging) return;
      dy = Math.max(0, y - startY);
      sheet.style.transform = 'translateY(' + dy + 'px)';
    }
    function up() {
      if (!dragging) return;
      dragging = false;
      sheet.style.transition = '';
      sheet.style.transform = '';
      if (dy > 90) sheetClose();
    }

    handles.forEach(function (h) {
      h.style.touchAction = 'none';
      h.addEventListener('touchstart', function (e) { down(e.touches[0].clientY); }, { passive: true });
      h.addEventListener('touchmove',  function (e) { move(e.touches[0].clientY); }, { passive: true });
      h.addEventListener('touchend', up);
      h.addEventListener('mousedown', function (e) {
        if (e.target.closest('button, input')) return;
        down(e.clientY);
      });
    });
    document.addEventListener('mousemove', function (e) { move(e.clientY); });
    document.addEventListener('mouseup', up);
  });

  return {
    open: sheetOpen,
    close: sheetClose,
    /* Whether a sheet is up, for the handlers that must not act behind one. */
    current: function () { return openSheet; }
  };
}
