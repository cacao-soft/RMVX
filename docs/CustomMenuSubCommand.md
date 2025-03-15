# サブコマンドウィンドウ

- メニューコマンドから呼び出せるサブコマンドの機能を追加します。

## ダウンロード

- [スクリプト](https://github.com/cacao-soft/RMVX/raw/main/CustomMenu/CustomMenuSubCommand.rb)

## 設定項目

### メニュー項目名

### サブコマンドの設定

```ruby
COMMANDS[0] = {
  :pos  =>> [160,24,160],
  :text => ["アイテムＡ", "アイテムＢ", "アイテムＣ"],
  :func => [ Scene_Skill,
             'Scene_Item.new',
             '%call_common(@c_index, 1)' ]
}
```

この形式を１グループとして設定します。\
サブコマンドを増やしたい場合は、同じものを増やして\
COMMANDS[n] n の値を変更して下さい。\
n は、start_subcommand_selection(n) で使用します。

### :pos

```ruby
:pos  => [ｘ座標, ｙ座標, 横幅, 文字位置],
```

ウィンドウの位置と横幅、文字位置を設定します。\
縦幅は項目数で自動で変更されます。\
文字位置は(0..左揃え、1..中央揃え、2..右揃え)の数値で設定します。\
省略時は左揃えです。

### :text

```ruby
:text => ["アイテムＡ", "アイテムＢ", "アイテムＣ"],
```

項目名の設定です。表示したい数だけ追加してください。\
設定方法は、Custom Menu Base の項目名の設定と同じです。

### :func

```ruby
:func => [Scene_Skill, 'Scene_Item.new', '%call_common(@c_index, 1)']
```

項目処理の設定です。
項目名に合わせて設定してください。
Custom Menu Base での設定とほぼ同じです。

- **【シーン移動】**
  - シーン切り替えのスクリプト $scene = Hoge.new の右の部分を文字列で記述します。
- **【スクリプトの実行】**
  - 文字列の先頭に % を加えると、シーン移動を行わなずに実行します。
  - イベント変数の操作も同様に行えます。
  - '%add_variable_value(変数の番号, 変化範囲[, 増加値[, 初期値]])'
- **【コモンイベント】**
  - '%call_common(@c_index, コモンＩＤ)' と記述します。
- **【各ウィンドウの再描画】**
  - 項目処理とは ; で区切ってください。
    - 全ウィンドウ : refresh_all
    - コマンド : refresh_command
    - ステータス : refresh_status
    - オプション : refresh_option
- **【サブコマンドを閉じる】**
  - 項目処理とは ; で区切ってください。
    - メニュー項目へ戻る : quit
    - アクター選択へ戻る : back
  - > 例）'%$game_switches[1]=true;refresh_command;quit'
- **【ステータスウィンドウの選択位置を変更】**
  - sindex(value) : value の値だけ位置を進めます。負数の場合は戻します。
- **【その他】**
  - コマンドウィンドウのインデックスは、@c_indexで取得できます。
  - ステータスウィンドウのインデックスは、@s_indexで取得できます。
  - サブコマンドの選択項目のインデックスは、@select_idで取得できます。
  - ※ :disable の判定では使用できません。

### :disable

```ruby
:disable  => ['$game_system.save_disabled', nil],
```

項目が選択可能かを判定する式を文字列で設定します。この設定は省略可能です。\
設定する場合は、項目すべての設定を行ってください。\
判定を行わない項目は、`nil`もしくは`false`と設定してください。

## 使用方法

### サブコマンドの表示

Custom Menu Base の項目処理の設定を次のように設定します。

```text
'%start_subcommand_selection(ID)'
```

サブコマンドの設定で設定した COMMANDS[0] = {} の 0 の部分がIDです。

```text
'%start_subcommand_selection(ID, s_index)'
```

アクター選択を行ってから、サブコマンドを表示します。\
項目処理で選択した項目を取得するには`@s_index`を使用します。\
選択されたアクターを取得するには`actor`を使用してください。
