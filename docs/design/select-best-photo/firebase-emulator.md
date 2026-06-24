# SelectBestPhoto Firebase Emulator方針

## 1. 目的

Firebase Emulator Suiteを使い、Firestore、Storage、Authのローカル検証を実Firebaseプロジェクトへ接続せずに行う。

## 2. ローカル設定

- ローカルプロジェクトID: `demo-select-best-photo`
- Auth Emulator: `127.0.0.1:9099`
- Firestore Emulator: `127.0.0.1:8080`
- Storage Emulator: `127.0.0.1:9199`
- Emulator UI: `127.0.0.1:4000`

設定ファイル:

- `.firebaserc`
- `firebase.json`
- `firestore.rules`
- `storage.rules`

## 3. Rulesテスト

`tests/firebase/rules.test.mjs` をRulesテストの入口にする。TASK-0005では初期状態を全拒否にし、Rules詳細は以下のタスクで拡張する。

- TASK-0010: Firestore Rules初期実装とEmulatorテスト
- TASK-0011: Storage Rules初期実装とEmulatorテスト
- TASK-0034: Firebase Emulator統合テスト

## 4. アプリ側Debug接続方針

Firebase Service層を追加するタイミングで、DebugビルドのみEmulatorへ接続する。接続設定は `#if DEBUG` に閉じ込め、本番ビルドではEmulator接続コードを無効にする。

実装時の方針:

```swift
#if DEBUG
// Auth: 127.0.0.1:9099
// Firestore: 127.0.0.1:8080
// Storage: 127.0.0.1:9199
#endif
```

現時点ではFirebase Service層が未実装のため、TASK-0005では方針の明文化に留める。

## 5. `GoogleService-Info.plist` 管理方針

`GoogleService-Info.plist` はFirebaseプロジェクト固有の設定ファイルとして扱い、リポジトリへコミットしない。ローカル開発者はFirebase Consoleから取得したファイルを手元のXcodeプロジェクトへ追加する。

実FirebaseのAPIキー、証明書、個別プロジェクト設定は、ドキュメントやテストデータにも記載しない。
