## 検体007 簡略版

```mql4
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
```

---

## 検体008 簡略版

```mql4
#property strict

extern int    MagicNumber = 3000;
extern double FixedLot    = 0.01;
extern int    AtrPeriod   = 14;
extern double SLfactor    = 1.0;
extern double TPfactor    = 1.0;
extern double MaxSpread   = 0.6;
extern int    Slippage    = 3;

double gPoint;

int OnInit()
  {
   gPoint = (Digits == 5 || Digits == 3) ? Point * 10 : Point;
   return(INIT_SUCCEEDED);
  }

void OnTick()
  {
   double spread = (Ask - Bid) / gPoint;
   if(spread > MaxSpread) return;

   if(HasOpenPosition()) return;

   bool buySignal  = GetBuySignal();
   bool sellSignal = GetSellSignal();

   if(buySignal)  SendOrder(OP_BUY);
   if(sellSignal) SendOrder(OP_SELL);
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

void SendOrder(int type)
  {
   double lot = NormalizedLot();
   if(!CheckMargin(Symbol(), type, lot)) return;

   // 確定足(index=1)のATRを使用
   double atr = iATR(Symbol(), PERIOD_CURRENT, AtrPeriod, 1);
   if(atr <= 0) return;

   double price, sl, tp;

   if(type == OP_BUY)
     {
      price = Ask;
      sl    = NormalizeDouble(price - atr * SLfactor, Digits);
      tp    = NormalizeDouble(price + atr * TPfactor, Digits);
     }
   else
     {
      price = Bid;
      sl    = NormalizeDouble(price + atr * SLfactor, Digits);
      tp    = NormalizeDouble(price - atr * TPfactor, Digits);
     }

   // SL/TPを発注と同時に設定（二段階設定禁止）
   int ticket = OrderSend(
                   Symbol(), type, lot, price, Slippage,
                   sl, tp, "", MagicNumber, 0, clrNONE);

   if(ticket < 0)
      Print("SendOrder失敗 err=", GetLastError());
  }

bool HasOpenPosition()
  {
   for(int i = OrdersTotal() - 1; i >= 0; i--)
     {
      if(!OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) continue;
      // 修正：原検体の && バグを || に修正
      if(OrderSymbol() != Symbol() || OrderMagicNumber() != MagicNumber) continue;
      if(OrderCloseTime() == 0) return(true);
     }
   return(false);
  }

double NormalizedLot()
  {
   double step   = MarketInfo(Symbol(), MODE_LOTSTEP);
   double minLot = MarketInfo(Symbol(), MODE_MINLOT);
   double maxLot = MarketInfo(Symbol(), MODE_MAXLOT);
   double lot    = MathRound(FixedLot / step) * step;
   return(MathMin(MathMax(lot, minLot), maxLot));
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
```
