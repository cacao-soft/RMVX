# カスタムメニュー (コマンド設定)

ベーススクリプト内の設定項目『項目処理』に設定する文字列です。\
この部分に何を書けばいいのか分からない場合は参考にしてください。\
これらのスクリプトは、カスタムメニューより上に導入して動作を確認しております。

## CACAO SOFT

### モンスター図鑑

項目処理：`"%start_ebook"`

### モンスター図鑑 #2

項目処理：`"%start_mbook"`

### パーティ編成

項目処理：`"%start_party_selection"`

### ステータス振り分け

項目処理：`"Scene_StatusPoint.new(actor.id)"`

## KGC Software

### モンスター図鑑

項目処理：`"Scene_EnemyGuide.new"`

### スキルCP制

項目処理：`"Scene_SetBattleSkill.new(s_index)"`

### スキル習得装備

項目処理：`"Scene_APViewer.new(s_index)"`

### パラメータ振分

項目処理：`"Scene_DistributeParameter.new(s_index)"`

### 多人数パーティ

項目処理：`"Scene_PartyForm.new"`

### 戦闘難易度

項目名： `"%Commands.set_variable_text(KGC::BattleDifficulty::DIFFICULTY_VARIABLE, KGC::BattleDifficulty::DIFFICULTY)[:name]"`

項目処理： `"%Commands.add_variable_value(KGC::BattleDifficulty::DIFFICULTY_VARIABLE, KGC::BattleDifficulty::DIFFICULTY.size)"`

※ サイドキーへの設定は、%削除して項目処理を記述します。

## TYPE74RX-T

### 冒険メモ

項目処理：`"Scene_RX_Memo.new"`

※ こちらのスクリプトは、Interpreter 108 EX と競合します。
注釈処理の必須スクリプト、Interpreter 108 EX、冒険メモの順で導入して下さい。
これだけだと問題が隠れただけなので、TYPE74RX-Tさんの注釈処理のスクリプトの
Game_Interpreter#execute_command の定義をコメントアウトしてみてください。
それで問題なく動作するようでしたら、大丈夫だと思います。

## Space not far

### ポイント制スキル習得

項目処理：`"Scene_LearnSkill.new(s_index)"`

### ポイント制パラメーター成長

項目処理：`"Scene_GrowStatus.new(s_index)"`

### サウンドテスト

項目処理：`"Scene_SoundTest.new"`

### 隊列並び替え

項目処理：`"Scene_Arrange.new"`

## 白の魔

### スキルポイント振り分け

項目処理：`'Scene_SkillPoint.new(s_index)'`

下記スクリプトで、メニュー項目からの呼び出しを可能にします。

### パーティ入れ替え改

項目処理：`'Scene_MemberChange.new'`

下記スクリプトで、メニュー項目からの呼び出しを可能にします。

```ruby
class Scene_MemberChange
  def return_scene
    if $game_temp.last_menu_index < 0
      $scene = Scene_Map.new
    else
      $scene = Scene_Menu.new
    end
  end
end
```

### 魔物図鑑

項目処理：`'Scene_MonsterDictionary.new'`

下記スクリプトで、メニュー項目からの呼び出しを可能にします。

```ruby
class Scene_MonsterDictionary
  def return_scene
    if $game_temp.last_menu_index < 0
      $scene = Scene_Map.new
    else
      $scene = Scene_Menu.new
    end
  end
end
```

### アイテム図鑑

項目処理 (道具図鑑)：`'Scene_ItemDictionary.new'`

項目処理 (武器図鑑)：`'Scene_WeaponDictionary.new'`

項目処理 (防具図鑑)：`'Scene_ArmorDictionary.new'`

下記スクリプトで、メニュー項目からの呼び出しを可能にします。

```ruby
class Scene_ItemDictionary
  def return_scene
    if $game_temp.last_menu_index < 0
      $scene = Scene_Map.new
    else
      $scene = Scene_Menu.new
    end
  end
end
class Scene_WeaponDictionary
  def return_scene
    if $game_temp.last_menu_index < 0
      $scene = Scene_Map.new
    else
      $scene = Scene_Menu.new
    end
  end
end
class Scene_ArmorDictionary
  def return_scene
    if $game_temp.last_menu_index < 0
      $scene = Scene_Map.new
    else
      $scene = Scene_Menu.new
    end
  end
end
```

### アイテム図鑑２・３

項目処理：`'Scene_TotalDictionary.new'`

下記スクリプトで、メニュー項目からの呼び出しを可能にします。

```ruby
class Scene_TotalDictionary
  def return_scene
    if $game_temp.last_menu_index < 0
      $scene = Scene_Map.new
    else
      $scene = Scene_Menu.new
    end
  end
end
```