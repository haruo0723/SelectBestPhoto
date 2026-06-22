# プロジェクト技術スタック定義

## 生成情報

- 生成日: 2026-06-22
- 生成ツール: init-tech-stack
- プロジェクト名: SelectBestPhoto
- プロジェクトタイプ: iPhone向けモバイルアプリ
- チーム規模: 個人または小規模チーム想定
- 開発期間: MVPから段階的に拡張

## プロジェクト要件サマリー

- 対象プラットフォーム: iOS 18以降
- 対象デバイス: iPhoneのみ
- UI: SwiftUI
- バックエンド: Firebase
- 認証: Firebase Anonymous Authentication + ペアコード
- データ同期: Cloud Firestore
- メディア保存: Firebase Cloud Storage
- パッケージ管理: Swift Package Manager
- セキュリティ: 写真・動画を扱うため、プライバシー保護とFirebase Security Rulesを重視
- パフォーマンス: 写真、動画、Live Photosの圧縮・表示・アップロード基準は技術検証で決定

## アプリケーション

- フレームワーク: SwiftUI
- 言語: Swift
- 最小OS: iOS 18
- IDE: Xcode
- アーキテクチャ: SwiftUI + MVVMを基本とする
- 非同期処理: Swift Concurrency
- 画面遷移: SwiftUI NavigationStack
- 写真選択: PhotosUI
- 写真・動画処理: Photos, AVFoundation, ImageIO
- Live Photos表示: PhotosUI / PHLivePhotoView

### 選択理由

- iPhone専用アプリのため、SwiftUIとApple標準フレームワークを優先する。
- iOS 18以降を対象にできるため、SwiftUIの標準コンポーネントとSwift Concurrencyを前提に設計できる。
- 写真、動画、Live Photosを扱うため、PhotosUI、Photos、AVFoundationを中心に構成する。

## バックエンド

- Backend as a Service: Firebase
- 認証: Firebase Authentication
- 認証方式: Anonymous Authentication
- ペア参加: アプリ内で発行したペアコードを相手が入力
- データベース: Cloud Firestore
- ファイルストレージ: Firebase Cloud Storage
- 任意導入候補: Firebase App Check, Firebase Crashlytics
- 初期スコープ外: 独自APIサーバー、通知機能、App Store公開

### 選択理由

- 2人間のデータ同期、入力状況管理、結果公開条件の制御にCloud Firestoreが適している。
- 写真・動画・Live Photos関連データはCloud Storageに保存し、Firestoreには参照情報と状態を保持する。
- 明示的なログイン画面を設けない要件に対して、Anonymous Authenticationとペアコード方式が合う。

## Firebase SDK

- 導入方式: Swift Package Manager
- リポジトリ: `https://github.com/firebase/firebase-ios-sdk`
- 初期導入モジュール:
  - `FirebaseCore`
  - `FirebaseAuth`
  - `FirebaseFirestore`
  - `FirebaseStorage`
- 追加候補:
  - `FirebaseAppCheck`
  - `FirebaseCrashlytics`

### 導入方針

- Firebase SDKはXcodeのSwift Package Managerで追加する。
- Google Analyticsは初期要件にないため、初期導入では必須にしない。
- Firebase設定ファイル `GoogleService-Info.plist` は機密性を確認し、リポジトリ管理方針を別途決める。

## データ設計方針

- メインDB: Cloud Firestore
- ストレージ: Firebase Cloud Storage
- ローカル永続化: 必要に応じてSwiftDataまたはファイルキャッシュを検討
- メディア参照: FirestoreにStorageパス、種類、順位、年月、所有ユーザー、入力状態を保持
- メディア実体: 表示・再生用に軽量化した写真、動画、Live Photos関連データをStorageへ保存

### 設計方針

- 元データはiPhone写真ライブラリに残し、アプリは元データを直接変更・削除しない。
- Firestoreのドキュメント構造は、カップル、ユーザー、年月、部門、入力状態を分離して設計する。
- 結果発表の公開条件はクライアント表示制御だけでなく、Security Rulesでも保護する。
- リセット時にStorage上の不要メディアを削除する要件があるため、参照カウントまたは所有スコープを明確にする。

## 開発環境

- IDE: Xcode
- パッケージ管理: Swift Package Manager
- バージョン管理: Git
- 対象デバイス: iPhone simulator / 実機iPhone
- Firebaseローカル検証: Firebase Emulator Suiteの利用を検討

### 主要コマンド

Xcodeプロジェクト作成後に更新する。

```bash
# 例: プロジェクト作成後に設定
xcodebuild -scheme SelectBestPhoto -destination 'platform=iOS Simulator,name=iPhone 16' build
xcodebuild test -scheme SelectBestPhoto -destination 'platform=iOS Simulator,name=iPhone 16'
```

## テスト

- ユニットテスト: Swift Testingを優先、必要に応じてXCTestを併用
- UIテスト: XCTest / XCUITest
- Firebase連携テスト: Firebase Emulator Suiteまたはテスト用Firebaseプロジェクトで検証
- 重点検証:
  - 両者入力完了まで相手の結果を表示しないこと
  - 月間、年間、カスタム部門の入力状態遷移
  - リセット時の確認と再入力
  - Storage上のメディア削除
  - 写真、動画、Live Photosの読み込み、圧縮、再生

## 品質管理

- フォーマット: Xcode標準フォーマットを基本に、必要に応じてSwiftFormatを導入
- Lint: 必要に応じてSwiftLintを導入
- CI: GitHub ActionsまたはXcode Cloudを検討
- クラッシュ収集: Firebase Crashlyticsを検討
- セキュリティ:
  - Firebase Security Rulesを本番前に必ず整備する。
  - ペアコード、ユーザーID、写真パス、個人情報をログに出さない。
  - EXIFなどメタデータの扱いは技術検証で決定する。
  - App Checkの導入を本番運用前に検討する。

## UI/UX方針

- Apple標準のナビゲーション、入力、共有、アクセシビリティの作法を優先する。
- 写真・動画・ランキングを主役にし、説明文は最小限にする。
- 結果発表画面は下位から上位へ期待感が高まる演出にする。
- Dynamic Type、VoiceOver、十分なコントラスト、タップ領域を考慮する。
- iPad専用レイアウトは作らない。

## 推奨ディレクトリ構造

Xcodeプロジェクト作成後の想定構成。

```text
.
├── SelectBestPhoto/
│   ├── App/
│   │   ├── SelectBestPhotoApp.swift
│   │   └── AppDelegate.swift
│   ├── Features/
│   │   ├── Pairing/
│   │   ├── MonthlyBest/
│   │   ├── AnnualBest/
│   │   ├── CustomCategories/
│   │   ├── ResultReveal/
│   │   └── Settings/
│   ├── Models/
│   ├── Services/
│   │   ├── Firebase/
│   │   ├── Media/
│   │   └── Storage/
│   ├── Shared/
│   │   ├── Components/
│   │   ├── Extensions/
│   │   └── Utilities/
│   └── Resources/
├── SelectBestPhotoTests/
├── SelectBestPhotoUITests/
├── docs/
│   ├── requirements.md
│   └── tech-stack.md
├── AGENTS.md
└── README.md
```

## 未決定・技術検証事項

- 写真圧縮の解像度、画質、ファイルサイズ基準
- 動画圧縮の解像度、ビットレート、長さ、ファイルサイズ基準
- Live Photosの保存形式と再生方式
- 想定メディア件数とFirebase費用
- 読み込めないファイルのエラー表示、スキップ、再試行方針
- EXIFなどメタデータの保持、削除、選択式の方針
- Firebase Security Rulesの具体設計
- Firebase Emulator Suiteを使う範囲
- SwiftLint / SwiftFormatの採用有無
- CIをGitHub ActionsにするかXcode Cloudにするか

## 更新履歴

- 2026-06-22: 初回生成
