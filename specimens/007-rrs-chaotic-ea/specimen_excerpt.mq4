## 検体007 簡略版

#property strict

extern int    MagicBase   = 2000;
extern double FixedLot    = 0.01;
extern int    TakeProfit  = 50;
extern int    StopLoss    = 50;
extern double MaxSpread   = 0.6;
extern int    Slippage    = 3;

int    gBuyMagic;
int    gSellMagic;
double gPoint;

int OnInit()
  {
   gBuyMagic  = MagicBase + 1;
   gSellMagic = MagicBase + 2;
   gPoint     = (Digits == 5 || Digits == 3) ? Point * 10 : Point;
   return(INIT_SUCCEEDED);
  }

void OnTick()
  {
   double spread = (Ask - Bid) / gPoint;
   if(spread > MaxSpread) return;

   bool hasBuy  = HasPosition(OP_BUY,  gBuyMagic);
   bool hasSell = HasPosition(OP_SELL, gSellMagic);

   bool buySignal  = GetBuySignal();
   bool sellSignal = GetSellSignal();

   if(buySignal  && hasSell) CloseAll(OP_SELL, gSellMagic);
   if(sellSignal && hasBuy)  CloseAll(OP_BUY,  gBuyMagic);

   if(buySignal  && !hasBuy  && !hasSell) OpenOrder(OP_BUY);
   if(sellSignal && !hasSell && !hasBuy)  OpenOrder(OP_SELL);
  }

//--- ★エントリーシグナル：ここに独自ロジックを実装する★
bool GetBuySignal()
  {
   return(false);
  }

bool GetSellSignal()
  {
   return(false);
  }

void OpenOrder(int type)
  {
   if(!CheckMargin(Symbol(), type, FixedLot)) return;

   double price = (type == OP_BUY) ? Ask : Bid;
   double sl    = (type == OP_BUY)
                  ? price - StopLoss   * gPoint
                  : price + StopLoss   * gPoint;
   double tp    = (type == OP_BUY)
                  ? price + TakeProfit * gPoint
                  : price - TakeProfit * gPoint;
   int    magic = (type == OP_BUY) ? gBuyMagic : gSellMagic;

   int ticket = OrderSend(
                   Symbol(), type, FixedLot, price, Slippage,
                   NormalizeDouble(sl, Digits),
                   NormalizeDouble(tp, Digits),
                   "", magic, 0, clrNONE);

   if(ticket < 0)
      Print("OpenOrder失敗 err=", GetLastError());
  }

bool HasPosition(int type, int magic)
  {
   for(int i = OrdersTotal() - 1; i >= 0; i--)
     {
      if(!OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) continue;
      if(OrderSymbol()      != Symbol()) continue;
      if(OrderMagicNumber() != magic)    continue;
      if(OrderType()        == type && OrderCloseTime() == 0) return(true);
     }
   return(false);
  }

void CloseAll(int type, int magic)
  {
   for(int i = OrdersTotal() - 1; i >= 0; i--)
     {
      if(!OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) continue;
      if(OrderSymbol()      != Symbol()) continue;
      if(OrderMagicNumber() != magic)    continue;
      if(OrderType()        != type)     continue;

      double closePrice = (type == OP_BUY) ? Bid : Ask;
      if(!OrderClose(OrderTicket(), OrderLots(), closePrice, Slippage, clrNONE))
         Print("CloseAll失敗 err=", GetLastError());
     }
  }

bool CheckMargin(string symbol, int type, double lots)
  {
   if(AccountFreeMarginCheck(symbol, type, lots) < 0)
     {
      Print("証拠金不足");
      return(false);
     }
   return(true);
  }
