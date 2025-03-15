# Custom Menu Base

- カスタムメニューを使うための機能が定義されています。
- 主にメニュー全体と項目の設定を行います。

## ダウンロード

- [Custom Menu Base](https://github.com/cacao-soft/RMVX/raw/main/CustomMenu/CustomMenuBase.rb)
- [Custom Menu Config](https://github.com/cacao-soft/RMVX/raw/main/CustomMenu/CustomMenuConfig.rb)
  ※ メニュー項目の設定を番号で行えるように拡張します。

## 使用準備

### 背景画像

```text
保存場所：Graphics/System
ファイル名：任意 (設定項目で変更可能)
画像サイズ：任意 (制限はありませんが、544x416 推奨)
```

## 設定項目

### メニュー項目名

```text
CMD_NAME = [
  "アイテム",
  "スキル",
  "装備",
  "ステータス",
  "セーブ",
  "ゲーム終了"
]
```

項目名を設定します。
配列の順序で項目を配置します。
順番を間違えないように注意してください。
例に倣って、文字列で記述してください。

#### スクリプトの記述

項目名の先頭に"%"を付けると、スクリプトだと判別します。

> 例）"%$game_variables[1]"

この例だと、イベント変数１番の値を項目名として表示します。

#### スイッチで項目名を変更

```ruby
Commands.set_switche_text(スイッチの番号, "ＯＮ", "ＯＦＦ")
```

> 例）'%Commands.set_switche_text(1, "ＹＥＳ", "ＮＯ")'

この例だと、１番のスイッチがＯＮのとき「ＹＥＳ」と表示して、
ＯＦＦのとき「ＮＯ」と表示します。

スイッチの番号のところに真偽値を入れれば、その値で判断します。

> 例）'%Commands.set_switche_text($game_system.save_disabled,
"セーブ可", "セーブ不可")'

#### 変数で項目名を変更

```ruby
Commands.set_variable_text(変数の番号, テキストの配列[, イベント？])
```

変数の場合は、テキストを配列で設定します。

> 例）'%Commands.set_variable_text(1, ["１", "２", "３"])'

この例だと、１番のイベント変数の値が 0 のとき「１」と、
1 のとき「２」というように表示されます。

こちらも変数の番号のところに、変数を入れることができます。
その場合は、３つ目の引数にfalseを入れる必要があります。

> 例）'%Commands.set_variable_text($game_variables[1], ["１", "２", "３"], false)'

#### 項目名を配列で設定

項目名に配列を使用することで項目名を分岐します。\
`['スクリプト', "分岐１", "分岐２", "分岐３"]`\
スクリプトの結果が真偽値だった場合、"分岐１"のテキストがtrue(ＯＮ時)、"分岐２"のテキストがfalse(ＯＦＦ時)の項目名となります。

> 例）['$game_switches[1]', "ＯＮ", "ＯＦＦ"]

例では、１番のスイッチの値によって項目名が変更されます。

ＥＶ変数で分岐する場合は、"分岐１"のテキストが 0 の時で順に増えていきます。

> 例）['$game_variables[1]', "１", "２", "３", "４"]

### 項目処理

```text
CMD_SCENE = [
  "Scene_Item.new",
  "Scene_Skill.new(s_index)",
  "Scene_Equip.new(s_index)",
  "Scene_Status.new(s_index)",
  "Scene_File.new(true, false, false)",
  "Scene_End.new"
]
```

項目の処理を設定します。
こちらも並び順で処理を割り当てますので、順番を間違えないように注意してください。
項目処理の設定例をいくつか用意しています。

こちらの設定は多少難しくなるかもしれません。
複数の設定方法がありますのでお間違えの無いように。

#### 項目処理の設定方法

項目処理を行うメソッドやシーン切り替えの処理を文字列で記述します。
$scene = Scene_Item.new などの処理がシーン切り替えの処理になります。
例でいうと Scene_Item.new の部分を記述します。
引数がある場合も同じように引数部分を含めて記述してください。
また、引数は次のように省略したものに置き換えることが出来ます。

```text
actor   : $game_party.members[@status_window.index]
c_index : @command_window.index
s_index : @status_window.index
```

> 例）"Scene_Skill.new(s_index)"

#### シーン切り替えのない処理

シーン切り替えのない処理も実行可能です。例えば、スイッチの操作などです。

> 例）"%$game_switches[1] ^= true"

この例では、１番のスイッチのＯＮ・ＯＦＦを切り替えます。

#### アクター選択の処理 (手動)

通常、アクター選択が必要かは自動で判別されますが、
メソッドの呼び出しなどでは、正しく判別できません。
そのような場合は、先頭に & を記述してください。

> 例）"&call_method"

#### コモンイベントの実行

```ruby
Commands.call_common(c_index, コモンＩＤ)
```

> 例）"Commands.call_common(c_index, 1)"

この例では、１番のコモンイベントを呼び出します。
コモンイベントの処理が終了すると、マップに戻ります。
メニューへ戻りたい場合は、イベントコマンド「ラベル」に
メニューへ戻ると記入してください。
自動で選択位置が調整されますが、戻り位置がおかしい場合などは、
メニューへ戻る(0)のように項目の戻り位置を指定する事が出来ます。

#### イベント変数の増加

```ruby
Commands.add_variable_value(変数の番号, 変化範囲[, 増加する値[, 初期値]])
```

このスクリプトを使用すると、指定された変数の値を増加させる事ができます。
※ このスクリプトで増加できる変数は、イベント変数のみです。

> 例）"%Commands.add_variable_value(1, 3)"

この例では、１番のイベント変数の値を 0...3 の範囲で１ずつ増加させます。
値が 2 まで行くと 0 へ戻ります。(012012012 ... )

追加の引数の増加する値は、そのままです。増加する値ですね。省略時には、１です。
初期値というのが、最大数まで上がった後に戻る値です。省略時は、０です。

#### 各ウィンドウの再描画

メニューを再表示せずにウィンドウの内容を更新したい場合に使用します。
項目処理とは ; で区切って記述してください。

```text
全ウィンドウ : Commands.refresh_all
コマンド     : Commands.refresh_command
ステータス   : Commands.refresh_status
オプション   : Commands.refresh_option
```

※ オプションの中には再描画を行わないものもあります。

### システム項目

```text
CMD_SYSTEM = [false, false, false, false, true, true]
```

パーティを組んでいないときにでも選択できる項目を設定します。
`true`で選択可、`false`で選択不可。

### 禁止処理

```text
CMD_DISABLE = [
  false, false, false, false, "$game_system.save_disabled", false
]
```

項目が選択禁止かを判定するための変数を文字列で指定します。\
判定しない場合は、`true`で常に禁止、`false`で常に許可します。

スイッチの状態で分岐させたい場合は、`"$game_switches[12]"`のようにします。\
１２番のスイッチがＯＮのとき項目の選択が禁止されます。

### サイドメニュー

```text
SIDE_KEY = nil    # ボタンの種類 (Input::A)
SIDE_SCENE = ""   # 実行する処理 (Scene_Debug.new)
```

サイドキーを設定して、ワンプッシュで処理を実行します。

> 例）SIDE_KEY = Input::A; SIDE_SCENE = "Scene_Debug.new"

この例だと、Ａボタン（Shiftキー）を押すとデバッグ画面を表示します。\
シーン移動する場合は、移動先のインスタンスを文字列でスクリプトを実行する場合は、先頭に % を加えた文字列で設定してください。
