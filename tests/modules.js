/* ============================================================
   Lume — loading the app into jsdom

   jsdom cannot execute <script type="module">, so a module
   entry is bundled first by scripts/bundler.js and handed over
   as one ordinary script. Classic scripts, if any remain, are
   evaluated as they always were.
   ============================================================ */
const fs = require('fs');
const path = require('path');
const {
  bundle, order, transform, codeMatches, IMPORT_RE, resolveSpec
} = require('../scripts/bundler');

/* The one line every harness calls in place of its old script loop.
   Classic scripts are evaluated as before; a module entry is bundled
   from its graph first. Evaluation errors are collected rather than
   thrown, so a suite reports them the way it always has. */
function loadInto(dom, root, errors) {
  const collect = errors || [];
  const tags = [...dom.window.document.querySelectorAll('script[src]')];
  for (const tag of tags) {
    const src = tag.getAttribute('src');
    const isModule = (tag.getAttribute('type') || '').toLowerCase() === 'module';
    let code;
    try {
      code = isModule ? bundle(src, root) : fs.readFileSync(path.join(root, src), 'utf8');
    } catch (e) {
      collect.push('bundle ' + src + ': ' + e.message);
      continue;
    }
    try {
      dom.window.eval(code);
    } catch (e) {
      collect.push(
        'script ' + src + ': ' + e.message + '\n' + (e.stack || '').split('\n').slice(0, 4).join('\n')
      );
    }
  }
  return collect;
}

module.exports = { bundle, order, transform, codeMatches, IMPORT_RE, resolveSpec, loadInto };
