//+------------------------------------------------------------------+
//|                                                         Test.mq5 |
//|                                  Copyright 2023, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2023, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"
#include<Trade/trade.mqh>
CTrade trade;
bool doesHaveOrder = false;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
//---

//---
   return(INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
//---

}
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
//---
   if(doesHaveOrder == false)
   {
      double Ask = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_ASK),_Digits);
      double Bid = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_BID),_Digits);
      //trade.Buy(0.1, Symbol(), Ask,0,0,"test");
      //trade.Sell(0.1, Symbol(), Bid,0,0,"test");
      //trade.BuyStop(0.1, Ask + 50 * SymbolInfoDouble(Symbol(), SYMBOL_POINT), Symbol(),0,0,0,0,"test");
      trade.SellStop(0.1, Bid - 50 * SymbolInfoDouble(Symbol(), SYMBOL_POINT), Symbol(),0,0,0,0,"test");
      //trade.BuyLimit(0.1,Bid - 50 * SymbolInfoDouble(Symbol(), SYMBOL_POINT),Symbol(),0,0,0,0,"test");
      //trade.SellLimit(0.1,Ask + 0.02 * SymbolInfoDouble(Symbol(), SYMBOL_POINT),Symbol(),0,0,0,0,"test");
      doesHaveOrder = true;
   }

}
//+------------------------------------------------------------------+
//| Trade function                                                   |
//+------------------------------------------------------------------+
void OnTrade()
{
//---

}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTradeTransaction(const MqlTradeTransaction& trans,
                        const MqlTradeRequest& request,
                        const MqlTradeResult& result)
{
   //Print("TRADE_TRANSACTION_ORDER_ADD: ",TRADE_TRANSACTION_ORDER_ADD,
   //      " TRADE_TRANSACTION_ORDER_UPDATE: ",TRADE_TRANSACTION_ORDER_UPDATE,
   //      " TRADE_TRANSACTION_ORDER_DELETE: ",TRADE_TRANSACTION_ORDER_DELETE,
   //      " TRADE_TRANSACTION_DEAL_ADD: ",TRADE_TRANSACTION_DEAL_ADD,
   //      " TRADE_TRANSACTION_DEAL_UPDATE: ",TRADE_TRANSACTION_DEAL_UPDATE,
   //      " TRADE_TRANSACTION_DEAL_DELETE: ",TRADE_TRANSACTION_DEAL_DELETE,
   //      " TRADE_TRANSACTION_HISTORY_ADD: ",TRADE_TRANSACTION_HISTORY_ADD,
   //      " TRADE_TRANSACTION_HISTORY_UPDATE: ",TRADE_TRANSACTION_HISTORY_UPDATE,
   //      " TRADE_TRANSACTION_HISTORY_DELETE: ",TRADE_TRANSACTION_HISTORY_DELETE,
   //      " TRADE_TRANSACTION_POSITION: ",TRADE_TRANSACTION_POSITION,
   //      " TRADE_TRANSACTION_REQUEST: ",TRADE_TRANSACTION_REQUEST
   //     );
//   Print(" ORDER_TYPE_BUY: ",ORDER_TYPE_BUY,
//         " ORDER_TYPE_SELL: ",ORDER_TYPE_SELL,
//         " ORDER_TYPE_BUY_LIMIT: ",ORDER_TYPE_BUY_LIMIT,
//         " ORDER_TYPE_SELL_LIMIT: ",ORDER_TYPE_SELL_LIMIT,
//         " ORDER_TYPE_BUY_STOP: ",ORDER_TYPE_BUY_STOP,
//         " ORDER_TYPE_SELL_STOP: ",ORDER_TYPE_SELL_STOP);
//
   Print(" trans.type: ",trans.type," trans.deal: ",trans.deal," trans.deal_type: ",trans.deal_type,
         " trans.order: ",trans.order," trans.order_state: ",trans.order_state,
         " trans.order_type: ",trans.order_type," trans.position: ",trans.position,
         " trans.position_by: ",trans.position_by,"",trans.price,
         " trans.price_sl: ",trans.price_sl," trans.price_tp: ",trans.price_tp,
         " trans.price_trigger: ",trans.price_trigger," trans.symbol: ",trans.symbol,
         " trans.time_expiratio: ",trans.time_expiration," trans.time_type: ",trans.time_type,
         " trans.volume: ",trans.volume);
   if(trans.type == TRADE_TRANSACTION_ORDER_DELETE && trans.order_type == ORDER_TYPE_BUY)
   {
      Print("BUY"," tiket: ",trans.order);
   }
   if(trans.type == TRADE_TRANSACTION_ORDER_DELETE && trans.order_type == ORDER_TYPE_SELL)
   {
      Print("SELL"," tiket: ",trans.order);
   }
   if(trans.type == TRADE_TRANSACTION_ORDER_ADD && trans.order_type == ORDER_TYPE_BUY_STOP)
   {
      Print("BUY_STOP"," tiket: ",trans.order);
   }
   if(trans.type == TRADE_TRANSACTION_ORDER_ADD && trans.order_type == ORDER_TYPE_SELL_STOP)
   {
      Print("SELL_STOP"," tiket: ",trans.order);
   }
   if(trans.type == TRADE_TRANSACTION_ORDER_DELETE && trans.order_type == ORDER_TYPE_BUY_STOP)
   {
      Print("BUY_STOP_To_BUY"," tiket: ",trans.order);
   }
      if(trans.type == TRADE_TRANSACTION_ORDER_DELETE && trans.order_type == ORDER_TYPE_SELL_STOP)
   {
      Print("SELL_STOP_To_SELL"," tiket: ",trans.order);
   }
}
//+------------------------------------------------------------------+
