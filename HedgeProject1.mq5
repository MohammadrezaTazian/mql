//+------------------------------------------------------------------+
//|                                                HedgeProject1.mq5 |
//|                                              Mohammadreza Tazian |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Mohammadreza Tazian"
#property link      "https://www.mql5.com"
#property version   "1.00"
#include<Trade/Customtrade.mqh>
CustomCTrade trade;
bool     isFirstBuy = false;
double   tpDistance = 70;
double   orderDistance = 50;
double   orderVolume = 0.01;
ENUM_ORDER_TYPE_FILLING type_filling1 = ORDER_FILLING_FOK;
int deviation1 = 0;
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
//---

}
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
   double Ask = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_ASK),_Digits);
   if(IsMarketOpen() && !isFirstBuy &&  trade.Buy(orderVolume, Symbol(), Ask,0,Ask + tpDistance * SymbolInfoDouble(Symbol(), SYMBOL_POINT),NULL,type_filling1))
   {
      isFirstBuy = true;
   }
}
//+------------------------------------------------------------------+
//| TradeTransaction function                                        |
//+------------------------------------------------------------------+
void OnTradeTransaction(const MqlTradeTransaction& trans,
                        const MqlTradeRequest& request,
                        const MqlTradeResult& result)
{
   string query;

   
   if(trans.type == TRADE_TRANSACTION_DEAL_ADD && trans.deal_type == DEAL_TYPE_BUY && trans.order == trans.position)
   {
      if(IsOrderBuyStop(trans.position))
      {
         trade.OrderDelete(GetTiketOfOpenedPenddingStop("SellStop"));

         query = "update tbl_Hedge set IsDeletedOrder = 1 WHERE OrderTicket = " + IntegerToString(trans.position);
         DatabaseDataEntryQuery(query);

         query = "INSERT INTO tbl_Hedge (OrderType,OrderTicket,OpenedOrderPrice,OrderTP,IsOpenedOrder,IsHedgedOrder,IsFakeOrder,IsDeletedOrder,IsLastOrder)"
                 "VALUES ('BuyStopToBuy'," + IntegerToString(trans.position) + "," + DoubleToString(trans.price) + "," + DoubleToString(trans.price_tp) + ",true,false,false,false,true);";
         DatabaseDataEntryQuery(query);
      }
      else
      {
         query = "INSERT INTO tbl_Hedge (OrderType,OrderTicket,OpenedOrderPrice,OrderTP,IsOpenedOrder,IsHedgedOrder,IsFakeOrder,IsDeletedOrder,IsLastOrder)"
                 "VALUES ('Buy'," + IntegerToString(trans.position) + "," + DoubleToString(trans.price) + "," + DoubleToString(trans.price_tp) + ",true,false,false,false,true);";
         DatabaseDataEntryQuery(query);
      }

      trade.BuyStop(orderVolume, trans.price + orderDistance  * SymbolInfoDouble(Symbol(), SYMBOL_POINT),Symbol(),0,trans.price + orderDistance * SymbolInfoDouble(Symbol(), SYMBOL_POINT) + tpDistance * SymbolInfoDouble(Symbol(), SYMBOL_POINT),0,0,NULL,type_filling1);
      trade.SellStop(orderVolume, trans.price - orderDistance  * SymbolInfoDouble(Symbol(), SYMBOL_POINT),Symbol(),0,trans.price - orderDistance * SymbolInfoDouble(Symbol(), SYMBOL_POINT) - tpDistance * SymbolInfoDouble(Symbol(), SYMBOL_POINT),0,0,NULL,type_filling1,deviation1);
   }

   if(trans.type == TRADE_TRANSACTION_DEAL_ADD && trans.deal_type == DEAL_TYPE_SELL && trans.order == trans.position)
   {
      if(IsOrderSellStop(trans.position))
      {
         trade.OrderDelete(GetTiketOfOpenedPenddingStop("BuyStop"));

         query = "update tbl_Hedge set IsDeletedOrder = 1 WHERE OrderTicket = " + IntegerToString(trans.position);
         DatabaseDataEntryQuery(query);

         query = "INSERT INTO tbl_Hedge (OrderType,OrderTicket,OpenedOrderPrice,OrderTP,IsOpenedOrder,IsHedgedOrder,IsFakeOrder,IsDeletedOrder,IsLastOrder)"
                 "VALUES ('SellStopToSell'," + IntegerToString(trans.position) + "," + DoubleToString(trans.price) + "," + DoubleToString(trans.price_tp) + ",true,false,false,false,true);";
         DatabaseDataEntryQuery(query);
      }
      else
      {
         query = "INSERT INTO tbl_Hedge (OrderType,OrderTicket,OpenedOrderPrice,OrderTP,IsOpenedOrder,IsHedgedOrder,IsFakeOrder,IsDeletedOrder,IsLastOrder)"
                 "VALUES ('Sell'," + IntegerToString(trans.position) + "," + DoubleToString(trans.price) + "," + DoubleToString(trans.price_tp) + ",true,false,false,false,true);";
         DatabaseDataEntryQuery(query);
      }

      trade.BuyStop(orderVolume, trans.price + orderDistance  * SymbolInfoDouble(Symbol(), SYMBOL_POINT),Symbol(),0,trans.price + orderDistance * SymbolInfoDouble(Symbol(), SYMBOL_POINT) + tpDistance * SymbolInfoDouble(Symbol(), SYMBOL_POINT),0,0,NULL,type_filling1);
      trade.SellStop(orderVolume, trans.price - orderDistance  * SymbolInfoDouble(Symbol(), SYMBOL_POINT),Symbol(),0,trans.price - orderDistance * SymbolInfoDouble(Symbol(), SYMBOL_POINT) - tpDistance * SymbolInfoDouble(Symbol(), SYMBOL_POINT),0,0,NULL,type_filling1,deviation1);
   }

   if(trans.type == TRADE_TRANSACTION_DEAL_ADD && trans.deal_type == DEAL_TYPE_SELL && trans.order != trans.position)//end buy
   {
      query = "update tbl_Hedge set IsDeletedOrder = 1 WHERE OrderTicket = " + IntegerToString(trans.position);
      DatabaseDataEntryQuery(query);
   }

   if(trans.type == TRADE_TRANSACTION_DEAL_ADD && trans.deal_type == DEAL_TYPE_BUY && trans.order != trans.position)//end sell
   {
      query = "update tbl_Hedge set IsDeletedOrder = 1 WHERE OrderTicket = " + IntegerToString(trans.position);
      DatabaseDataEntryQuery(query);
   }

   if(trans.type == TRADE_TRANSACTION_ORDER_ADD && trans.order_type == ORDER_TYPE_BUY_STOP)
   {
      query = "INSERT INTO tbl_Hedge (OrderType,OrderTicket,OpenedOrderPrice,OrderTP,IsOpenedOrder,IsHedgedOrder,IsFakeOrder,IsDeletedOrder,IsLastOrder)"
              "VALUES ('BuyStop'," + IntegerToString(trans.order) + "," + DoubleToString(trans.price) + "," + DoubleToString(trans.price_tp) + ",false,false,false,false,false);";
      DatabaseDataEntryQuery(query);
   }

   if(trans.type == TRADE_TRANSACTION_ORDER_ADD && trans.order_type == ORDER_TYPE_SELL_STOP)
   {
      query = "INSERT INTO tbl_Hedge (OrderType,OrderTicket,OpenedOrderPrice,OrderTP,IsOpenedOrder,IsHedgedOrder,IsFakeOrder,IsDeletedOrder,IsLastOrder)"
              "VALUES ('SellStop'," + IntegerToString(trans.order) + "," + DoubleToString(trans.price) + "," + DoubleToString(trans.price_tp) + ",false,false,false,false,false);";
      DatabaseDataEntryQuery(query);
   }

}
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
bool IsOrderBuyStop(ulong positionId)
{

   int isOrderBuyStop = 0;
   string currentQuery = "SELECT  CASE WHEN EXISTS (SELECT 1 From tbl_Hedge WHERE OrderType = 'BuyStop' AND IsDeletedOrder = 0) THEN 1 ELSE 0 End AS isOrderBuyStop";
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
      if(DatabaseColumnInteger(request, 0, isOrderBuyStop ))
      {
         return isOrderBuyStop == 1 ? true : false;
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
   return isOrderBuyStop == 1 ? true : false;
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool IsOrderSellStop(ulong positionId)
{
   int isOrderSellStop = 0;
   string currentQuery = "SELECT  CASE WHEN EXISTS (SELECT 1 From tbl_Hedge WHERE OrderType = 'BuyStop' AND IsDeletedOrder = 0) THEN 1 ELSE 0 End AS isOrderSellStop";
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
      if(DatabaseColumnInteger(request, 0, isOrderSellStop ))
      {
         return isOrderSellStop == 1 ? true : false;
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
   return isOrderSellStop == 1 ? true : false;
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int GetTiketOfOpenedPenddingStop(string pendingStopType)
{
   int OrderTicket;
   string currentQuery = "SELECT OrderTicket FROM tbl_Hedge WHERE OrderType = '" + pendingStopType + "' AND IsDeletedOrder = 0";
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
      if(DatabaseColumnInteger(request, 0, OrderTicket ))
      {
         return OrderTicket;
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
   return -2;
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
