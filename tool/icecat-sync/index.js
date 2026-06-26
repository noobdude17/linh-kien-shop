// Sync ảnh sản phẩm: Icecat -> Cloudinary -> Firestore
//
// CHẠY:
//   cd tool/icecat-sync
//   npm install
//   node index.js              # chỉ sync sản phẩm chưa có ảnh
//   OVERWRITE=1 node index.js  # sync lại cả sản phẩm đã có ảnh
//
// CẦN (xem phần CONFIG bên dưới):
//   - Icecat: assets/config/icecat_config.json (đã có)
//   - Cloudinary: cloud name + unsigned preset (đã có trong firebase_config.json)
//   - Firebase: service account JSON -> ĐỂ TRỐNG, bạn tự điền sau.

const fs = require('fs');
const path = require('path');
const Icecat = require('icecat');
const cloudinary = require('cloudinary').v2;
const admin = require('firebase-admin');

// ---------------- CONFIG ----------------
const ROOT = path.resolve(__dirname, '..', '..');

// Icecat (Open Icecat chỉ cần username; package vẫn nhận cả password).
const icecatCfg = JSON.parse(
  fs.readFileSync(path.join(ROOT, 'assets/config/icecat_config.json'), 'utf8')
);

// Cloudinary: lấy từ firebase_config.json, cho phép override bằng env.
const fbCfg = readJsonOrEmpty(path.join(ROOT, 'assets/config/firebase_config.json'));
const CLOUDINARY_CLOUD = process.env.CLOUDINARY_CLOUD_NAME || fbCfg.CLOUDINARY_CLOUD_NAME || '';
const CLOUDINARY_PRESET = process.env.CLOUDINARY_UPLOAD_PRESET || fbCfg.CLOUDINARY_UPLOAD_PRESET || '';

// Firebase Admin: ĐỂ TRỐNG — bạn điền sau.
// Cách 1: đặt biến môi trường GOOGLE_APPLICATION_CREDENTIALS trỏ tới file .json
// Cách 2: gán đường dẫn vào hằng số dưới đây.
const SERVICE_ACCOUNT_PATH = process.env.GOOGLE_APPLICATION_CREDENTIALS || '';
const FIREBASE_PROJECT_ID = fbCfg.FIREBASE_PROJECT_ID || '';

const OVERWRITE = process.env.OVERWRITE === '1';
const PRODUCTS = 'products';
const LANG = 'EN';
const MAX_IMAGES = 5;
// ----------------------------------------

cloudinary.config({ cloud_name: CLOUDINARY_CLOUD });
const icecat = new Icecat(icecatCfg.ICECAT_USERNAME, icecatCfg.ICECAT_PASSWORD);

function readJsonOrEmpty(p) {
  try { return JSON.parse(fs.readFileSync(p, 'utf8')); } catch { return {}; }
}

function initFirestore() {
  if (!SERVICE_ACCOUNT_PATH) {
    throw new Error(
      'Chưa có Firebase service account. Đặt GOOGLE_APPLICATION_CREDENTIALS ' +
      'hoặc gán SERVICE_ACCOUNT_PATH trong index.js.'
    );
  }
  admin.initializeApp({
    credential: admin.credential.cert(require(path.resolve(SERVICE_ACCOUNT_PATH))),
    projectId: FIREBASE_PROJECT_ID || undefined,
  });
  return admin.firestore();
}

// Mã ProductCode để thử, tốt nhất -> tệ nhất.
function candidates(d) {
  const brand = (d.brand || '').trim();
  const out = [];
  const add = (s) => {
    s = (s || '').toString().trim();
    if (s && !out.includes(s)) out.push(s);
  };
  add(d.mpn);
  add(d.imageLabel);
  const name = (d.name || '').trim();
  if (brand && name.toLowerCase().startsWith(brand.toLowerCase())) {
    add(name.slice(brand.length).trim());
  }
  add(name);
  return out;
}

// Trả mảng URL ảnh Icecat (ảnh chính trước), [] nếu không khớp.
async function icecatImages(brand, code) {
  let product;
  try {
    product = await icecat.openCatalog.getProductBySKU(LANG, brand, code);
  } catch {
    return []; // 404 / 403 (Full Icecat cần app_key) / lỗi -> coi như miss
  }
  const imgs = product.getImages() || [];
  const urls = imgs
    .sort((a, b) => (b.IsMain === 'Y' ? 1 : 0) - (a.IsMain === 'Y' ? 1 : 0))
    .map((i) => i.HighImg)
    .filter(Boolean);
  return [...new Set(urls)].slice(0, MAX_IMAGES);
}

// ponytail: nguồn ảnh dự phòng (Google image search...) — ĐỂ TRỐNG, điền sau.
async function fallbackImages(_d) {
  return [];
}

async function uploadToCloudinary(imageUrl, id) {
  const res = await cloudinary.uploader.unsigned_upload(imageUrl, CLOUDINARY_PRESET, {
    folder: `products/${id}`,
  });
  return res.secure_url;
}

async function main() {
  if (!CLOUDINARY_CLOUD || !CLOUDINARY_PRESET) {
    throw new Error('Thiếu Cloudinary cloud name / preset.');
  }
  console.log(`Icecat: ${icecatCfg.ICECAT_USERNAME} | Cloudinary: ${CLOUDINARY_CLOUD}`);
  const db = initFirestore();
  const snap = await db.collection(PRODUCTS).get();
  console.log(`Có ${snap.size} sản phẩm. Bắt đầu...`);

  let ok = 0, miss = 0, skip = 0;
  for (const doc of snap.docs) {
    const d = doc.data();
    const name = d.name || doc.id;

    if (!OVERWRITE && (d.imageUrl || '').toString()) {
      skip++;
      continue;
    }

    let icImgs = [];
    let hit = null;
    for (const code of candidates(d)) {
      const imgs = await icecatImages((d.brand || '').trim(), code);
      if (imgs.length) { icImgs = imgs; hit = code; break; }
    }
    if (!icImgs.length) icImgs = await fallbackImages(d); // trống cho tới khi bạn điền

    if (!icImgs.length) {
      console.log(`✗ ${name}: không khớp`);
      miss++;
      continue;
    }
    const urls = [];
    for (const img of icImgs) urls.push(await uploadToCloudinary(img, doc.id));
    await doc.ref.update({ imageUrl: urls[0], images: urls });
    console.log(`✓ ${name}${hit ? ` [${hit}]` : ''}: ${urls.length} ảnh`);
    ok++;
  }
  console.log(`🎉 Hoàn tất — OK ${ok} · MISS ${miss} · bỏ qua ${skip}`);
}

main().then(() => process.exit(0)).catch((e) => {
  console.error('❌', e.message);
  process.exit(1);
});
