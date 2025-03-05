# ディレクトリの操作

- 特殊ディレクトリ(デスクトップ、マイドキュメント、Application Data)のパスの取得
- ディレクトリの作成
- ファイルの検索

## スクリプト

- [ダウンロード](https://raw.githubusercontent.com/cacao-soft/RMVX/main/ExDir.rb)

## 機能一覧

### デスクトップのパスを取得

```
DirEx.psf(DieEx::DESKTOP)  
```

### マイドキュメントのパスを取得

```
DirEx.psf(DieEx::PERSONAL)  
```

### Application Dataのパスを取得

```
DirEx.psf(DieEx::APPDATA)
```

### ディレクトリの作成

```
DirEx.mkdir("ディレクトリのパス")
```

機能的には Dir.mkdir と同じです。
ただし、途中のディレクトリがなくても例外を出さずに作成します。

### パターンに一致するファイルを検索

```
DirEx.glob(パターン)
```

パターンに一致するフォルダ・ファイルのパスを配列で返します。
Dir.glob は、日本語に対応していないため
日本語名のフォルダを含めると正しく検索できません。
この機能は、Win32 API の FindFirstFile と同じものです。
Ruby の Dir.glob とは異なりますのでご注意ください。
FindFirstFile 関数は、最後に円記号(\)を付けると必ず失敗するそうです。

```ruby
# カレントディレクトリ内のフォルダとファイルを検索
DirEx.glob("./*")
# カレントディレクトリ内のセーブファイルを検索
DirEx.glob("./Save*.rvdata")
```