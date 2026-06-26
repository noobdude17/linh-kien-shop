# Tiến độ sync ảnh (dừng tay 2026-06-26)

Dừng tại **389/728** dòng · **147 hits** · 242 miss.
Dòng cuối đã xong: `gpu-asus-asus-tuf-gaming-geforce-rtx-5070`.

Hits theo nhóm: mainboard 64 · gpu 46 · storage 28 · ram 9.
(CPU gần như miss hết — ảnh Icecat trả phí, để lại.)

## Kết quả đã lưu
- 147 URL ảnh đã upload Cloudinary, lưu ở `image_results.csv` (id,imageUrl,images).
- **Chưa đẩy vào Firestore** -> app CHƯA thấy ảnh.

## Chạy tiếp (resume — bỏ qua id đã xong)
```bash
cd tool/icecat-sync
node from-csv.js
```

## Để ảnh hiện trong app (đẩy lên Firestore)
Cần `key.json` (service account). Rồi:
```bash
cd tool/icecat-sync
GOOGLE_APPLICATION_CREDENTIALS=./key.json node push-firestore.js
```
