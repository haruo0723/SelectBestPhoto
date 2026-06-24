# TASK-0005 設定確認・動作テスト

## 確認概要

- **タスクID**: TASK-0005
- **確認内容**: Firebase Emulator検証環境の軽量セットアップ確認
- **確認日**: 2026-06-24
- **確認者**: Codex

## 確認項目

### 設定ファイル

- [x] `.firebaserc` が存在する
- [x] `firebase.json` が存在する
- [x] `firestore.rules` が存在する
- [x] `storage.rules` が存在する
- [x] `package.json` にEmulator起動とRulesテストのscriptがある
- [x] `package-lock.json` が存在する
- [x] `tests/firebase/rules.test.mjs` が存在する

### ドキュメント

- [x] `README.md` にEmulator起動とRulesテスト手順がある
- [x] `docs/design/select-best-photo/firebase-emulator.md` にDebug接続方針がある
- [x] `GoogleService-Info.plist` の非コミット方針が文書化されている
- [x] `.gitignore` に `GoogleService-Info.plist` が含まれている

### 構文確認

- [x] `.firebaserc` はJSONとして読める
- [x] `firebase.json` はJSONとして読める
- [x] `package.json` はJSONとして読める
- [x] `tests/firebase/rules.test.mjs` はNode.js構文として読める

## 実行確認

実行した確認:

```bash
node -e "JSON.parse(require('fs').readFileSync('.firebaserc','utf8')); JSON.parse(require('fs').readFileSync('firebase.json','utf8')); JSON.parse(require('fs').readFileSync('package.json','utf8'));"
node --check tests/firebase/rules.test.mjs
test -f firestore.rules
test -f storage.rules
npm install
PATH=/usr/local/opt/openjdk/bin:$PATH npm run firebase:rules:test
npm audit --audit-level=high
git diff --check
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild -project SelectBestPhoto.xcodeproj -scheme SelectBestPhoto -destination 'generic/platform=iOS Simulator' -derivedDataPath .build/DerivedData build
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer swiftlint
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer swiftformat --lint .
```

確認結果:

```text
JSON parse: OK
Node syntax: OK
Rules files: OK
npm install: OK
npm run firebase:rules:test: 3 tests passed
npm audit --audit-level=high: 5 moderate vulnerabilities, highなし
git diff --check: OK
xcodebuild build: ** BUILD SUCCEEDED **
swiftlint: Found 0 violations, 0 serious in 5 files.
swiftformat --lint .: 0/5 files require formatting, 64 files skipped.
```

未実行:

- `npm run firebase:emulators`: ローカル常駐プロセス起動を伴うため未実行

補足:

- `@firebase/rules-unit-testing@4.0.1` のpeer dependencyに合わせ、Nodeテスト用 `firebase` は11系に調整した。
- `firebase-tools` は `15.22.1` へ更新し、`tar` 由来のhigh脆弱性が検出されない状態にした。
- Homebrewで導入したOpenJDKはkeg-onlyのため、Rulesテスト実行時は `PATH=/usr/local/opt/openjdk/bin:$PATH` を明示した。

## 完了判定

- [x] Firebase Emulator Suiteの設定ファイルがある
- [x] Firestore/Storage Rulesテストを実行できる土台がある
- [x] アプリ側がDebug時にEmulatorへ接続できる方針が明確
- [x] `GoogleService-Info.plist` の管理方針が文書化されている

## 次の推奨タスク

- TASK-0006: 共通ドメインモデルとFirestore Codableモデル
- TASK-0010: Firestore Rules初期実装とEmulatorテスト
- TASK-0011: Storage Rules初期実装とEmulatorテスト
