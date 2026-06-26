// Đọc mpn_results.csv -> lấy ảnh Icecat theo MPN -> upload Cloudinary.
// Ảnh / sản phẩm lỗi (Icecat miss, upload fail) -> BỎ QUA, không dừng.
// Kết quả ghi ra image_results.csv (id,imageUrl,images) — có thể resume.
//
// CHẠY:
//   cd tool/icecat-sync
//   node from-csv.js                 # đọc ../../mpn_results.csv
//   node from-csv.js path/to.csv     # CSV khác
//   LIMIT=5 node from-csv.js         # chỉ xử lý 5 dòng đầu (test)

const fs = require('fs');
const path = require('path');
const Icecat = require('icecat');
const cloudinary = require('cloudinary').v2;

const ROOT = path.resolve(__dirname, '..', '..');
const icecatCfg = JSON.parse(fs.readFileSync(path.join(ROOT, 'assets/config/icecat_config.json'), 'utf8'));
const fbCfg = JSON.parse(fs.readFileSync(path.join(ROOT, 'assets/config/firebase_config.json'), 'utf8'));
const CLOUD = process.env.CLOUDINARY_CLOUD_NAME || fbCfg.CLOUDINARY_CLOUD_NAME;
const PRESET = process.env.CLOUDINARY_UPLOAD_PRESET || fbCfg.CLOUDINARY_UPLOAD_PRESET;
const LANG = 'EN';
const MAX_IMAGES = 5;
const LIMIT = parseInt(process.env.LIMIT || '0', 10); // 0 = tất cả

cloudinary.config({ cloud_name: CLOUD });
const icecat = new Icecat(icecatCfg.ICECAT_USERNAME, icecatCfg.ICECAT_PASSWORD);

const IN = process.argv[2] || path.join(ROOT, 'mpn_results.csv');
const OUT = path.join(__dirname, 'image_results.csv');

// CSV tối thiểu, đủ xử lý field có dấu nháy/đấu phẩy.
function parseCsv(text) {
  const rows = [];
  let row = [], field = '', q = false;
  for (let i = 0; i < text.length; i++) {
    const c = text[i];
    if (q) {
      if (c === '"' && text[i + 1] === '"') { field += '"'; i++; }
      else if (c === '"') q = false;
      else field += c;
    } else if (c === '"') q = true;
    else if (c === ',') { row.push(field); field = ''; }
    else if (c === '\n') { row.push(field); rows.push(row); row = []; field = ''; }
    else if (c !== '\r') field += c;
  }
  if (field.length || row.length) { row.push(field); rows.push(row); }
  return rows;
}

function csvCell(s) {
  s = (s ?? '').toString();
  return /[",\n]/.test(s) ? '"' + s.replace(/"/g, '""') + '"' : s;
}

// URL ảnh Icecat (ảnh chính trước), [] nếu miss/lỗi.
async function icecatImages(brand, code) {
  let product;
  try { product = await icecat.openCatalog.getProductBySKU(LANG, brand, code); }
  catch { return []; }
  const imgs = product.getImages() || [];
  const urls = imgs
    .sort((a, b) => (b.IsMain === 'Y' ? 1 : 0) - (a.IsMain === 'Y' ? 1 : 0))
    .map((i) => i.HighImg).filter(Boolean);
  return [...new Set(urls)].slice(0, MAX_IMAGES);
}

async function uploadToCloudinary(imageUrl, id) {
  const res = await cloudinary.uploader.unsigned_upload(imageUrl, PRESET, { folder: `products/${id}` });
  return res.secure_url;
}

async function main() {
  if (!CLOUD || !PRESET) throw new Error('Thiếu Cloudinary cloud name / preset.');
  const rows = parseCsv(fs.readFileSync(IN, 'utf8'));
  const header = rows.shift();
  const idC = header.indexOf('id'), brandC = header.indexOf('brand'), mpnC = header.indexOf('mpn');
  if (idC < 0 || mpnC < 0) throw new Error('CSV thiếu cột id / mpn.');

  // resume: bỏ qua id đã có trong OUT.
  const done = new Set();
  if (fs.existsSync(OUT)) {
    for (const r of parseCsv(fs.readFileSync(OUT, 'utf8')).slice(1)) if (r[0]) done.add(r[0]);
  } else {
    fs.writeFileSync(OUT, 'id,imageUrl,images\n');
  }

  console.log(`Icecat ${icecatCfg.ICECAT_USERNAME} | Cloudinary ${CLOUD} | ${rows.length} dòng`);
  let ok = 0, miss = 0, skip = 0, n = 0;
  for (const r of rows) {
    if (LIMIT && n >= LIMIT) break;
    n++;
    const id = r[idC], brand = (r[brandC] || '').trim(), mpn = (r[mpnC] || '').trim();
    if (!id) continue;
    if (done.has(id)) { skip++; continue; }
    if (!mpn) { console.log(`✗ ${id}: không có mpn`); miss++; continue; }

    const urls = [];
    for (const img of await icecatImages(brand, mpn)) {
      try { urls.push(await uploadToCloudinary(img, id)); }
      catch { /* ảnh lỗi -> để lại, bỏ qua */ }
    }

    if (!urls.length) { console.log(`✗ ${id} [${mpn}]: không khớp / lỗi`); miss++; continue; }
    fs.appendFileSync(OUT, [id, urls[0], urls.join('|')].map(csvCell).join(',') + '\n');
    console.log(`✓ ${id} [${mpn}]: ${urls.length} ảnh`);
    ok++;
  }
  console.log(`🎉 OK ${ok} · MISS ${miss} · bỏ qua ${skip} -> ${OUT}`);
}

main().then(() => process.exit(0)).catch((e) => { console.error('❌', e.message); process.exit(1); });
