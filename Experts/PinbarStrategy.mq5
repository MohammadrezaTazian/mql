//+------------------------------------------------------------------+
//|                                               PinbarStrategy.mq5 |
//|                                              Mohammadreza Tazian |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Mohammadreza Tazian"
#property link      "https://www.mql5.com"
#property version   "1.00"
#include <Trade\Trade.mqh>
CTrade trade;

bool haveOpenedOrder = false;
double pinbarBodySize = 0.00030;
double pinbarTailFactor = 2.5;
double orderVolume = 1;

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

}
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
   if(!haveOpenedOrder)
   {
      double open = NormalizeDouble(iOpen(Symbol(),PERIOD_CURRENT,1), _Digits);
      double close = NormalizeDouble(iClose(Symbol(),PERIOD_CURRENT,1), _Digits);
      double high = NormalizeDouble(iHigh(Symbol(),PERIOD_CURRENT,1), _Digits);
      double low = NormalizeDouble(iLow(Symbol(),PERIOD_CURRENT,1), _Digits);

      if(IsPinbar(open,close,high,low))
      {
         double Ask = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_ASK), _Digits);
         double Bid = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_BID), _Digits);
         double point = SymbolInfoDouble(Symbol(), SYMBOL_POINT);

         if(trade.Buy(orderVolume,Symbol(),Ask,low,Ask + MathAbs(open - close) * point,"bought"))
         {
            haveOpenedOrder = true;
         }
      }
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
//| TradeTransaction function                                        |
//+------------------------------------------------------------------+
void OnTradeTransaction(const MqlTradeTransaction& trans,
                        const MqlTradeRequest& request,
                        const MqlTradeResult& result)
{
//---

}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool IsPinbar(double open,double close,double high,double low)
{


   if(
      open > close //Red Candle
      //&& open - close <= pinbarBodySize
      && close - low > 4 * (open - close)
   )
   {
   Print("open > close");
      return true;
   }
   if(
      open < close //Green Candle
      //&& close - open <= pinbarBodySize
      && open - low > 4 * (close - open)
   )
   {
      Print("open < close");
      return true;
   }
   return false;
}
//+------------------------------------------------------------------+
