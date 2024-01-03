//+------------------------------------------------------------------+
//|                                                HedgeProject1.mq5 |
//|                                              Mohammadreza Tazian |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Mohammadreza Tazian"
#property link      "https://www.mql5.com"
#property version   "1.00"
#include<Trade/trade.mqh>
CTrade   trade;
bool     isFirstBuy = false;
double   tpDistance = 70;
double   orderDistance = 50;
double   orderVolume = 0.1;
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
   if(!isFirstBuy &&  trade.Buy(orderVolume, Symbol(), Ask,0,Ask + tpDistance * SymbolInfoDouble(Symbol(), SYMBOL_POINT),NULL))
   {
      isFirstBuy = true;
      trade.BuyStop(orderVolume, Ask + orderDistance  * SymbolInfoDouble(Symbol(), SYMBOL_POINT),Symbol(),0,Ask + orderDistance * SymbolInfoDouble(Symbol(), SYMBOL_POINT) + tpDistance * SymbolInfoDouble(Symbol(), SYMBOL_POINT),0,0,NULL);
      trade.SellStop(orderVolume, Ask - orderDistance  * SymbolInfoDouble(Symbol(), SYMBOL_POINT),Symbol(),0,Ask - orderDistance * SymbolInfoDouble(Symbol(), SYMBOL_POINT) - tpDistance * SymbolInfoDouble(Symbol(), SYMBOL_POINT),0,0,NULL);


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

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
   if(trans.type == TRADE_TRANSACTION_DEAL_ADD && trans.deal_type == DEAL_TYPE_BUY && trans.order == trans.position)
   {
      if(IsOrderBuyStop(trans.position))
      {
         query = "INSERT INTO tbl_Hedge (OrderType,OrderTicket,OpenedOrderPrice,OrderTP,IsOpenedOrder,IsHedgedOrder,IsFakeOrder,IsDeletedOrder,IsLastOrder)"
                 "VALUES ('BuyStopToBuy'," + trans.position + "," + trans.price + "," + trans.price_tp + ",1,false,false,false,false);";
         DatabaseDataEntryQuery(query);
      }
      else
      {
         query = "INSERT INTO tbl_Hedge (OrderType,OrderTicket,OpenedOrderPrice,OrderTP,IsOpenedOrder,IsHedgedOrder,IsFakeOrder,IsDeletedOrder,IsLastOrder)"
                 "VALUES ('Buy'," + trans.position + "," + trans.price + "," + trans.price_tp + ",1,false,false,false,true);";
         DatabaseDataEntryQuery(query);
      }
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
   string currentQuery = "SELECT  CASE WHEN EXISTS (SELECT 1 From tbl_Hedge WHERE OrderType = 'BuyStop' AND IsOrderOpen = 1) THEN 1 ELSE 0 End AS isOrderBuyStop";
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
   string currentQuery = "SELECT  CASE WHEN EXISTS (SELECT 1 From tbl_Hedge WHERE OrderType = 'BuyStop' AND IsOrderOpen = 1) THEN 1 ELSE 0 End AS isOrderSellStop";
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
