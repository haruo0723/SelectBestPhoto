# AGENTS.md

このファイルは、AIコーディングエージェントがこのリポジトリで作業するときに守るルールを定義します。
内容はプロジェクトの実態に合わせて随時更新してください。

## プロジェクト概要

- プロジェクト名: SelectBestPhoto
- 目的: カップルが月ごとのベスト写真・動画を登録し、結果発表を楽しみながら月間・年間の思い出を振り返れるようにする。
- 主な利用者: カップル2人
- 主要機能:
  - 月間ベスト写真・動画の順位付き登録
  - 両方の入力完了後に見られる結果発表
  - 年間ベスト候補、年間TOP5、敗者復活枠
  - 年ごとのカスタム部門
  - テキスト候補型カスタム部門
  - Firebaseによる2人間の同期
  - Live Photos、写真、動画の表示・再生
- 要件の正本: `docs/requirements.md`

## 作業の基本方針

- 回答、説明、作業報告は原則として日本語で行う。
- コード、コマンド、ログ、エラーメッセージ、固有名詞は必要に応じて原文のまま扱う。
- 実装作業は生成AIが主体となって完了まで進めることを基本とし、人間の手作業を前提にした未実施タスクを残さない。
- 人間の関与は、仕様判断、重要な設計判断、破壊的操作、外部サービス設定など、確認が必要な場面に限定する。
- 小さな実装判断や調査は、既存コードと要件に沿って自律的に進める。
- 軽微な修正、調査、テスト追加、ドキュメント更新は事前確認なしで進めてよい。
- 仕様、設計、データ構造、依存関係、破壊的操作、広範囲な変更に関わる判断は、実行前に確認する。
- ユーザーの指示にない仕様や要件を推測で決めない。
- 不明瞭な部分、複数の解釈があり得る部分、要件に影響する判断がある場合は、作業を進める前に必ずユーザーへ質問する。
- 作業報告は簡潔にし、主に変更点、確認結果、残リスクを伝える。
- 詳細な説明、代替案、背景説明は、ユーザーが求めた場合または判断に重要な場合のみ記載する。
- 既存の設計、命名、ディレクトリ構成、UIパターンを優先する。
- 変更は依頼内容に必要な範囲へ絞り、無関係なリファクタリングは行わない。
- 仕様が曖昧な場合は、実装前に前提を明示し、必要に応じて確認する。
- ユーザーが加えた未コミット変更を勝手に戻さない。
- 破壊的な操作や依存関係の大きな変更は、事前に確認する。

## 開発環境

- 対象プラットフォーム: iOS 18以降
- 対応デバイス: iPhoneのみ。iPad対応は予定しない。
- 使用言語・フレームワーク: Swift / SwiftUI
- 開発環境: Xcode
- バックエンド: Firebase
- 認証: Firebase Anonymous Authentication + ペアコード
- データ保存: Cloud Firestore
- メディア保存: Firebase Cloud Storage
- パッケージ管理: Swift Package Managerを優先する。変更する場合は事前に確認する。
- ビルドコマンド: `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild -project SelectBestPhoto.xcodeproj -scheme SelectBestPhoto -destination 'generic/platform=iOS Simulator' -derivedDataPath .build/DerivedData build`
- テストビルドコマンド: `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild -project SelectBestPhoto.xcodeproj -scheme SelectBestPhoto -destination 'generic/platform=iOS Simulator' -derivedDataPath .build/DerivedData build-for-testing`
- テスト実行コマンド: `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild test -project SelectBestPhoto.xcodeproj -scheme SelectBestPhoto -destination 'platform=iOS Simulator,name=iPhone 17' -derivedDataPath .build/DerivedData`
- ローカル確認方針: Mac負荷を抑えるため、通常は `build` / `build-for-testing` までを確認する。画面や端末固有の動作確認はユーザーが実機で行い、Simulator上のテスト実行はCIまたは必要時に限定する。
- Lint/Formatコマンド: SwiftLint / SwiftFormat の採用要否はプロジェクト作成後に判断する。
- ローカル起動コマンド: Xcodeプロジェクト作成後に更新する。

## ディレクトリ構成

現時点の構成は以下。

```text
.
├── SelectBestPhoto.xcodeproj/
├── SelectBestPhoto/
│   ├── App/
│   ├── Features/
│   └── Resources/
├── SelectBestPhotoTests/
├── SelectBestPhotoUITests/
├── docs/
│   ├── requirements.md
│   ├── spec/
│   ├── design/
│   ├── tasks/
│   └── implements/
├── README.md
└── AGENTS.md
```

## コーディング規約

- 命名規則: Swift API Design Guidelinesと既存コードの命名を優先する。
- ファイル分割方針: SwiftUIのView、状態管理、モデル、サービスの責務が肥大化しないよう分割する。
- コメント方針: コメントは日本語で記載する。自明な処理にはコメントを足さず、複雑な判断や制約にだけ簡潔に記載する。
- エラー処理方針: ユーザーが次に取るべき行動を理解できる表現にし、内部エラーの詳細をそのまま表示しない。
- ログ出力方針: デバッグに必要な範囲に留め、写真パス、ペアコード、ユーザーID、個人情報を不用意に出力しない。
- 国際化・日本語表示方針: 初期対応は日本語UIを前提とし、多言語対応の要否は将来判断する。

## UI/UX方針

- iOS 18以降のSwiftUIアプリとして、Apple標準のナビゲーション、入力、共有、アクセシビリティの作法を優先する。
- iPhoneでの利用を前提とし、iPad専用レイアウトやiPad最適化は行わない。
- 主要画面は、月間ベスト、年間ベスト、カスタム部門、結果発表へ迷わず進める構成にする。
- 画面上の説明文は必要最小限にし、操作で理解できるUIを優先する。
- 写真・動画・ランキングが主役として映えるUIにする。
- 結果発表画面は、下位から上位へ期待感が高まる体験にする。
- デザインはシンプルで使いやすくしつつ、平坦になりすぎないようにカード、余白、階層、質感、モーションなどで奥行きや特別感を出す。
- 順位は視覚的に分かりやすく、1位は金メダル、2位は銀メダルなどの表現を活用できる。
- 対応範囲はiPhoneのみとし、主要なiPhone画面サイズで破綻しないようにする。
- アクセシビリティはDynamic Type、VoiceOver、十分なコントラスト、タップ領域の確保を意識する。

## テスト方針

- 仕様に関わる変更には、可能な限りテストを追加または更新する。
- UI変更では、主要な操作フローが壊れていないことを確認する。
- Firebase連携、権限、アップロード、リセット、結果発表の公開条件は重点的に検証する。
- バグ修正では、再発防止になるテストを優先する。
- テストが実行できない場合は、理由と未検証リスクを報告する。

## 完了条件

作業完了前に、可能な範囲で以下を確認する。

- 依頼された仕様を満たしている。
- 関連するテスト、ビルド、Lintが通る。
- 変更範囲に不要な差分が含まれていない。
- 未確認事項や残リスクがある場合は明記する。

## 禁止事項

- ユーザーの許可なく大きな依存関係を追加しない。
- ユーザーの許可なくデータ削除、履歴改変、設定初期化などの破壊的操作をしない。
- セキュリティ情報、APIキー、個人情報をリポジトリへ追加しない。
- 仕様未確定のまま、広範囲な設計変更を行わない。
- Firestore / Storageのセキュリティルールを緩いまま本運用しない。
- iPhone写真ライブラリ上の元データを直接変更・削除しない。

## 未決定・技術検証事項

- メディア圧縮基準
- 想定メディア件数
- 読み込めないファイルの扱い
- メタデータの扱い
- 結果発表画面の具体的な演出詳細
