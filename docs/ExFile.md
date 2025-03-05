# 初期化ファイルの操作

初期化ファイル(.ini)の内容を読み込むスクリプトです。

- 特定のキー１つに対して、読み込み・書き込みを行う
- 一度にすべての内容を読み込み管理する。

## ダウンロード

- [スクリプトファイル](https://github.com/cacao-soft/RMVX/raw/main/ExFile.rb)

## 関数一覧

### 特定のキーの値を取得

```ruby
IniFile.read(filename, section, key, default="")
```

|引数|説明|デフォルト値|
|-|-|-|
|filename|読み込む ini ファイル名||
|section|セクション名||
|key|キー名||
|default|値が存在しない場合のデフォルト値|""|

### 特定のキーの値を設定

```ruby
IniFile.write(filename, section, key, string)
```

|引数|説明|デフォルト値|
|-|-|-|
|filename|書き込む ini ファイル名||
|section|セクション名||
|key|キー名||
|string|設定する値 (数値の場合は、文字列に変換します。)||

## サンプル

### 設定の更新 (読み込みと書き込み)

```ruby
title = IniFile.read("Game.ini", "Game", "Title", "無題")
IniFile.write("Game.ini", "Game", "Title", "新・タイトル")
```

### 新規に初期化ファイルを作成

```ruby
settings = IniFile.new("filename.ini")
settings["Section"]["Key"] = 123
settings["Section"]["Key2"] = "テスト"
settings.save
```

### 既存の初期化ファイルを読み込む

```ruby
settings = IniFile.new("Game.ini")
settings.load
# 特定のキーの値を確認
p settings["Game"]["Title"]
# すべての情報を確認
p settings
```
