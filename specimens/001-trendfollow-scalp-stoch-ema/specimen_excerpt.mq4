// =====================================================================
// 検体001：トレンドフォロー型スキャルピングEA（構造サンプル・MQL4）
// =====================================================================
// 本ファイルは、特定の製品の完全なソースコードではない。
// 「Stochastic + EMA傾き + ATR可変利確 + 固定SL」という広く流通している
// 設計"型"を診断するために、問題となる構造を最小限に再構成した抜粋である。
// 行番号は診断レポート（NOTE.md 参照）の参照箇所と対応する。
//
// 診断レポート本体：（記事URL / リポジトリの NOTE.md を参照）
// 目的：批評・研究（このロジック型がなぜ実弾で勝てないかの技術的解剖）
// =====================================================================


// ---------------------------------------------------------------------
// 【E】設計パラメータ：利小損大（TP 2〜5pips / SL 固定30pips）
//     リスクリワード 1:6 〜 1:15。この時点で「高勝率前提」の構造が確定する。
// ---------------------------------------------------------------------
#define DEF_TP_PIPS      5    // 通常時の利確（高ボラ時）
#define DEF_TP_PIPS_LV   2    // 低ボラ時の利確（極小）
#define DEF_SL_PIPS      30   // 損切（固定・利確の6〜15倍）


// ---------------------------------------------------------------------
// 【B】FATAL：未来リーク（Look-ahead / peeking）
//     エントリー判定の中核に shift=0（形成中の未確定足）を使用。
//     確定足は shift=1 以降。shift=0 はティックごとに値が変わる＝リペイント。
//     しかも prev は shift=1 や shift=2 と混在しており、確定足の概念が不統一。
// ---------------------------------------------------------------------
double stochMainPrev = iStochastic(sym, TF, 13,3,3, MODE_SMA, 0, MODE_MAIN, 1);   // shift=1
double stochMainCurr = iStochastic(sym, TF, 13,3,3, MODE_SMA, 0, MODE_MAIN, 0);   // shift=0 ← 未確定足
double stochSigCurr  = iStochastic(sym, TF, 13,3,3, MODE_SMA, 0, MODE_SIGNAL, 0); // shift=0 ← 未確定足

double maPrev     = iMA(sym, TF, 204, 0, MODE_EMA, PRICE_CLOSE, 2);  // shift=2
double maCurr     = iMA(sym, TF, 204, 0, MODE_EMA, PRICE_CLOSE, 0);  // shift=0 ← 未確定足
double maCurrFast = iMA(sym, PERIOD_M1, 4, 0, MODE_EMA, PRICE_CLOSE, 0); // shift=0 ← 未確定足


// ---------------------------------------------------------------------
// 【A】FATAL：決済条件が数学的に永遠に偽（恒偽）
//     (atr < TRH) と (atr > TRH) を AND で結合 → 同時に真になり得ない。
//     設計意図は OR（低ボラなら2pips利確 / 高ボラなら5pips利確）だが
//     AND で書いたため、この能動的な利確ブロックは一度も実行されない。
// ---------------------------------------------------------------------
if( order.IsOpen()
    && ((atr < ATR_TRH) && (order.ProfitPips() >= TP_LV))   // 条件X
    && ((atr > ATR_TRH) && (order.ProfitPips() >= TP)) )    // 条件Y ←Xと両立不能
{
    order.Close();   // ← 恒偽のため到達しない（死にコード）
}


// ---------------------------------------------------------------------
// 【C】FATAL：スプレッド制限フィルタが空回り（未初期化メンバ）
//     エントリー判定が参照する marketSpread は、判定前に一度も更新されない。
//     初期値0のまま → (0 <= 上限) が常に真 → スプレッドを実質チェックしない。
//     ※ Ask/Bid/TickSize は更新しているのに、Spread への代入だけが欠落。
// ---------------------------------------------------------------------
double marketSpread;   // メンバ宣言（初期値0、以降このパスで未代入）
// ...
marketTickSize = MarketInfo(sym, MODE_TICKSIZE);  // 更新あり
marketAskPrice = MarketInfo(sym, MODE_ASK);       // 更新あり
marketBidPrice = MarketInfo(sym, MODE_BID);       // 更新あり
// ★ marketSpread への代入が無い
// ...
if( (marketSpread <= SPREAD_LIMIT)   // ← 常に true（フィルタが死んでいる）
    && (atr >= ATR_LIM)
    && (hour >= START_HOUR) && (hour <= END_HOUR) )
{
    // エントリー処理
}


// ---------------------------------------------------------------------
// 【D】損益pips計算の方向バグ（Short評価で Ask/Bid を取り違え）
//     Short は Bid で建てるのに、含み損益評価を Ask で行っている。
//     Short の評価に Ask を使うと、常にスプレッド分の系統誤差が乗る。
// ---------------------------------------------------------------------
int ProfitPips()
{
    double cur = MarketInfo(sym, MODE_ASK);   // ← Long/Short 共通で Ask
    if (dir == LONG)  return (int)((cur - openPrice) / tick);
    if (dir == SHORT) return (int)((openPrice - cur) / tick); // Short も Ask評価＝誤差
    return 0;
}
