#=============================================================================
#  [RGSS2] ベンチマーク - v1.0.0
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

  ある処理にかかる時間を測定する機能を追加します。

 -- 使用方法 ----------------------------------------------------------------

  ★ 処理時間の測定
   Benchmark.measure { ... }

  ★ 処理時間の平均を測定
   Benchmark.measure(実行回数) { ... }

  ※ ... の部分に測定する処理を記述してください。

=end


#/////////////////////////////////////////////////////////////////////////////#
#                                                                             #
#                下記のスクリプトを変更する必要はありません。                 #
#                                                                             #
#/////////////////////////////////////////////////////////////////////////////#


module Benchmark
  def self.measure(n = 1)
    list = []
    n.times {
      time = Time.now
      yield
      list << Time.now - time
    }
    total = 0.0
    list.each { |i| total += i }
    print sprintf("Time : %6.4f s ", (total / list.size))
  end
end