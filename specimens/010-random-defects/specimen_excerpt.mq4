//+------------------------------------------------------------------+
//| 検体010 — 匿名診断標本（病巣のみ抽出版）                          |
//| 出所/著作権/作成者情報は全削除。教育・解剖用の最小骨格。          |
//| ※本コードは「勝てる戦略」ではない。欠陥構造の可視化が目的。       |
//+------------------------------------------------------------------+

#property strict

//--- 入力（診断対象パラメータのみ残置）
enum TradingStrategy_enum {OneSide, DoubleSide};
extern TradingStrategy_enum Trading_Strategy = DoubleSide;

extern double minLot_Size = 0.01;
extern double maxLot_Size = 0.50;

extern int    TakeProfit  = 100;   // 病巣: SLと非対称(1:2逆ザヤ)
extern int    StopLoss    = 200;   // 病巣: 同上

extern int    Trailing_Start = 50;
extern int    Trailing_Gap   = 50;

extern int    maxSpread   = 100;   // 病巣: 0.6pips基準の約16倍。実質無効
extern int    Slippage    = 3;

enum RiskMode_enum {FixedMoney, BalancePercentage};
extern RiskMode_enum Risk_In_Money_Type = BalancePercentage;
extern double Money_In_Risk = 5.0;

extern int    Magic = 1000;

//--- 内部
int    gBuyMagic, gSellMagic;
int    OrderCount_Buy, OrderCount_Sell;
int    BuySellRandomMath = -1;
int    Buy_StopLevel, Sell_StopLevel;
string buy_random_symbol, sell_random_symbol;
string buyOpenTrade_Symbol, sellOpenTrade_Symbol;
double Buy_Lot_Size, Sell_Lot_Size;
double gFloatingPL, gRisk_Money;

//+------------------------------------------------------------------+
int OnInit()
  {
   if(Trading_Strategy == OneSide) { gBuyMagic = Magic+1;  gSellMagic = Magic+11; }
   else                           { gBuyMagic = Magic+2;  gSellMagic = Magic+22; }
   return(INIT_SUCCEEDED);
  }

void OnDeinit(const int reason) { }

//+------------------------------------------------------------------+
void OnTick()
  {
//--- 病巣①: 毎ティック再シード → 非決定論・再現不能
   MathSrand(GetTickCount());
   BuySellRandomMath = MathRand() % 6;          // 病巣②: 乱数方向決定(エッジ皆無)

   OrderCount_Buy  = trade_count(OP_BUY,  gBuyMagic);
   OrderCount_Sell = trade_count(OP_SELL, gSellMagic);

   buy_random_symbol  = randomsymbol();         // 病巣③: 乱数銘柄(BT単一/実運用多数)
   sell_random_symbol = randomsymbol();

   buyOpenTrade_Symbol  = GetSymbolOpenTrade(gBuyMagic,  OP_BUY);
   sellOpenTrade_Symbol = GetSymbolOpenTrade(gSellMagic, OP_SELL);

   Buy_Lot_Size  = RandomLotSize();             // 病巣④: 乱数ロット(資金管理放棄)
   Sell_Lot_Size = RandomLotSize();

   Buy_StopLevel  = (int)MarketInfo(buy_random_symbol,  MODE_STOPLEVEL) + 2;
   Sell_StopLevel = (int)MarketInfo(sell_random_symbol, MODE_STOPLEVEL) + 2;

//--- 病巣⑤: グローバル銘柄参照のトレーリング(多銘柄時に破綻)
   if(Trailing_Gap > 0 && Trailing_Start > 0)
     {
      if(OrderCount_Buy  >= 1) TrailingStopLoss(gBuyMagic);
      if(OrderCount_Sell >= 1) TrailingStopLoss(gSellMagic);
     }

//--- 病巣⑥: DoubleSideで常時両建て(スプレッド二重払い)
   if(Trading_Strategy == DoubleSide) DoubleSide_OrderSend();
   else                               OneSide_OrderSend();

//--- 病巣⑦: 損失%で全閉じ(決済価格も単一銘柄参照で多銘柄時に失敗)
   gFloatingPL = CalcFloating(gBuyMagic) + CalcFloating(gSellMagic);
   gRisk_Money = (Risk_In_Money_Type == BalancePercentage)
               ? (-1.0 * AccountBalance() * (Money_In_Risk * 0.01))
               : (-1.0 * Money_In_Risk);

   if(gFloatingPL <= gRisk_Money)
     {
      CloseAll(gBuyMagic);
      CloseAll(gSellMagic);
     }
  }

//+------------------------------------------------------------------+
void DoubleSide_OrderSend()
  {
   if(OrderCount_Buy == 0 && CheckVolume(Buy_Lot_Size, buy_random_symbol)
      && CheckMoney(buy_random_symbol, Buy_Lot_Size, OP_BUY)
      && MarketInfo(buy_random_symbol, MODE_SPREAD) < maxSpread)
     {
      double ask = MarketInfo(buy_random_symbol, MODE_ASK);
      double sl  = (StopLoss  > 0) ? ask - MathMax(StopLoss,  Buy_StopLevel)*Point : 0;
      double tp  = (TakeProfit> 0) ? ask + MathMax(TakeProfit, Buy_StopLevel)*Point : 0;
      ResetLastError();
      if(OrderSend(buy_random_symbol, OP_BUY, Buy_Lot_Size, ask, Slippage, sl, tp, "", gBuyMagic, 0, clrNONE) < 0)
         Print("Buy Order Error: ", GetLastError());
     }

   if(OrderCount_Sell == 0 && CheckVolume(Sell_Lot_Size, sell_random_symbol)
      && CheckMoney(sell_random_symbol, Sell_Lot_Size, OP_SELL)
      && MarketInfo(sell_random_symbol, MODE_SPREAD) < maxSpread)
     {
      double bid = MarketInfo(sell_random_symbol, MODE_BID);
      double sl  = (StopLoss  > 0) ? bid + MathMax(StopLoss,  Sell_StopLevel)*Point : 0;
      double tp  = (TakeProfit> 0) ? bid - MathMax(TakeProfit, Sell_StopLevel)*Point : 0;
      ResetLastError();
      if(OrderSend(sell_random_symbol, OP_SELL, Sell_Lot_Size, bid, Slippage, sl, tp, "", gSellMagic, 0, clrNONE) < 0)
         Print("Sell Order Error: ", GetLastError());
     }
  }

//+------------------------------------------------------------------+
void OneSide_OrderSend()
  {
//--- 病巣: 乱数2/5は無発注の死にコード(設計意図の空洞)
   if(OrderCount_Buy == 0 && OrderCount_Sell == 0
      && (BuySellRandomMath == 1 || BuySellRandomMath == 4)
      && CheckVolume(Buy_Lot_Size, buy_random_symbol)
      && CheckMoney(buy_random_symbol, Buy_Lot_Size, OP_BUY)
      && MarketInfo(buy_random_symbol, MODE_SPREAD) < maxSpread)
     {
      double ask = MarketInfo(buy_random_symbol, MODE_ASK);
      double sl  = (StopLoss  > 0) ? ask - MathMax(StopLoss,  Buy_StopLevel)*Point : 0;
      double tp  = (TakeProfit> 0) ? ask + MathMax(TakeProfit, Buy_StopLevel)*Point : 0;
      ResetLastError();
      if(OrderSend(buy_random_symbol, OP_BUY, Buy_Lot_Size, ask, Slippage, sl, tp, "", gBuyMagic, 0, clrNONE) < 0)
         Print("Buy Order Error: ", GetLastError());
     }

   if(OrderCount_Sell == 0 && OrderCount_Buy == 0
      && (BuySellRandomMath == 0 || BuySellRandomMath == 3)
      && CheckVolume(Sell_Lot_Size, sell_random_symbol)
      && CheckMoney(sell_random_symbol, Sell_Lot_Size, OP_SELL)
      && MarketInfo(sell_random_symbol, MODE_SPREAD) < maxSpread)
     {
      double bid = MarketInfo(sell_random_symbol, MODE_BID);
      double sl  = (StopLoss  > 0) ? bid + MathMax(StopLoss,  Sell_StopLevel)*Point : 0;
      double tp  = (TakeProfit> 0) ? bid - MathMax(TakeProfit, Sell_StopLevel)*Point : 0;
      ResetLastError();
      if(OrderSend(sell_random_symbol, OP_SELL, Sell_Lot_Size, bid, Slippage, sl, tp, "", gSellMagic, 0, clrNONE) < 0)
         Print("Sell Order Error: ", GetLastError());
     }
  }

//+------------------------------------------------------------------+
double CalcFloating(int magic)
  {
   double v = 0;
   for(int i = 0; i < OrdersTotal(); i++)
     {
      if(!OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) continue;
      if(OrderType() != OP_BUY && OrderType() != OP_SELL) continue;
      if(OrderMagicNumber() == magic)
         v += OrderProfit() + OrderSwap() + OrderCommission();
     }
   return v;
  }

//+------------------------------------------------------------------+
void CloseAll(int magic)
  {
   for(int pos = OrdersTotal()-1; pos >= 0; pos--)
     {
      if(!OrderSelect(pos, SELECT_BY_POS, MODE_TRADES)) continue;
      if(OrderMagicNumber() != magic) continue;

      ResetLastError();
      if(OrderType() == OP_BUY)
        {
         //--- 病巣: 決済価格に単一銘柄グローバルを使用(多銘柄時に失敗)
         if(!OrderClose(OrderTicket(), OrderLots(), MarketInfo(buyOpenTrade_Symbol, MODE_BID), Slippage, clrNONE))
            Print("Buy close failed: ", GetLastError());
        }
      else if(OrderType() == OP_SELL)
        {
         if(!OrderClose(OrderTicket(), OrderLots(), MarketInfo(sellOpenTrade_Symbol, MODE_ASK), Slippage, clrNONE))
            Print("Sell close failed: ", GetLastError());
        }
     }
  }

//+------------------------------------------------------------------+
int trade_count(int type, int magic)
  {
   int c = 0;
   for(int i = 0; i < OrdersTotal(); i++)
     {
      if(!OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) continue;
      if(OrderMagicNumber() != magic) continue;
      if(OrderType() == type) c++;
     }
   return c;
  }

//+------------------------------------------------------------------+
void TrailingStopLoss(int magic)
  {
   for(int i = OrdersTotal()-1; i >= 0; i--)
     {
      if(!OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) continue;
      double entry = OrderOpenPrice();

      //--- 病巣: SL計算でグローバル単一銘柄を参照 → 多銘柄時に別銘柄価格でSL
      if(OrderMagicNumber() == magic && OrderType() == OP_BUY)
        {
         double bid = MarketInfo(buyOpenTrade_Symbol, MODE_BID);
         if(bid - (entry + Trailing_Start*Point) > Point*Trailing_Gap)
            if(OrderStopLoss() < bid - Point*Trailing_Gap || OrderStopLoss() == 0)
              {
               ResetLastError(); RefreshRates();
               if(!OrderModify(OrderTicket(), OrderOpenPrice(), bid - Point*Trailing_Gap, OrderTakeProfit(), 0, clrNONE))
                  Print("Buy trail error: ", GetLastError());
              }
        }

      if(OrderMagicNumber() == magic && OrderType() == OP_SELL)
        {
         double ask = MarketInfo(sellOpenTrade_Symbol, MODE_ASK);
         if((entry - Trailing_Start*Point) - ask > Point*Trailing_Gap)
            if(OrderStopLoss() > ask + Point*Trailing_Gap || OrderStopLoss() == 0)
              {
               ResetLastError(); RefreshRates();
               if(!OrderModify(OrderTicket(), OrderOpenPrice(), ask + Point*Trailing_Gap, OrderTakeProfit(), 0, clrNONE))
                  Print("Sell trail error: ", GetLastError());
              }
        }
     }
  }

//+------------------------------------------------------------------+
bool CheckMoney(string symb, double lots, int type)
  {
   if(AccountFreeMarginCheck(symb, type, lots) < 0)
     {
      Print("Not enough money to trade");
      return(false);
     }
   return(true);
  }

//+------------------------------------------------------------------+
string randomsymbol()
  {
   string pairs[] = {"USD","GBP","AUD","CAD","JPY","XAU","XAG",
                     "EUR","CHF","SGD","HKD","NZD"};
   int total = SymbolsTotal(true);
   string valid[];

   for(int i = 0; i < total; i++)
     {
      string name = SymbolName(i, true);
      for(int j = 0; j < ArraySize(pairs); j++)
         for(int k = 0; k < ArraySize(pairs); k++)
            if(j != k)
               if(StringFind(name, pairs[j]) != -1 && StringFind(name, pairs[k]) != -1)
                 {
                  ArrayResize(valid, ArraySize(valid)+1);
                  valid[ArraySize(valid)-1] = name;
                 }
     }

   if(ArraySize(valid) > 0)
      return valid[MathRand() % ArraySize(valid)];
   return "";
  }

//+------------------------------------------------------------------+
string GetSymbolOpenTrade(int magic, int type)
  {
   for(int i = 0; i < OrdersTotal(); i++)
      if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
         if(OrderMagicNumber() == magic && OrderType() == type)
            return OrderSymbol();
   return "";
  }

//+------------------------------------------------------------------+
double RandomLotSize()
  {
   double v = minLot_Size + (maxLot_Size - minLot_Size) * MathRand() / 32767.0;
   return NormalizeDouble(v, 2);
  }

//+------------------------------------------------------------------+
bool CheckVolume(double volume, string symb)
  {
   double vmin  = SymbolInfoDouble(symb, SYMBOL_VOLUME_MIN);
   double vmax  = SymbolInfoDouble(symb, SYMBOL_VOLUME_MAX);
   double vstep = SymbolInfoDouble(symb, SYMBOL_VOLUME_STEP);
   if(volume < vmin) return(false);
   if(volume > vmax) return(false);
   int ratio = (int)MathRound(volume / vstep);
   if(MathAbs(ratio*vstep - volume) > 0.0000001) return(false);
   return(true);
  }
//+------------------------------------------------------------------+
