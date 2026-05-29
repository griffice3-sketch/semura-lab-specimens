// +------------------------------------------------------------------+
// | Semura Lab - 抽出された脆弱性ロジック（解説用簡略化モデル）          |
// | ※このコードはロジックの破綻構造を解説するための抽象化モデルです。   |
// | ※実際の稼働は不可能であり、特定の著作物を示すものではありません。   |
// +------------------------------------------------------------------+

// 患部1：口座を破壊する「変則マーチン配列」と「配列オーバーラン」
double CalculateNextLot(int trade_count) {
    // 過剰最適化（カーブフィッティング）された不規則な倍率配列
    int multiplier[15];
    multiplier[0]=1;  multiplier[1]=1;  multiplier[2]=2;   multiplier[3]=3;   
    multiplier[4]=6;  multiplier[5]=9;  multiplier[6]=14;  multiplier[7]=22;  
    multiplier[8]=33; multiplier[9]=48; multiplier[10]=82; multiplier[11]=111;
    multiplier[12]=122; multiplier[13]=164; multiplier[14]=185; // 15段目で185倍

    // 【致命的欠陥】配列範囲外アクセス（Array Out of Bounds）
    // trade_countが14（最大段数）に達した際、存在しない[15]番目を参照しようとしてクラッシュする
    double next_lot_multiplier = multiplier[trade_count + 1];

    return (next_lot_multiplier);
}

// 患部2：発注方向とコメントの完全な乖離（スパゲッティコード）
void ExecuteOrders() {
    double base_lot = 0.1;

    // 【致命的欠陥】SELL（売り）を発注しているのに、コメントは"BUY"になっている
    OrderSend(Symbol(), OP_SELL, base_lot, Bid, 2, 0, 0, "BUY", 12345, 0, clrRed);

    // 【致命的欠陥】BUY（買い）を発注しているのに、コメントは"sell"になっている
    OrderSend(Symbol(), OP_BUY, base_lot, Ask, 2, 0, 0, "sell", 12345, 0, clrGreen);
}

// 患部3：永遠に実行されない到達不能コード（デッドコード）
void CheckAndOpen() {
    if (OrdersTotal() > 0) {
        for (int i = 0; i < OrdersTotal(); i++) {
            if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) {
                
                // 何らかの条件判定...
                
                break; // 【致命的欠陥】ここでループを強制的に抜けてしまう

                // breakの後に記述されているため、この発注処理は永遠に実行されない
                ExecuteOrders(); 
            }
        }
    }
}
