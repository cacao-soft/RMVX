#=============================================================================
#  [RGSS2] ディレクトリ操作 - v1.0.2
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

  フォルダ操作に関する標準ライブラリの機能を補います。

 -- 注意事項 ----------------------------------------------------------------

  ※ 他のＣＡＣＡＯ製スクリプトより上に配置してください。
  ※ Cacao Base Script がある場合は、その下に設置してください。

 -- 使用方法 ----------------------------------------------------------------

  ★ 特殊ディレクトリのパスを取得 (CSIDL)
   DirEx.psf(DieEx::DESKTOP)     # デスクトップ
   DirEx.psf(DieEx::PERSONAL)    # マイドキュメント
   DirEx.psf(DieEx::APPDATA)     # Application Data

  ★ 特殊ディレクトリのパスを取得
   DirEx.pdsk                    # デスクトップ
   DirEx.pusr                    # マイドキュメント
   DirEx.papp                    # Application Data
   DirEx.ptmp                    # 一時フォルダ
  ※ パスの最後に / は付かない。

  ★ ディレクトリの作成
   DirEx.mkdir("ディレクトリのパス")
   DirEx.mkdir("./Test/")        # カレントディレクトリに Test を作成
   DirEx.mkdir('C:\Test\Folder') # C ドライブに Test とその中に Folder 作成
  ※ 存在しないフォルダ内でも作成できます。
  ※ 既にフォルダが存在している場合も例外は発生しません。
  ※ その他の機能は、Dir.mkdir と同じです。

  ★ パターンに一致するファイルを検索
   DirEx.glob(patten)
  ※ FindFirstFile と同じ機能です。Dir.glob とは異なります。
  ※ 最後に円記号(\)を付けると必ず失敗します。

=end


#/////////////////////////////////////////////////////////////////////////////#
#                                                                             #
#                下記のスクリプトを変更する必要はありません。                 #
#                                                                             #
#/////////////////////////////////////////////////////////////////////////////#


class DirEx
  #--------------------------------------------------------------------------
  # ● 定数
  #--------------------------------------------------------------------------
  MAX_PATH = 260              # パスの最大サイズ
  PACK_CODE = "Z#{MAX_PATH}"  # 
  #--------------------------------------------------------------------------
  # ● CSIDL 値
  #--------------------------------------------------------------------------
  DESKTOP   = 0x00            # デスクトップ
  PERSONAL  = 0x05            # マイドキュメント
  APPDATA   = 0x1A            # Application Data
  #--------------------------------------------------------------------------
  # ● Win32API
  #--------------------------------------------------------------------------
  SHGetSpecialFolderPath =
    Win32API.new('shell32', 'SHGetSpecialFolderPath', 'lpii', 'i')
  GetTempPath =
    Win32API.new('kernel32.dll', 'GetTempPathA', 'ip', 'i')
  FindFirstFile =
    Win32API.new('kernel32', 'FindFirstFile', 'pp', 'l')
  FindNextFile =
    Win32API.new('kernel32', 'FindNextFile', 'lp', 'i')
  FindClose =
    Win32API.new('kernel32', 'FindClose', 'l', 'i')
  #--------------------------------------------------------------------------
  # ● 特殊ディレクトリのパスを取得
  #--------------------------------------------------------------------------
  def self.psf(csidl)
    sz = [""].pack(PACK_CODE)
    SHGetSpecialFolderPath.call(0, sz, csidl, 0)
    return NKF.nkf("-w -x -m0", sz.unpack(PACK_CODE).first).gsub("\\", "/")
  end
  #--------------------------------------------------------------------------
  # ● デスクトップのパスを取得
  #--------------------------------------------------------------------------
  def self.pdsk
    return self.psf(DESKTOP)
  end
  #--------------------------------------------------------------------------
  # ● マイドキュメントのパスを取得
  #--------------------------------------------------------------------------
  def self.pusr
    return self.psf(PERSONAL)
  end
  #--------------------------------------------------------------------------
  # ● Application Data のパスを取得
  #--------------------------------------------------------------------------
  def self.papp
    return self.psf(APPDATA)
  end
  #--------------------------------------------------------------------------
  # ● 一時フォルダのパスを取得
  #--------------------------------------------------------------------------
  def self.ptmp
    sz = [""].pack(PACK_CODE)
    GetTempPath.call(MAX_PATH, sz)
    path = sz.unpack(PACK_CODE).first
    return NKF.nkf("-w -x -m0", path).gsub("\\", "/").sub(/\/$/, "")
  end
  #--------------------------------------------------------------------------
  # ● ディレクトリ階層を作成
  #--------------------------------------------------------------------------
  def self.mkdir(path)
    tmp = ""
    for d in path.split(/[\/\\]/)
      tmp << d + "/"
      next if FileTest.directory?(tmp)
      Dir.mkdir(tmp)
    end
  rescue => error
    raise error.class, error.message, caller.first
  end
  #--------------------------------------------------------------------------
  # ● ディレクトリ・ファイルの列挙
  #--------------------------------------------------------------------------
  def self.glob(patten)
    result = []
    fd = "\0" * 328
    hFind = FindFirstFile.call(NKF.nkf("-s", patten), fd)
    if hFind != -1
      begin
        result << NKF.nkf('-w', fd.unpack('x44A260').first)
        fd = "\0" * 328
      end while FindNextFile.call(hFind, fd) == 1
    end
    FindClose.call(hFind)
    return result
  end
end
