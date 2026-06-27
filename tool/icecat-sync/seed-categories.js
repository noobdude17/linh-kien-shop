// Cập nhật icon emoji cho categories trong Firestore.
// CHẠY:
//   cd tool/icecat-sync
//   GOOGLE_APPLICATION_CREDENTIALS=./key.json node seed-categories.js

const fs = require('fs');
const path = require('path');
const { initializeApp, cert } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');

const ROOT = path.resolve(__dirname, '..', '..');
const fbCfg = JSON.parse(fs.readFileSync(path.join(ROOT, 'assets/config/firebase_config.json'), 'utf8'));
const SERVICE_ACCOUNT_PATH = process.env.GOOGLE_APPLICATION_CREDENTIALS || '';
const FIREBASE_PROJECT_ID = fbCfg.FIREBASE_PROJECT_ID || '';

const CATEGORY_ICONS = {
  'cpu':       { icon: '🖥', name: 'CPU / Vi xử lý' },
  'gpu':       { icon: '🎴', name: 'Card đồ họa' },
  'ram':       { icon: '📊', name: 'RAM' },
  'storage':   { icon: '💿', name: 'SSD / Lưu trữ' },
  'mainboard': { icon: '🔲', name: 'Mainboard' },
  'psu':       { icon: '🔋', name: 'Nguồn (PSU)' },
  'cooler':    { icon: '🌀', name: 'Tản nhiệt' },
  'laptop':    { icon: '💻', name: 'Laptop' },
  'monitor':   { icon: '🖥️', name: 'Màn hình' },
  'keyboard':  { icon: '⌨️', name: 'Bàn phím' },
  'mouse':     { icon: '🖱️', name: 'Chuột' },
  'case':      { icon: '📦', name: 'Case / Vỏ máy tính' },
  'accessory': { icon: '🎧', name: 'Phụ kiện' },
};

async function main() {
  if (!SERVICE_ACCOUNT_PATH) throw new Error('Chưa có GOOGLE_APPLICATION_CREDENTIALS');
  initializeApp({
    credential: cert(require(path.resolve(SERVICE_ACCOUNT_PATH))),
    projectId: FIREBASE_PROJECT_ID || undefined,
  });
  const db = getFirestore();
  const snap = await db.collection('categories').get();
  console.log(`${snap.size} categories tìm thấy`);

  let ok = 0;
  for (const doc of snap.docs) {
    const entry = CATEGORY_ICONS[doc.id];
    if (!entry) { console.log(`⚠ Không có mapping cho: ${doc.id}`); continue; }
    await doc.ref.update({ icon: entry.icon });
    console.log(`✓ ${doc.id}: ${entry.icon}`);
    ok++;
  }
  console.log(`🎉 Cập nhật ${ok} categories`);
}

main().then(() => process.exit(0)).catch(e => { console.error('❌', e.message); process.exit(1); });
