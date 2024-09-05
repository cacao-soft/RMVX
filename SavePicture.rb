#=============================================================================
#  [RGSS2] ピクチャの画像保存 - v1.0.0
# ---------------------------------------------------------------------------
#  Copyright (c) 2021 CACAO
#  Released under the MIT License.
#  https://opensource.org/licenses/mit-license.php
# ---------------------------------------------------------------------------
#  [Twitter] https://twitter.com/cacao_soft/
#  [GitHub]  https://github.com/cacao-soft/
#=============================================================================

=begin

 -- 概    要 ----------------------------------------------------------------

  表示されているピクチャを画像として保存する機能を追加します。

 -- 注意事項 ----------------------------------------------------------------

  ※ このスクリプトの実行には、『＜拡張＞ ピクチャの操作』 が必要です。
  ※ フォルダ・ファイル名には、\ / : * ? " < > / の文字を使用できません。

 -- 使用方法 ----------------------------------------------------------------

  ★ save_picture(id[, ...])
   イベントコマンド「スクリプト」内でのみ使用可能です。
   引数には、保存するピクチャの番号を設定します。
   複数の番号を設定すると最初のピクチャに残りを重ねて保存されます。

  ★ $game_system.picture_count
   セーブ回数を取得します。数値を代入することで回数の変更も可能です。


=end


module CAO::Picture
  #--------------------------------------------------------------------------
  # ◇ 保存先フォルダ
  #--------------------------------------------------------------------------
  #   文字列でフォルダ名を設定します。( / で区切ると断層的な設定も可能)
  #   空文字列 "" にするとフォルダを作成しません。
  #--------------------------------------------------------------------------
  #   %N : セーブ番号(00)      例）"ScreenShot/Save%N"
  #--------------------------------------------------------------------------
  SS_DIRECTORY = "ScreenShot"
  
  #--------------------------------------------------------------------------
  # ◇ 保存ファイル名
  #--------------------------------------------------------------------------
  #   以下の %○ の文字は、特定の情報に置き換えられます。
  #--------------------------------------------------------------------------
  #   %N セーブ番号(00)  %n 保存回数(001)  %% %自身
  #   %Y 西暦  %y 西暦(下2桁)  %m 月(01)  %d 日(01)  %j 通算日(001-366)
  #   %H 時間(24時間制)  %I 時間(12時間制)  %M 分(00)  %S 秒(00)
  #--------------------------------------------------------------------------
  SS_FILENAME = "%j%M%S%n"
end

class Game_System
  #--------------------------------------------------------------------------
  # ● 公開インスタンス変数
  #--------------------------------------------------------------------------
  attr_accessor :picture_count            # ピクチャを保存した回数
  #--------------------------------------------------------------------------
  # ○ オブジェクト初期化
  #--------------------------------------------------------------------------
  alias _cao_initialize_pic initialize
  def initialize
    _cao_initialize_pic
    @picture_count = 0
  end
end

class Game_Interpreter
  #--------------------------------------------------------------------------
  # ● ピクチャを PNG 形式で保存
  #--------------------------------------------------------------------------
  def save_picture(*args)
    if args.empty?
      msg = "wrong number of arguments (#{0} for 1)"
      raise ArgumentError, msg, caller.first
    end
    for i in args
      unless i.is_a?(Fixnum)
        msg = "wrong argument type #{i.class} (expected Fixnum)"
        raise TypeError, msg, caller(3).first
      end
      if i < 1
        msg = "id #{i} out of range"
        raise IndexError, msg, caller(3).first
      end
    end
    spriteset = $scene.instance_variable_get(:@spriteset)
    picture_sprites = spriteset.instance_variable_get(:@picture_sprites)
    picture_sprites.each {|sprite| sprite.update }
    for id in args
      sprite = picture_sprites[id - 1]
      unless sprite && sprite.bitmap
        print "#{id} 番のピクチャに画像が設定されていません。"
        return
      end
    end
    width = picture_sprites[args.first - 1].bitmap.width
    height = picture_sprites[args.first - 1].bitmap.height
    bitmap = Bitmap.new(width, height)
    for id in args
      sprite = picture_sprites[id - 1]
      next if sprite.bitmap == nil || sprite.bitmap.disposed?
      bitmap.blt(0, 0, sprite.bitmap, sprite.bitmap.rect)
    end
    $game_system.picture_count += 1
    if CAO::Picture::SS_DIRECTORY
      directory = CAO::Picture::SS_DIRECTORY.dup
      directory.gsub!("%N", sprintf("%02d",$game_temp.last_file_index))
      if directory != "" && !FileTest.directory?(directory)
        dir = ""
        for d in directory.gsub("\\", "/").split("/")
          dir += "#{d}"
          Dir::mkdir(dir) unless FileTest.directory?(dir)
          dir += "/"
        end
      end
      filepath = "#{CAO::Picture::SS_DIRECTORY}/#{CAO::Picture::SS_FILENAME}"
    else
      filepath = CAO::Picture::SS_FILENAME.dup
    end
    filepath.gsub!("%n", sprintf("%03d",$game_system.picture_count))
    filepath.gsub!("%N", sprintf("%02d",$game_temp.last_file_index))
    bitmap.save_png(Time.now.strftime(filepath) + ".png", true)
    bitmap.dispose
  end
end
