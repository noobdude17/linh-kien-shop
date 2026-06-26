// Gán rating + reviewCount ngẫu nhiên (nhưng nhất quán) cho tất cả sản phẩm.
// Rating phân bố thực tế: 3.5–5.0, lệch về 4.x (giống sàn TMĐT).
//
// CHẠY:
//   cd tool/icecat-sync
//   GOOGLE_APPLICATION_CREDENTIALS=./key.json node seed-ratings.js
//   GOOGLE_APPLICATION_CREDENTIALS=./key.json DRY_RUN=1 node seed-ratings.js  # xem trước

const fs = require('fs');
const path = require('path');
const { initializeApp, cert } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');

const ROOT = path.resolve(__dirname, '..', '..');
const fbCfg = JSON.parse(fs.readFileSync(path.join(ROOT, 'assets/config/firebase_config.json'), 'utf8'));
const SERVICE_ACCOUNT_PATH = process.env.GOOGLE_APPLICATION_CREDENTIALS || '';
const FIREBASE_PROJECT_ID = fbCfg.FIREBASE_PROJECT_ID || '';
const DRY_RUN = process.env.DRY_RUN === '1';

// Hash đơn giản từ string -> số [0,1) nhất quán (không dùng Math.random).
function pseudoRandom(str) {
  let h = 2166136261;
  for (let i = 0; i < str.length; i++) {
    h ^= str.charCodeAt(i);
    h = (h * 16777619) >>> 0;
  }
  return h / 0xffffffff;
}

// Phân bố rating thực tế: 70% range 4.2–4.9, 20% range 3.5–4.2, 10% range 4.9–5.0
function generateRating(id) {
  const r = pseudoRandom(id + '_rating');
  let raw;
  if (r < 0.70) raw = 4.2 + (pseudoRandom(id + '_r2') * 0.7);   // 4.2–4.9
  else if (r < 0.90) raw = 3.5 + (pseudoRandom(id + '_r3') * 0.7); // 3.5–4.2
  else raw = 4.9 + (pseudoRandom(id + '_r4') * 0.1);              // 4.9–5.0
  return Math.round(raw * 10) / 10; // 1 chữ số thập phân
}

function generateReviewCount(id, rating) {
  const r = pseudoRandom(id + '_reviews');
  // Sản phẩm rating cao -> nhiều review hơn
  const base = rating >= 4.7 ? 80 : rating >= 4.3 ? 40 : 15;
  return Math.floor(base + r * base * 1.5);
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

  const snap = await db.collection('products').get();
  console.log(`${snap.size} sản phẩm tìm thấy. DRY_RUN=${DRY_RUN}`);

  let batch = db.batch();
  let count = 0;
  let batchCount = 0;
  for (const doc of snap.docs) {
    const id = doc.id;
    const rating = generateRating(id);
    const reviewCount = generateReviewCount(id, rating);
    console.log(`${DRY_RUN ? '[DRY]' : '     '} ${id}: ⭐ ${rating} (${reviewCount} đánh giá)`);
    if (!DRY_RUN) {
      batch.update(doc.ref, { rating, reviewCount });
      count++;
      batchCount++;
      if (batchCount === 400) {
        await batch.commit();
        console.log('--- commit batch ---');
        batch = db.batch();
        batchCount = 0;
      }
    }
  }
  if (!DRY_RUN && batchCount > 0) {
    await batch.commit();
    console.log(`🎉 Cập nhật ${count} sản phẩm`);
  }
  if (DRY_RUN) console.log('DRY RUN xong. Thêm DRY_RUN=0 để ghi thật.');
}

main().then(() => process.exit(0)).catch((e) => { console.error('❌', e.message); process.exit(1); });
