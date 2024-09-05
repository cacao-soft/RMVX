#=============================================================================
#  [RGSS2] Custom Menu Config - v1.0.4
# ---------------------------------------------------------------------------
#  Copyright (c) 2021 CACAO
#  Released under the MIT License.
#  https://opensource.org/license/mit
# ---------------------------------------------------------------------------
#  [Twitter] https://twitter.com/cacao_soft/
#  [GitHub]  https://github.com/cacao-soft/
#=============================================================================

=begin

 -- 概    要 ----------------------------------------------------------------

  カスタムメニューのメニュー項目の設定です。

 -- 注意事項 ----------------------------------------------------------------

  ※ Custom Menu Base の下に導入してください。
  ※ このスクリプトは、カスタムメニューの動作には必要ありません。

 -- 項目追加 ----------------------------------------------------------------

  ※ 開発者向けの情報です。

  項目の設定を追加するには、$custom_menu_command にハッシュで追加します。
#~ $custom_menu_command ||= {}
#~ $custom_menu_command[識別子] = ["項目名", "項目処理", システム項目, 禁止処理]
  １行目は、変数が定義されているかを調べて、未定義なら初期化します。
  ２行目が実際に設定を追加する処理です。追加したい数だけ設定してください。

  ※ これらの処理は、このスクリプトより上で行ってください。
  ※ 識別子には、番号ではなくシンボルを使用することを推奨します。

=end


#==============================================================================
# ◆ ユーザー設定
#==============================================================================

  #--------------------------------------------------------------------------
  # ◇ メニュー項目の設定
  #--------------------------------------------------------------------------
  #   Custom Menu Base でのメニュー項目の設定を上書きします。
  #   設定方法は１項目をセットで設定すること以外はすべて同じです。
  #
  #   [項目名, 項目処理, システム項目, 禁止処理] の順で設定してください。
  #
  #  【簡易設定】
  #     下のほうの一覧にある番号を記述するだけ設定することができます。
  #     例）CMD_CFG = [0, 1, 2, 3, 4, 6]    # これでデフォルトのメニュー項目
  #--------------------------------------------------------------------------
  CMD_CFG = [
    # [ 項目名, 項目処理, システム項目, 禁止処理 ]
    [ # アイテム
      'アイテム',
      'Scene_Item.new',
      false, false
    ],

    [ # スキル
      'スキル',
      'Scene_Skill.new(s_index)',
      false, false
    ],

    [ # 装備
      '装備',
      'Scene_Equip.new(s_index)',
      false, false
    ],

    [ # ステータス
      'ステータス',
      'Scene_Status.new(s_index)',
      false, false
    ],

    [ # セーブ
      'セーブ',
      'Scene_File.new(true, false, false)',
      true, '$game_system.save_disabled'
    ],

    6,  # ゲーム終了
  ]

  #==========================================================================
  #
  # 【デフォルト】
  #    0 .. アイテム                     1 .. スキル
  #    2 .. 装備                         3 .. ステータス
  #    4 .. セーブ                       5 .. ロード
  #    6 .. ゲーム終了                   7 .. メニューを閉じる
  #
  # 【CACAO SOFT】
  #   10 .. モンスター図鑑              11 .. モンスター図鑑 #2
  #   12 .. パーティ編成                13 .. ステータス振り分け
  #
  # 【KGC Software】
  #   20 .. モンスター図鑑              21 .. スキルCP制
  #   22 .. スキル習得装備              23 .. パラメータ振分 (1 or 2)
  #   24 .. 多人数パーティ              25 .. 戦闘難易度
  #
  # 【TYPE74RX-T】
  #   30 .. 冒険メモ                    31 ..
  #
  # 【First Seed Material】
  #   40 .. ExScene_Outline ※          41 ..
  #
  # 【Space not far】
  #   50 .. ポイント制スキル習得        51 .. ポイント制パラメーター成長
  #   52 .. サウンドテスト              53 .. 隊列並び替え
  #
  # 【Code Crush】
  #   60 .. キャラ紹介画面 ※           61 .. 用語辞典 ※
  #   62 .. パーティー編集              63 ..
  #
  # 【RGSS Wiki】
  #   70 .. ATB設定(サイドビュー戦闘)   71 ..
  #
  # 【白の魔】
  #   80 .. スキルポイント振り分け      81 .. パーティ入れ替え改 ※
  #   82 .. 魔物図鑑 ※                 83 .. アイテム図鑑 (道具図鑑) ※
  #   84 .. アイテム図鑑 (武器図鑑) ※  85 .. アイテム図鑑 (防具図鑑) ※
  #   86 .. アイテム図鑑 (2 or 3) ※    87 ..
  #
  #
  #  ※ マーク付きのスクリプトは改変が必要です。
  #     下記サイトの「コマンド設定」から改変箇所をご確認ください。
  #     http://cacaosoft.webcrow.jp/script/rgss2/cm/
  #
  #==========================================================================


#/////////////////////////////////////////////////////////////////////////////#
#                                                                             #
#                下記のスクリプトを変更する必要はありません。                 #
#                                                                             #
#/////////////////////////////////////////////////////////////////////////////#


module CAO::CM
  $custom_menu_command ||= {}
  #--------------------------------------------------------------------------
  # ● メニュー項目設定の取得
  #--------------------------------------------------------------------------
  #   type : 識別番号
  #--------------------------------------------------------------------------
  def self.set_command(type)
    # 拡張項目
    return $custom_menu_command[type] if $custom_menu_command[type]
    # 通常項目
    case type
    # デフォルト
    when 0
      return ['アイテム', 'Scene_Item.new', false, false]
    when 1
      return ['スキル', 'Scene_Skill.new(s_index)', false, false]
    when 2
      return ['装備', 'Scene_Equip.new(s_index)', false, false]
    when 3
      return ['ステータス', 'Scene_Status.new(s_index)', false, false]
    when 4
      return ['セーブ', 'Scene_File.new(true, false, false)',
              true, '$game_system.save_disabled']
    when 5
      return ['ロード', 'Scene_File.new(false, false, false)', true, false]
    when 6
      return ['ゲーム終了', 'Scene_End.new', true, false]
    when 7
      return ['閉じる', 'Scene_Map.new', true, false]
    # CACAO SOFT
    when 10
      return ['%CAO::Ebook::EBOOK_NAME', '%start_ebook', true, false]
    when 11
      return ['%CAO::MB::TEXT_MB_TITLE', '%start_mbook', true, false]
    when 12
      return ['パーティ編成', '%start_party_selection', false, false]
    when 13
      return ['振り分け', 'Scene_StatusPoint.new(actor.id)', false, false]
    # KGC Software
    when 20
      return ['%KGC::EnemyGuide::VOCAB_MENU_ENEMY_GUIDE',
              'Scene_EnemyGuide.new', true, false]
    when 21
      return ['%KGC::SkillCPSystem::VOCAB_MENU_SET_SKILL',
              'Scene_SetBattleSkill.new(s_index)', false, false]
    when 22
      return ['%KGC::EquipLearnSkill::VOCAB_MENU_AP_VIEWER',
              'Scene_APViewer.new(s_index)', false, false]
    when 23
      return ['%KGC::DistributeParameter::VOCAB_MENU_DISTRIBUTE_PARAMETER',
              'Scene_DistributeParameter.new(s_index)', false, false]
    when 24
      return ['%KGC::LargeParty::VOCAB_MENU_PARTYFORM',
              'Scene_PartyForm.new', false, false]
    when 25
      return ['%Commands.set_variable_text('\
              'KGC::BattleDifficulty::DIFFICULTY_VARIABLE,'\
              'KGC::BattleDifficulty::DIFFICULTY)[:name]',
              '%Commands.add_variable_value('\
              'KGC::BattleDifficulty::DIFFICULTY_VARIABLE,'\
              'KGC::BattleDifficulty::DIFFICULTY.size)', true, false]
    # TYPE74RX-T
    when 30
      return ['%RX_T::RX_MemoCommand', 'Scene_RX_Memo.new', true, false]
    # First Seed Material
    when 40
      return ['冒険日記', 'Scene_Outline.new', true, false]
    # Space not far
    when 50
      return ['%SNF::LEARN_WORD', 'Scene_LearnSkill.new(s_index)', false, false]
    when 51
      return ['振り分け', 'Scene_GrowStatus.new(s_index)', false, false]
    when 52
      return ['%SNF::SOUND_HEAD', 'Scene_SoundTest.new', true, false]
    when 53
      return ['%SNF::ARRANGE_HEAD', 'Scene_Arrange.new', false, false]
    # Code Crush
    when 60
      return ['キャラ紹介', 'Scene_Charactor.new(s_index)', false, false]
    when 61
      return ['用語辞典', 'Scene_Dictionary.new', true, false]
    when 62
      return ['パーティ編成', 'Scene_PartyEdit.new(c_index)', false, false]
    # RGSS Wiki
    when 70
      return ['%N02::ATB_CUSTOMIZE_NAME', 'Scene_ATB.new', true, false]
    # 白の魔
    when 80
      return ['%WD_skilldivide_ini::Sp_command',
              'Scene_SkillPoint.new(s_index)', false, false]
    when 81
      return ['パーティ編成', 'Scene_MemberChange.new', false, false]
    when 82
      return ['魔物図鑑', 'Scene_MonsterDictionary.new', true, false]
    when 83
      return ['道具図鑑', 'Scene_ItemDictionary.new', true, false]
    when 84
      return ['武器図鑑', 'Scene_WeaponDictionary.new', true, false]
    when 85
      return ['防具図鑑', 'Scene_ArmorDictionary.new', true, false]
    when 86
      return ['アイテム図鑑', 'Scene_TotalDictionary.new', true, false]
    else
      msg = "(#{type}) : 存在しない識別番号です。\n"\
            "メニュー項目の設定を確認してください。"
      raise CustomizeError, msg, __FILE__
    end
  end
end

# メニュー項目の初期化
CAO::CM::CMD_NAME    = []   # 項目名
CAO::CM::CMD_SCENE   = []   # 項目処理
CAO::CM::CMD_SYSTEM  = []   # システム項目
CAO::CM::CMD_DISABLE = []   # 禁止処理

# メニュー項目の設定
for cmd in CMD_CFG
  if Array === cmd
    if cmd.size != 4
      msg = "wrong number of arguments (#{cmd.size} for 4)"
      raise CustomizeError, msg, __FILE__
    end
  else
    cmd = CAO::CM.set_command(cmd)
  end
  CAO::CM::CMD_NAME    << cmd[0]
  CAO::CM::CMD_SCENE   << cmd[1]
  CAO::CM::CMD_SYSTEM  << cmd[2]
  CAO::CM::CMD_DISABLE << cmd[3]
end
