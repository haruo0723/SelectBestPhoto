# プロジェクト技術スタック定義

## 生成情報

- 生成日: 2026-06-22
- 生成ツール: init-tech-stack
- プロジェクト名: SelectBestPhoto
- プロジェクトタイプ: iPhone向けモバイルアプリ
- チーム規模: 個人開発
- 開発期間: 短期プロジェクト 3-6ヶ月
- コスト方針: 低コスト優先
- 学習方針: 安定優先
- CI方針: GitHub Actions

## プロジェクト要件サマリー

- 対象プラットフォーム: iOS 18以降
- 対象デバイス: iPhoneのみ
- UI: SwiftUI
- バックエンド: Firebase
- 認証: Firebase Anonymous Authentication + ペアコード
- データ同期: Cloud Firestore
- メディア保存: Firebase Cloud Storage
- パッケージ管理: Swift Package Manager
- 主な扱いデータ: 写真、動画、Live Photos、テキスト候補、関連画像、入力状態、順位、設定
- セキュリティ: 写真・動画を扱うため、Firebase Security Rules、App Check、メタデータ方針、ログ出力制御を重視する。
- パフォーマンス: Firebase費用と転送量を抑えるため、アップロード前のメディア軽量化とキャッシュ戦略を重視する。

## アプリケーション

- 言語: Swift 6系
- IDE: Xcode 27系を推奨
- 最小OS: iOS 18
- UIフレームワーク: SwiftUI
- 画面遷移: NavigationStack
- 状態管理: SwiftUI標準の状態管理とObservationを基本とする
- 非同期処理: Swift Concurrency
- アーキテクチャ: SwiftUI + MVVMを基本とし、機能単位でView、ViewModel、Service、Modelを分離する
- 写真選択: PhotosUI
- 写真処理: Photos / ImageIO
- 動画処理: AVFoundation / AVKit
- Live Photos: Photos / PhotosUI / PHLivePhotoView
- ファイル読み込み: UniformTypeIdentifiers、必要に応じてDocumentPicker相当の標準API

### 選択理由

- iPhone専用かつiOS 18以降のため、Apple標準フレームワークを優先すると依存を増やさず実装できる。
- 写真、動画、Live Photosの扱いは標準APIとの親和性が重要なため、SwiftUI、PhotosUI、AVFoundationを中心にする。
- 個人開発かつ低コスト優先のため、独自サーバーは置かずFirebaseをBackend as a Serviceとして使う。
- 安定優先のため、外部UIライブラリや独自アーキテクチャは初期導入しない。

## バックエンド

- Backend as a Service: Firebase
- 認証: Firebase Authentication
- 認証方式: Anonymous Authentication
- ペア参加: 片方が発行したペアコードを相手が入力
- データベース: Cloud Firestore
- ファイルストレージ: Firebase Cloud Storage
- セキュリティ強化候補: Firebase App Check
- 障害把握候補: Firebase Crashlytics
- 初期スコープ外: 独自APIサーバー、通知機能、App Store公開、書き出し機能

### Firebase SDK

- 導入方式: Swift Package Manager
- リポジトリ: `https://github.com/firebase/firebase-ios-sdk`
- 推奨系列: Firebase Apple SDK 12系
- 初期導入モジュール:
  - `FirebaseCore`
  - `FirebaseAuth`
  - `FirebaseFirestore`
  - `FirebaseStorage`
- 追加候補:
  - `FirebaseAppCheck`
  - `FirebaseCrashlytics`

### 選択理由

- Cloud Firestoreは、2人間の入力状態、公開条件、順位付きデータ、設定の同期に適している。
- Cloud Storageは、写真・動画・Live Photos関連データ、テキスト候補型カスタム部門の関連画像保存に適している。
- Anonymous Authenticationは、明示的なログイン画面を設けない要件と相性がよい。

## データ設計方針

- Firestoreには、ペア、ユーザー、年月、部門、候補、順位、入力状態、公開状態、設定、Storage参照を保存する。
- Storageには、アプリ表示・再生用に軽量化した写真、動画、Live Photos関連データ、関連画像を保存する。
- 元データはiPhone写真ライブラリに残し、アプリは元データを直接変更・削除しない。
- 結果発表の公開条件は、クライアント表示制御だけでなくFirestore Security Rulesでも保護する。
- リセット時にStorage上の不要メディアを削除する要件があるため、参照元、所有スコープ、削除対象を設計時に明確化する。
- ローカルキャッシュは、実装段階で必要性を見てファイルキャッシュまたはSwiftDataを検討する。

## メディア処理方針

- アップロード前に写真・動画を表示・再生用途へ軽量化する。
- 写真は表示用サイズへ縮小し、過度なStorage容量と転送量を避ける。
- 動画はアプリ内再生に支障がない範囲で圧縮版を保存する。
- Live Photosは静止画部分とモーション部分を、アプリ内再生できる形式で保存する。
- EXIFなど個人情報を含む可能性があるメタデータは、保持、削除、選択式のいずれにするかを技術検証で決める。
- 読み込めないファイルの扱いは、スキップ、再試行、エラー表示の方針を技術検証で決める。

## 開発環境

- IDE: Xcode 27系推奨。安定性重視でXcode 26系に固定する場合は、プロジェクト作成時にチーム内で明記する。
- パッケージ管理: Swift Package Manager
- バージョン管理: Git
- 対象実行環境: iPhone Simulator / 実機iPhone
- Firebase検証: Firebase Emulator Suiteまたはテスト用Firebaseプロジェクトを使用する。
- CI: GitHub Actions
- フォーマット: SwiftFormat
- Lint: SwiftLint
- Apple標準ツール: SF Symbols、Instruments、Accessibility Inspector、Xcode Organizer

### 主要コマンド

Xcodeプロジェクト作成後に、実際のschemeとSimulator名へ更新する。

```bash
xcodebuild -scheme SelectBestPhoto -destination 'platform=iOS Simulator,name=iPhone 16' build
xcodebuild test -scheme SelectBestPhoto -destination 'platform=iOS Simulator,name=iPhone 16'
swiftlint
swiftformat .
```

## テスト方針

- ユニットテスト: Swift Testingを基本とし、既存APIやUIテスト都合に応じてXCTestを併用する。
- UIテスト: XCUITest
- Firebase連携テスト: Firebase Emulator Suiteまたはテスト用Firebaseプロジェクトで検証する。
- メディア処理テスト: 圧縮、サムネイル生成、アップロード対象生成、再生可能性を重点確認する。
- 重点シナリオ:
  - 両方が入力完了するまで相手の結果を表示しない。
  - 入力状況が未入力、入力中、入力完了で正しく切り替わる。
  - 月間、年間、カスタム部門、テキスト候補型カスタム部門の順位入力が下位から進む。
  - リセット前に確認ダイアログを表示し、再入力後に結果発表を再視聴できる。
  - Storage上の不要メディア削除が、必要なメディアを巻き込まない。
  - 写真、動画、Live Photosが主要なiPhone画面サイズで表示・再生できる。

## 品質・CI

- GitHub Actionsで、ビルド、テスト、SwiftLint、SwiftFormatチェックを実行する。
- 個人開発のため、初期は最小構成のCIから始め、Firebase連携テストは安定後に追加する。
- SwiftLintとSwiftFormatは、Xcodeプロジェクト作成後に設定ファイルを追加する。
- Crashlyticsは、実機配布または長期利用が見えてから導入する。
- 依存関係はSwift Package Managerで管理し、大きな依存追加は要件と保守コストを確認してから行う。

## セキュリティ・プライバシー

- Firebase Security Rulesを本番運用前に必ず整備する。
- 結果発表の公開条件は、Firestore Rulesでも保護する。
- Storage Rulesでは、ペアに属するユーザーだけが対象メディアへアクセスできるようにする。
- ペアコード、ユーザーID、写真パス、個人情報をログに出さない。
- 写真・動画をFirebaseへアップロードする前に、ユーザーが対象を認識できるUIにする。
- `GoogleService-Info.plist` の管理方針は、Firebaseプロジェクト作成時に決める。
- App Checkは、本番に近い運用へ進む前に導入を検討する。

## UI/UX方針

- Apple標準のナビゲーション、入力、共有、アクセシビリティの作法を優先する。
- 写真・動画・ランキングを主役にし、説明文は必要最小限にする。
- 結果発表画面は、下位から上位へ期待感が高まる体験にする。
- 順位は視覚的に分かりやすく、1位、2位、3位の差が自然に伝わるUIにする。
- Dynamic Type、VoiceOver、十分なコントラスト、44pt以上のタップ領域を意識する。
- iPad専用レイアウトやiPad最適化は行わない。

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
│   │   ├── TextCategories/
│   │   ├── RevivalPicks/
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
- `GoogleService-Info.plist` のリポジトリ管理方針
- 結果発表画面の具体的なアニメーション、質感、見せ方

## 参照情報

- Apple Xcode: https://developer.apple.com/xcode/
- Swift: https://www.swift.org/
- Firebase Apple SDK: https://github.com/firebase/firebase-ios-sdk
- Firebase Apple setup: https://firebase.google.com/docs/ios/setup
- SwiftLint: https://github.com/realm/SwiftLint
- SwiftFormat: https://github.com/nicklockwood/SwiftFormat

## 更新履歴

- 2026-06-22: init-tech-stackにより初回生成
