//+------------------------------------------------------------------+
//|                                                        test2.mq5 |
//|                                              Mohammadreza Tazian |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Mohammadreza Tazian"
#property link      "https://www.mql5.com"
#property version   "1.00"
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
   string filename = "company.sqlite";
//--- create or open the database in the common terminal folder
   int db = DatabaseOpen(filename, DATABASE_OPEN_READWRITE | DATABASE_OPEN_CREATE | DATABASE_OPEN_COMMON);
   if(db == INVALID_HANDLE)
   {
      Print("DB: ", filename, " open failed with code ", GetLastError());
      return 1;
   }
   if(DatabaseTableExists(db, "COMPANY"))
   {
      //--- delete the table
      if(!DatabaseExecute(db, "DROP TABLE COMPANY"))
      {
         Print("Failed to drop table COMPANY with code ", GetLastError());
         DatabaseClose(db);
         return 1;
      }
   }
//--- create the COMPANY table
   if(!DatabaseExecute(db, "CREATE TABLE COMPANY("
                       "ID INT PRIMARY KEY     NOT NULL,"
                       "NAME           TEXT    NOT NULL,"
                       "AGE            INT     NOT NULL,"
                       "ADDRESS        CHAR(50),"
                       "SALARY         REAL );"))
   {
      Print("DB: ", filename, " create table failed with code ", GetLastError());
      return 1;
   }
   if(!DatabaseExecute(db, "INSERT INTO COMPANY (ID,NAME,AGE,ADDRESS,SALARY) VALUES (1,'Paul',32,'California',25000.00); "
                       "INSERT INTO COMPANY (ID,NAME,AGE,ADDRESS,SALARY) VALUES (2,'Allen',25,'Texas',15000.00); "
                       "INSERT INTO COMPANY (ID,NAME,AGE,ADDRESS,SALARY) VALUES (3,'Teddy',23,'Norway',20000.00);"
                       "INSERT INTO COMPANY (ID,NAME,AGE,ADDRESS,SALARY) VALUES (4,'Mark',25,'Rich-Mond',65000.00);"))
   {
      Print("DB: ", filename, " insert failed with code ", GetLastError());
      return 1;
   }

   int request = DatabasePrepare(db, "SELECT * FROM COMPANY WHERE SALARY>15000");
   if(request == INVALID_HANDLE)
   {
      Print("DB: ", filename, " request failed with code ", GetLastError());
      return 1;
   }
   int    id, age;
   string name, address;
   double salary;
   Print("Persons with salary > 15000:");
   int bb = DatabaseRead(request);
   for(int i=0; DatabaseRead(request); i++)
     {
      //--- read the values of each field from the obtained entry
      if(DatabaseColumnInteger(request, 0, id) && DatabaseColumnText(request, 1, name) &&
         DatabaseColumnInteger(request, 2, age) && DatabaseColumnText(request, 3, address) && DatabaseColumnDouble(request, 4, salary))
         Print(i, ":  ", id, " ", name, " ", age, " ", address, " ", salary);
      else
        {
         Print(i, ": DatabaseRead() failed with code ", GetLastError());
         DatabaseFinalize(request);
         return 1;
        }
        Print("I = ",i);
     }
//--- remove the query after use
   DatabaseFinalize(request);
   DatabaseClose(db);
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

}
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
