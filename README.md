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
├── README.md
└── AGENTS.md
```

Firebase初期化は `SelectBestPhoto/App/AppDelegate.swift` に集約しています。`GoogleService-Info.plist` が未投入の開発初期状態では初期化をスキップし、Firebase設定ファイル投入後に `FirebaseApp.configure()` が実行されます。
