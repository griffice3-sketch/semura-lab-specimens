//==================================================================
// Semura Lab. 検体002 構造抜粋 (specimen_excerpt)
//
// 本ファイルは検体の全文ではない。診断レポートで名指しする問題箇所
// のみを、構造が伝わる最小限に再構成した「抜粋」である。
// 行コメント 【A】〜【E】 は診断レポートの該当項目に対応する。
//==================================================================


//------------------------------------------------------------------
// 【A】 方向判定ロジックの不在 — シグナルが丸ごと無効化されている
//------------------------------------------------------------------
void OpenOrder(){

   // --- 本来の方向判定（パラボリックSAR）が全てコメントアウトされている ---
   //int TF = PERIOD_H1;
   //double sar2 = iSAR(NULL, TF, 0.02, 0.2, 0);
   //bool buySignal  = sar2 > iOpen(_Symbol, TF, 1);
   //bool sellSignal = sar2 < iOpen(_Symbol, TF, 1);

   int OrdType = OP_SELL;          // ← 方向は「売り」に固定（定数代入）

   // --- シグナルによる分岐も全てコメントアウト ---
   //if (sellSignal) OrdType = OP_SELL;
   //if (buySignal)  OrdType = OP_BUY;

   // 以降、OrdType は常に OP_SELL のまま。相場状況によらず売りのみ発注。
   // ……
}


//------------------------------------------------------------------
// 【B】 エントリー建て付け — 実効SLにスプレッドが上乗せされる構造
//------------------------------------------------------------------
   // SELLSTOP の場合（InpSL_Pips=3.5, InpTP_Pips=7 が既定値）
   double OpenPrice = Bid - (InpSL_Pips/2 * Pips2Double);   // = Bid - 1.75pips
   double TP        = OpenPrice - (InpTP_Pips * Pips2Double);
   double SL        = Ask + (InpSL_Pips/2 * Pips2Double);   // = Ask + 1.75pips
   // 実効SL距離 = SL - OpenPrice = (Ask - Bid) + 3.5 = スプレッド + 3.5pips
   // → 名目SL 3.5pips に、約定前からスプレッド分が静かに上乗せされる。


//------------------------------------------------------------------
// 【C】 ロットサイズ計算 — SL幅・pip価値を参照しない「名ばかりリスク%」
//------------------------------------------------------------------
double CalculateVolume(){
   double LotSize = (InpRisk) * AccountFreeMargin();  // InpRisk=3（「Risk %」と表示）
   LotSize = LotSize / 100000;
   double n = MathFloor(LotSize / Inpuser_lot);
   LotSize = n * Inpuser_lot;
   // SL距離も1pipの金額価値も一切参照していない。
   // 実体は「余剰証拠金に比例した固定係数ロット」であり、リスク率制御ではない。
   return(LotSize);
}


//------------------------------------------------------------------
// 【D】 トレーリング対象が「未約定の待機注文」— 指値が価格を追い続ける
//------------------------------------------------------------------
   // 約定前の SELLSTOP に対して、建値(OpenPrice)・SL・TP を毎ティック再設定
   else if(OrderType() == OP_SELLSTOP){
      double newOP = Ask - (InpSL_Pips/2 * Pips2Double);
      double newTP = newOP - (InpTP_Pips * Pips2Double);
      double newSL = Ask + (InpSL_Pips/2 * Pips2Double);
      OrderModify(OrderTicket(), newOP, newSL, newTP, 0, clrRed);
      // 待機注文が現在価格に追従し続ける。約定の意味が曖昧になる。
   }


//------------------------------------------------------------------
// 【E】 死にコード／飾りパラメータ — 実装に接続されていない入力群
//------------------------------------------------------------------
   //extern double InpProfitStep   = 1.2;   // Trailing Step（コメントアウト）
   //input int     InpPeriodKelner = 20;    // 名称のみ残存、本体で未使用
   // 入力欄に並ぶが、計算ロジックへ一切接続されていない。
