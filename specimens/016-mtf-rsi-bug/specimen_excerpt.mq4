
//+------------------------------------------------------------------+
//| 検体016 ―― 簡略化ロジック（Semura Lab 診断用抜粋）                |
//|                                                                  |
//| ※本コードは診断レポートで言及した「中核ロジックのみ」を抽出・    |
//|   簡略化したものです。                                           |
//| ※著作権表記・作成者情報・署名ラベル・MM計算等は診断に無関係の    |
//|   ため削除しています。                                           |
//| ※あくまで「検体」としての構造把握用であり、実戦使用は不可。      |
//|   損切り・スプレッド/時間フィルタ等を欠くため、本コードを        |
//|   そのまま稼働させてはいけません。                               |
//| ※本掲載はロジックの批判が目的ではなく、診断対象（検体）として    |
//|   引用・解説する位置づけです。                                   |
//+------------------------------------------------------------------+
#property strict

input int    Tenkan = 9;    // 転換線
input int    Kijun  = 26;   // 基準線
input int    Senkou = 52;   // 先行スパン
input double Lots   = 0.1;  // 固定ロット
input int    Slippage = 100;
input int    Magic    = 2130512104;

int  LastBars = 0;
bool HaveLong, HaveShort;

//--- 新バーごとに1回だけ判定 ---
int start()
{
   if (LastBars == Bars) return(0);
   LastBars = Bars;

   // 【一次シグナル】遅行スパン × 価格クロス（オフセット Kijun+1 で未来読み回避）
   double ChikouNow  = iIchimoku(NULL,0,Tenkan,Kijun,Senkou,MODE_CHIKOUSPAN, Kijun+1);
   double ChikouPrev = iIchimoku(NULL,0,Tenkan,Kijun,Senkou,MODE_CHIKOUSPAN, Kijun+2);
   bool Bull = (ChikouNow > Close[Kijun+1]) && (ChikouPrev <= Close[Kijun+2]);
   bool Bear = (ChikouNow < Close[Kijun+1]) && (ChikouPrev >= Close[Kijun+2]);

   // 【二次フィルタ①】価格が雲の上/下
   double SpanA_P = iIchimoku(NULL,0,Tenkan,Kijun,Senkou,MODE_SENKOUSPANA, 1);
   double SpanB_P = iIchimoku(NULL,0,Tenkan,Kijun,Senkou,MODE_SENKOUSPANB, 1);
   bool KumoBull = (Close[1] > SpanA_P) && (Close[1] > SpanB_P);
   bool KumoBear = (Close[1] < SpanA_P) && (Close[1] < SpanB_P);

   // 【二次フィルタ②】遅行スパンが雲の上/下
   double SpanA_C = iIchimoku(NULL,0,Tenkan,Kijun,Senkou,MODE_SENKOUSPANA, Kijun+1);
   double SpanB_C = iIchimoku(NULL,0,Tenkan,Kijun,Senkou,MODE_SENKOUSPANB, Kijun+1);
   bool ChikouBull = (ChikouNow > SpanA_C) && (ChikouNow > SpanB_C);
   bool ChikouBear = (ChikouNow < SpanA_C) && (ChikouNow < SpanB_C);

   GetPositionStates();

   // 【執行】反対シグナルで決済 → 三条件一致でドテン（SL/TPなし＝常時保有）
   if (Bull) {
      if (HaveShort) ClosePrevious();
      if (KumoBull && ChikouBull) OrderSend(Symbol(),OP_BUY ,Lots,Ask,Slippage,0,0,"",Magic);
   }
   else if (Bear) {
      if (HaveLong) ClosePrevious();
      if (KumoBear && ChikouBear) OrderSend(Symbol(),OP_SELL,Lots,Bid,Slippage,0,0,"",Magic);
   }
   return(0);
}

//--- 現在の保有状態（単一ポジション前提）---
void GetPositionStates()
{
   HaveLong = HaveShort = false;
   for (int i = 0; i < OrdersTotal(); i++) {
      if (!OrderSelect(i, SELECT_BY_POS)) continue;
      if (OrderMagicNumber()!=Magic || OrderSymbol()!=Symbol()) continue;
      if (OrderType()==OP_BUY)  { HaveLong  = true; return; }
      if (OrderType()==OP_SELL) { HaveShort = true; return; }
   }
}

//--- 反対シグナル時の決済 ---
void ClosePrevious()
{
   for (int i = OrdersTotal()-1; i >= 0; i--) {
      if (!OrderSelect(i, SELECT_BY_POS)) continue;
      if (OrderSymbol()!=Symbol() || OrderMagicNumber()!=Magic) continue;
      if (OrderType()==OP_BUY)  OrderClose(OrderTicket(),OrderLots(),Bid,Slippage);
      if (OrderType()==OP_SELL) OrderClose(OrderTicket(),OrderLots(),Ask,Slippage);
   }
}
