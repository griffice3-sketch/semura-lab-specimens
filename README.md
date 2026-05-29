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
| [001](./specimens/001-trendfollow-scalp-stoch-ema/) | トレンドフォロー型スキャルピング（Stoch+EMA+ATR利確+固定SL） | 決済不発・未来リーク・スプレッド制限空回り。RR1:6〜1:15の利小損大 | https://zenn.dev/semura_lab/articles/ad67ce1279fe1a https://medium.com/@griffice3/anatomy-of-a-high-win-rate-ea-that-loses-on-a-live-account-reverse-engineering-a-b1cea8eb2d4f |
| [002](./specimens/002-trendfollow-scalp-sar-sellfix/) | トレンドフォロー型スキャルピング（SAR想定／方向判定なし・売り固定） | 方向判定ロジック全コメントアウトで売り固定・実効SLにスプレッド上乗せ・名ばかりリスク率。RRは利大損小だがエッジ皆無 | https://zenn.dev/semura_lab/articles/129a676f73d878 https://medium.com/@griffice3/when-an-ea-has-no-strategy-dissecting-a-589-line-scalper-c559a4364f2c |
| [003](./specimens/003-doa-straddle-ea) | ブレイクアウト・ストラドル型EA<br>（無条件両建て / 待機注文追従型） | 追随判定の数理的破綻（価格加算）・環境認識フィルタ完全不在で無条件発注・極小TP/SLでの両建てによる二重コスト。構造的な確死 | https://zenn.dev/semura_lab/articles/521617d71e3ec8<br>https://medium.com/@griffice3/adding-prices-instead-of-subtracting-dissecting-a-logic-breakdown-in-an-unfiltered-straddle-ea-2f33da4d5a91 |
| [003](./specimens/004-hedge-martingale-ea) | 004 | 両建てヘッジ・変則マーチンゲール型EA（両建てロック / 逆行ナンピン加重平均決済） | 配列オーバーランのバグ（未定義動作）・最大185倍に膨張する過剰最適化された不規則ロット配列・両建てロックによる最大DDの意図的隠蔽。一撃のトレンドで口座全損する破滅構造 | https://zenn.dev/semura_lab/articles/55385603a74854 https://medium.com/@griffice3/ea-dissection-log-004-the-madness-of-a-185x-multiplier-dissecting-the-ruinous-structure-and-c7f9e4382056 |

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
