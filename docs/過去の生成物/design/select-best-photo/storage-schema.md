# SelectBestPhoto Storageスキーマ設計

## 1. 方針

- Firebase Cloud Storageには元データではなく、アプリ表示・再生用に軽量化した派生メディアを保存する。🔵
- 端末またはiCloud写真ライブラリ上の元データは、登録、編集、リセット、Storage削除のいずれでも変更・削除しない。🔵
- StorageファイルはFirestoreの `mediaAssets` と必ず対応させる。🔵
- 削除は `mediaAssets.referenceScopes` を確認し、必要なメディアを巻き込まない。🔵
- GPSなど位置情報はアップロード対象から除外する。🔵

## 2. パス構成

```text
pairs/{pairId}/media/{mediaAssetId}/photo-display.jpg
pairs/{pairId}/media/{mediaAssetId}/thumbnail.jpg
pairs/{pairId}/media/{mediaAssetId}/video.mp4
pairs/{pairId}/media/{mediaAssetId}/live-photo-still.jpg
pairs/{pairId}/media/{mediaAssetId}/live-photo-motion.mov
pairs/{pairId}/profile-icons/{mediaAssetId}/display.jpg
pairs/{pairId}/text-candidate-images/{mediaAssetId}/display.jpg
```

- `mediaAssetId` はFirestore `mediaAssets/{mediaAssetId}` と一致させる。🟡
- プロフィールアイコンとテキスト候補関連画像も `mediaAssets` で管理し、用途を `referenceScopes` に持たせる。🟡

## 3. メディア種別別ファイル

| 種別 | 保存ファイル | 方針 | 信頼性 |
| --- | --- | --- | --- |
| 写真 | `photo-display.jpg`, `thumbnail.jpg` | 通常写真はJPEG互換優先 | 🔵 |
| 動画 | `video.mp4`, `thumbnail.jpg` | H.264 MP4優先 | 🔵 |
| Live Photos | `live-photo-still.jpg`, `live-photo-motion.mov`, `thumbnail.jpg` | JPEG単体化せず、静止画部分とモーション部分を対応付けて保存 | 🔵 |
| 関連画像 | `display.jpg`, `thumbnail.jpg` | 写真と同様 | 🔵 |

## 4. アップロードメタデータ

| メタデータ | 内容 | 信頼性 |
| --- | --- | --- |
| `pairId` | 所属ペア | 🔵 |
| `mediaAssetId` | Firestore対応ID | 🟡 |
| `ownerUserId` | アップロード者 | 🔵 |
| `mediaKind` | photo/video/livePhoto | 🔵 |
| `contentPurpose` | display/thumbnail/video/livePhotoMotion | 🟡 |

- Storage Rulesで使う値は、Firestore `mediaAssets` との整合を前提にする。🟡
- 写真パスや個人情報をログに出さない。🔵

## 5. 削除フロー

1. リセット対象スコープをFirestoreトランザクションで更新する。🔵
2. 対象スコープの参照を `mediaAssets.referenceScopes` から外す。🔵
3. 参照が空になった `mediaAssets` を `pendingDeletion` にする。🟡
4. Firebase Cloud Storage上の派生ファイルだけを削除する。端末またはiCloud写真ライブラリ上の元データには触れない。🔵
5. 成功したら `deletionState` を `deleted` に更新する。🟡
6. 失敗した場合は `pendingDeletion` を残し、次回再試行する。🟡

## 6. 技術検証事項

| 項目 | 検証内容 | 信頼性 |
| --- | --- | --- |
| 写真圧縮 | 解像度、品質、ファイルサイズ、表示品質 | 🔵 |
| 動画圧縮 | 解像度、ビットレート、長さ、処理時間 | 🔵 |
| Live Photos | 保存形式、再生方式、互換性 | 🔵 |
| キャッシュ | Storage再取得削減、容量上限、削除タイミング | 🟡 |
