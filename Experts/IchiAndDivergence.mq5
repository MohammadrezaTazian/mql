//+------------------------------------------------------------------+
//|                                            IchiAndDivergence.mq5 |
//|                                              Mohammadreza Tazian |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Mohammadreza Tazian"
#property link      "https://www.mql5.com"
#property version   "1.00"
#include <Indicators/Trend.mqh>
CiIchimoku* ichimoku;
int q = false;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
void OnInit()
{

   ichimoku = new CiIchimoku();
   ichimoku.Create(_Symbol,PERIOD_CURRENT,9,26,52);
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
   double tenkansenValue = ichimoku.TenkanSen(0);
   if(!q)
   {
      Comment("tenkansenValue: ",tenkansenValue);
      q = true;
   }
}
//+------------------------------------------------------------------+
