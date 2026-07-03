// Tạo collection `brands` từ các hãng distinct trong products.
// CHẠY: node seed-brands.js  (dùng ./key.json)
const fs = require('fs');
const path = require('path');
const { initializeApp, cert } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');

const ROOT = path.resolve(__dirname, '..', '..');
const fbCfg = JSON.parse(fs.readFileSync(path.join(ROOT, 'assets/config/firebase_config.json'), 'utf8'));
initializeApp({
  credential: cert(require(path.resolve('./key.json'))),
  projectId: fbCfg.FIREBASE_PROJECT_ID || undefined,
});
const db = getFirestore();

const slug = (name) =>
  name.trim().toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/^-+|-+$/g, '') || `brand-${Date.now()}`;

async function main() {
  const snap = await db.collection('products').get();
  const brands = new Set();
  for (const doc of snap.docs) {
    const b = (doc.data().brand || '').trim();
    if (b && b !== 'AdminTest') brands.add(b);
  }
  const batch = db.batch();
  for (const name of brands) {
    batch.set(db.collection('brands').doc(slug(name)), { name });
  }
  await batch.commit();
  console.log(`Seeded ${brands.size} brands: ${[...brands].sort().join(', ')}`);
}
main().then(() => process.exit(0)).catch((e) => { console.error('ERR', e); process.exit(1); });
