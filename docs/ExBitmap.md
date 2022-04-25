# Bitmap Class EX

- Bitmap クラスに BMP,PNG 画像の出力機能を追加します。

## 注意事項

- このスクリプトは、開発者向けです。
- 当サイトの他のスクリプトより上に配置してください。
- Cacao Base Script がある場合は、その下に設置してください。

## スクリプト

- [ダウンロード](https://raw.githubusercontent.com/cacao-soft/RMVX/main/ExBitmap.rb)

## 使用方法

```
Bitmap#save_bitmap(filename)
```
このビットマップをビットマップファイルで出力  
filename : 保存するファイル名  

```
Bitmap#save_png(filename, alpha = false)
```
このビットマップをピングファイルで出力  
filename : 保存するファイル名  
alpha    : αチャンネルの有無  

```
Bitmap#save_png_g(filename, alpha = false)
```
このビットマップをピングファイル(グレースケール)で出力  
filename : 保存するファイル名  
alpha    : αチャンネルの有無  

```
Bitmap#draw_pixel(x, y, color)
```
このビットマップに点を描画します。  

```
Bitmap#draw_rect(x, y, width, height, color)
Bitmap#draw_rect(rect, color)
```
このビットマップに矩形(単色)を描画します。  

```
Bitmap#draw_line_rect(x, y, width, height, color[, border])
Bitmap#draw_line_rect(rect, color[, border])
```
このビットマップに矩形(枠)を描画します。  
border : 枠の太さ (省略時、1)  

```
Bitmap#draw_gradient_rect(x, y, width, height, gc1, gc2[, vertical])
Bitmap#draw_gradient_rect(rect, gc1, gc2[, vertical])
```
このビットマップに矩形(グラデーション)を描画します。  

```
Bitmap#draw_window(x, y, width, height[, windowskin[, opacity]])
Bitmap#draw_window([rect][, windowskin[, opacity]])
```
このビットマップにウィンドウを描画します。  
x,y,width,height,rect : ウィンドウの位置とサイズ (省略時、最大サイズ)  
windowskin : スキン名、スキン画像 (省略時、スキン名(Window))  
opacity    : ウィンドウの不透明度 (省略時、200)  

## サンプル

### Bitmap 画像の出力

```
bmp = Bitmap.new(32, 32)
bmp.save_bitmap("bitmap.bmp")
```
これで、ゲームフォルダに "bitmap.bmp" という画像が作成されます。
アルファチャンネルなしのフルカラーで出力します。

### PNG 画像の出力

ＰＮＧ画像は、いくつか出力方法を選べます。

1. アルファチャンネル付き

```
bmp = Bitmap.new("Graphics/Battlers/Slime")
bmp.save_png("Slime.png", true)
```

2. アルファチャンネルなし

```
name = Time.now.strftime("%Y%m%d%H%M%S")
bmp = Graphics.snap_to_bitmap
bmp.save_png("ScreenShot/#{name}.png")
```
※ ScreenShot フォルダを作成しておく必要があります。

3. グレースケール α付き

```
bmp = Bitmap.new("Graphics/Battlers/Slime")
bmp.save_png_g("Slime_g.png", true)
```

4. グレースケール αなし

```
name = Time.now.strftime("%Y%m%d%H%M%S")
bmp = Graphics.snap_to_bitmap
bmp.save_png_g("ScreenShot/#{name}.png")
```

### 色相変更後のエネミーの画像を出力

```ruby
# 出力するモンスターの番号を指定して下さい。
# 単数の場合は [1] など、
# 複数の場合は [1,2,3]など 数値との間を , で区切る
# 色相は、データベースで設定しておいてください。
for enemy_id in [1, 3, 12]  # 出力するエネミーの ID
  name = $data_enemies[enemy_id].battler_name
  hue = $data_enemies[enemy_id].battler_hue
  save = name + ".png"
  Cache.battler(name, hue).save_png(save, true)
end
print "出力完了！"
```

### スクリーンショット

- [F5 撮影](https://raw.githubusercontent.com/cacao-soft/RMVX/main/ScreenShot_F5.rb)
- [PrtScr 撮影](https://raw.githubusercontent.com/cacao-soft/RMVX/main/ScreenShot_PS.rb)
