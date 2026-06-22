# 概要

<!-- 何を変更したか、ユーザー体験・仕様・設計上の意味が分かる粒度で記載してください。 -->

## 関連 docs / タスク

- 正本: `docs/requirements.md`
- 技術スタック: `docs/tech-stack.md`
- 関連仕様:
  - <!-- 例: `docs/spec/select-best-photo/acceptance-criteria.md` -->
- 関連設計:
  - <!-- 例: `docs/design/select-best-photo/architecture.md` -->
- 関連タスク:
  - <!-- 例: `docs/tasks/select-best-photo/TASK-0001.md` -->

## 変更種別

- [ ] 仕様 / 要件
- [ ] Swift / SwiftUI 実装
- [ ] Firebase Auth / Firestore / Storage
- [ ] Security Rules / App Check / ログ制御
- [ ] 写真 / 動画 / Live Photos / メディア処理
- [ ] UI / UX / アクセシビリティ
- [ ] テスト
- [ ] CI / 開発環境
- [ ] ドキュメント

## モバイルアプリ確認

- [ ] iPhone向け画面サイズで破綻しない
- [ ] Dynamic Typeで主要操作と情報が利用できる
- [ ] VoiceOverで操作対象と状態が理解できる
- [ ] 44pt以上のタップ領域を確保している
- [ ] 写真・動画・ランキングが主役として見える
- [ ] 結果発表は下位から上位へ期待感が高まる体験になっている
- [ ] UI変更なし

## Firebase / セキュリティ確認

- [ ] 両方の入力完了前に相手の結果が表示されない
- [ ] Firestore Security Rulesで公開条件を保護している
- [ ] Storage Rulesでペア外ユーザーのアクセスを防いでいる
- [ ] リセット時に削除するのはFirebase Storage上の不要な派生メディアだけ
- [ ] ペアコード、ユーザーID、写真パス、個人情報をログ出力していない
- [ ] Firebase / セキュリティ変更なし

## メディア確認

- [ ] 写真は表示用に適切に圧縮・表示できる
- [ ] 動画はアプリ上で再生できる形式で扱える
- [ ] Live Photosを通常写真として潰していない
- [ ] アップロード前にユーザーが送信対象を認識できる
- [ ] 端末またはiCloud写真ライブラリ上の元データを変更・削除しない
- [ ] メディア変更なし

## テスト / 検証

<!-- 実行したコマンドと結果を記載してください。未実行の場合は理由を書いてください。 -->

- [ ] `xcodebuild build`
- [ ] `xcodebuild test`
- [ ] `swiftlint`
- [ ] `swiftformat --lint .`
- [ ] GitHub Actions相当のローカル検査
- [ ] 手動確認

```text
実行結果:
```

## リスク / 未確認事項

<!-- 仕様未決定、技術検証待ち、手元で確認できなかった点を記載してください。 -->
