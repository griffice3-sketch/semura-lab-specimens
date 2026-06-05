```mql4
//+------------------------------------------------------------------+
//|  双方向ペンディング・グリッド（簡略版 / 検体009 抽出ロジック）   |
//+------------------------------------------------------------------+
#property strict

//--- Inputs
extern double PipStep              = 12;       // 注文間隔(Pips)
extern double TakeProfitPips       = 10;       // TP(Pips)
extern double LotSize              = 0.01;     // ロット
extern int    Slippage             = 3;        // スリッページ
extern string AboveMarketTradeType = "BUY";    // 上方向の種別(Buy/Sell)
extern string BelowMarketTradeType = "SELL";   // 下方向の種別(Buy/Sell)
extern int    MagicNumber          = 123456;   // マジックナンバー

int      totalOrdersPerSide = 10;              // 片側の本数
datetime lastOrderTime      = 0;

//+------------------------------------------------------------------+
int OnInit()
  {
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
void OnTick()
  {
   if(IsTradeContextBusy())
      return;

   if(TimeCurrent() - lastOrderTime < 5)   // 5秒スロットル
      return;
   lastOrderTime = TimeCurrent();

   MaintainPendingGrid(true);    // 上方向
   MaintainPendingGrid(false);   // 下方向
  }
//+------------------------------------------------------------------+
// ペンディング種別の決定
int GetPendingOrderType(bool above, string direction)
  {
   if(direction == "BUY")
      return above ? OP_BUYSTOP : OP_BUYLIMIT;
   else
      return above ? OP_SELLLIMIT : OP_SELLSTOP;
  }
//+------------------------------------------------------------------+
void MaintainPendingGrid(bool above)
  {
   string direction   = above ? AboveMarketTradeType : BelowMarketTradeType;
   int    pendingType = GetPendingOrderType(above, direction);
   double pointSize   = MarketInfo(Symbol(), MODE_POINT);
   int    digits      = (int)MarketInfo(Symbol(), MODE_DIGITS);
   int    stopLevel   = (int)MarketInfo(Symbol(), MODE_STOPLEVEL);
   double stopDistance= stopLevel * pointSize;
   double tpOffset    = (TakeProfitPips*10) * pointSize;

   //--- 同種ペンディング注文の本数をカウント
   int existingCount = 0;
   for(int i = OrdersTotal() - 1; i >= 0; i--)
     {
      if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
         if(OrderSymbol()==Symbol() && OrderType()==pendingType && OrderMagicNumber()==MagicNumber)
            existingCount++;
     }

   //--- 不足分を発注
   for(int j = existingCount; j < totalOrdersPerSide; j++)
     {
      double orderPrice  = 0;
      double takeProfit  = 0;

      switch(pendingType)
        {
         case OP_BUYSTOP:
            orderPrice = NormalizeDouble(Ask + (j+1)*(PipStep*10)*pointSize, digits);
            if((orderPrice - Ask) < stopDistance) continue;
            takeProfit = NormalizeDouble(orderPrice + tpOffset, digits);
            break;

         case OP_SELLSTOP:
            orderPrice = NormalizeDouble(Bid - (j+1)*(PipStep*10)*pointSize, digits);
            if((Bid - orderPrice) < stopDistance) continue;
            takeProfit = NormalizeDouble(orderPrice - tpOffset, digits);
            break;

         case OP_BUYLIMIT:
            orderPrice = NormalizeDouble(Ask - (j+1)*(PipStep*10)*pointSize, digits);
            if((Ask - orderPrice) < stopDistance) continue;
            takeProfit = NormalizeDouble(orderPrice + tpOffset, digits);
            break;

         case OP_SELLLIMIT:
            orderPrice = NormalizeDouble(Bid + (j+1)*(PipStep*10)*pointSize, digits);
            if((orderPrice - Bid) < stopDistance) continue;
            takeProfit = NormalizeDouble(orderPrice - tpOffset, digits);
            break;

         default:
            continue;
        }

      OrderSend(Symbol(), pendingType, LotSize, orderPrice, Slippage,
                0,            // ← SL未設定（診断指摘の致命的箇所）
                takeProfit, "Grid", MagicNumber, 0, clrBlue);
     }
  }
//+------------------------------------------------------------------+
```
