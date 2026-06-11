# Semura Lab. — EA構造診断アーカイブ

市場に流通する自動売買EA（エキスパートアドバイザー）の**ロジック構造**を、
コードの実態と物理法則（絶対摩擦・リスクリワード）から技術的に解剖・記録するアーカイブ。

特定の製品や作者を批判・暴露することが目的ではない。
「広く流通する設計"型"が、現実の取引環境でなぜ機能しないのか」を
一般論として技術的に検証し、再現可能な形で記録することを目的とする。

---

## 診断の物差し（Semura Lab. 規格）

すべての検体は、以下の実運用規格と物理法則のフィルタを通して診断される。

| 項目 | 基準 |
|------|------|
| リスクリワード | 1:1（TP/SL 5〜8pips のタイト設計） |
| 絶対摩擦 | スプレッド 0.6pips を想定。高スプレッド時は取引回避必須 |
| ポジション管理 | 常に1ポジションのみ |
| 目標 | 勝率55% / PF 1.2〜1.5 / 月利10% |

診断の観点（共通テンプレート）：
**仕様照合 → 致命バグ → CAP監査（未来リーク・プラセボ・カーブフィット）→ 摩擦の数理 → 規格適合**

---

## 検体カタログ

| No. | 検体（型） | 主要所見 | 診断記事 |
|-----|-----------|----------|----------|
| [001](./specimens/001-trendfollow-scalp-stoch-ema/) | トレンドフォロー型スキャルピング（Stoch+EMA+ATR利確+固定SL） | 決済不発・未来リーク・スプレッド制限空回り。RR1:6〜1:15の利小損大 | https://semura-lab.com/report/001 https://medium.com/@griffice3/anatomy-of-a-high-win-rate-ea-that-loses-on-a-live-account-reverse-engineering-a-b1cea8eb2d4f |
| [002](./specimens/002-trendfollow-scalp-sar-sellfix/) | トレンドフォロー型スキャルピング（SAR想定／方向判定なし・売り固定） | 方向判定ロジック全コメントアウトで売り固定・実効SLにスプレッド上乗せ・名ばかりリスク率。RRは利大損小だがエッジ皆無 | https://semura-lab.com/report/002 https://medium.com/@griffice3/when-an-ea-has-no-strategy-dissecting-a-589-line-scalper-c559a4364f2c |
| [003](./specimens/003-doa-straddle-ea) | ブレイクアウト・ストラドル型EA<br>（無条件両建て / 待機注文追従型） | 追随判定の数理的破綻（価格加算）・環境認識フィルタ完全不在で無条件発注・極小TP/SLでの両建てによる二重コスト。構造的な確死 | https://semura-lab.com/report/003 https://medium.com/@griffice3/adding-prices-instead-of-subtracting-dissecting-a-logic-breakdown-in-an-unfiltered-straddle-ea-2f33da4d5a91 |
| [004](./specimens/004-hedge-martingale-ea) | 両建てヘッジ・変則マーチンゲール型EA（両建てロック / 逆行ナンピン加重平均決済） | 配列オーバーランのバグ（未定義動作）・最大185倍に膨張する過剰最適化された不規則ロット配列・両建てロックによる最大DDの意図的隠蔽。一撃のトレンドで口座全損する破滅構造 | https://semura-lab.com/report/004 https://medium.com/@griffice3/ea-dissection-log-004-the-madness-of-a-185x-multiplier-dissecting-the-ruinous-structure-and-c7f9e4382056 |
| [005](./specimens/005-alligator-trend-follower-ea) | 古典的な順張りトレンドフォロー型EA（Alligator指標 / 単一ポジション / ドテン決済） | 未確定足（インデックス0）参照によるリペイントの罠・昇順決済ループによる配列破壊バグ・マジックナンバー欠落による他ポジション誤爆。バックテストの数値を根本から歪め、実稼働を不全にする致命的な配線ミス | https://semura-lab.com/report/005 https://medium.com/@griffice3/code-level-autopsy-of-sniperjaw-ea-when-flawed-wiring-destroys-trading-logic-991c9424533c |
| [006](./specimens/006-stochastic-eclipse-ea) | ストキャスティクス系オシレーターEA（Stochastic Eclipse） | バックテストの虚像（CAP）の看破。過去データへの過剰最適化（カーブフィット）や、実稼働では再現不可能なロジックによって意図的に作り出された「見せかけの右肩上がり」をコードレベルで解剖・証明 | https://semura-lab.com/report/006 https://medium.com/@griffice3/code-level-autopsy-of-stochastic-eclipse-ea-uncovering-the-illusion-of-backtesting-58d629a6182e |
| [007](./specimens/007-rrs-chaotic-ea/)| 確率的ランダムウォーク実験機（RRS Chaotic EA）| 生存能力ゼロの確率的ランダムウォーク実験機の解剖。市場情報を一切参照しない乱数エントリー、リスクリワードの逆転、最大10ポジションの連鎖爆発リスクなど、エッジ（数学的優位性）の完全な不在と構造的破綻をコードレベルで証明 | https://semura-lab.com/report/007 https://medium.com/@griffice3/semura-lab-diagnostic-report-specimen-007-anatomy-of-a-stochastic-random-walk-experiment-b20bf858d20a |
| [008](./specimens/008-basic-atr-stop-take-ea/) | 動的ATR・SL/TP実装の骨格テンプレート | エントリーロジックを持たない（無条件発注）開発用骨格テンプレートの解剖。実運用での誤動作を引き起こすポジションカウントバグや二段階発注の脆弱性を指摘しつつ、ATRを用いた動的SL/TP機構やロット正規化など、優位性のある「大脳」を組み込むための「再利用可能な配管」としての資産価値を評価 | https://semura-lab.com/report/008 https://medium.com/@griffice3/semura-lab-diagnostic-report-specimen-008-anatomy-of-a-dynamic-atr-sl-tp-skeleton-template-4f0c3772d842 |
| [009](./specimens/009-Pending-tread-ea/) | 双方向ペンディング・グリッド型（ノンロジック自動発注機） | 市場価格の変動に関係なく機械的に発注を行う「ノンロジック」型の構造を解剖。グリッド幅やロット配分が適切でない場合に発生する「相場の摩擦」が、いかに効率を削ぎ落とし、証拠金維持率を蝕むリスク要因となるかを物理的視点から分析。グリッド運用における「致命的なパラメータ設定」の危険性と、生存能力を維持するための発注密度最適化の必要性を提言。 | https://semura-lab.com/report/009 https://medium.com/@griffice3/specimen-009-bi-directional-pending-grid-type-non-logic-auto-order-machine-c01a254e6543 |
| [010](./specimens/010-random-defects/) | 完全無作為・非対称決済型（高勝率偽装ランダム発注機） | エントリーを完全な無作為（乱数）に依存しつつ、利確と損切の幅を非対称（1:2の逆ザヤ）に固定することで、見かけ上の勝率を意図的に約66%へ偏らせる「メトリクスの化粧」の構造を解剖。さらに、単一銘柄しか処理できないテスター環境の仕様に無自覚なまま実装された多銘柄抽出ロジックが、バックテストとリアル口座で全く異なる挙動（致命的な検証乖離）を引き起こす欠陥を法医学的視点から指摘。優位性の不在とスプレッド摩擦を隠蔽する偽装システムとして完全破棄を提言。 | https://semura-lab.com/report/010 https://medium.com/@griffice3/semura-lab-pure-diagnostic-and-reconstruction-of-trading-logic-31d3130af021 |
| [011](./specimens/011-moving-average-defects/) | 単一移動平均クロス・固定RR型（優位性偽装の実装破綻スクリプト） | 移動平均線に対する前足の終値クロスという古典的コンセプトの裏で、5桁ブローカーにおけるpips換算の致命的誤認（意図の1/10で発注される構造）により「損小利大」の非対称ペイオフが完全な幻影と化しているバグを解剖。さらに、`OrderSelect()` を経ない未定義データの参照による建値移動の暴発リスク、および `OrderModify()` の引数順序崩壊による利確幅（TP）の自己破壊構造を指摘。バックテストの好成績が市場の優位性ではなく「実装バグが生んだ幻影」であることを暴き、全面再構築を命じる不採用物件として登録。 | https://semura-lab.com/report/011 https://medium.com/@griffice3/specimen-011-single-moving-average-cross-fixed-rr-type-implementation-broken-script-disguised-761ec9a7370b |
| [012](./specimens/012-sar-macd-friction-defects/) | トレンドフォロー型・複合フィルター単発エントリー機（摩擦無防備とSL密着の自滅スクリプト） | Parabolic SARのドテン、SMAクロス、MACD方向一致という三段階フィルターを用いた防御的な設計思想の裏で、スプレッドや約定摩擦に対する考慮が完全に欠落しており、リアル環境での即死が確定している致命的欠陥を解剖。 | https://semura-lab.com/report/012 https://medium.com/@griffice3/specimen-012-trend-following-multi-filter-single-entry-engine-self-destructing-script-via-e79f475e9793 |

---

## 各検体フォルダの構成

```
specimens/<番号-検体名>/
├── specimen_excerpt.<ext>   診断で名指しする問題箇所の構造抜粋（全文ではない）
└── NOTE.md                  検体カード（プロフィール・診断サマリ・記事リンク）
```

新しい検体を追加する際は `_TEMPLATE/` を複製して使う。
記事への埋め込み手順は [`HOWTO_publish.md`](./HOWTO_publish.md) を参照。

---

## 掲載方針・免責

掲載するコードは、診断に必要な該当箇所を構造が分かる最小限に再構成した**抜粋**であり、
特定製品のソースコード全文の再配布ではない。批評・研究を目的とする。
詳細は [`DISCLAIMER.md`](./DISCLAIMER.md) を参照。

— Semura Lab.
