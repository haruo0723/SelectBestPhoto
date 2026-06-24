# SelectBestPhoto

カップルが月ごとのベスト写真・動画を登録し、結果発表を楽しみながら月間・年間の思い出を振り返るためのiPhoneアプリです。

## 開発環境

- 対象: iOS 18以降、iPhone専用
- 言語/UI: Swift 6 / SwiftUI
- IDE: Xcode 27系推奨
- Scheme: `SelectBestPhoto`
- Bundle Identifier: `com.hirotokouno.SelectBestPhoto`

## 開発コマンド

```bash
# ビルド
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild -project SelectBestPhoto.xcodeproj -scheme SelectBestPhoto -destination 'generic/platform=iOS Simulator' -derivedDataPath .build/DerivedData build

# テストターゲットのビルド
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild -project SelectBestPhoto.xcodeproj -scheme SelectBestPhoto -destination 'generic/platform=iOS Simulator' -derivedDataPath .build/DerivedData build-for-testing

# CIまたは必要時のみ: Simulator上でテストを実行
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild test -project SelectBestPhoto.xcodeproj -scheme SelectBestPhoto -destination 'platform=iOS Simulator,name=iPhone 17' -derivedDataPath .build/DerivedData

# Lint
swiftlint

# Formatチェック
swiftformat --lint .
```

`xcodebuild` をそのまま使うには Xcode 本体を選択してください。グローバル設定を変更したくない場合は、上記のように `DEVELOPER_DIR` を指定します。

ローカルMacでは負荷を抑えるため、通常は `build` / `build-for-testing` までを確認します。画面や端末固有の動作確認は実機で行い、Simulator上のテスト実行はCIまたは必要時に限定します。

```bash
sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
```

SwiftLint / SwiftFormat が未インストールの場合は Homebrew で導入します。

```bash
brew install swiftlint swiftformat
```

CIは `.github/workflows/ci.yml` で、ビルド、Simulatorテスト、SwiftLint、SwiftFormatの最小チェックを実行します。

## Firebase Emulator

Firebase連携とSecurity Rules検証は、ローカルではFirebase Emulator Suiteを前提にします。初期設定は軽量な土台に留め、具体的なFirestore RulesはTASK-0010、Storage RulesはTASK-0011で拡張します。

```bash
# Firebase CLIとRulesテスト依存をインストール
npm install

# Auth / Firestore / Storage Emulatorを起動
npm run firebase:emulators

# Firestore / Storage Rulesテストを実行
npm run firebase:rules:test
```

EmulatorのローカルプロジェクトIDは `demo-select-best-photo` です。ポートはAuth `9099`、Firestore `8080`、Storage `9199`、Emulator UI `4000` を使用します。

`GoogleService-Info.plist` は実Firebaseプロジェクト固有の設定ファイルのため、リポジトリにはコミットしません。ローカルではFirebase Consoleから取得したファイルをXcodeプロジェクトの対象リソースに追加し、必要な開発者だけが手元に保持します。

DebugビルドでEmulatorへ接続する実装は、Firebase Service層を追加するタイミングで `#if DEBUG` に限定して行います。本番ビルドではEmulator接続コードを有効にしません。

## 現在の構成

```text
.
├── SelectBestPhoto.xcodeproj/
├── SelectBestPhoto/
│   ├── App/
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
│   │   ├── Cache/
│   │   └── Storage/
│   ├── Shared/
│   │   ├── Components/
│   │   ├── Extensions/
│   │   └── Utilities/
│   └── Resources/
├── SelectBestPhotoTests/
├── SelectBestPhotoUITests/
├── docs/
├── firebase.json
├── firestore.rules
├── storage.rules
├── package.json
├── tests/
├── README.md
└── AGENTS.md
```

Firebase初期化は `SelectBestPhoto/App/AppDelegate.swift` に集約しています。`GoogleService-Info.plist` が未投入の開発初期状態では初期化をスキップし、Firebase設定ファイル投入後に `FirebaseApp.configure()` が実行されます。
