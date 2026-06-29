
//==================================================================
//  検体017 ＝ 簡略化サンプル（Semura Lab 診断用抽出版）
//------------------------------------------------------------------
//  ※本コードは診断のために中核ロジックのみを抽出・簡略化した
//    「検体標本」です。著作権表記・作成者情報・署名描画・
//    リトライ処理・ロット検証等は診断に不要なため除去しています。
//
//  ※これは実運用を目的としたEAではありません。
//    そのまま稼働させても正常な売買・資金管理は保証されず、
//    実践使用は不可とします（解剖用の標本です）。
//
//  ※本抽出は特定ロジックの優劣評価ではなく、診断対象の
//    「検体」として構造を提示するものです。
//==================================================================

// --- パラメータ（診断に利用した部分のみ）
extern double LotSize       = 0.1;   // ロット
extern double StopLoss      = 100;   // SL(pips)
extern double TakeProfit    = 100;   // TP(pips)
extern int    StochK        = 5;     // %K
extern int    StochD        = 3;     // %D
extern int    StochSlowing  = 3;     // Slowing
extern int    UpperThreshold= 80;    // 上限閾値
extern int    LowerThreshold= 20;    // 下限閾値


// --- 中核シグナル：Stochastic 閾値クロス
//     ※診断指摘点：バー0（未確定足）を参照している
void OnTick()
{
   double prev = iStochastic(Symbol(),0,StochK,StochD,StochSlowing,
                             MODE_SMA,STO_LOWHIGH,MODE_BASE,1);
   double curr = iStochastic(Symbol(),0,StochK,StochD,StochSlowing,
                             MODE_SMA,STO_LOWHIGH,MODE_BASE,0);

   bool openBuy   = (prev < LowerThreshold && curr > LowerThreshold); // 売られすぎ反転
   bool openSell  = (prev > UpperThreshold && curr < UpperThreshold); // 買われすぎ反転
   bool closeBuy  = (curr > UpperThreshold);                          // 上限で買い決済
   bool closeSell = (curr < LowerThreshold);                          // 下限で売り決済

   // --- 決済（反対閾値到達 or 固定SL/TP）
   if(closeBuy)  CloseAll(OP_BUY);
   if(closeSell) CloseAll(OP_SELL);

   // --- 新規（単一ポジションのみ：二重保有抑止）
   if(openBuy  && NoPosition(OP_BUY))  Open(OP_BUY);
   if(openSell && NoPosition(OP_SELL)) Open(OP_SELL);
}


// --- 保有チェック（同方向ポジションが無ければ true）
bool NoPosition(int type)
{
   for(int i=0; i<OrdersTotal(); i++){
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES))
         if(OrderSymbol()==Symbol() && OrderType()==type) return(false);
   }
   return(true);
}


// --- 新規発注（固定ロット・固定SL/TP）
void Open(int cmd)
{
   double price = (cmd==OP_BUY) ? Ask : Bid;
   double sl    = (cmd==OP_BUY) ? price-StopLoss*Point*10 : price+StopLoss*Point*10;
   double tp    = (cmd==OP_BUY) ? price+TakeProfit*Point*10 : price-TakeProfit*Point*10;
   OrderSend(Symbol(),cmd,LotSize,price,10,sl,tp);
}


// --- 同方向ポジションを決済
void CloseAll(int cmd)
{
   for(int i=OrdersTotal()-1; i>=0; i--){
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES))
         if(OrderSymbol()==Symbol() && OrderType()==cmd){
            double p = (cmd==OP_BUY) ? Bid : Ask;
            OrderClose(OrderTicket(),OrderLots(),p,10);
         }
   }
}
//==================================================================
//  以上、検体017 抽出標本（診断専用 / 実践使用不可）
//==================================================================
```

---

**簡略化の要点（記事用メモ）**

- **削除:** 著作権・リンク・作成者署名（描画ラベル一式）、リトライ多重ループ、ロット妥当性検証関数、未使用変数群。
- **抽出:** 診断対象となった「Stochastic閾値クロスによる逆張りエントリー／反対閾値決済」「単一ポジション管理」「固定SL/TP」の3点のみ。
- **位置づけ:** 本コードはロジックの良否を論ずるためではなく、**診断記事の解剖標本（検体017）**として構造提示するもの。**実運用不可**。
