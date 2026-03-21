# Let's Contribute!

azooKeyの開発に参加したい方のため、Contributionの始め方を説明します。

## 1. Build・Runする

[README.md](../README.md)に従ってプロジェクトをクローンして環境構築を行い、エミュレータや実機デバイスで実行してみてください。

うまくいかないことがあったら、遠慮なくIssueを立ててください。あなたがわからないことは他の人にもわからない可能性があります。

## 2. 簡単な変更をしてみる

### 2.1. Issueを立てる

GitHub上で「feat: 〇〇する」というような形のIssueを立ててください。Assigneeを自分のアカウントに変更してください。

### 2.2. プロジェクトを準備する

GitHub上で、azooKeyのプロジェクトをフォークしてください。あなたのユーザ名が「hoge」の場合は「[https://github.com/hoge/azooKey](https://github.com/hoge/azooKey)」ができあがります。

「1」でクローンして動かしたazooKeyのディレクトリで、以下のコマンドを実行します。`<alias>`部分は好きな名前（例えば`hoge`）に置き換えてください。これにより、あなたのフォークに`hoge`と言うエイリアスが追加されます。

```bash
git remote add <alias> https://github.com/hoge/azooKey
```

#### 2.2.1. linterをインストールする

azooKeyではソースコードを整形するため、[SwiftLint](https://github.com/realm/SwiftLint)を用いています。`brew`などでインストールしてください。

```bash
brew install swiftlint
swiftlint --version
```

Xcodeでは、`swiftlint`が有効になっていれば自動でソースコードの整形が行われるようになっています。それ以外の環境では手動で`swiftlint --fix`を`azooKey/`で実行してください。

### 2.3. ブランチを切る

azooKeyのディレクトリで、以下のコマンドを実行します。こうすることで、`develop`をベースにブランチを新しく作成できます。

```bash
git switch -c feat/do_something
```

### 2.4. ファイルを変更する

ドキュメントなどを参考に、変更を行ってください。

### 2.5. Build・Runして変更を確認する

変更が正しく反映されていることを、XcodeでBuild・Runして確認してください。

### 2.6. コミットして、ブランチをPushする

まず、変更をcommitしてください。Xcode上でやるのが簡単だと思います。この際、余計なファイルがcommitされていないか注意してください。

ブランチをpushします。

```bash
git push <alias> feat/do_something
```

### 2.7. Pull Requestを立てる

「feat: 〇〇する」のようなPull Requestを立ててください。管理者が確認し、問題なければmergeします。mergeされた変更は、その後のリリースでazooKeyのユーザに提供されます。

### まとめ

これが一連のプロセスです。少しやることが多いように見えますが、ほとんどは一般的な開発のプロセスと変わりません。

わからないことがあれば、気軽にIssueを立ててください。Issueをきっかけにドキュメントを追加したり、よりわかりやすい表現に置き換えたりすることができます。

## 3. さらに開発に参加する

基本的に、開発は以上のプロセスと同じ方法で行います。開発への参加は大歓迎です。

何か新しいことを始める場合、まずはIssueを立てるか、すでに立っているIssueを引き受けてください。[Good First IssueのラベルのついているIssue](https://github.com/ensan-hcl/azooKey/labels/good%20first%20issue)は取り組みやすいと思います。

開発作業中にわからないことがあった場合は気軽にIssueで質問してください。

### 3.1. 不具合を修正する

不具合はIssueで管理しています。`Bug`などのタグでフィルターすると見つけられるでしょう。新たに見つけた不具合を修正する場合は、Issueを立ててください。

### 3.2. 新機能を追加する

新機能もIssueで管理しています。`Enhancement`などのタグでフィルターすると見つけられるでしょう。新たな機能を提案する場合は、Issueを立ててください。

新機能の提案は受け入れられる場合と受け入れられない場合がありますが、Vision Document (`docs/visions`) の内容に則った提案は受け入れられる可能性が高いです。

### 3.3. リファクタリングする

テストを追加する、ドキュメントを整理・追加する、コードを高速化するなど、気軽に提案してください。

