# Cacao Base Script

## 概要

- 拙作スクリプトの動作に必要となる機能を定義したベーススクリプト

## 必須事項

- 導入場所
  - 他の拙作スクリプトよりも上に配置してください。

## 機能一覧

### 標準

- Object#marshal_copy
  - 深いコピー。Marshal.load(Marshal.dump(self))と同じ。
- Array#swap(pos1, pos2)
  - 要素の入れ替え。self を返す。
- Array#move(src_pos, dest_pos)
  - 要素の移動。self を返す。

### RGSS

- Rect#to_a
  - [x, y, width, height] の配列を返す。
- Color#to_a
  - [red, green, blue, alpha] の配列を返す。

### 拡張

- Point.new(x, y)
	- Point#x, Point#y, Point#to_a

- RPG::Time.total
	- フレーム数から経過秒数を算出
- RPG::Time.to_a
	- 経過時間を配列で取得 [時間, 分数, 秒数]
- RPG::Time.to_s(format = "%03d:%02d:%02d")
	- 経過時間を文字列で取得 "999:59:59"

- Cache.bitmap(filename)
	- ビットマップキャッシュの取得
- Cache.bitmap(filename, bitmap)
	- ビットマップキャッシュの設定
- Cache.bitmap?(filename)
	- キャッシュの有無を確認
- Cache.clear_bitmap(filename)
	- 特定のキャッシュを削除する
- Bitmap#to_cache(filename)
	- ビットマップをキャッシュする

- $data_mapinfos[map_id].name
	- map_id のマップ名を取得 (データベース上)
- Game_Map#name(check_area = true, convert = true)
	- 現在地名の取得 (check_area エリア名を含めるか convert 制御文字削除の可否)
- Game_Map#map_name(convert = false)
	- マップ名を取得 (convert 制御文字削除の可否)
- Game_Map#area_name(convert = false)
	- エリア名を取得 (convert 制御文字削除の可否)
- Game_Map#convert_text(text)
	- 制御文字を削除した文字列を作成

- Vocab.exp
	- 経験値の名称
- Vocab.exp_a
	- 経験値の略称
- Game_Actor#level_up_exp
	- レベルアップに必要な総経験値の取得 (レベル 1 から)
- Game_Actor#next_rest_exp
	- レベルアップに必要な残り経験値の取得
- Game_Actor#level_exp
	- レベルアップに必要な経験値の取得 (現在のレベルから)
- Window_Base#exp_color(actor)
	- exp_color(actor)
- Window_Base#exp_gauge_color1
	- EXP ゲージの色 1 の取得
- Window_Base#exp_gauge_color2
	- EXP ゲージの色 2 の取得
- Window_Base#draw_actor_exp(actor, x, y, width = 120)
	- 経験値の描画
- Window_Base#draw_actor_exp_gauge(actor, x, y, width = 120)
	- 経験値ゲージの描画