// Đọc image_results.csv -> ghi imageUrl + images vào Firestore products/<id>.
// Doc không tồn tại / lỗi -> BỎ QUA, không dừng.
//
// CẦN: Firebase service account.
//   GOOGLE_APPLICATION_CREDENTIALS=/path/key.json node push-firestore.js
//
// CHẠY:
//   cd tool/icecat-sync
//   GOOGLE_APPLICATION_CREDENTIALS=./key.json node push-firestore.js

const fs = require('fs');
const path = require('path');
const { initializeApp, cert } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');

const ROOT = path.resolve(__dirname, '..', '..');
const fbCfg = JSON.parse(fs.readFileSync(path.join(ROOT, 'assets/config/firebase_config.json'), 'utf8'));
const SERVICE_ACCOUNT_PATH = process.env.GOOGLE_APPLICATION_CREDENTIALS || '';
const FIREBASE_PROJECT_ID = fbCfg.FIREBASE_PROJECT_ID || '';
const IN = process.argv[2] || path.join(__dirname, 'image_results.csv');
const PRODUCTS = 'products';

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

async function main() {
  if (!SERVICE_ACCOUNT_PATH) {
    throw new Error('Chưa có service account. Đặt GOOGLE_APPLICATION_CREDENTIALS trỏ tới file key.json.');
  }
  initializeApp({
    credential: cert(require(path.resolve(SERVICE_ACCOUNT_PATH))),
    projectId: FIREBASE_PROJECT_ID || undefined,
  });
  const db = getFirestore();

  const rows = parseCsv(fs.readFileSync(IN, 'utf8'));
  const header = rows.shift();
  const idC = header.indexOf('id'), urlC = header.indexOf('imageUrl'), imgsC = header.indexOf('images');
  console.log(`${rows.length} dòng có ảnh -> Firestore`);

  let ok = 0, fail = 0;
  for (const r of rows) {
    const id = r[idC];
    if (!id) continue;
    const imageUrl = r[urlC] || '';
    const images = (r[imgsC] || '').split('|').filter(Boolean);
    if (!imageUrl) continue;
    try {
      await db.collection(PRODUCTS).doc(id).update({ imageUrl, images });
      console.log(`✓ ${id}: ${images.length} ảnh`);
      ok++;
    } catch (e) {
      console.log(`✗ ${id}: ${e.message}`); // doc thiếu / lỗi -> bỏ qua
      fail++;
    }
  }
  console.log(`🎉 Cập nhật ${ok} · lỗi ${fail}`);
}

main().then(() => process.exit(0)).catch((e) => { console.error('❌', e.message); process.exit(1); });
