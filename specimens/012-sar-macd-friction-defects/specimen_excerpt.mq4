
//+------------------------------------------------------------------+
//|  検体012 ／ 簡略化ロジック（Semura Lab 診断用抽出版）             |
//|  ※本コードは原著作者情報・識別情報をすべて除去した簡略版です      |
//|------------------------------------------------------------------|
//|  【表示】これは「検体簡略化」版である。                          |
//|  【位置づけ】特定ロジックの批判を目的とせず、診断手法を説明する   |
//|             ための「検体（サンプル）」として抽出・再構成したもの。|
//|  【重要・免責】本コードは診断対象部分のみを抜き出した不完全な     |
//|             断片であり、コンパイル・実運用・バックテストには      |
//|             一切使用できない。実取引での利用を想定していない。    |
//+------------------------------------------------------------------+
#property strict

//============================================================
// 〔診断に利用した中核パラメータのみ抽出〕
//============================================================
input double StepSAR        = 0.02;   // SAR 加速ステップ
input double MaxSAR         = 0.2;    // SAR 最大加速
input int    SMA_Period     = 40;     // トレンド判定SMA
input int    SMA_Shift      = 3;      // SMAシフト
input int    SignalWindowBars = 5;    // SARフリップ探索本数
input int    MaxArmedBars   = 15;     // アーム保持上限
input bool   UseRiskPercent = true;   // リスク%ロット使用
input double RiskPercent    = 1.0;    // 口座フリーマージン基準リスク
input double TakeProfitPips = 0.0;    // TP（既定=無し）

//============================================================
// 〔状態フラグ：診断対象の挙動を再現する最小限〕
//============================================================
bool BuyArmed = false,  SellArmed = false;
datetime BuyArmedBarTime = 0, SellArmedBarTime = 0;
datetime lastTradeBarTime = 0;

//============================================================
// 〔診断ポイント①：三段ゲートのエントリー判定〕
//   SARフリップ → SMA(1)クロスでアーム → MACD方向一致で発射
//============================================================
void EvaluateEntryLogic()
{
   // --- 確定足のみ処理（未来参照なし：診断で確認済みの誠実点）
   static datetime lastBar = 0;
   if(Time[1] == lastBar) return;
   lastBar = Time[1];

   // --- MACD方向（確定足）
   double mMain   = iMACD(NULL,0,12,26,9,PRICE_CLOSE,MODE_MAIN,1);
   double mSignal = iMACD(NULL,0,12,26,9,PRICE_CLOSE,MODE_SIGNAL,1);
   bool macdBull = (mMain > mSignal);
   bool macdBear = (mMain < mSignal);

   // --- 第1ゲート：SARフリップ探索
   bool buyFlip=false, sellFlip=false; int bIdx=-1, sIdx=-1;
   for(int j=1; j<=SignalWindowBars; j++)
   {
      double sar1 = iSAR(NULL,0,StepSAR,MaxSAR,j);
      double sar2 = iSAR(NULL,0,StepSAR,MaxSAR,j+1);
      double sma  = iMA(NULL,0,SMA_Period,SMA_Shift,MODE_SMA,PRICE_CLOSE,j);
      if(sar2>Close[j+1] && sar1<Close[j] && sar1<sma){ buyFlip=true;  bIdx=j; break; }
      if(sar2<Close[j+1] && sar1>Close[j] && sar1>sma){ sellFlip=true; sIdx=j; break; }
   }

   // --- 第2ゲート：SMA(1)クロスでアーム
   if(buyFlip && !BuyArmed)
   {
      if(Close[bIdx+1] < iMA(NULL,0,1,0,MODE_SMA,PRICE_CLOSE,bIdx+1) &&
         Close[bIdx]   > iMA(NULL,0,1,0,MODE_SMA,PRICE_CLOSE,bIdx))
         { BuyArmed=true; BuyArmedBarTime=Time[bIdx]; }
   }
   if(sellFlip && !SellArmed)
   {
      if(Close[sIdx+1] > iMA(NULL,0,1,0,MODE_SMA,PRICE_CLOSE,sIdx+1) &&
         Close[sIdx]   < iMA(NULL,0,1,0,MODE_SMA,PRICE_CLOSE,sIdx))
         { SellArmed=true; SellArmedBarTime=Time[sIdx]; }
   }

   // --- アーム解除（逆フリップ or タイムアウト）
   if(BuyArmed  && (sellFlip || BarsSince(BuyArmedBarTime)  > MaxArmedBars)) BuyArmed=false;
   if(SellArmed && (buyFlip  || BarsSince(SellArmedBarTime) > MaxArmedBars)) SellArmed=false;

   // --- 第3ゲート：MACD方向一致で発射（単一ポジション前提）
   if(CountPositions()==0 && Time[1]!=lastTradeBarTime)
   {
      double sar = iSAR(NULL,0,StepSAR,MaxSAR,1);
      double sma = iMA(NULL,0,SMA_Period,SMA_Shift,MODE_SMA,PRICE_CLOSE,1);
      if(BuyArmed  && macdBull && sar<sma && Close[1]>sar && Close[1]>sma) OpenTrade(OP_BUY);
      if(SellArmed && macdBear && sar>sma && Close[1]<sar && Close[1]<sma) OpenTrade(OP_SELL);
   }
}

//============================================================
// 〔診断ポイント②：リスク%ロット ＋ SL=直近SAR〕
//   ※診断で「SL密着時にロット暴騰」を確認した中核部分
//============================================================
void OpenTrade(int type)
{
   double price = (type==OP_BUY)? Ask : Bid;
   double initialSL = NormalizeDouble(iSAR(NULL,0,StepSAR,MaxSAR,1),Digits);
   double lots = 0.10;

   if(UseRiskPercent)
   {
      double riskAmount = AccountFreeMargin()*(RiskPercent/100.0);
      double stopDiff   = MathAbs(price - initialSL);   // ← SAR密着で極小化し得る
      lots = CalculateLotsByRisk(riskAmount, stopDiff); // ← 結果ロット暴騰の論点
   }
   // ※OrderSend本体は診断に不要のため省略（実行不可）
}

//============================================================
// 〔診断ポイント③：出口＝MACD反転即時クローズ ＋ SARトレール〕
//============================================================
void ManageExitLogic()
{
   double mMain   = iMACD(NULL,0,12,26,9,PRICE_CLOSE,MODE_MAIN,1);
   double mSignal = iMACD(NULL,0,12,26,9,PRICE_CLOSE,MODE_SIGNAL,1);
   double sarLast = iSAR(NULL,0,StepSAR,MaxSAR,1);

   // MACD方向が反転した瞬間にクローズ（診断で「ホイップソー要因」と指摘した部分）
   //  OP_BUY  → mMain<mSignal でクローズ
   //  OP_SELL → mMain>mSignal でクローズ
   // SLを sarLast へ片方向トレール（診断対象の挙動）
   // ※実発注API（OrderClose/OrderModify）は省略（実行不可）
}

//============================================================
// 〔補助〕診断挙動の再現に必要な最小ヘルパー（骨子のみ）
//============================================================
double CalculateLotsByRisk(double riskAmount, double stopDiff)
{
   // tickValue/tickSize から1ロット当たりリスクを算出し
   // riskAmount を割って rawLots を得る構造のみ抽出（min/max丸めは省略）
   if(stopDiff<=0.0) return 0.0;
   double tickValue = MarketInfo(Symbol(),MODE_TICKVALUE);
   double tickSize  = MarketInfo(Symbol(),MODE_TICKSIZE);
   if(tickValue<=0.0 || tickSize<=0.0) return 0.0;
   double perLot = stopDiff*(tickValue/tickSize);
   return (perLot>0.0)? (riskAmount/perLot) : 0.0;
}

int BarsSince(datetime t)
{
   for(int s=1; s<iBars(NULL,0); s++) if(Time[s]==t) return s-1;
   return MaxArmedBars+1;
}

int CountPositions()
{
   // 自EAポジション数のカウント骨子のみ（Magic判定は省略）
   return 0;
}

//+------------------------------------------------------------------+
//  〔再掲・免責〕                                                    |
//  本ファイルは検体012の「診断に用いた論理部分のみ」を抽出した       |
//  簡略・不完全な断片である。発注・決済の実体API、初期化、ティック   |
//  駆動部などは意図的に省略しており、コンパイル不可・実運用不可。     |
//  特定ロジックや作成者を批判する目的は一切なく、診断プロセスを       |
//  説明するための学術的「検体」としてのみ位置づけられる。            |
//+------------------------------------------------------------------+
