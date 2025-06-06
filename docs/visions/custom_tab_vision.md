# Custom Tab Vision

カスタムタブはazooKeyの重要な機能の1つです。この機能について、将来実現したい変更を説明します。

## エディタ

### アプリ内でpc styleのカスタムタブを作成できるようにする

現在、pc styleのカスタムタブは作成できません。エディタを新たに追加し、アプリ内で編集できるようにしたいと考えています。

### プリセット機能・カスタムプリセット機能

アクションについて、「〇〇を入力する」「カーソルを動かす」というような、複数のアクションの連続を1つにまとめ、簡単に設定できるようにするカスタムプリセット機能を考えています。

同様に、キーについても、「あいうえおキー」「ABCキー」など、頻繁に作成されるキーをプリセットとして提供できる機能を考えています。また、カスタムプリセットを追加する機能も考えています。

### Webエディタ

スマホ上で編集するのはそこまで手軽ではないので、パソコンで気軽に編集できる環境があると良いだろうと考えています。

### Google Colab環境の提供

プログラム経由でのカスタムタブ生成を簡単にするため、Google Colaboratoryでサンプルプロジェクトを用意したいと考えています。

## 仕様

* `if`文相当の機能を追加したいと考えています。例えば、「ペーストキーが有効化されている場合は表示し、されていない場合は表示しない」というような条件分岐が可能になるはずです。
* 「シフト」をうまく扱える枠組みを模索中です。「レイヤー」のような概念を導入し、各レイヤーにおけるバリエーションとして位置付けるといいのかもしれません。
* 検索機能をオプションで追加できるようにしたいと考えています。
* カスタムローマ字入力のような機能を実現したいと考えています。

## その他

* 将来的に、カスタムタブのシェアをアプリ内で可能にしたいと思っています。
* タブの更新の配布などもアプリ内でうまく実現したいと考えています。