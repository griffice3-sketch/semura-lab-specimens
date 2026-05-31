//+------------------------------------------------------------------+
//| 検体006: Stochastic Eclipse (レポート検証用コアロジック抽出版)       |
//+------------------------------------------------------------------+

// 【重大な指摘事項】コメント（MAクロス）と実装（Stochastic）の不一致
/*
ENTRY BUY: when the fast MA crosses the slow from the bottom, both MA are going up
ENTRY SELL: when the fast MA crosses the slow from the top, both MA are going down
EXIT: When Stop Loss or Take Profit are reached or, reaching the upper threshold for buy orders and reaching the lower threshold for sell orders
Only 1 order at a time
*/

extern double LotSize=0.1;
extern double StopLoss=100;
extern double TakeProfit=100;
extern int Slippage=10;

extern int StochK=5;
extern int StochD=3;
extern int StochSlowing=3;
extern int UpperThreshold=80;
extern int LowerThreShold=20;

// V-5: 死にコード（宣言のみで未使用。スプレッド・時間制御の放棄痕跡）
double MinSL;
double MaxSL;
double Spread;
int SleepSecs=3; 

// 状態フラグ
bool CanOrder=true;
bool CanOpenBuy=true;
bool CanOpenSell=true;
bool CrossToOpenBuy=false;
bool CrossToOpenSell=false;
bool CrossToCloseBuy=false;
bool CrossToCloseSell=false;


//--- ロジック中枢 ---//

void CheckStochCross(){
   CrossToOpenBuy=false; CrossToOpenSell=false;
   CrossToCloseBuy=false; CrossToCloseSell=false;
   
   // V-2: 形成中バー（引数0）参照によるリペイントの温床
   double StochPrev=iStochastic(Symbol(),0,StochK,StochD,StochSlowing,MODE_SMA,STO_LOWHIGH,MODE_BASE,1);
   double StochCurr=iStochastic(Symbol(),0,StochK,StochD,StochSlowing,MODE_SMA,STO_LOWHIGH,MODE_BASE,0);
   
   if(StochPrev<LowerThreShold && StochCurr>LowerThreShold) CrossToOpenBuy=true;
   if(StochPrev>UpperThreshold && StochCurr<UpperThreshold) CrossToOpenSell=true;
   if(StochCurr>UpperThreshold) CrossToCloseBuy=true;
   if(StochCurr<LowerThreShold) CrossToCloseSell=true;
}

void OrdersOpen(){
   // V-6: 「Only 1 order」の虚偽。BUY/SELLの片方しか保有判定をしておらず両建てが成立する
   CanOpenBuy=true; CanOpenSell=true;
   for( int i = 0 ; i < OrdersTotal() ; i++ ) {
      if( OrderSelect( i, SELECT_BY_POS, MODE_TRADES ) ) {
         if( OrderSymbol()==Symbol() && OrderType() == OP_BUY) CanOpenBuy=false;
         if( OrderSymbol()==Symbol() && OrderType() == OP_SELL) CanOpenSell=false;
      }
   }
}

void CloseAll(int Command){
   // V-3: 昇順ループによるインデックス破壊リスク（クローズ漏れが発生する古典的バグ）
   for( int i = 0 ; i < OrdersTotal() ; i++ ) {
      if( OrderSelect( i, SELECT_BY_POS, MODE_TRADES ) ) {
         if( OrderSymbol()==Symbol() && OrderType()==Command) {
            
            // V-4: RefreshRates()無し。価格使い回しによるリクオート時の約定不能リスク
            double ClosePrice = (Command==OP_BUY) ? Bid : Ask;
            OrderClose(OrderTicket(),OrderLots(),ClosePrice,Slippage,Red);
         }
      }
   }
}

void OpenNew(int Command){
   double OpenPrice = (Command==OP_BUY) ? Ask : Bid;
   double SLPrice = (Command==OP_BUY) ? OpenPrice-StopLoss*Point : OpenPrice+StopLoss*Point;
   double TPPrice = (Command==OP_BUY) ? OpenPrice+TakeProfit*Point : OpenPrice-TakeProfit*Point;
   
   // V-1: マジックナンバー未設定 (第9引数が0)。他EAや手動注文と干渉する致命傷
   OrderSend(Symbol(),Command,LotSize,OpenPrice,Slippage,SLPrice,TPPrice,"",0,0,Green);
}

//--- メイン処理 ---//
void OnTick() {
   OrdersOpen();
   CheckStochCross();
   
   if(CrossToCloseBuy) CloseAll(OP_BUY);
   if(CrossToCloseSell) CloseAll(OP_SELL);
   if(CrossToOpenBuy && CanOpenBuy) OpenNew(OP_BUY);
   if(CrossToOpenSell && CanOpenSell) OpenNew(OP_SELL);
}
