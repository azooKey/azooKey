# iPhone Duo向けの画面レイアウト調整

画面全体の固定寸法ではなく、表示中のコンテナの寸法とサイズクラスで配置を決めます。設定・使い方・着せ替え・拡張は標準のTabViewとNavigationStackを利用し、iPhoneでも縦横の表示を許可します。タブにはラベルを付け、保存・キャンセルのツールバーを意味に沿った配置へ揃えます。バーを縦に並べる処理はOSに任せます。

## 編集画面

カスタムキー編集はiOS 27.1以降でArrangementViewを使い、フォームとプレビューを配置します。コンパクト表示でプレビューが隠れる場合も、方向選択、文字・ラベル編集、追加、削除、並び替えへフォームからアクセスできます。編集データは配置の外側へ保持します。旧OSではサイズクラスとコンテナ幅に応じたフォーム／2ペイン表示へフォールバックします。

キー・タブ編集、文字サイズの見本、画像トリミングは表示中の幅を使用します。アプリの寸法計算でUIScreen.mainや「iPhoneは常に縦向き」という仮定は使いません。プレビューでは現在の幅と一致する寸法キャッシュだけを再利用します。

## 既存キーボードの追従とタップ領域

キーボード拡張は画面シーンのeffectiveGeometryから向きを取得します。キーボード自身の横長のウィンドウ形状を、端末の向きとして扱いません。幅・向き・セーフエリア・予約領域の変化時に寸法を更新します。

候補バーは従来の上下余白をタップ領域に含め、短い候補にも幅44pt以上の領域を確保します。最上段キーの判定をキー領域内に収め、候補へのタップを奪わないようにします。iOS 27.1では候補バーなどの独自コントロールを折り目・カメラの予約領域から避けます。

## 範囲

左右に同じ配列を表示する新機能、専用の設定・プレビュー、片側幅・中央間隔の調整は含めません。標準の配列と既存のサイズ調整機能を使用します。左右表示の実装は別ブランチで保管し、仕様相談後に別PRとして扱います。

## ビルドと検証

最小OSは変更していません。Duo向けのArrangementView・予約領域を使用するビルドはXcode 27.1以降で行います。旧SDKでは新APIをコンパイル対象から外します。シミュレータで起動する場合もApp Groupのため署名を有効にしてください。CLIではCODE_SIGNING_ALLOWED=YES CODE_SIGN_IDENTITY=- DEVELOPMENT_TEAM=を指定できます。

DuoLayoutTestsはキーボードの回帰テスト、DuoAppTestsはアプリUIのテスト用スキームです。手順と今回の確認結果は[検証手順](iphone-duo-validation.md)、変更前後の画像は[画面比較](iphone-duo-screenshots.md)を参照してください。

参照：[AppleのiPhone Duo向けデザインガイド](https://developer.apple.com/jp/design/human-interface-guidelines/designing-for-iphone-duo)、[Preparing your app for iPhone Duo](https://developer.apple.com/documentation/technologyoverviews/preparing-your-app-for-iphone-duo)。
