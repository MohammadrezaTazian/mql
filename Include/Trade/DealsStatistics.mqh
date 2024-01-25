//+------------------------------------------------------------------+
//|                                                      ProjectName |
//|                                      Copyright 2020,CompanyName |
//|                                       http://www.companyname.net |
//+------------------------------------------------------------------+
#include <Trade\DealInfo.mqh>
CDealInfo  deal;
//+------------------------------------------------------------------+
//| Class DealsStatistics                                            |
//+------------------------------------------------------------------+
class DealsStatistics
{
public :
   double            profit[];
   double            neatProfit[];
   double            balance[];
   int               dealsTotal;

public :
//+------------------------------------------------------------------+
//| Deals Statistics                                                 |
//+------------------------------------------------------------------+
   void DealsStatistics()
   {
      datetime end = TimeCurrent();
      datetime start = 0 ;
      HistorySelect(start,end);
      dealsTotal = HistoryDealsTotal();
      ArrayResize(profit,dealsTotal,0);
      ArrayResize(neatProfit,dealsTotal,0);
      ArrayResize(balance,dealsTotal,0);
   }

   ~DealsStatistics()
   {
      ArrayFree(profit);
      ArrayFree(neatProfit);
      ArrayFree(balance);
   }
//+------------------------------------------------------------------+
//| Get Data                                                         |
//+------------------------------------------------------------------+
   void GetData()
   {
      for(int i = 0; i < dealsTotal; i++)
      {
         deal.SelectByIndex(i);
         profit[i] = deal.Profit();
         neatProfit[i] = deal.Profit() + deal.Commission() + deal.Swap();
         if(i > 0)
            balance[i] = balance[i - 1] + neatProfit[i];
         else
            balance[i] = neatProfit[i];
         int d = 0;
      }
   }
//+------------------------------------------------------------------+
//| Get Initial Balance                                              |
//+------------------------------------------------------------------+
   double GetInitialBalance()
   {
      return profit[ 0 ];
   }

};
//+------------------------------------------------------------------+
