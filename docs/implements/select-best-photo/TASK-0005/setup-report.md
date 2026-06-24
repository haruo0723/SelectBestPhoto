# TASK-0005 設定作業実行

## 作業概要

- **タスクID**: TASK-0005
- **作業内容**: Firebase Emulator検証環境の軽量セットアップ
- **実行日**: 2026-06-24
- **実行者**: Codex

## 参照文書

- `docs/tasks/select-best-photo/TASK-0005.md`
- `docs/tasks/select-best-photo/overview.md`
- `docs/tech-stack.md`
- `docs/design/select-best-photo/security-rules.md`

## 実行した作業

### 1. Firebase Emulator Suite設定

**作成ファイル**:

- `.firebaserc`
- `firebase.json`

ローカル検証用のプロジェクトIDを `demo-select-best-photo` に固定し、Auth、Firestore、Storage、Emulator UIのポートを定義した。

### 2. Security Rules初期ファイル

**作成ファイル**:

- `firestore.rules`
- `storage.rules`

TASK-0005では軽量対応として、初期状態は全拒否のRulesにした。ペア所属、公開条件、Storage所有者検証などの本実装はTASK-0010/TASK-0011で行う。

### 3. Rulesテスト土台

**作成ファイル**:

- `package.json`
- `tests/firebase/rules.test.mjs`

Firebase Emulator Suite上でFirestore/Storage Rulesテストを実行する入口を追加した。初期テストでは、Rulesが全拒否であることを確認する。

### 4. Firebase設定ファイル管理

**更新ファイル**:

- `.gitignore`
- `README.md`
- `docs/design/select-best-photo/firebase-emulator.md`

`GoogleService-Info.plist` をリポジトリへ含めない方針を明記し、Firebase debug logやEmulator exportもignore対象にした。

### 5. タスク進捗更新

**更新ファイル**:

- `docs/tasks/select-best-photo/TASK-0005.md`
- `docs/tasks/select-best-photo/overview.md`

完了条件をチェック済みにし、完了日を記録した。

## 作業結果

- [x] Firebase Emulator Suiteの設定ファイルを追加
- [x] Firestore/Storage Rulesテストの入口を追加
- [x] Debug時Emulator接続方針を文書化
- [x] `GoogleService-Info.plist` の管理方針をREADMEと設計メモへ記載
- [x] TASK-0005の完了記録を更新

## 注意事項

- 軽量対応のため、Firebase CLIやnpm依存のインストールは実行していない。
- Rules詳細はTASK-0010/TASK-0011で実装する前提として、現時点のRulesは全拒否にしている。
- アプリ側のEmulator接続コードは、Firebase Service層を追加する後続タスクで実装する。
