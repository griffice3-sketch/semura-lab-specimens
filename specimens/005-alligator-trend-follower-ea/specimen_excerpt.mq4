// +------------------------------------------------------------------+
// | Semura Lab - 抽出された脆弱性ロジック（解説用簡略化モデル）      |
// | ※このコードはロジックの破綻構造を解説するための抽象化モデルです。 |
// | ※実際の稼働は不可能であり、特定の著作物を示すものではありません。 |
// +------------------------------------------------------------------+

// 患部1：未確定足の参照による「リペイントバグ」（未来予知 / CAP）
void DetectTrend_Flawed() {
    // 【致命的欠陥】シフト値（第12引数）に「0（現在形成中の未確定足）」を指定している。
    // ティックが動くたびに値が変動し、シグナルが点滅・反転するため、
    // バックテストと実運用が完全に乖離する（検証不可能な致命傷）。
    double jawNow   = iAlligator(Symbol(), 0, 13, 8, 8, 5, 5, 3, MODE_SMMA, PRICE_MEDIAN, MODE_GATORJAW, 0);
    double teethNow = iAlligator(Symbol(), 0, 13, 8, 8, 5, 5, 3, MODE_SMMA, PRICE_MEDIAN, MODE_GATORTEETH, 0);
    double lipsNow  = iAlligator(Symbol(), 0, 13, 8, 8, 5, 5, 3, MODE_SMMA, PRICE_MEDIAN, MODE_GATORLIPS, 0);
}

// 患部2：マジックナンバーの完全な欠落（他注文の巻き込み）
void SendOrder_Flawed() {
    double lots = 0.1;
    
    // 【致命的欠陥】OrderSendの第9引数（マジックナンバー）に「0」が指定されている。
    // EA固有の識別IDが付与されないため、裁量トレードや他EAのポジションと
    // 区別がつかなくなり、誤認・誤決済といった深刻なコンフリクトを引き起こす。
    int ticket = OrderSend(Symbol(), OP_BUY, lots, Ask, 2, 0, 0, "Sniper", 0, 0, clrGreen);
}

// 患部3：決済関数のインデックス破壊（昇順ループ）
void CloseOrders_Flawed() {
    // 【致命的欠陥】OrdersTotal()に対して「昇順 (i++)」でループを回している。
    // OrderCloseが成功してポジションが消滅すると、配列のインデックスが前方にずれ、
    // 直後の注文が読み飛ばされてしまうMQL初心者の典型的なバグ。
    for (int i = 0; i < OrdersTotal(); i++) {
        if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) {
            // マジックナンバーの確認すら行っていないため、他システムのポジションも巻き添えにする
            if (OrderSymbol() == Symbol() && OrderType() == OP_BUY) {
                OrderClose(OrderTicket(), OrderLots(), Bid, 2, clrRed);
            }
        }
    }
}

// 患部4：放置された死にコード（摩擦コストへの無防備）
void CheckSpread_Flawed() {
    // 【補足欠陥】スプレッドを管理・制限するための変数が宣言されているが...
    double spreadValue;
    
    // コード内のどこにも計算・代入・評価の処理が存在しない（Dead code）。
    // 結果的にSemura Labが想定する0.6pips等の「物理的摩擦」に対して無防備となり、
    // レンジ相場でのシグナル乱発時にスプレッド負けで口座を削り取られる。
}
