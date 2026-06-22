# SelectBestPhoto ユーザー準備タスク

## 1. 概要

このファイルは、実装前または実装中にユーザー側で準備・判断が必要な項目を整理する。

- 要件名: select-best-photo
- 正本: `docs/requirements.md`
- 技術スタック参照: `docs/tech-stack.md`

信頼性レベルは `docs/spec/select-best-photo/requirements.md` と同じ定義を使う。

## 2. 必須タスク

| 優先度 | タスク | 内容 | 信頼性 |
| --- | --- | --- | --- |
| 必須 | Firebaseプロジェクト作成 | SelectBestPhoto用のFirebaseプロジェクトを作成する | 🔵 |
| 必須 | iOSアプリ登録 | FirebaseプロジェクトにiOSアプリを登録し、Bundle IDを確定する | 🔵 |
| 必須 | `GoogleService-Info.plist` 取得 | FirebaseのiOS設定ファイルを取得する。リポジトリ管理方針は作成時に決める | 🔵 |
| 必須 | Firebase Authentication有効化 | Anonymous Authenticationを有効にする | 🔵 |
| 必須 | Cloud Firestore有効化 | ペア、ユーザー、年月、部門、候補、順位、入力状態、公開状態、設定、Storage参照を保存できるようにする | 🔵 |
| 必須 | Firebase Cloud Storage有効化 | 軽量化済み写真、動画、Live Photos関連データ、関連画像を保存できるようにする | 🔵 |
| 必須 | テスト用Firebase環境方針決定 | Firebase Emulator Suiteを使うか、テスト用Firebaseプロジェクトを使うかを決める | 🔵 |
| 必須 | Security Rules設計準備 | ペア内アクセス制御、公開条件、Storageアクセス制御を設計できる状態にする | 🔵 |
| 必須 | メディア検証素材準備 | 写真、動画、Live Photos、読み込めない可能性のあるファイル、関連画像の検証素材を用意する | 🟡 |

## 3. 推奨タスク

| 優先度 | タスク | 内容 | 信頼性 |
| --- | --- | --- | --- |
| 推奨 | App Check検討 | 本番に近い運用へ進む前にFirebase App Check導入可否を決める | 🔵 |
| 推奨 | Crashlytics検討 | 実機配布または長期利用が見えた段階でCrashlytics導入可否を決める | 🔵 |
| 推奨 | Firebase費用試算 | 想定メディア件数、圧縮後サイズ、転送量から低コスト運用できるか確認する | 🔵 |
| 推奨 | メタデータ方針決定 | EXIFなど個人情報を含む可能性があるメタデータを保持、削除、選択式のどれにするか決める | 🔵 |
| 推奨 | 結果発表デザイン検討 | 下位から上位へ期待感が高まる具体的なアニメーション、質感、見せ方を検討する | 🔵 |
| 推奨 | Xcodeバージョン方針決定 | Xcode 27系推奨のまま進めるか、安定性重視でXcode 26系に固定するか決める | 🔵 |

## 4. 外部サービス・設定

- Firebase Console: https://console.firebase.google.com/
- Firebase Apple setup: https://firebase.google.com/docs/ios/setup
- Firebase iOS SDK: https://github.com/firebase/firebase-ios-sdk

## 5. 注意事項

- APIキー、証明書、`GoogleService-Info.plist` などの設定ファイルをリポジトリへ含めるかは、Firebaseプロジェクト作成時に方針を決める。🔵
- Firestore / StorageのSecurity Rulesを緩いまま本運用しない。🔵
- 写真パス、ペアコード、ユーザーID、個人情報をログに出さない。🔵
- iPhone写真ライブラリ上の元データを直接変更・削除しない。🔵

## 6. タスク件数

- 必須: 9件
- 推奨: 6件
- 合計: 15件
