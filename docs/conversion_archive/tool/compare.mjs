/* Compare a web capture against its Flutter counterpart.
 *
 * TEMPORARY CONVERSION TOOLING. Deleted with the prototype at Phase F9.
 *
 *   node docs/conversion_archive/tool/compare.mjs \
 *     --cell docs/conversion_archive/shots/home/home_390x844_light_en
 *
 * Reads `<cell>.web.png` / `.web.json` and `<cell>.flutter.png` / `.flutter.json`
 * and writes `<cell>.side.png`, `<cell>.diff.png` and `<cell>.report.md`.
 *
 * A per-pixel diff over anti-aliased text produces noise on every edge, so the
 * report separates the two populations: pixels that differ by a little (which
 * is rasterisation, and permitted) from pixels that differ by a lot (which is
 * a different layout, and is not).
 *
 * No dependencies — PNG is a chunked format over zlib, and Node has zlib.
 */
import { readFileSync, writeFileSync, existsSync } from 'node:fs';
import { deflateSync, inflateSync } from 'node:zlib';

const argv = process.argv.slice(2);
const args = {};
for (let i = 0; i < argv.length; i++) {
  if (argv[i].startsWith('--')) args[argv[i].slice(2)] = argv[i + 1];
}

const CELL = args.cell;
if (!CELL) {
  process.stderr.write('usage: compare.mjs --cell <path without extension>\n');
  process.exit(2);
}

/* ---- PNG ---------------------------------------------------------------- */

const CRC = (() => {
  const t = new Int32Array(256);
  for (let n = 0; n < 256; n++) {
    let c = n;
    for (let k = 0; k < 8; k++) c = c & 1 ? 0xedb88320 ^ (c >>> 1) : c >>> 1;
    t[n] = c;
  }
  return (buf) => {
    let c = -1;
    for (let i = 0; i < buf.length; i++) c = t[(c ^ buf[i]) & 0xff] ^ (c >>> 8);
    return (c ^ -1) >>> 0;
  };
})();

/** Decode an 8-bit RGB or RGBA PNG into { width, height, rgba }. */
function decodePng(buf) {
  let p = 8; // skip signature
  let ihdr = null;
  const idat = [];
  while (p < buf.length) {
    const len = buf.readUInt32BE(p);
    const type = buf.toString('latin1', p + 4, p + 8);
    const data = buf.subarray(p + 8, p + 8 + len);
    if (type === 'IHDR') {
      ihdr = {
        width: data.readUInt32BE(0),
        height: data.readUInt32BE(4),
        depth: data[8],
        colour: data[9],
        interlace: data[12],
      };
    } else if (type === 'IDAT') {
      idat.push(data);
    } else if (type === 'IEND') {
      break;
    }
    p += 12 + len;
  }
  if (!ihdr) throw new Error('no IHDR');
  if (ihdr.depth !== 8) throw new Error(`unsupported bit depth ${ihdr.depth}`);
  if (ihdr.interlace) throw new Error('interlaced PNG not supported');

  const channels = ihdr.colour === 6 ? 4 : ihdr.colour === 2 ? 3 : null;
  if (!channels) throw new Error(`unsupported colour type ${ihdr.colour}`);

  const raw = inflateSync(Buffer.concat(idat));
  const { width, height } = ihdr;
  const stride = width * channels;
  const out = Buffer.alloc(width * height * 4);
  let prev = Buffer.alloc(stride);

  for (let y = 0; y < height; y++) {
    const filter = raw[y * (stride + 1)];
    const line = Buffer.from(
      raw.subarray(y * (stride + 1) + 1, y * (stride + 1) + 1 + stride),
    );
    for (let x = 0; x < stride; x++) {
      const a = x >= channels ? line[x - channels] : 0;
      const b = prev[x];
      const c = x >= channels ? prev[x - channels] : 0;
      switch (filter) {
        case 1: line[x] = (line[x] + a) & 0xff; break;
        case 2: line[x] = (line[x] + b) & 0xff; break;
        case 3: line[x] = (line[x] + ((a + b) >> 1)) & 0xff; break;
        case 4: {
          const pp = a + b - c;
          const pa = Math.abs(pp - a);
          const pb = Math.abs(pp - b);
          const pc = Math.abs(pp - c);
          const pr = pa <= pb && pa <= pc ? a : pb <= pc ? b : c;
          line[x] = (line[x] + pr) & 0xff;
          break;
        }
        default: break;
      }
    }
    for (let x = 0; x < width; x++) {
      const s = x * channels;
      const d = (y * width + x) * 4;
      out[d] = line[s];
      out[d + 1] = line[s + 1];
      out[d + 2] = line[s + 2];
      out[d + 3] = channels === 4 ? line[s + 3] : 255;
    }
    prev = line;
  }
  return { width, height, rgba: out };
}

/** Encode { width, height, rgba } as an 8-bit RGBA PNG. */
function encodePng({ width, height, rgba }) {
  const stride = width * 4;
  const raw = Buffer.alloc((stride + 1) * height);
  for (let y = 0; y < height; y++) {
    raw[y * (stride + 1)] = 0; // filter: none
    rgba.copy(raw, y * (stride + 1) + 1, y * stride, (y + 1) * stride);
  }
  const chunk = (type, data) => {
    const len = Buffer.alloc(4);
    len.writeUInt32BE(data.length);
    const body = Buffer.concat([Buffer.from(type, 'latin1'), data]);
    const crc = Buffer.alloc(4);
    crc.writeUInt32BE(CRC(body));
    return Buffer.concat([len, body, crc]);
  };
  const ihdr = Buffer.alloc(13);
  ihdr.writeUInt32BE(width, 0);
  ihdr.writeUInt32BE(height, 4);
  ihdr[8] = 8;
  ihdr[9] = 6;
  return Buffer.concat([
    Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]),
    chunk('IHDR', ihdr),
    chunk('IDAT', deflateSync(raw, { level: 9 })),
    chunk('IEND', Buffer.alloc(0)),
  ]);
}

/* ---- comparison --------------------------------------------------------- */

const webPng = `${CELL}.web.png`;
const flutterPng = `${CELL}.flutter.png`;
for (const f of [webPng, flutterPng]) {
  if (!existsSync(f)) {
    process.stderr.write(`missing ${f}\n`);
    process.exit(1);
  }
}

const web = decodePng(readFileSync(webPng));
const flutter = decodePng(readFileSync(flutterPng));

const readJson = (p) =>
  existsSync(p) ? JSON.parse(readFileSync(p, 'utf8')) : null;
const webFacts = readJson(`${CELL}.web.json`);
const flutterFacts = readJson(`${CELL}.flutter.json`);

/** Anything at or below this per channel is rasterisation, which is permitted. */
const TOLERANCE = 8;

const w = Math.min(web.width, flutter.width);
const h = Math.min(web.height, flutter.height);

const diff = Buffer.alloc(w * h * 4);
let near = 0;
let far = 0;
for (let y = 0; y < h; y++) {
  for (let x = 0; x < w; x++) {
    const a = (y * web.width + x) * 4;
    const b = (y * flutter.width + x) * 4;
    const d = (y * w + x) * 4;
    const dr = Math.abs(web.rgba[a] - flutter.rgba[b]);
    const dg = Math.abs(web.rgba[a + 1] - flutter.rgba[b + 1]);
    const db = Math.abs(web.rgba[a + 2] - flutter.rgba[b + 2]);
    const worst = Math.max(dr, dg, db);
    if (worst === 0) {
      // Unchanged: keep it, dimmed, so the differences read against the layout.
      diff[d] = 255 - ((255 - web.rgba[a]) >> 2);
      diff[d + 1] = 255 - ((255 - web.rgba[a + 1]) >> 2);
      diff[d + 2] = 255 - ((255 - web.rgba[a + 2]) >> 2);
    } else if (worst <= TOLERANCE) {
      near++;
      diff[d] = 120; diff[d + 1] = 170; diff[d + 2] = 255; // blue: rasterisation
    } else {
      far++;
      diff[d] = 255; diff[d + 1] = 40; diff[d + 2] = 90; // red: a real difference
    }
    diff[d + 3] = 255;
  }
}

// Side by side, web on the left.
const gap = 16;
const sw = web.width + gap + flutter.width;
const sh = Math.max(web.height, flutter.height);
const side = Buffer.alloc(sw * sh * 4, 0xff);
const blit = (src, dx) => {
  for (let y = 0; y < src.height; y++) {
    for (let x = 0; x < src.width; x++) {
      const s = (y * src.width + x) * 4;
      const d = (y * sw + x + dx) * 4;
      side[d] = src.rgba[s];
      side[d + 1] = src.rgba[s + 1];
      side[d + 2] = src.rgba[s + 2];
      side[d + 3] = 255;
    }
  }
};
blit(web, 0);
blit(flutter, web.width + gap);

writeFileSync(`${CELL}.side.png`, encodePng({ width: sw, height: sh, rgba: side }));
writeFileSync(`${CELL}.diff.png`, encodePng({ width: w, height: h, rgba: diff }));

const total = w * h;
const pct = (n) => ((100 * n) / total).toFixed(3);
const sizesMatch = web.width === flutter.width && web.height === flutter.height;

const report = `# ${CELL.split(/[\\/]/).pop()}

| | web | Flutter |
|---|---|---|
| image | ${web.width} × ${web.height} | ${flutter.width} × ${flutter.height} |
| width class | ${webFacts?.measured?.dataBp ?? '—'} | ${flutterFacts?.measured?.widthClass ?? '—'} |
| direction | ${webFacts?.measured?.dir ?? '—'} | ${flutterFacts?.measured?.dir ?? '—'} |
| shell | ${webFacts?.measured?.shell ? `${Math.round(webFacts.measured.shell.width)} × ${Math.round(webFacts.measured.shell.height)}` : '—'} | ${flutterFacts?.measured?.shell ? `${Math.round(flutterFacts.measured.shell.width)} × ${Math.round(flutterFacts.measured.shell.height)}` : '—'} |

${sizesMatch ? '' : '**The two captures are different sizes.** Everything below compares only the overlapping region, so the numbers understate the difference.\n'}
| measure | pixels | share |
|---|---:|---:|
| identical | ${total - near - far} | ${pct(total - near - far)} % |
| within tolerance (≤ ${TOLERANCE}/255 — rasterisation) | ${near} | ${pct(near)} % |
| **beyond tolerance — a real difference** | **${far}** | **${pct(far)} %** |

${far === 0
  ? 'No pixel differs beyond anti-aliasing. This cell matches.'
  : `${far} pixels differ beyond anti-aliasing. Open \`${CELL.split(/[\\/]/).pop()}.diff.png\` — red is a real difference, blue is rasterisation.`}

Artifacts: \`.web.png\`, \`.flutter.png\`, \`.side.png\`, \`.diff.png\`.
`;

writeFileSync(`${CELL}.report.md`, report);

process.stdout.write(
  `${sizesMatch ? 'same size' : 'SIZE MISMATCH'} · ` +
  `${pct(far)} % beyond tolerance · ${pct(near)} % rasterisation\n`,
);
process.exit(far === 0 ? 0 : 1);
