//+------------------------------------------------------------------+
//| 検体015（簡略化版）— 記事掲載用抽出コード                        |
//|                                                                  |
//| ※本コードは技術解説記事のために原本から抽出・簡略化した         |
//|   「検体」です。著作権者・作成者情報は削除済み。                 |
//| ※診断に用いた中核ロジックのみを抜粋しています。                 |
//| ※そのままでは動作せず、実取引には一切使用できません。           |
//| ※掲載目的はロジックの是非を論じることではなく、                 |
//|   あくまで診断対象（検体）としての参照に限定します。             |
//+------------------------------------------------------------------+

// --- 入力（抜粋）---
// H1とD1、2つのRSIで合議する想定の設計
input int             iRSI_Period_H1    = 12;
input ENUM_TIMEFRAMES iRSI_TimeFrame_H1 = PERIOD_H1;
input int             iRSI_Period_D1    = 18;   // ※後段で未使用
input ENUM_TIMEFRAMES iRSI_TimeFrame_D1 = PERIOD_D1; // ※後段で未使用
input double          iRSI_Level_UP     = 80.0; // 売りゾーン
input double          iRSI_Level_DW     = 20.0; // 買いゾーン

// --- 診断に利用した中核部分のみ抽出 ---
double rsi_h0, rsi_h1;   // H1: 直近確定足 / 1本前
double rsi_d0, rsi_d1;   // D1: 直近確定足 / 1本前（のはず）

// H1のRSI（正しくH1を参照）
rsi_h0 = iRSI(_Symbol, iRSI_TimeFrame_H1, iRSI_Period_H1, PRICE_CLOSE, 1);
rsi_h1 = iRSI(_Symbol, iRSI_TimeFrame_H1, iRSI_Period_H1, PRICE_CLOSE, 2);

// ★診断ポイント：D1を参照すべき箇所がH1のまま（合議制が実質1票化）
rsi_d0 = iRSI(_Symbol, iRSI_TimeFrame_H1, iRSI_Period_H1, PRICE_CLOSE, 1); // 本来は D1
rsi_d1 = iRSI(_Symbol, iRSI_TimeFrame_H1, iRSI_Period_H1, PRICE_CLOSE, 2); // 本来は D1

// 買い条件：H1とD1が共に下限超え＆上昇
if(rsi_h0 >= iRSI_Level_DW && rsi_h0 > rsi_h1)
   if(rsi_d0 >= iRSI_Level_DW && rsi_d0 > rsi_d1)
      signal_up = true;

// 売り条件：H1とD1が共に上限以下＆下降
if(rsi_h0 <= iRSI_Level_UP && rsi_h0 < rsi_h1)
   if(rsi_d0 <= iRSI_Level_UP && rsi_d0 < rsi_d1)
      signal_dw = true;

// 発注（抜粋）：逆ポジションをドテン決済 → 新規エントリー
// ※SL/TP = 0（損切り・利確の指定なし）
// OrderSend(_Symbol, OP_BUY/OP_SELL, lt, price, iSlippage, 0, 0, ...);
