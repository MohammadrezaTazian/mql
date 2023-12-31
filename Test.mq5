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
      //trade.Buy(0.1, Symbol(), Ask,0,Ask + 70 * SymbolInfoDouble(Symbol(), SYMBOL_POINT),"test");
      //trade.Sell(0.1, Symbol(), Bid,0,Bid - 70 * SymbolInfoDouble(Symbol(), SYMBOL_POINT),"test");
      trade.BuyStop(
         0.1,
         Ask + 1 * SymbolInfoDouble(Symbol(), SYMBOL_POINT), Symbol(),
         0,
         Ask + 1 * SymbolInfoDouble(Symbol(), SYMBOL_POINT) + 1 * SymbolInfoDouble(Symbol(),
               SYMBOL_POINT),
         0,
         0,
         "test"
      );
      //trade.SellStop(
      //   0.1,
      //   Bid - 50 * SymbolInfoDouble(Symbol(), SYMBOL_POINT),
      //   Symbol(),
      //   0,
      //   Bid - 50 * SymbolInfoDouble(Symbol(), SYMBOL_POINT) - 70 * SymbolInfoDouble(Symbol(),SYMBOL_POINT),
      //   0,
      //   0,
      //   "test"
      //);
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
   Print(" OrderSelect(trans.position):",OrderSelect(2)," OrderGetInteger(ORDER_TYPE):",OrderGetInteger(ORDER_TYPE));

}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTradeTransaction(const MqlTradeTransaction& trans,
                        const MqlTradeRequest& request,
                        const MqlTradeResult& result)
{
//   Print(
//      "TRADE_TRANSACTION_ORDER_ADD:",TRADE_TRANSACTION_ORDER_ADD,
//      " TRADE_TRANSACTION_ORDER_UPDATE:",TRADE_TRANSACTION_ORDER_UPDATE,
//      " TRADE_TRANSACTION_ORDER_DELETE:",TRADE_TRANSACTION_ORDER_DELETE,
//      " TRADE_TRANSACTION_DEAL_ADD:",TRADE_TRANSACTION_DEAL_ADD,
//      " TRADE_TRANSACTION_DEAL_UPDATE:",TRADE_TRANSACTION_DEAL_UPDATE,
//      " TRADE_TRANSACTION_DEAL_DELETE:",TRADE_TRANSACTION_DEAL_DELETE,
//      " TRADE_TRANSACTION_HISTORY_ADD:",TRADE_TRANSACTION_HISTORY_ADD,
//      " TRADE_TRANSACTION_HISTORY_UPDATE:",TRADE_TRANSACTION_HISTORY_UPDATE,
//      " TRADE_TRANSACTION_HISTORY_DELETE:",TRADE_TRANSACTION_HISTORY_DELETE,
//      " TRADE_TRANSACTION_POSITION:",TRADE_TRANSACTION_POSITION,
//      " TRADE_TRANSACTION_REQUEST:",TRADE_TRANSACTION_REQUEST
//   );
//   Print(
//      " ORDER_TYPE_BUY:",ORDER_TYPE_BUY,
//      " ORDER_TYPE_SELL:",ORDER_TYPE_SELL,
//      " ORDER_TYPE_BUY_LIMIT:",ORDER_TYPE_BUY_LIMIT,
//      " ORDER_TYPE_SELL_LIMIT:",ORDER_TYPE_SELL_LIMIT,
//      " ORDER_TYPE_BUY_STOP:",ORDER_TYPE_BUY_STOP,
//      " ORDER_TYPE_SELL_STOP:",ORDER_TYPE_SELL_STOP,
//      " ORDER_TYPE_BUY_STOP_LIMIT:",ORDER_TYPE_BUY_STOP_LIMIT,
//      " ORDER_TYPE_SELL_STOP_LIMIT:",ORDER_TYPE_SELL_STOP_LIMIT,
//      " ORDER_TYPE_CLOSE_BY:",ORDER_TYPE_CLOSE_BY
//   );
//   Print(
//      " ORDER_STATE_STARTED:",ORDER_STATE_STARTED,
//      " ORDER_STATE_PLACED:",ORDER_STATE_PLACED,
//      " ORDER_STATE_CANCELED:",ORDER_STATE_CANCELED,
//      " ORDER_STATE_PARTIAL:",ORDER_STATE_PARTIAL,
//      " ORDER_STATE_FILLED:",ORDER_STATE_FILLED,
//      " ORDER_STATE_REJECTED:",ORDER_STATE_REJECTED,
//      " ORDER_STATE_EXPIRED:",ORDER_STATE_EXPIRED,
//      " ORDER_STATE_REQUEST_ADD:",ORDER_STATE_REQUEST_ADD,
//      " ORDER_STATE_REQUEST_MODIFY:",ORDER_STATE_REQUEST_MODIFY,
//      " ORDER_STATE_REQUEST_CANCEL:",ORDER_STATE_REQUEST_CANCEL
//   );
//   Print(
//      " DEAL_TYPE_BUY:",DEAL_TYPE_BUY,
//      " DEAL_TYPE_SELL:",DEAL_TYPE_SELL,
//      " DEAL_TYPE_BALANCE:",DEAL_TYPE_BALANCE,
//      " DEAL_TYPE_CREDIT:",DEAL_TYPE_CREDIT,
//      " DEAL_TYPE_CHARGE:",DEAL_TYPE_CHARGE,
//      " DEAL_TYPE_CORRECTION:",DEAL_TYPE_CORRECTION,
//      " DEAL_TYPE_BONUS:",DEAL_TYPE_BONUS,
//      " DEAL_TYPE_COMMISSION:",DEAL_TYPE_COMMISSION,
//      " DEAL_TYPE_COMMISSION_DAILY:",DEAL_TYPE_COMMISSION_DAILY,
//      " DEAL_TYPE_COMMISSION_MONTHLY:",DEAL_TYPE_COMMISSION_MONTHLY,
//      " DEAL_TYPE_COMMISSION_AGENT_DAILY:",DEAL_TYPE_COMMISSION_AGENT_DAILY,
//      " DEAL_TYPE_COMMISSION_AGENT_MONTHLY:",DEAL_TYPE_COMMISSION_AGENT_MONTHLY,
//      " DEAL_TYPE_INTEREST:",DEAL_TYPE_INTEREST,
//      " DEAL_TYPE_BUY_CANCELED:",DEAL_TYPE_BUY_CANCELED,
//      " DEAL_TYPE_SELL_CANCELED:",DEAL_TYPE_SELL_CANCELED,
//      " DEAL_DIVIDEND:",DEAL_DIVIDEND,
//      " DEAL_DIVIDEND_FRANKED:",DEAL_DIVIDEND_FRANKED,
//      " DEAL_TAX:",DEAL_TAX
//   );
//   Print(
//      " ORDER_TIME_GTC:",ORDER_TIME_GTC,
//      " ORDER_TIME_DAY:",ORDER_TIME_DAY,
//      " ORDER_TIME_SPECIFIED:",ORDER_TIME_SPECIFIED,
//      " ORDER_TIME_SPECIFIED_DAY:",ORDER_TIME_SPECIFIED_DAY
//   );
//
   Print(
      " trans.type:",trans.type,
      " trans.deal:",trans.deal,
      " trans.deal_type:",trans.deal_type,
      " trans.order:",trans.order,
      " trans.order_state:",trans.order_state,
      " trans.order_type:",trans.order_type,
      " trans.position:",trans.position,
      " trans.position_by:",trans.position_by,
      " trans.price:",trans.price,
      " trans.price_sl:",trans.price_sl,
      " trans.price_tp:",trans.price_tp,
      " trans.price_trigger:",trans.price_trigger,
      " trans.symbol:",trans.symbol,
      " trans.time_expiratio:",trans.time_expiration,
      " trans.time_type:",trans.time_type,
      " trans.volume:",trans.volume
   );
   //Print(
   //   " request.action:",request.action,
   //   " request.comment,:",request.comment,
   //   " request.deviation:",request.deviation,
   //   " request.expiration:",request.expiration,
   //   " request.magic:",request.magic,
   //   " request.order:",request.order,
   //   " request.position:",request.position,
   //   " request.position_by:",request.position_by,
   //   " request.price:",request.price,
   //   " request.sl:",request.sl,
   //   " request.tp:",request.tp,
   //   " request.type:",request.type,
   //   " request.stoplimit:",request.stoplimit,
   //   " request.type_filling:",request.type_filling,
   //   " request.type_time:",request.type_time,
   //   " request.volume:",request.volume
   //);
   //Print(
   //   " result.ask:",result.ask,
   //   " result.bid:",result.bid,
   //   " result.comment:",result.comment,
   //   " result.deal:",result.deal,
   //   " result.order:",result.order,
   //   " result.price:",result.price,
   //   " result.request_id:",result.request_id,
   //   " result.retcode:",result.retcode,
   //   " result.retcode_external:",result.retcode_external,
   //   " result.volume:",result.volume
   //);
   Print(" OrderSelect(trans.position):",OrderSelect(trans.position)," OrderGetInteger(ORDER_TYPE):",OrderGetInteger(ORDER_TYPE));

   if(trans.type == TRADE_TRANSACTION_DEAL_ADD && trans.deal_type == DEAL_TYPE_BUY && trans.order == trans.position)
   {
      Print("BUY"," trans.order:",trans.position," trans.price:",trans.price," trans.price_tp:",trans.price_tp);
   }
   else if(trans.type == TRADE_TRANSACTION_DEAL_ADD && trans.deal_type == DEAL_TYPE_BUY && trans.order != trans.position)
   {
      Print("End A Sell Position"," trans.order:",trans.position," trans.price:",trans.price," trans.price_tp:",trans.price_tp);
   }
   else if(trans.type == TRADE_TRANSACTION_DEAL_ADD && trans.deal_type == DEAL_TYPE_SELL && trans.order == trans.position)
   {
      Print("SELL"," trans.order:",trans.position," trans.price:",trans.price," trans.price_tp:",trans.price_tp);
   }
   else if(trans.type == TRADE_TRANSACTION_DEAL_ADD && trans.deal_type == DEAL_TYPE_SELL && trans.order != trans.position)
   {
      Print("End A Buy Position"," trans.order:",trans.position," trans.price:",trans.price," trans.price_tp:",trans.price_tp);
   }
   else if(trans.type == TRADE_TRANSACTION_ORDER_ADD && trans.order_type == ORDER_TYPE_BUY_LIMIT)
   {
      Print("BUY_LIMIT"," trans.order:",trans.order," trans.price:",trans.price," trans.price_tp:",trans.price_tp);
   }
   else if(trans.type == TRADE_TRANSACTION_ORDER_ADD && trans.order_type == ORDER_TYPE_SELL_LIMIT)
   {
      Print("SELL_LIMIT"," trans.order:",trans.order," trans.price:",trans.price," trans.price_tp:",trans.price_tp);
   }
   else if(trans.type == TRADE_TRANSACTION_ORDER_ADD && trans.order_type == ORDER_TYPE_BUY_STOP)
   {
      Print("BUY_STOP"," trans.order:",trans.order," trans.price:",trans.price," trans.price_tp:",trans.price_tp);
   }
   else if(trans.type == TRADE_TRANSACTION_ORDER_ADD && trans.order_type == ORDER_TYPE_SELL_STOP)
   {
      Print("SELL_STOP"," trans.order:",trans.order," trans.price:",trans.price," trans.price_tp:",trans.price_tp);
   }
}
//+------------------------------------------------------------------+
