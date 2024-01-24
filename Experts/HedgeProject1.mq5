//+------------------------------------------------------------------+
//|                                                HedgeProject1.mq5 |
//|                                              Mohammadreza Tazian |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Mohammadreza Tazian"
#property link "https://www.mql5.com"
#property version "1.00"
#include <Trade/Customtrade.mqh>
CustomCTrade trade;
bool isFirstBuy = false;
double tpDistance = 95;
double orderDistance = 50;
double orderVolume = 0.00001;
int hedgeSize = 1;
ENUM_ORDER_TYPE_FILLING type_filling1 = ORDER_FILLING_FOK;
int deviation1 = 0;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
   CreateDatabaseAndTable();
   return (INIT_SUCCEEDED);
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
   double Ask = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_ASK), _Digits);
   double Bid = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_BID), _Digits);
   if (IsMarketOpen() && !isFirstBuy && trade.Buy(orderVolume, Symbol(), Ask, 0, Ask + tpDistance * SymbolInfoDouble(Symbol(), SYMBOL_POINT), NULL, type_filling1))
   {
      isFirstBuy = true;
   }
   if(IsExistConditionForHedge())
   {
      RemoveTPFromHedgeOrder();

      string query = "Update tbl_Hedge SET IsHedgedOrder = 1 WHERE IsOpenedOrder = 1 AND IsDeletedOrder = 0 AND IsHedgedOrder = 0 AND IsFakeOrder = 0";
      DatabaseDataEntryQuery(query);
   }
   if (GetFakeOrderStopLevelPrice("BuyFakeStop") != 0 && Ask >= GetFakeOrderStopLevelPrice("BuyFakeStop"))
   {
      int lastLevel = GetLastOrderLevel();
      string query = "Update tbl_Hedge SET IsLastOrder = 0 WHERE IslastOrder = 1";
      DatabaseDataEntryQuery(query);



      query = "Update tbl_Hedge SET IsDeletedOrder = 1 WHERE IsFakeOrder = 1 AND OrderType LIKE '%ToSellFake'";
      DatabaseDataEntryQuery(query);

      query = "INSERT INTO tbl_Hedge (Level,LevelPrice,ResetNo,OrderType,OrderTicket,OpenedOrderPrice,OrderTP,IsOpenedOrder,IsHedgedOrder,IsFakeOrder,IsDeletedOrder,IsLastOrder)"
              "VALUES (" +
              (lastLevel + 1) + "," + GetFakeOrderStopLevelPrice("BuyFakeStop") + "," + GetLastResetNo() +
              ",'BuyFakeStopToBuyFake',-1," + GetFakeOrderStopLevelPrice("BuyFakeStop") + ",0,true,false,true,false,true);";
      DatabaseDataEntryQuery(query);

      trade.OrderDelete(GetTicketOfOpenedPenddingStop("SellStop"));
      trade.OrderDelete(GetTicketOfOpenedPenddingStop("BuyStop"));
      query = "Update tbl_Hedge SET IsDeletedOrder = 1 WHERE IsDeletedOrder = 0 AND OrderType IN ('SellStop','BuyStop','BuyFakeStop','SellFakeStop')";
      DatabaseDataEntryQuery(query);

      MakePenddingOrder();
   }
   if (GetFakeOrderStopLevelPrice("SellFakeStop") != 0 && Bid <= GetFakeOrderStopLevelPrice("SellFakeStop"))

   {
      int lastLevel = GetLastOrderLevel();

      string query = "Update tbl_Hedge SET IsLastOrder = 0 WHERE IslastOrder = 1";
      DatabaseDataEntryQuery(query);

      query = "Update tbl_Hedge SET IsDeletedOrder = 1 WHERE IsFakeOrder = 1 AND OrderType LIKE '%ToSellFake'";
      DatabaseDataEntryQuery(query);

      query = "INSERT INTO tbl_Hedge (Level,LevelPrice,ResetNo,OrderType,OrderTicket,OpenedOrderPrice,OrderTP,IsOpenedOrder,IsHedgedOrder,IsFakeOrder,IsDeletedOrder,IsLastOrder)"
              "VALUES (" +
              (lastLevel - 1) + "," + GetFakeOrderStopLevelPrice("SellFakeStop") + "," + GetLastResetNo() +
              ",'SellFakeStopToSellFake',-1," + GetFakeOrderStopLevelPrice("SellFakeStop") + ",0,true,false,true,false,true);";
      DatabaseDataEntryQuery(query);

      trade.OrderDelete(GetTicketOfOpenedPenddingStop("SellStop"));
      trade.OrderDelete(GetTicketOfOpenedPenddingStop("BuyStop"));
      query = "Update tbl_Hedge SET IsDeletedOrder = 1 WHERE IsDeletedOrder = 0 AND OrderType IN ('SellStop','BuyStop','BuyFakeStop','SellFakeStop')";
      DatabaseDataEntryQuery(query);

      MakePenddingOrder();
   }
}
//+------------------------------------------------------------------+
//| TradeTransaction function                                        |
//+------------------------------------------------------------------+
void OnTradeTransaction(const MqlTradeTransaction &trans,
                        const MqlTradeRequest &request,
                        const MqlTradeResult &result)
{
   string query;

   if (trans.type == TRADE_TRANSACTION_DEAL_ADD && trans.deal_type == DEAL_TYPE_BUY && trans.order == trans.position)
   {
      if (IsOrderBuyStop(trans.position))
      {
         trade.OrderDelete(GetTicketOfOpenedPenddingStop("SellStop"));
         query = "update tbl_Hedge set IsDeletedOrder = 1 WHERE OrderType IN ('SellStop','SellFakeStop')";
         DatabaseDataEntryQuery(query);

         query = "update tbl_Hedge set IsDeletedOrder = 1 WHERE OrderTicket = " + IntegerToString(trans.position);
         DatabaseDataEntryQuery(query);

         query = "update tbl_Hedge set IsLastOrder = 0 WHERE IsLastOrder = 1";
         DatabaseDataEntryQuery(query);

         query = " INSERT INTO tbl_Hedge (Level,LevelPrice,ResetNo,OrderType,OrderTicket,OpenedOrderPrice,OrderTP,IsOpenedOrder,IsHedgedOrder,IsFakeOrder,IsDeletedOrder,IsLastOrder)"
                 "VALUES (" +
                 GetLastOrderLevelByTicket(trans.position) + "," + GetLastOrderLevelPriceByTicket(trans.position) + "," + GetLastResetNo() + ",'BuyStopToBuy'," + IntegerToString(trans.position) + "," + DoubleToString(trans.price) + "," + DoubleToString(trans.price_tp) + ",true,false,false,false,true);";
         DatabaseDataEntryQuery(query);

         query = "update tbl_Hedge set IsDeletedOrder = 1 WHERE OrderType IN ('SellFakeStopToSellFake','BuyFakeStopToBuyFake')";
         DatabaseDataEntryQuery(query);
      }
      else
      {
         query = "INSERT INTO tbl_Hedge (Level,LevelPrice,ResetNo,OrderType,OrderTicket,OpenedOrderPrice,OrderTP,IsOpenedOrder,IsHedgedOrder,IsFakeOrder,IsDeletedOrder,IsLastOrder)"
                 "VALUES (0," +
                 DoubleToString(trans.price) + "," + GetLastResetNo() + ",'Buy'," + IntegerToString(trans.position) + "," + DoubleToString(trans.price) + "," + DoubleToString(trans.price_tp) + ",true,false,false,false,true);";
         DatabaseDataEntryQuery(query);
      }

      MakePenddingOrder();
   }

   if (trans.type == TRADE_TRANSACTION_DEAL_ADD && trans.deal_type == DEAL_TYPE_SELL && trans.order == trans.position)
   {
      if (IsOrderSellStop(trans.position))
      {
         trade.OrderDelete(GetTicketOfOpenedPenddingStop("BuyStop"));
         query = "update tbl_Hedge set IsDeletedOrder = 1 WHERE OrderType IN ('BuyStop','BuyFakeStop')";
         DatabaseDataEntryQuery(query);

         query = "update tbl_Hedge set IsDeletedOrder = 1 WHERE OrderTicket = " + IntegerToString(trans.position);
         DatabaseDataEntryQuery(query);

         query = "update tbl_Hedge set IsLastOrder = 0 WHERE IsLastOrder = 1";
         DatabaseDataEntryQuery(query);

         query = "INSERT INTO tbl_Hedge (Level,LevelPrice,ResetNo,OrderType,OrderTicket,OpenedOrderPrice,OrderTP,IsOpenedOrder,IsHedgedOrder,IsFakeOrder,IsDeletedOrder,IsLastOrder)"
                 "VALUES (" +
                 GetLastOrderLevelByTicket(trans.position) + "," + GetLastOrderLevelPriceByTicket(trans.position) + "," + GetLastResetNo() + ",'SellStopToSell'," + IntegerToString(trans.position) + "," + DoubleToString(trans.price) + "," + DoubleToString(trans.price_tp) + ",true,false,false,false,true);";
         DatabaseDataEntryQuery(query);

         query = "update tbl_Hedge set IsDeletedOrder = 1 WHERE OrderType IN ('SellFakeStopToSellFake','BuyFakeStopToBuyFake')";
         DatabaseDataEntryQuery(query);
      }
      else
      {
         query = "INSERT INTO tbl_Hedge (Level,LevelPrice,ResetNo,OrderType,OrderTicket,OpenedOrderPrice,OrderTP,IsOpenedOrder,IsHedgedOrder,IsFakeOrder,IsDeletedOrder,IsLastOrder)"
                 "VALUES (0," +
                 DoubleToString(trans.price) + "," + GetLastResetNo() + ",'Sell'," + IntegerToString(trans.position) + "," + DoubleToString(trans.price) + "," + DoubleToString(trans.price_tp) + ",true,false,false,false,true);";
         DatabaseDataEntryQuery(query);
      }

      MakePenddingOrder();
   }

   if (trans.type == TRADE_TRANSACTION_DEAL_ADD && trans.deal_type == DEAL_TYPE_SELL && trans.order != trans.position) // end buy
   {
      query = "update tbl_Hedge set IsDeletedOrder = 1 WHERE OrderTicket = " + IntegerToString(trans.position);
      DatabaseDataEntryQuery(query);
   }

   if (trans.type == TRADE_TRANSACTION_DEAL_ADD && trans.deal_type == DEAL_TYPE_BUY && trans.order != trans.position) // end sell
   {
      query = "update tbl_Hedge set IsDeletedOrder = 1 WHERE OrderTicket = " + IntegerToString(trans.position);
      DatabaseDataEntryQuery(query);
   }

   if (trans.type == TRADE_TRANSACTION_ORDER_ADD && trans.order_type == ORDER_TYPE_BUY_STOP)
   {
      query = "INSERT INTO tbl_Hedge (Level,LevelPrice,ResetNo,OrderType,OrderTicket,OpenedOrderPrice,OrderTP,IsOpenedOrder,IsHedgedOrder,IsFakeOrder,IsDeletedOrder,IsLastOrder)"
              "VALUES (" +
              (GetLastOrderLevel() + 1) + "," + (GetLastOrderLevelPrice() + orderDistance * SymbolInfoDouble(Symbol(), SYMBOL_POINT)) + "," + GetLastResetNo() + ",'BuyStop'," + IntegerToString(trans.order) + "," + DoubleToString(trans.price) + "," + DoubleToString(trans.price_tp) + ",false,false,false,false,false);";
      DatabaseDataEntryQuery(query);
   }

   if (trans.type == TRADE_TRANSACTION_ORDER_ADD && trans.order_type == ORDER_TYPE_SELL_STOP)
   {
      query = "INSERT INTO tbl_Hedge (Level,LevelPrice,ResetNo,OrderType,OrderTicket,OpenedOrderPrice,OrderTP,IsOpenedOrder,IsHedgedOrder,IsFakeOrder,IsDeletedOrder,IsLastOrder)"
              "VALUES (" +
              (GetLastOrderLevel() - 1) + "," + (GetLastOrderLevelPrice() - orderDistance * SymbolInfoDouble(Symbol(), SYMBOL_POINT)) + "," + GetLastResetNo() + ",'SellStop'," + IntegerToString(trans.order) + "," + DoubleToString(trans.price) + "," + DoubleToString(trans.price_tp) + ",false,false,false,false,false);";
      DatabaseDataEntryQuery(query);
   }
}
//+------------------------------------------------------------------+
void CreateDatabaseAndTable()
{
   string filename = "Hedgedb.sqlite";
//--- create or open the database in the common terminal folder
   int db = DatabaseOpen(filename, DATABASE_OPEN_READWRITE | DATABASE_OPEN_CREATE | DATABASE_OPEN_COMMON);
   if (db == INVALID_HANDLE)
   {
      Print("DB: ", filename, " open failed with code ", GetLastError());
      return;
   }

//--- if the COMPANY table exists, delete it
   if (DatabaseTableExists(db, "tbl_Hedge") && !DatabaseExecute(db, "DROP TABLE tbl_Hedge"))
   {
      Print("Failed to drop table COMPANY with code ", GetLastError());
      DatabaseClose(db);
      return;
   }
//--- create the COMPANY table
   if (!DatabaseExecute(db, "CREATE TABLE tbl_Hedge("
                        "ID                      INTEGER                    PRIMARY KEY    AUTOINCREMENT,"
                        "Level                   INTEGER                    NOT NULL,"
                        "LevelPrice              REAL                       NOT NULL,"
                        "ResetNo                 INTEGER                    NOT NULL,"
                        "OrderType               TEXT                       NOT NULL,"
                        "OrderTicket             INTEGER                    NOT NULL,"
                        "OpenedOrderPrice        REAL                       NOT NULL,"
                        "OrderTP                 bool                       NOT NULL,"
                        "IsOpenedOrder           bool                       NOT NULL,"
                        "IsHedgedOrder           bool                       NOT NULL,"
                        "IsFakeOrder             bool                       NOT NULL,"
                        "IsDeletedOrder          bool                       NOT NULL,"
                        "IsLastOrder             bool                       NOT NULL);"))
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
void DatabaseDataEntryQuery(string currentQuery)
{
   string filename = "Hedgedb.sqlite";
//--- create or open the database in the common terminal folder
   int db = DatabaseOpen(filename, DATABASE_OPEN_READWRITE | DATABASE_OPEN_CREATE | DATABASE_OPEN_COMMON);
   if (db == INVALID_HANDLE)
   {
      Print("DB: ", filename, " open failed with code ", GetLastError());
      return;
   }
   if (!DatabaseExecute(db, currentQuery))
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
   if (db == INVALID_HANDLE)
   {
      Print("DB: ", filename, " open failed with code ", GetLastError());
      return false;
   }
//--- create a query and get a handle for it
   int request = DatabasePrepare(db, currentQuery);
   if (request == INVALID_HANDLE)
   {
      Print("DB: ", filename, " request failed with code ", GetLastError());
      DatabaseClose(db);
      return false;
   }

   int DatabaseReadCount = DatabaseRead(request);
   for (int i = 0; i < DatabaseReadCount; i++)
   {
      if (DatabaseColumnInteger(request, 0, isOrderBuyStop))
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
   DatabaseClose(db);
   return isOrderBuyStop == 1 ? true : false;
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool IsOrderSellStop(ulong positionId)
{
   int isOrderSellStop = 0;
   string currentQuery = "SELECT  CASE WHEN EXISTS (SELECT 1 From tbl_Hedge WHERE OrderType = 'SellStop' AND IsDeletedOrder = 0) THEN 1 ELSE 0 End AS isOrderSellStop";
   string filename = "Hedgedb.sqlite";

//--- create or open the database in the common terminal folder
   int db = DatabaseOpen(filename, DATABASE_OPEN_READWRITE | DATABASE_OPEN_CREATE | DATABASE_OPEN_COMMON);
   if (db == INVALID_HANDLE)
   {
      Print("DB: ", filename, " open failed with code ", GetLastError());
      return false;
   }
//--- create a query and get a handle for it
   int request = DatabasePrepare(db, currentQuery);
   if (request == INVALID_HANDLE)
   {
      Print("DB: ", filename, " request failed with code ", GetLastError());
      DatabaseClose(db);
      return false;
   }

   int DatabaseReadCount = DatabaseRead(request);
   for (int i = 0; i < DatabaseReadCount; i++)
   {
      if (DatabaseColumnInteger(request, 0, isOrderSellStop))
      {
         DatabaseClose(db);
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
   DatabaseClose(db);
   return isOrderSellStop == 1 ? true : false;
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int GetTicketOfOpenedPenddingStop(string pendingStopType)
{
   int OrderTicket;
   string currentQuery = "SELECT OrderTicket FROM tbl_Hedge WHERE OrderType = '" + pendingStopType + "' AND IsDeletedOrder = 0";
   string filename = "Hedgedb.sqlite";

//--- create or open the database in the common terminal folder
   int db = DatabaseOpen(filename, DATABASE_OPEN_READWRITE | DATABASE_OPEN_CREATE | DATABASE_OPEN_COMMON);
   if (db == INVALID_HANDLE)
   {
      Print("DB: ", filename, " open failed with code ", GetLastError());
      return false;
   }
//--- create a query and get a handle for it
   int request = DatabasePrepare(db, currentQuery);
   if (request == INVALID_HANDLE)
   {
      Print("DB: ", filename, " request failed with code ", GetLastError());
      DatabaseClose(db);
      return false;
   }

   int DatabaseReadCount = DatabaseRead(request);
   for (int i = 0; i < DatabaseReadCount; i++)
   {
      if (DatabaseColumnInteger(request, 0, OrderTicket))
      {
      DatabaseClose(db);
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
   DatabaseClose(db);
   return -2;
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool IsMarketOpen()
{
   bool isOpen = false;                           // by default market is closed
   MqlDateTime mdtServerTime;                     // declare server time structure variable
   datetime dtServerDateTime = TimeTradeServer(); // store server time
   if (!TimeToStruct(dtServerDateTime,            // is servertime correctly converted to struct?
                     mdtServerTime))
   {
      return (false); // no, return market is closed
   }

   ENUM_DAY_OF_WEEK today = (ENUM_DAY_OF_WEEK) // get actual day and cast to enum
                            mdtServerTime.day_of_week;

   if (today > 0 || today < 6) // is today in monday to friday?
   {
      datetime dtF;                                     // store trading session begin and end time
      datetime dtT;                                     // date component is 1970.01.01 (0)
      datetime dtServerTime = dtServerDateTime % 86400; // set date to 1970.01.01 (0)
      if (!SymbolInfoSessionTrade(Symbol(), today,      // do we have values for dtFrom and dtTo?
                                  0, dtF, dtT))
      {
         return (false); // no, return market is closed
      }
      switch (today) // check for different trading sessions
      {
      case 1:
         if (dtServerTime >= dtF && dtServerTime <= dtT) // is server time in 00:05 (300) - 00:00 (86400)
            isOpen = true;                               // yes, set market is open
         break;
      case 5:
         if (dtServerTime >= dtF && dtServerTime <= dtT) // is server time in 00:04 (240) - 23:55 (86100)
            isOpen = true;                               // yes, set market is open
         break;
      default:
         if (dtServerTime >= dtF && dtServerTime <= dtT) // is server time in 00:04 (240) - 00:00 (86400)
            isOpen = true;                               // yes, set market is open
         break;
      }
   }
   return (isOpen);
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double GetLastOrderLevelPrice()
{
   double LevelPrice = 0;
   string currentQuery = "SELECT LevelPrice FROM tbl_Hedge WHERE IslastOrder = 1";
   string filename = "Hedgedb.sqlite";

//--- create or open the database in the common terminal folder
   int db = DatabaseOpen(filename, DATABASE_OPEN_READWRITE | DATABASE_OPEN_CREATE | DATABASE_OPEN_COMMON);
   if (db == INVALID_HANDLE)
   {
      Print("DB: ", filename, " open failed with code ", GetLastError());
      return false;
   }
//--- create a query and get a handle for it
   int request = DatabasePrepare(db, currentQuery);
   if (request == INVALID_HANDLE)
   {
      Print("DB: ", filename, " request failed with code ", GetLastError());
      DatabaseClose(db);
      return false;
   }

   int DatabaseReadCount = DatabaseRead(request);
   for (int i = 0; i < DatabaseReadCount; i++)
   {
      if (DatabaseColumnDouble(request, 0, LevelPrice))
      {
      DatabaseClose(db);
         return LevelPrice;
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
   DatabaseClose(db);
   return 0;
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int GetLastOrderLevel()
{
   int Level;
   string currentQuery = "SELECT Level FROM tbl_Hedge WHERE IslastOrder = 1";
   string filename = "Hedgedb.sqlite";

//--- create or open the database in the common terminal folder
   int db = DatabaseOpen(filename, DATABASE_OPEN_READWRITE | DATABASE_OPEN_CREATE | DATABASE_OPEN_COMMON);
   if (db == INVALID_HANDLE)
   {
      Print("DB: ", filename, " open failed with code ", GetLastError());
      return false;
   }
//--- create a query and get a handle for it
   int request = DatabasePrepare(db, currentQuery);
   if (request == INVALID_HANDLE)
   {
      Print("DB: ", filename, " request failed with code ", GetLastError());
      DatabaseClose(db);
      return false;
   }

   int DatabaseReadCount = DatabaseRead(request);
   for (int i = 0; i < DatabaseReadCount; i++)
   {
      if (DatabaseColumnInteger(request, 0, Level))
      {
      DatabaseClose(db);
         return Level;
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
   DatabaseClose(db);
   return 0;
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double GetLastOrderLevelPriceByTicket(ulong ticket)
{
   double LevelPrice = 0;
   string currentQuery = "SELECT LevelPrice FROM tbl_Hedge WHERE OrderTicket = " + ticket;
   string filename = "Hedgedb.sqlite";

//--- create or open the database in the common terminal folder
   int db = DatabaseOpen(filename, DATABASE_OPEN_READWRITE | DATABASE_OPEN_CREATE | DATABASE_OPEN_COMMON);
   if (db == INVALID_HANDLE)
   {
      Print("DB: ", filename, " open failed with code ", GetLastError());
      return false;
   }
//--- create a query and get a handle for it
   int request = DatabasePrepare(db, currentQuery);
   if (request == INVALID_HANDLE)
   {
      Print("DB: ", filename, " request failed with code ", GetLastError());
      DatabaseClose(db);
      return false;
   }

   int DatabaseReadCount = DatabaseRead(request);
   for (int i = 0; i < DatabaseReadCount; i++)
   {
      if (DatabaseColumnDouble(request, 0, LevelPrice))
      {
      DatabaseClose(db);
         return LevelPrice;
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
   DatabaseClose(db);
   return 0;
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int GetLastOrderLevelByTicket(ulong ticket)
{
   int Level;
   string currentQuery = "SELECT Level FROM tbl_Hedge WHERE OrderTicket = " + ticket;
   string filename = "Hedgedb.sqlite";

//--- create or open the database in the common terminal folder
   int db = DatabaseOpen(filename, DATABASE_OPEN_READWRITE | DATABASE_OPEN_CREATE | DATABASE_OPEN_COMMON);
   if (db == INVALID_HANDLE)
   {
      Print("DB: ", filename, " open failed with code ", GetLastError());
      return false;
   }
//--- create a query and get a handle for it
   int request = DatabasePrepare(db, currentQuery);
   if (request == INVALID_HANDLE)
   {
      Print("DB: ", filename, " request failed with code ", GetLastError());
      DatabaseClose(db);
      return false;
   }

   int DatabaseReadCount = DatabaseRead(request);
   for (int i = 0; i < DatabaseReadCount; i++)
   {
      if (DatabaseColumnInteger(request, 0, Level))
      {
      DatabaseClose(db);
         return Level;
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
   DatabaseClose(db);
   return 0;
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool IsExistSameOrderInThisLevel(int level, string orderType)
{
   int isExistSameOrderInThisLevel = 0;
   string currentQuery = "SELECT CASE WHEN EXISTS(SELECT 1 FROM tbl_Hedge WHERE IsDeletedOrder = 0 AND IsFakeOrder = 0 AND IsOpenedOrder = 1 AND OrderType LIKE '" + orderType + "%' AND Level = " + level + " ) THEN 1 ELSE 0  END AS IsExistSameOrderInThisLevel";
   string filename = "Hedgedb.sqlite";

//--- create or open the database in the common terminal folder
   int db = DatabaseOpen(filename, DATABASE_OPEN_READWRITE | DATABASE_OPEN_CREATE | DATABASE_OPEN_COMMON);
   if (db == INVALID_HANDLE)
   {
      Print("DB: ", filename, " open failed with code ", GetLastError());
      return false;
   }
//--- create a query and get a handle for it
   int request = DatabasePrepare(db, currentQuery);
   if (request == INVALID_HANDLE)
   {
      Print("DB: ", filename, " request failed with code ", GetLastError());
      DatabaseClose(db);
      return false;
   }

   int DatabaseReadCount = DatabaseRead(request);
   for (int i = 0; i < DatabaseReadCount; i++)
   {
      if (DatabaseColumnInteger(request, 0, isExistSameOrderInThisLevel))
      {
      DatabaseClose(db);
         return isExistSameOrderInThisLevel == 1 ? true : false;
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
   DatabaseClose(db);
   return isExistSameOrderInThisLevel == 1 ? true : false;
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool IsExistFakeOrderStop()
{
   int isExistFakeOrderStop = 0;
   string currentQuery = "SELECT CASE WHEN EXISTS(SELECT 1 FROM tbl_Hedge WHERE IsDeletedOrder = 0 AND IsFakeOrder = 1 AND IsOpenedOrder = 0 AND OrderType LIKE '%FakeStop' ) THEN 1 ELSE 0  END AS IsExistFakeOrderStop";
   string filename = "Hedgedb.sqlite";

//--- create or open the database in the common terminal folder
   int db = DatabaseOpen(filename, DATABASE_OPEN_READWRITE | DATABASE_OPEN_CREATE | DATABASE_OPEN_COMMON);
   if (db == INVALID_HANDLE)
   {
      Print("DB: ", filename, " open failed with code ", GetLastError());
      return false;
   }
//--- create a query and get a handle for it
   int request = DatabasePrepare(db, currentQuery);
   if (request == INVALID_HANDLE)
   {
      Print("DB: ", filename, " request failed with code ", GetLastError());
      DatabaseClose(db);
      return false;
   }

   int DatabaseReadCount = DatabaseRead(request);
   for (int i = 0; i < DatabaseReadCount; i++)
   {
      if (DatabaseColumnInteger(request, 0, isExistFakeOrderStop))
      {
      DatabaseClose(db);
         return isExistFakeOrderStop == 1 ? true : false;
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
   DatabaseClose(db);
   return isExistFakeOrderStop == 1 ? true : false;
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double GetFakeOrderStopLevelPrice(string orderType)
{
   double fakeOrderStopLevelPrice = 0;
   string currentQuery = "SELECT LevelPrice FROM tbl_Hedge WHERE IsFakeOrder = 1 AND IsDeletedOrder = 0 AND OrderType = '" + orderType + "'";
   string filename = "Hedgedb.sqlite";

//--- create or open the database in the common terminal folder
   int db = DatabaseOpen(filename, DATABASE_OPEN_READWRITE | DATABASE_OPEN_CREATE | DATABASE_OPEN_COMMON);
   if (db == INVALID_HANDLE)
   {
      Print("DB: ", filename, " open failed with code ", GetLastError());
      return false;
   }
//--- create a query and get a handle for it
   int request = DatabasePrepare(db, currentQuery);
   if (request == INVALID_HANDLE)
   {
      Print("DB: ", filename, " request failed with code ", GetLastError());
      DatabaseClose(db);
      return false;
   }

   int DatabaseReadCount = DatabaseRead(request);
   for (int i = 0; i < DatabaseReadCount; i++)
   {
      if (DatabaseColumnDouble(request, 0, fakeOrderStopLevelPrice))
      {
      DatabaseClose(db);
         return fakeOrderStopLevelPrice;
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
   DatabaseClose(db);
   return fakeOrderStopLevelPrice;
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int GetLastResetNo()
{
   int lastResetNo = -1;
   string currentQuery = "SELECT CASE WHEN NOT EXISTS (SELECT 1 FROM tbl_Hedge) THEN 1 WHEN EXISTS (SELECT 1 FROM tbl_Hedge WHERE IsDeletedOrder = 0) THEN (SELECT ResetNo FROM tbl_Hedge WHERE IsDeletedOrder = 0) ELSE (SELECT MAX(ResetNo) + 1 FROM tbl_Hedge) END LastResetNo";
   string filename = "Hedgedb.sqlite";

//--- create or open the database in the common terminal folder
   int db = DatabaseOpen(filename, DATABASE_OPEN_READWRITE | DATABASE_OPEN_CREATE | DATABASE_OPEN_COMMON);
   if (db == INVALID_HANDLE)
   {
      Print("DB: ", filename, " open failed with code ", GetLastError());
      return false;
   }
//--- create a query and get a handle for it
   int request = DatabasePrepare(db, currentQuery);
   if (request == INVALID_HANDLE)
   {
      Print("DB: ", filename, " request failed with code ", GetLastError());
      DatabaseClose(db);
      return false;
   }

   int DatabaseReadCount = DatabaseRead(request);
   for (int i = 0; i < DatabaseReadCount; i++)
   {
      if (DatabaseColumnInteger(request, 0, lastResetNo))
      {
      DatabaseClose(db);
         return lastResetNo;
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
   DatabaseClose(db);
   return lastResetNo;
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void MakePenddingOrder()
{
   int epsilon = 0;
   if (IsExistSameOrderInThisLevel(GetLastOrderLevel() + 1, "Buy"))
   {
      string query = "INSERT INTO tbl_Hedge (Level,LevelPrice,ResetNo,OrderType,OrderTicket,OpenedOrderPrice,OrderTP,IsOpenedOrder,IsHedgedOrder,IsFakeOrder,IsDeletedOrder,IsLastOrder)"
                     "VALUES (" +
                     (GetLastOrderLevel() + 1) + "," + (GetLastOrderLevelPrice() + orderDistance * SymbolInfoDouble(Symbol(), SYMBOL_POINT)) + "," + GetLastResetNo() + ",'BuyFakeStop'," + (-1) + "," + (GetLastOrderLevelPrice() + orderDistance * SymbolInfoDouble(Symbol(), SYMBOL_POINT)) + "," + (GetLastOrderLevelPrice() + orderDistance * SymbolInfoDouble(Symbol(), SYMBOL_POINT) + tpDistance * SymbolInfoDouble(Symbol(), SYMBOL_POINT)) + ",false,false,true,false,false);";
      DatabaseDataEntryQuery(query);
   }
   else
   {
      while(!trade.BuyStop(orderVolume, GetLastOrderLevelPrice() + (orderDistance + epsilon) * SymbolInfoDouble(Symbol(), SYMBOL_POINT), Symbol(), 0, GetLastOrderLevelPrice() + orderDistance * SymbolInfoDouble(Symbol(), SYMBOL_POINT) + tpDistance * SymbolInfoDouble(Symbol(), SYMBOL_POINT), 0, 0, NULL, type_filling1))
      {
         epsilon ++;
      }
   }

   if (IsExistSameOrderInThisLevel(GetLastOrderLevel() - 1, "Sell"))
   {
      string query = "INSERT INTO tbl_Hedge (Level,LevelPrice,ResetNo,OrderType,OrderTicket,OpenedOrderPrice,OrderTP,IsOpenedOrder,IsHedgedOrder,IsFakeOrder,IsDeletedOrder,IsLastOrder)"
                     "VALUES (" +
                     (GetLastOrderLevel() - 1) + "," + (GetLastOrderLevelPrice() - orderDistance * SymbolInfoDouble(Symbol(), SYMBOL_POINT)) + "," + GetLastResetNo() + ",'SellFakeStop'," + (-1) + "," + (GetLastOrderLevelPrice() - orderDistance * SymbolInfoDouble(Symbol(), SYMBOL_POINT)) + "," + (GetLastOrderLevelPrice() - orderDistance * SymbolInfoDouble(Symbol(), SYMBOL_POINT) - tpDistance * SymbolInfoDouble(Symbol(), SYMBOL_POINT)) + ",false,false,true,false,false);";
      DatabaseDataEntryQuery(query);
   }
   else
   {
      epsilon = 0;
      while(!trade.SellStop(orderVolume, GetLastOrderLevelPrice() - (orderDistance + epsilon) * SymbolInfoDouble(Symbol(), SYMBOL_POINT), Symbol(), 0, GetLastOrderLevelPrice() - orderDistance * SymbolInfoDouble(Symbol(), SYMBOL_POINT) - tpDistance * SymbolInfoDouble(Symbol(), SYMBOL_POINT), 0, 0, NULL, type_filling1, deviation1))
      {
         epsilon ++;
      }
   }
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool IsExistConditionForHedge()
{
   int isExistConditionForHedge = 0;
   string currentQuery = "SELECT "
                         "CASE "
                         "WHEN "
                         " (SELECT COUNT(*) FROM tbl_Hedge WHERE OrderType IN ('Buy','BuyStopToBuy') AND IsHedgedOrder = 0 AND IsDeletedOrder = 0) = " + hedgeSize + ""
                         " AND (SELECT COUNT(*) FROM tbl_Hedge WHERE OrderType IN ('Sell','SellStopToSell') AND IsHedgedOrder = 0 AND IsDeletedOrder = 0) = " + hedgeSize + " THEN 1"
                         " ELSE 0"
                         " END AS IsExistConditionForHedge";

   string filename = "Hedgedb.sqlite";

//--- create or open the database in the common terminal folder
   int db = DatabaseOpen(filename, DATABASE_OPEN_READWRITE | DATABASE_OPEN_CREATE | DATABASE_OPEN_COMMON);
   if (db == INVALID_HANDLE)
   {
      Print("DB: ", filename, " open failed with code ", GetLastError());
      return false;
   }
//--- create a query and get a handle for it
   int request = DatabasePrepare(db, currentQuery);
   if (request == INVALID_HANDLE)
   {
      Print("DB: ", filename, " request failed with code ", GetLastError());
      DatabaseClose(db);
      return false;
   }

   int DatabaseReadCount = DatabaseRead(request);
   for (int i = 0; DatabaseReadCount; i++)
   {
      if (DatabaseColumnInteger(request, 0, isExistConditionForHedge))
      {
      DatabaseClose(db);
         return isExistConditionForHedge == 1 ? true : false;
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
   DatabaseClose(db);
   return isExistConditionForHedge == 1 ? true : false;
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void RemoveTPFromHedgeOrder()
{
   int orderTicket = 0;
   string currentQuery = "SELECT OrderTicket FROM tbl_Hedge WHERE IsOpenedOrder = 1 AND IsDeletedOrder = 0 AND IsHedgedOrder = 0 AND IsFakeOrder = 0";

   string filename = "Hedgedb.sqlite";

//--- create or open the database in the common terminal folder
   int db = DatabaseOpen(filename, DATABASE_OPEN_READWRITE | DATABASE_OPEN_CREATE | DATABASE_OPEN_COMMON);
   if (db == INVALID_HANDLE)
   {
      Print("DB: ", filename, " open failed with code ", GetLastError());
      return;
   }
//--- create a query and get a handle for it
   int request = DatabasePrepare(db, currentQuery);
   if (request == INVALID_HANDLE)
   {
      Print("DB: ", filename, " request failed with code ", GetLastError());
      DatabaseClose(db);
      return;
   }

   for (int i = 0; DatabaseRead(request); i++)
   {
      if (DatabaseColumnInteger(request,0, orderTicket))
      {
         trade.PositionModify(orderTicket, 0, 0);
      }
      else
      {
         Print(i, ": DatabaseRead() failed with code ", GetLastError());
         DatabaseFinalize(request);
         DatabaseClose(db);
         return;
      }
   }
//--- remove the query after use
   DatabaseFinalize(request);
   DatabaseClose(db);
}
//+------------------------------------------------------------------+
