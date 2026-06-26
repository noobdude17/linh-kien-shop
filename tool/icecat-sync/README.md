# icecat-sync

Sync ảnh sản phẩm: **Icecat → Cloudinary → Firestore**.

## Chạy
```bash
cd tool/icecat-sync
npm install
node index.js              # chỉ sync sản phẩm chưa có ảnh
OVERWRITE=1 node index.js  # sync lại cả sản phẩm đã có ảnh
```

## Cấu hình
| Thứ | Nguồn | Trạng thái |
|-----|-------|-----------|
| Icecat user/pass | `assets/config/icecat_config.json` | ✅ có sẵn |
| Cloudinary cloud + preset | `assets/config/firebase_config.json` | ✅ có sẵn |
| Firebase service account | env `GOOGLE_APPLICATION_CREDENTIALS` hoặc `SERVICE_ACCOUNT_PATH` trong `index.js` | ⬜ **bạn tự điền** |

Lấy service account: Firebase Console → Project settings → Service accounts → Generate new private key.
```bash
GOOGLE_APPLICATION_CREDENTIALS=/đường/dẫn/key.json node index.js
```

## Cách khớp ảnh
Với mỗi product, thử lần lượt làm ProductCode: `mpn` → `imageLabel` → `name` (bỏ brand) → `name`.
Icecat free **không tìm theo tên** — chỉ trúng khi chuỗi là mã model thật (vd `GV-N4070EAGLE OC-12GD`).
Tên chung chung → MISS. Ảnh Full Icecat (cần app_key trả phí) → 403 → MISS. Muốn chắc: thêm field `mpn`.

## Để trống (làm sau)
`fallbackImages()` trong `index.js` — nguồn ảnh dự phòng (Google image search...) khi Icecat miss. Hiện trả `[]`.
