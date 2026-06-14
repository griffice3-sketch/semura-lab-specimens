
```cpp
//==================================================================
//  検体014 ／ 簡略化ロジック（診断用抽出版）
//------------------------------------------------------------------
//  ※本コードは Semura Lab 診断の検証目的で抽出・簡略化したものです
//  ※著作権表記・作成者情報・固有識別子は削除済み
//  ※診断に用いた「判断の核」部分のみを残し、補助処理は省略
//  ※そのままでは動作せず、実運用・実トレードには使用できません
//  ※特定ロジックの批判ではなく、あくまで「検体」としての引用です
//==================================================================

// --- 主要パラメータ（診断対象部分のみ）---
FastEMA = 12 / SlowEMA = 26 / RSIPeriod = 14
RSI_Buy = 55 / RSI_Sell = 45
SL = 30pips / TP = 60pips（RR 1:2）
RiskPercent = 1.0%（Equity基準サイジング）
MaxSpread = 30pt / 取引時間 = 1:00〜23:00（server）
単一ポジションのみ（ナンピン・マーチンなし）

// --- フィルター（生存条件）---
if (時間帯外 || スプレッド超過) return;
if (1バー1回 && 新バーでない) return;

// --- シグナル抽出（診断の核）---
CopyBuffer(EMA_fast, 1, 2, fastBuf);   // ※ArraySetAsSeries未設定
CopyBuffer(EMA_slow, 1, 2, slowBuf);
CopyBuffer(RSI,      1, 1, rsiBuf);

fastNow  = fastBuf[0];  fastPrev = fastBuf[1];
slowNow  = slowBuf[0];  slowPrev = slowBuf[1];
rsi      = rsiBuf[0];

bullCross = (fastPrev <= slowPrev) && (fastNow > slowNow);
bearCross = (fastPrev >= slowPrev) && (fastNow < slowNow);

// --- エントリー判断 ---
lots = RiskCash / (SL_Pips * pipValuePerLot);   // リスク基準ロット

if (bullCross && rsi >= RSI_Buy && ポジションなし)
    Buy(lots, SL=ask-30pips, TP=ask+60pips);

if (bearCross && rsi <= RSI_Sell && ポジションなし)
    Sell(lots, SL=bid+30pips, TP=bid-60pips);

// --- ポジション管理（要点のみ）---
Breakeven_Pips = 15 → 含み益15pipsで建値にSL移動
Trailing_Pips  = 20 → 含み益20pips超でトレーリング

//==================================================================
//  【再掲・注意】
//  本抽出は診断ロジックの理解を目的とした簡略表現であり、
//  完全な再現性・動作保証はありません。実取引には使用不可。
//==================================================================
```
