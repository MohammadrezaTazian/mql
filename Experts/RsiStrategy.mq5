//+------------------------------------------------------------------+
//|                                                  RsiStrategy.mq5 |
//|                                              Mohammadreza Tazian |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Mohammadreza Tazian"
#property link      "https://www.mql5.com"
#property version   "1.00"

//+------------------------------------------------------------------+
//| Include                                                          |
//+------------------------------------------------------------------+
#include <Trade\Trade.mqh>
//+------------------------------------------------------------------+
//| Inputs                                                           |
//+------------------------------------------------------------------+
static input long   InpMagiqnumber = 546812; // magiq number
static input double InpLotsize     = 0.01;   // lot size
input int           InpRSIPeriod   = 21;     // rsi period
input int           InpRSILevel    = 70;     // rsi level (uper)
input int           InpStopLoss    = 100;    // stop loss in point  (0=off)
input int           InpTakeProfit  = 200;    //take profit in point  (0=off)
input bool          InpClosesignal = false;  // close trades by opposite signal
//+------------------------------------------------------------------+
//| Global variabls                                                  |
//+------------------------------------------------------------------+
int handle;
double buffer[];
MqlTick currentTick;
CTrade  trade;
datetime openTimeBuy = 0;
datetime openTimeSell = 0;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
// check user inputs
   if(InpMagiqnumber <= 0)
   {
      Alert("Magiqnumber  <= 0");
      return INIT_PARAMETERS_INCORRECT;
   }
   if(InpLotsize <= 0 || InpLotsize > 10)
   {
      Alert("Lotsize  <= 0  || >10");
      return INIT_PARAMETERS_INCORRECT;
   }
   if(InpRSIPeriod <= 1)
   {
      Alert("  RSIPeriod  <= 1");
      return INIT_PARAMETERS_INCORRECT;
   }
   if(InpRSILevel >= 100 || InpRSILevel <= 50)
   {
      Alert("  RSILevel  >= 100 || <=50");
      return INIT_PARAMETERS_INCORRECT;
   }
   if(InpStopLoss < 0)
   {
      Alert("  StopLoss  <= 0");
      return INIT_PARAMETERS_INCORRECT;
   }
   if(InpTakeProfit < 0)
   {
      Alert("  TakeProfi  <= 0");
      return INIT_PARAMETERS_INCORRECT;
   }
   if(InpTakeProfit < 0)
   {
      Alert("  TakeProfi  <= 0");
      return INIT_PARAMETERS_INCORRECT;
   }
// set number to trade object
   trade.SetExpertMagicNumber(InpMagiqnumber);
// create rsi handle
   handle = iRSI(_Symbol,PERIOD_CURRENT,InpRSIPeriod,PRICE_CLOSE);
   if(handle == INVALID_HANDLE)
   {
      Alert("Failed to create indicator handle");
      return INIT_FAILED;
   }
// set buffer as series
   ArraySetAsSeries(buffer,true);

   return(INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
// release indicator handle
   if(handle != INVALID_HANDLE)
   {
      IndicatorRelease(handle);
   }

}
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
// get curent tick

   if(!SymbolInfoTick(_Symbol,currentTick))
   {
      Print("Failed to  get current tick");
      return;
   }
// get rsi values
   int values = CopyBuffer(handle,0,0,2,buffer);
   if(values != 2)
   {
      Print("Failed to get indicator values");
      return;

   }
   Comment("buffer[0]:",buffer[0],
           "\nbuffer[1]:",buffer[1]);
// count open position
   int cntBuy,cntsell;
   if(!countOpenPositions(cntBuy,cntsell))
   {
      return;
   }
// Chek for buy position
   if(cntBuy == 0 && buffer[1] >= 100 - InpRSILevel && buffer[0] < 100 - InpRSILevel && openTimeBuy != iTime(_Symbol,PERIOD_CURRENT,0))
   {

      openTimeBuy = iTime(_Symbol,PERIOD_CURRENT,0);
      if  (InpClosesignal)
      {
         if(!ClosePositions(2))
         {
            return;
         }
      }
      double sl = InpStopLoss == 0 ? 0 : currentTick.bid - InpStopLoss * _Point;
      double tp = InpTakeProfit == 0 ? 0 : currentTick.bid + InpTakeProfit * _Point;
      if(!NormalizePrice(sl))
      {
         return;
      }
      if(!NormalizePrice(tp))
      {
         return;
      }

      trade.PositionOpen(_Symbol,ORDER_TYPE_BUY,InpLotsize,currentTick.ask,sl,tp,"RSI EA" );
   }
// Chek for sell  position
   if(cntsell == 0 && buffer[1] <= InpRSILevel && buffer[0] > InpRSILevel && openTimeSell != iTime(_Symbol,PERIOD_CURRENT,0))
   {

      openTimeSell = iTime(_Symbol,PERIOD_CURRENT,0);
      if  (InpClosesignal)
      {
         if(!ClosePositions(1))
         {
            return;
         }
      }
      double sl = InpStopLoss == 0 ? 0 : currentTick.ask + InpStopLoss * _Point;
      double tp = InpTakeProfit == 0 ? 0 : currentTick.ask - InpTakeProfit * _Point;
      if(!NormalizePrice(sl))
      {
         return;
      }
      if(!NormalizePrice(tp))
      {
         return;
      }

      trade.PositionOpen(_Symbol,ORDER_TYPE_SELL,InpLotsize,currentTick.bid,sl,tp,"RSI EA" );
   }


}

//+------------------------------------------------------------------+
//| custom function                                             |
//+------------------------------------------------------------------+

// count open position
bool countOpenPositions(int  &cntBuy, int &cntSell)
{
   cntBuy = 0 ;
   cntSell = 0;
   int total = PositionsTotal();
   for(int i = total - 1 ; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket <= 0)
      {
         Print("Failed to get position ticket");
         return false;
      }
      if(!PositionSelectByTicket(ticket))
      {
         Print("Failed to select position  ");
         return false;
      }
      long magic;
      if(!PositionGetInteger(POSITION_MAGIC,magic))
      {
         Print("Failed to get position magicnumber  ");
         return false;
      }
      if(magic == InpMagiqnumber)
      {
         long type;
         if(!PositionGetInteger(POSITION_TYPE,type))
         {
            Print("Failed to get position type  ");
            return false;
         }
         if(type == POSITION_TYPE_BUY)
         {
            cntBuy++;
         }
         if(type == POSITION_TYPE_SELL)
         {
            cntSell++;
         }
      }
   }
   return true;

}
// normalize price
bool NormalizePrice(double &price)
{
   double ticksize = 0;
   if(!SymbolInfoDouble(_Symbol,SYMBOL_TRADE_TICK_SIZE,ticksize))
   {
      Print("Failed to get tick size");
      return false;
   }
   price = NormalizeDouble(MathRound(price / ticksize) * ticksize,_Digits);
   return true;
}


// close position
bool ClosePositions(int  all_buy_sell)
{

   int total = PositionsTotal();
   for(int i = total - 1 ; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket <= 0)
      {
         Print("Failed to get position ticket");
         return false;
      }
      if(!PositionSelectByTicket(ticket))
      {
         Print("Failed to select position  ");
         return false;
      }
      long magic;
      if(!PositionGetInteger(POSITION_MAGIC,magic))
      {
         Print("Failed to get position magicnumber  ");
         return false;
      }
      if(magic == InpMagiqnumber)
      {
         long type;
         if(!PositionGetInteger(POSITION_TYPE,type))
         {
            Print("Failed to get position type  ");
            return false;
         }
         if(all_buy_sell == 1 && type == POSITION_TYPE_SELL)
         {
            continue ;
         }
         if(all_buy_sell == 2 && type == POSITION_TYPE_BUY)
         {
            continue ;
         }
         trade.PositionClose(ticket);
         if(trade.ResultRetcode() != TRADE_RETCODE_DONE)
         {
            Print("Fail to close position ticket",
                  (string)ticket,"result:",(string)trade.ResultRetcode(),":",trade.CheckResultRetcodeDescription());

         }
      }
   }
   return true;

}
//+------------------------------------------------------------------+
