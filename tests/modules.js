/* ============================================================
   Lume — ES module graph loader for the test harness

   jsdom cannot execute <script type="module">. It has no module
   loader at all, and `window.eval` of source containing `import`
   is a syntax error. So the harness resolves the graph itself:
   it reads each module from disk, orders it after everything it
   imports, rewrites the import/export syntax into a tiny
   registry, and hands jsdom one ordinary script.

   This is a bundler, and it is honest about what that costs:

     · The graph MUST be acyclic. Imports are destructured at
       module-evaluation time, so a cycle would read an
       undefined binding instead of a live one. tests/modules.js
       throws on a cycle rather than producing a bundle that
       half-works, and tests/architecture.js asserts the same
       thing against the real source as a first-class rule.
     · Only the syntax Lume actually writes is supported. An
       unrecognised import/export form throws by name rather
       than being silently dropped.
     · The browser does NOT use this. It loads the same files
       natively over HTTP. tests/architecture.js walks the graph
       over a real HTTP server so a specifier that resolves here
       but 404s there cannot pass.
   ============================================================ */
const fs = require('fs');
const path = require('path');

/* Strings and comments must not be scanned for import/export, or a
   translation containing the word "export" would rewrite itself. This
   walks the source once and reports which byte offsets are code. */
function codeMask(src) {
  const mask = new Uint8Array(src.length); // 1 = code
  let i = 0;
  const n = src.length;
  while (i < n) {
    const c = src[i];
    if (c === '/' && src[i + 1] === '/') {
      while (i < n && src[i] !== '\n') i++;
      continue;
    }
    if (c === '/' && src[i + 1] === '*') {
      i += 2;
      while (i < n && !(src[i] === '*' && src[i + 1] === '/')) i++;
      i += 2;
      continue;
    }
    if (c === '"' || c === "'" || c === '`') {
      const quote = c;
      i++;
      while (i < n) {
        if (src[i] === '\\') { i += 2; continue; }
        if (src[i] === quote) { i++; break; }
        i++;
      }
      continue;
    }
    mask[i] = 1;
    i++;
  }
  return mask;
}

/* A regex match only counts when its first character is code. */
function codeMatches(src, re) {
  const mask = codeMask(src);
  const out = [];
  let m;
  re.lastIndex = 0;
  while ((m = re.exec(src))) {
    if (mask[m.index]) out.push(m);
    if (m[0].length === 0) re.lastIndex++;
  }
  return out;
}

/* The clause and the specifier must not cross a newline. Allowing them to
   let the word "import" in a doc comment match across the comment's own
   terminator and swallow the real import statement below it — and because
   the match then started inside a comment, codeMatches discarded the whole
   thing, so the import silently survived into the bundle. */
const IMPORT_RE = /^[ \t]*import\s+(?:([^'"\n]+?)[ \t]+from[ \t]+)?(['"])([^'"\n]+)\2[ \t]*;?[ \t]*$/gm;
const EXPORT_DECL_RE = /^[ \t]*export\s+(?=(?:async\s+)?(?:function|const|let|var|class)\b)/gm;
const EXPORT_LIST_RE = /^[ \t]*export\s*\{([^}]*)\}\s*;?[ \t]*$/gm;
const EXPORT_DEFAULT_RE = /^[ \t]*export\s+default\s+/gm;
const EXPORT_FROM_RE = /^[ \t]*export\s+(?:\*|\{[^}]*\})\s+from\s+/gm;

/* Names a declaration introduces, so `export const {a, b} = x` and
   `export function f` both report what they added. */
function declaredNames(afterExport) {
  const kind = afterExport.match(/^(?:async\s+)?(function\*?|const|let|var|class)\s+/);
  if (!kind) return [];
  const rest = afterExport.slice(kind[0].length);
  if (/^(?:function|class)/.test(kind[1]) || kind[1].startsWith('function')) {
    const id = rest.match(/^([A-Za-z_$][\w$]*)/);
    return id ? [id[1]] : [];
  }
  // const/let/var — may be a destructuring pattern or a comma list.
  const upToInit = rest.split('=')[0];
  return (upToInit.match(/[A-Za-z_$][\w$]*/g) || []).filter(
    (name, idx, all) => all.indexOf(name) === idx
  );
}

function importReplacement(clause, key) {
  const ref = `__lumeRequire(${JSON.stringify(key)})`;
  if (!clause) return `/* side-effect import */ ${ref};`;
  if (/^\*\s+as\s+/.test(clause)) {
    return `const ${clause.replace(/^\*\s+as\s+/, '').trim()} = ${ref};`;
  }
  const named = clause.match(/^\{([\s\S]*)\}$/);
  const mixed = clause.match(/^([A-Za-z_$][\w$]*)\s*,\s*\{([\s\S]*)\}$/);
  const list = body =>
    body
      .split(',')
      .map(s => s.trim())
      .filter(Boolean)
      .map(s => s.replace(/\s+as\s+/, ': '))
      .join(', ');

  if (named) return `const { ${list(named[1])} } = ${ref};`;
  if (mixed) return `const ${mixed[1]} = ${ref}.default, { ${list(mixed[2])} } = ${ref};`;
  if (/^[A-Za-z_$][\w$]*$/.test(clause)) return `const ${clause} = ${ref}.default;`;
  throw new Error('unsupported import clause: ' + clause);
}

function transform(src, specToKey) {
  if (codeMatches(src, EXPORT_FROM_RE).length) {
    throw new Error('re-export syntax (export ... from) is not supported by the harness loader');
  }

  const additions = [];
  /* Every rewrite is recorded as a span, then applied back-to-front so that
     an earlier edit never shifts a later one's offsets. */
  const edits = [];

  for (const m of codeMatches(src, IMPORT_RE)) {
    edits.push({
      start: m.index,
      end: m.index + m[0].length,
      text: importReplacement((m[1] || '').trim(), specToKey(m[3]))
    });
  }

  for (const m of codeMatches(src, EXPORT_LIST_RE)) {
    m[1]
      .split(',')
      .map(s => s.trim())
      .filter(Boolean)
      .forEach(entry => {
        const parts = entry.split(/\s+as\s+/).map(s => s.trim());
        additions.push(`__lumeExports[${JSON.stringify(parts[1] || parts[0])}] = ${parts[0]};`);
      });
    edits.push({ start: m.index, end: m.index + m[0].length, text: '' });
  }

  for (const m of codeMatches(src, EXPORT_DEFAULT_RE)) {
    additions.push('__lumeExports["default"] = __lumeDefault;');
    edits.push({ start: m.index, end: m.index + m[0].length, text: 'const __lumeDefault = ' });
  }

  for (const m of codeMatches(src, EXPORT_DECL_RE)) {
    const names = declaredNames(src.slice(m.index + m[0].length));
    if (!names.length) {
      throw new Error('could not read exported name near: ' + src.slice(m.index, m.index + 60));
    }
    names.forEach(name => {
      additions.push(`__lumeExports[${JSON.stringify(name)}] = ${name};`);
    });
    /* Drop only the `export ` word, keeping the declaration and its
       leading indentation exactly where the author wrote it. */
    edits.push({ start: m.index, end: m.index + m[0].length, text: m[0].replace(/export\s+/, '') });
  }

  edits.sort((a, b) => b.start - a.start);
  let out = src;
  let previousStart = Infinity;
  for (const edit of edits) {
    if (edit.end > previousStart) throw new Error('overlapping rewrites in module source');
    out = out.slice(0, edit.start) + edit.text + out.slice(edit.end);
    previousStart = edit.start;
  }

  /* Nothing may reach the bundle still spelt as a module. A surviving
     keyword means a form this loader does not understand, and it must say
     so rather than emit a script the browser will reject at parse time. */
  const leftover = codeMatches(out, /^[ \t]*(?:export|import)\b/gm);
  if (leftover.length) {
    throw new Error('unhandled module syntax near: ' + out.slice(leftover[0].index, leftover[0].index + 80));
  }

  return out + '\n' + additions.join('\n') + '\n';
}

/* Resolve a specifier relative to the importing module, as a repo path. */
function resolveSpec(fromKey, spec, root) {
  if (!spec.startsWith('.')) throw new Error('bare specifier not supported: ' + spec);
  const abs = path.resolve(path.dirname(path.join(root, fromKey)), spec);
  return path.relative(root, abs).split(path.sep).join('/');
}

/* Walks the graph from an entry, depth-first, and returns modules in
   evaluation order. Throws on a cycle, naming the loop. */
function order(entryKey, root) {
  const seen = new Map(); // key -> 'visiting' | 'done'
  const out = [];
  const stack = [];

  function visit(key) {
    const state = seen.get(key);
    if (state === 'done') return;
    if (state === 'visiting') {
      const loop = stack.slice(stack.indexOf(key)).concat(key).join(' -> ');
      throw new Error('import cycle: ' + loop);
    }
    const file = path.join(root, key);
    if (!fs.existsSync(file)) throw new Error('module not found: ' + key);
    seen.set(key, 'visiting');
    stack.push(key);
    const src = fs.readFileSync(file, 'utf8');
    for (const m of codeMatches(src, IMPORT_RE)) {
      visit(resolveSpec(key, m[3], root));
    }
    stack.pop();
    seen.set(key, 'done');
    out.push(key);
  }

  visit(entryKey);
  return out;
}

/* Produce one classic script that defines and runs the whole graph. */
function bundle(entryKey, root) {
  const keys = order(entryKey, root);
  const parts = keys.map(key => {
    const src = fs.readFileSync(path.join(root, key), 'utf8');
    const body = transform(src, spec => resolveSpec(key, spec, root));
    return (
      `__lumeDefine(${JSON.stringify(key)}, function (__lumeExports, __lumeRequire) {\n` +
      `"use strict";\n${body}\n});`
    );
  });

  return (
    '(function () {\n' +
    'var __lumeModules = Object.create(null);\n' +
    'var __lumeCache = Object.create(null);\n' +
    'function __lumeDefine(key, fn) { __lumeModules[key] = fn; }\n' +
    'function __lumeRequire(key) {\n' +
    '  if (__lumeCache[key]) return __lumeCache[key];\n' +
    '  var fn = __lumeModules[key];\n' +
    '  if (!fn) throw new Error("module not registered: " + key);\n' +
    '  var exports = __lumeCache[key] = {};\n' +
    '  fn(exports, __lumeRequire);\n' +
    '  return exports;\n' +
    '}\n' +
    parts.join('\n') +
    `\n__lumeRequire(${JSON.stringify(entryKey)});\n` +
    '})();'
  );
}

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
