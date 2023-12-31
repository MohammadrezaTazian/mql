//+------------------------------------------------------------------+
//|                                                      ProjectName |
//|                                      Copyright 2020, CompanyName |
//|                                       http://www.companyname.net |
//+------------------------------------------------------------------+

#property version   "1.00"
#include<Trade/trade.mqh>
CTrade trade;
bool isFirstBuy = false;
double lastOpenOrderPrice;
string query;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
   CreateDatabaseAndTable();
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
   double Ask = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_ASK),_Digits);
   double Bid;
   lastOpenOrderPrice = GetLastOpenOrderPrice();
//Regin1-------------------------------------OpenFistOrder--------------------------------------
   if(IsMarketOpen() && !isFirstBuy &&  trade.Buy(0.1, Symbol(), Ask,0,Ask + 70 * SymbolInfoDouble(Symbol(), SYMBOL_POINT),NULL))
   {
      isFirstBuy = true;
      lastOpenOrderPrice = GetLastOpenOrderPrice();
      //HaveAlredeayBuyOrder(lastOpenOrderPrice + 50 * SymbolInfoDouble(Symbol(), SYMBOL_POINT));
      //HaveAlredeaySellOrder(lastOpenOrderPrice - 50 * SymbolInfoDouble(Symbol(), SYMBOL_POINT));
      //trade.SellStop(0.1, lastOpenOrderPrice - 50 * SymbolInfoDouble(Symbol(), SYMBOL_POINT), Symbol(),0,lastOpenOrderPrice - 50 * SymbolInfoDouble(Symbol(), SYMBOL_POINT) - 70 * SymbolInfoDouble(Symbol(), SYMBOL_POINT),0,0,NULL);

   }
   if(!doesExistBuyOrderInThisLevel(lastOpenOrderPrice + 50 * SymbolInfoDouble(Symbol(), SYMBOL_POINT)))
   {
      trade.BuyStop(0.1, lastOpenOrderPrice + 50 * SymbolInfoDouble(Symbol(), SYMBOL_POINT), Symbol(),0,lastOpenOrderPrice + 50 * SymbolInfoDouble(Symbol(), SYMBOL_POINT) + 70 * SymbolInfoDouble(Symbol(), SYMBOL_POINT),0,0,NULL);
   }
   else
   {
      query = "INSERT INTO tbl_Hedge (OrderType,OrderTicket,OpenedOrderPrice,OrderTP,IsOpenedOrder,IsHedgedOrder,IsFakeOrder,IsDeletedOrder,IsLastOrder)"
              "VALUES ('buy',-1," + DoubleToString(lastOpenOrderPrice + 50 * SymbolInfoDouble(Symbol(), SYMBOL_POINT)) + ",-1,false,false,true,false,true);";
      DatabaseDataEntryQuery(query);
   }
   if(!doesExistSellOrderInThisLevel(lastOpenOrderPrice - 50 * SymbolInfoDouble(Symbol(), SYMBOL_POINT)))
   {
      trade.SellStop(0.1, lastOpenOrderPrice - 50 * SymbolInfoDouble(Symbol(), SYMBOL_POINT), Symbol(),0,lastOpenOrderPrice - 50 * SymbolInfoDouble(Symbol(), SYMBOL_POINT) - 70 * SymbolInfoDouble(Symbol(), SYMBOL_POINT),0,0,NULL);
   }
   else
   {
      query = "INSERT INTO tbl_Hedge (OrderType,OrderTicket,OpenedOrderPrice,OrderTP,IsOpenedOrder,IsHedgedOrder,IsFakeOrder,IsDeletedOrder,IsLastOrder)"
              "VALUES ('sell',-1," + DoubleToString(lastOpenOrderPrice - 50 * SymbolInfoDouble(Symbol(), SYMBOL_POINT)) + ",-1,false,false,true,false,true);";
      DatabaseDataEntryQuery(query);
   }
//EndRegin1-------------------------------------OpenFistOrder------------------------------------
//Regin2----------------------------------------------------------------------------

//EndRegin2-------------------------------------OpenFistOrder------------------------------------
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTradeTransaction(const MqlTradeTransaction& trans,
                        const MqlTradeRequest& request,
                        const MqlTradeResult& result)
{
   if(trans.type == TRADE_TRANSACTION_DEAL_ADD && trans.deal_type == DEAL_TYPE_BUY && trans.order == trans.position)
   {
      if(IsOrderBuyStop(trans.position))
      {
         //todo Update >> BuyStopToBuy
      }
      else
      {
         //todo insert Buy
      }
   }
   else if(trans.type == TRADE_TRANSACTION_DEAL_ADD && trans.deal_type == DEAL_TYPE_BUY && trans.order != trans.position)
   {
      Print("End A Sell Position"," trans.order:",trans.position," trans.price:",trans.price," trans.price_tp:",trans.price_tp);
   }
   else if(trans.type == TRADE_TRANSACTION_DEAL_ADD && trans.deal_type == DEAL_TYPE_SELL && trans.order == trans.position)
   {
      if(IsOrderSellStop(trans.position))
      {
         //todo Update >> SellStopToSell
      }
      else
      {
         //todo insert Sell
      }
   }
   else if(trans.type == TRADE_TRANSACTION_DEAL_ADD && trans.deal_type == DEAL_TYPE_SELL && trans.order != trans.position)
   {
      Print("End A Buy Position"," trans.order:",trans.position," trans.price:",trans.price," trans.price_tp:",trans.price_tp);
   }
   else if(trans.type == TRADE_TRANSACTION_ORDER_ADD && trans.order_type == ORDER_TYPE_BUY_STOP)
   {
      //todo insert buystop
   }
   else if(trans.type == TRADE_TRANSACTION_ORDER_ADD && trans.order_type == ORDER_TYPE_SELL_STOP)
   {
      //todo insert sellstop
   }

}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool IsMarketOpen()
{
   bool isOpen = false;                                  // by default market is closed
   MqlDateTime mdtServerTime;                            // declare server time structure variable
   datetime dtServerDateTime = TimeTradeServer();        // store server time
   if(!TimeToStruct(dtServerDateTime,                    // is servertime correctly converted to struct?
                    mdtServerTime))
   {
      return(false);                                      // no, return market is closed
   }

   ENUM_DAY_OF_WEEK today = (ENUM_DAY_OF_WEEK)           // get actual day and cast to enum
                            mdtServerTime.day_of_week;

   if(today > 0 || today < 6)                            // is today in monday to friday?
   {
      datetime dtF;                                       // store trading session begin and end time
      datetime dtT;                                       // date component is 1970.01.01 (0)
      datetime dtServerTime = dtServerDateTime % 86400;   // set date to 1970.01.01 (0)
      if(!SymbolInfoSessionTrade(Symbol(), today,              // do we have values for dtFrom and dtTo?
                                 0, dtF, dtT))
      {
         return(false);                                    // no, return market is closed
      }
      switch(today)                                       // check for different trading sessions
      {
      case 1:
         if(dtServerTime >= dtF && dtServerTime <= dtT)  // is server time in 00:05 (300) - 00:00 (86400)
            isOpen = true;                                // yes, set market is open
         break;
      case 5:
         if(dtServerTime >= dtF && dtServerTime <= dtT)  // is server time in 00:04 (240) - 23:55 (86100)
            isOpen = true;                                // yes, set market is open
         break;
      default:
         if(dtServerTime >= dtF && dtServerTime <= dtT)  // is server time in 00:04 (240) - 00:00 (86400)
            isOpen = true;                                // yes, set market is open
         break;
      }
   }
   return(isOpen);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CreateDatabaseAndTable()
{
   string filename = "Hedgedb.sqlite";
//--- create or open the database in the common terminal folder
   int db = DatabaseOpen(filename, DATABASE_OPEN_READWRITE | DATABASE_OPEN_CREATE | DATABASE_OPEN_COMMON);
   if(db == INVALID_HANDLE)
   {
      Print("DB: ", filename, " open failed with code ", GetLastError());
      return;
   }

//--- if the COMPANY table exists, delete it
   if(DatabaseTableExists(db, "tbl_Hedge") && !DatabaseExecute(db, "DROP TABLE tbl_Hedge"))
   {
      Print("Failed to drop table COMPANY with code ", GetLastError());
      DatabaseClose(db);
      return;
   }
//--- create the COMPANY table
   if(!DatabaseExecute(db, "CREATE TABLE tbl_Hedge("
                       "ID                      INTEGER                    PRIMARY KEY    AUTOINCREMENT,"
                       "OrderType               TEXT                       NOT NULL,"
                       "OrderTicket             INTEGER                    NOT NULL,"
                       "OpenedOrderPrice        REAL                       NOT NULL,"
                       "OrderTP                 bool                       NOT NULL,"
                       "IsOpenedOrder           bool                       NOT NULL,"
                       "IsHedgedOrder           bool                       NOT NULL,"
                       "IsFakeOrder             bool                       NOT NULL,"
                       "IsDeletedOrder          bool                       NOT NULL,"
                       "IsLastOrder             bool                       NOT NULL);"
                      )
     )
   {
      Print("DB: ", filename, " create table failed with code ", GetLastError());
      DatabaseClose(db);
      return;
   }
   //string query = "INSERT INTO tbl_Hedge (ID,OrderType,IsOrderOpen,IsOrderHedged,IsOrderClosed,OpenPrice,IsLastOrder)"
   //               "VALUES (1,'buy',false,true,false,1.33,true); "
   //               "INSERT INTO tbl_Hedge (ID,OrderType,IsOrderOpen,IsOrderHedged,IsOrderClosed,OpenPrice,IsLastOrder)"
   //               "VALUES (2,'buy',false,true,false,1.343,true); "
   //               "INSERT INTO tbl_Hedge (ID,OrderType,IsOrderOpen,IsOrderHedged,IsOrderClosed,OpenPrice,IsLastOrder)"
   //               "VALUES (3,'buy',false,true,false,22.22,true); "
   //               "INSERT INTO tbl_Hedge (ID,OrderType,IsOrderOpen,IsOrderHedged,IsOrderClosed,OpenPrice,IsLastOrder)"
   //               "VALUES (4,'sell',false,true,false,22.22,true); ";
   //if !DatabaseExecute(db,query)
   //{
   //   Print("DB: ", filename, " insert failed with code ", GetLastError());
   //   DatabaseClose(db);
   //   return;
   //}
//--- close the database
   DatabaseClose(db);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void DatabaseDataEntryQuery (string currentQuery)
{
   string filename = "Hedgedb.sqlite";
//--- create or open the database in the common terminal folder
   int db = DatabaseOpen(filename, DATABASE_OPEN_READWRITE | DATABASE_OPEN_CREATE | DATABASE_OPEN_COMMON);
   if(db == INVALID_HANDLE)
   {
      Print("DB: ", filename, " open failed with code ", GetLastError());
      return;
   }
   if (!DatabaseExecute(db,currentQuery))
   {
      Print("DB: ", filename, " query failed with code ", GetLastError());
      DatabaseClose(db);
      return;
   }
   DatabaseClose(db);
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double GetLastOpenOrderPrice ()
{
   string currentQuery = "SELECT OpenedOrderPrice From tbl_Hedge WHERE IsLastOrder = 1";
   string filename = "Hedgedb.sqlite";
   double    openedOrderPrice = -1;
//--- create or open the database in the common terminal folder
   int db = DatabaseOpen(filename, DATABASE_OPEN_READWRITE | DATABASE_OPEN_CREATE | DATABASE_OPEN_COMMON);
   if(db == INVALID_HANDLE)
   {
      Print("DB: ", filename, " open failed with code ", GetLastError());
      return -1;
   }
//--- create a query and get a handle for it
   int request = DatabasePrepare(db, currentQuery);
   if(request == INVALID_HANDLE)
   {
      Print("DB: ", filename, " request failed with code ", GetLastError());
      DatabaseClose(db);
      return -1;
   }

   int DatabaseReadCount = DatabaseRead(request);
   for(int i = 0; i < DatabaseReadCount; i++)
   {
      if(DatabaseColumnDouble(request, 0, openedOrderPrice ))
      {
         return openedOrderPrice;
      }
      else
      {
         Print(i, ": DatabaseRead() failed with code ", GetLastError());
         DatabaseFinalize(request);
         DatabaseClose(db);
         return -1;
      }
   }
//--- remove the query after use
   DatabaseFinalize(request);
   return openedOrderPrice;
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool doesExistBuyOrderInThisLevel(double orderPrice)
{
   int doesExistBuyOrder = 0;
   string currentQuery = "SELECT  CASE WHEN EXISTS (SELECT 1 From tbl_Hedge WHERE OpenedOrderPrice = " + DoubleToString(orderPrice,_Digits) + " AND OrderType = 'buy' AND IsOrderOpen = 0) THEN 1 ELSE 0 End AS doesExistBuyOrder";
   string filename = "Hedgedb.sqlite";

//--- create or open the database in the common terminal folder
   int db = DatabaseOpen(filename, DATABASE_OPEN_READWRITE | DATABASE_OPEN_CREATE | DATABASE_OPEN_COMMON);
   if(db == INVALID_HANDLE)
   {
      Print("DB: ", filename, " open failed with code ", GetLastError());
      return false;
   }
//--- create a query and get a handle for it
   int request = DatabasePrepare(db, currentQuery);
   if(request == INVALID_HANDLE)
   {
      Print("DB: ", filename, " request failed with code ", GetLastError());
      DatabaseClose(db);
      return false;
   }

   int DatabaseReadCount = DatabaseRead(request);
   for(int i = 0; i < DatabaseReadCount; i++)
   {
      if(DatabaseColumnInteger(request, 0, doesExistBuyOrder ))
      {
         return doesExistBuyOrder == 1 ? true : false;
      }
      else
      {
         Print(i, ": DatabaseRead() failed with code ", GetLastError());
         DatabaseFinalize(request);
         DatabaseClose(db);
         return false;
      }
   }
//--- remove the query after use
   DatabaseFinalize(request);
   return doesExistBuyOrder == 1 ? true : false;
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool doesExistSellOrderInThisLevel(double orderPrice)
{
   int doesExistSellOrder = 0;
   string currentQuery = "SELECT  CASE WHEN EXISTS (SELECT 1 From tbl_Hedge WHERE OpenedOrderPrice = " + DoubleToString(orderPrice,_Digits) + " AND OrderType = 'sell' AND IsOrderOpen = 0) THEN 1 ELSE 0 End AS doesExistBuyOrder";
   string filename = "Hedgedb.sqlite";

//--- create or open the database in the common terminal folder
   int db = DatabaseOpen(filename, DATABASE_OPEN_READWRITE | DATABASE_OPEN_CREATE | DATABASE_OPEN_COMMON);
   if(db == INVALID_HANDLE)
   {
      Print("DB: ", filename, " open failed with code ", GetLastError());
      return false;
   }
//--- create a query and get a handle for it
   int request = DatabasePrepare(db, currentQuery);
   if(request == INVALID_HANDLE)
   {
      Print("DB: ", filename, " request failed with code ", GetLastError());
      DatabaseClose(db);
      return false;
   }

   int DatabaseReadCount = DatabaseRead(request);
   for(int i = 0; i < DatabaseReadCount; i++)
   {
      if(DatabaseColumnInteger(request, 0, doesExistSellOrder ))
      {
         return doesExistSellOrder == 1 ? true : false;
      }
      else
      {
         Print(i, ": DatabaseRead() failed with code ", GetLastError());
         DatabaseFinalize(request);
         DatabaseClose(db);
         return false;
      }
   }
//--- remove the query after use
   DatabaseFinalize(request);
   return doesExistSellOrder == 1 ? true : false;
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool IsOrderBuyStop(ulong positionId)
{

   return false;
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool IsOrderSellStop(ulong positionId)
{
   return false;
}
//+------------------------------------------------------------------+
