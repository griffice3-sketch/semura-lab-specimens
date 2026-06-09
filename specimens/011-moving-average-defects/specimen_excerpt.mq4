
//+------------------------------------------------------------------+
//|  検体011 — 簡略化版（Semura Lab 診断用サンプル）                 |
//|------------------------------------------------------------------|
//|  ※本コードは診断目的で核心ロジックのみを抽出した「検体」です。   |
//|  ※著作権表記・作成者情報は削除済み。                            |
//|  ※実運用は不可。動作保証なし。研究・観察用途に限る。            |
//|  ※ロジックの優劣を論じるものではなく、検体として利用したのみ。   |
//+------------------------------------------------------------------+
#property strict

//==================================================================
//  [簡略化表示]
//  ・診断に使用した「エントリー判定」「決済判定」のみを抽出
//  ・建値移動(Breakeven)ブロックは診断対象外のため省略
//  ・初期化/ロット補正/ログ出力等の周辺処理は削除
//==================================================================

//--- 診断に必要な最小パラメータのみ ---
input int    MovingPeriod   = 14;     // SMA期間
input int    MagicNumber    = 12345;  // 識別番号
input double LotSize        = 0.5;    // ロット
input double StopLossPips   = 100;    // SL(検体記載値のまま)
input double TakeProfitPips = 800;    // TP(検体記載値のまま)
input int    StartHour      = 3;      // 稼働開始時
input int    EndHour        = 22;     // 稼働終了時

//+------------------------------------------------------------------+
//| Tick                                                             |
//+------------------------------------------------------------------+
void OnTick()
{
    int h = Hour();
    if (h >= StartHour && h < EndHour)
    {
        CheckForOpen();
        CheckForClose();
    }
}

//+------------------------------------------------------------------+
//| エントリー判定（診断抽出部）                                     |
//|  SMAを前足の始値→終値が跨いだ瞬間に順方向エントリー             |
//+------------------------------------------------------------------+
void CheckForOpen()
{
    if (Volume[0] > 1) return;  // 新バー初動のみ

    double ma  = iMA(Symbol(), 0, MovingPeriod, 0, MODE_SMA, PRICE_CLOSE, 0);
    double pt  = MarketInfo(Symbol(), MODE_POINT);

    //--- 売り：MA下抜けクロス ---
    if (Open[1] > ma && Close[1] < ma)
    {
        double sl = NormalizeDouble(Bid + StopLossPips   * pt, _Digits);
        double tp = NormalizeDouble(Bid - TakeProfitPips * pt, _Digits);
        OrderSend(Symbol(), OP_SELL, LotSize, Bid, 0, sl, tp, "", MagicNumber, 0, clrRed);
        return;
    }

    //--- 買い：MA上抜けクロス ---
    if (Open[1] < ma && Close[1] > ma)
    {
        double sl = NormalizeDouble(Ask - StopLossPips   * pt, _Digits);
        double tp = NormalizeDouble(Ask + TakeProfitPips * pt, _Digits);
        OrderSend(Symbol(), OP_BUY, LotSize, Ask, 0, sl, tp, "", MagicNumber, 0, clrBlue);
        return;
    }
}

//+------------------------------------------------------------------+
//| 決済判定（診断抽出部）                                           |
//|  SL/TP到達でクローズ                                            |
//+------------------------------------------------------------------+
void CheckForClose()
{
    for (int i = 0; i < OrdersTotal(); i++)
    {
        if (!OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) break;
        if (OrderMagicNumber() != MagicNumber || OrderSymbol() != Symbol()) continue;

        bool slHit = (OrderStopLoss() != 0.0) &&
                     ((OrderType()==OP_BUY  && Bid <= OrderStopLoss()) ||
                      (OrderType()==OP_SELL && Ask >= OrderStopLoss()));

        bool tpHit = (OrderTakeProfit() != 0.0) &&
                     ((OrderType()==OP_BUY  && Bid >= OrderTakeProfit()) ||
                      (OrderType()==OP_SELL && Ask <= OrderTakeProfit()));

        if (slHit) OrderClose(OrderTicket(), OrderLots(), OrderStopLoss(),   0, clrWhite);
        else if (tpHit) OrderClose(OrderTicket(), OrderLots(), OrderTakeProfit(), 0, clrWhite);
    }
}
//+------------------------------------------------------------------+
//  ── 注意事項 ──────────────────────────────────────────────
//  本検体011は Semura Lab における診断・観察のためのサンプルであり、
//  実際の取引で使用することはできません。動作・収益を一切保証しません。
//  本掲載はロジックを批判する目的ではなく、診断プロセスの題材として
//  「検体」を利用したという位置づけのみです。
//+------------------------------------------------------------------+
```

---

### 簡略化の要点（観点別）

| 観点 | 対応 |
|---|---|
| ①著作権・作成者情報の削除 | `copyright` / `link` / `version` 行、ファイル名表記を全削除 |
| ②検体簡略化の表示 | ヘッダおよび `[簡略化表示]` ブロックで明示 |
| ③診断利用部分のみ抽出 | エントリー判定・決済判定のみ残し、建値移動/初期化/ログ等を省略 |
| ④実践不可の断り | ヘッダと末尾「注意事項」に明記 |
| ⑤検体としての位置づけ | 末尾注記でロジック批判ではなく題材利用である旨を明示 |

※建値移動ブロックは診断時に「動作不能箇所」として切り出した部分であり、検体の核心ロジック観察には不要のため簡略化版からは除外している。
