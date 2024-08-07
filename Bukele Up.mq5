//+------------------------------------------------------------------+
//|                                                    Bukele UP.mq5 |
//|                                                    Tony Programa |
//|                         https://www.instagram.com/tony_programa/ |
//+------------------------------------------------------------------+
#property copyright "Tony Programa"
#property link      "https://www.instagram.com/tony_programa/"
#property version   "1.2"


enum Permit
  {
   Yes = 0,
   No = 1
  };

enum Type_Lotaje
  {
   Lotaje_Fijo       = 0,  //Fixed Lotsize
   Porcentaje_riesgo = 1,  //Percent of Capital
   Dollares          = 2,  //Dollars
  };

enum Day_No_Operation
  {
   Monday      = 1,
   Tuesday     = 2,
   Wednesday   = 3,
   Thursday    = 4,
   Friday      = 5,
   All         = 8 //Operate All Days
  };



//--- Parámetros de entrada
input string Setting_Capital     = "---------";       //---Setting Capital Section---
input Type_Lotaje Risk_Type      = 2;        //Risk for Operation
input double Value_Risk          = 100;        //Value of Risk
input Permit Aplly_SL            = 0;        //Apply Stop Loss?
input Type_Lotaje Take_Profit    = 2;        //Type Take Profit
input double Take_Profit_USD     = 400;      //Value Take Profit
input int Magic_Number           = 123;      //Magic Number


input string Breack_Out_Section  = "---------";    //---Breack Out Section---
input int Start_Hour             = 1;    //Start hour
input int Start_Min              = 0;    //Start minut
input int Final_Hour             = 4;    //Final hour
input int Final_Min              = 30;   //Final minut


input string Section_Breack_Even    = "---------";    //---Breack Even Section---
input Permit Apply_Breack_Even      = 1;  //Apply Breack Even?
input int Hours_Apply_Breack_Even   = 2;  //Hours of Apply Breack Even


input string Section_Final_Operations  = "---------";    //---Delete Lines/Operations(Op.)---
input int Hour_Close_Orders            = 19;       //Hour of Delete all Lines/Op.
input int Minut_Close_Orders           = 0;        //Minute of Delete all Lines/Op.
input Permit Close_Order_With_BE       = 0;        //Only an Op. with Break Even?
input Permit Only_A_Operation_Day      = 0;        //Permit only an Op. per Day?
input Permit Only_A_Operation          = 0;        //Permit only an Op. in this Account?


input string Other_Inputs  = "---------";    //---Other Inputs---
input Day_No_Operation Day_no_operate        = 5;     //What Day do not operate?
sinput double min_lotaje_permit              = 0.1;     //Minimum lotsize
sinput double max_lotaje_permit              = 0.2;        //Maximun lotsize
sinput int Digits_                           = 2;        //Digitos del lotsize



//---Otras variables
bool Permit_Creation_Breack_Out = false;
int Number_Minuts = 0;
datetime Hour_Operation = 0;


double blue_line  = 0;
double red_line   = 0;

double Value_Max;
double Value_Min;

int Only_One = 0;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {

   if(Start_Hour >= 24 || Start_Hour < 0)
     {
      Alert("Error in Start hour");
      return(INIT_FAILED);
     }

   if(Final_Hour >= 24 || Final_Hour < 0)
     {
      Alert("Error in Final hour");
      return(INIT_FAILED);
     }

   if(Start_Min >= 60 || Start_Min < 0)
     {
      Alert("Error in Start minut");
      return(INIT_FAILED);
     }

   if(Final_Min >= 60 || Final_Min < 0)
     {
      Alert("Error in Final minut");
      return(INIT_FAILED);
     }

   ChartSetInteger(ChartID(),CHART_COLOR_BACKGROUND,clrBlack);
   ChartSetInteger(ChartID(),CHART_COLOR_FOREGROUND,clrWhite);
   ChartSetInteger(ChartID(),CHART_COLOR_GRID,clrLightSlateGray);
   ChartSetInteger(ChartID(),CHART_COLOR_CHART_UP,clrWhiteSmoke);
   ChartSetInteger(ChartID(),CHART_COLOR_CHART_DOWN,clrWhiteSmoke);
   ChartSetInteger(ChartID(),CHART_COLOR_CANDLE_BEAR,clrWhite);
   ChartSetInteger(ChartID(),CHART_COLOR_CANDLE_BULL,clrBlue);
   ChartSetInteger(ChartID(),CHART_COLOR_CHART_LINE,clrDeepSkyBlue);
   ChartSetInteger(ChartID(),CHART_COLOR_VOLUME,clrWhite);
   ChartSetInteger(ChartID(),CHART_COLOR_ASK,clrRed);
   ChartSetInteger(ChartID(),CHART_COLOR_STOP_LEVEL,clrRed);

   Permit_Creation_Breack_Out = false;
   Number_Minuts = (60*MathAbs(Start_Hour - Final_Hour) - Start_Min + Final_Min);
   Value_Max  = 0;
   Value_Min  = 0;
   ObjectDelete(0,"Blue Line");
   ObjectDelete(0,"Red Line");

//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   ObjectDelete(0,"Blue Line");
   ObjectDelete(0,"Red Line");

  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---
   Comment("Profit: ", NormalizeDouble(Profit(Magic_Number),1), " ", AccountInfoString(ACCOUNT_CURRENCY));

   double Ask = SymbolInfoDouble(Symbol(),SYMBOL_ASK);
   double Bid = SymbolInfoDouble(Symbol(),SYMBOL_BID);

   MqlDateTime DateInformation;
   TimeCurrent(DateInformation);

   bool Time_Permit = true;

   if(Day_no_operate != 8)
      if(DateInformation.day_of_week == Day_no_operate)
         Time_Permit = false;

   if(Time_Permit && DateInformation.hour == Final_Hour && DateInformation.min == Final_Min + 1)
     {
      if(!Permit_Creation_Breack_Out)
        {
         Hour_Operation = 0;
         MqlRates PriceInformation[];
         ArraySetAsSeries(PriceInformation,true);
         CopyRates(Symbol(),PERIOD_M1,0,Number_Minuts + 2,PriceInformation);

         int Maximo = iHighest(Symbol(),PERIOD_M1,MODE_HIGH,Number_Minuts,1);
         int Minimo = iLowest(Symbol(),PERIOD_M1,MODE_LOW,Number_Minuts,1);

         Value_Max  = PriceInformation[Maximo].high;
         Value_Min  = PriceInformation[Minimo].low;


         if(!ObjectCreate(0,"Rectangle number: " + TimeToString(TimeCurrent(),TIME_DATE),OBJ_RECTANGLE,0,PriceInformation[1].time,Value_Max,PriceInformation[Number_Minuts + 1].time,Value_Min))
            Print("Error in create Object Number: ", GetLastError());
         else
           {
            ObjectSetInteger(0,"Rectangle number: " + TimeToString(TimeCurrent(),TIME_DATE),OBJPROP_BACK,true);
            ObjectSetInteger(0,"Rectangle number: " + TimeToString(TimeCurrent(),TIME_DATE),OBJPROP_FILL,true);
            ObjectSetInteger(0,"Rectangle number: " + TimeToString(TimeCurrent(),TIME_DATE),OBJPROP_COLOR,clrBlue);

            ObjectCreate(0,"Red Line", OBJ_HLINE,0,0,Value_Min - (5*_Point));
            ObjectSetInteger(0,"Red Line",OBJPROP_COLOR,clrRed);

            ObjectCreate(0,"Blue Line", OBJ_HLINE,0,0,Value_Max + (5*_Point));
            ObjectSetInteger(0,"Blue Line",OBJPROP_COLOR,clrBlue);

            Permit_Creation_Breack_Out = true;
           }
        }
     }
   else
      Permit_Creation_Breack_Out = false;


   double TAKE_PROFIT = 0;

   if(Take_Profit == 0)
      TAKE_PROFIT = Take_Profit_USD;
   else
      TAKE_PROFIT = Take_Profit_USD*AccountInfoDouble(ACCOUNT_BALANCE)/100;


   if((DateInformation.hour == Hour_Close_Orders && DateInformation.min >= Minut_Close_Orders) || Profit(Magic_Number) >= TAKE_PROFIT)//Close All Orders
     {
      if(DateInformation.hour == Hour_Close_Orders && DateInformation.min >= Minut_Close_Orders)
        {
         ObjectDelete(0,"Blue Line");
         ObjectDelete(0,"Red Line");
         Permit_Creation_Breack_Out = false;
         Value_Max  = 0;
         Value_Min  = 0;
        }

      MqlTradeRequest request_;
      MqlTradeResult  result_;
      for(int i=0; i<PositionsTotal(); i++)
         if(PositionSelectByTicket(PositionGetTicket(i)) && PositionGetInteger(POSITION_MAGIC) == Magic_Number && PositionGetString(POSITION_SYMBOL) == Symbol())
           {
            ZeroMemory(request_);
            ZeroMemory(result_);

            request_.action      = TRADE_ACTION_DEAL;
            request_.position    = PositionGetTicket(i);
            request_.symbol      = PositionGetString(POSITION_SYMBOL);
            request_.deviation   = 500;
            request_.volume      = PositionGetDouble(POSITION_VOLUME);
            request_.magic       = Magic_Number;
            request_.type_filling   = ORDER_FILLING_FOK;


            if((ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_BUY)
              {
               request_.type  = ORDER_TYPE_SELL;
               request_.price = SymbolInfoDouble(PositionGetString(POSITION_SYMBOL),SYMBOL_BID);
              }
            else
              {
               request_.type  = ORDER_TYPE_BUY;
               request_.price = SymbolInfoDouble(PositionGetString(POSITION_SYMBOL),SYMBOL_ASK);
              }

            if(!OrderSend(request_,result_))
              {
               request_.type_filling   = ORDER_FILLING_IOC;
               if(!OrderSend(request_,result_))
                 {
                  request_.type_filling  = ORDER_FILLING_BOC;
                  if(!OrderSend(request_,result_))
                     Print("Error in Close Position nuember: ",GetLastError());
                 }
              }

           }
     }


   if((ObjectFind(0,"Blue Line")>=0  || ObjectFind(0,"Red Line")>=0) && AccountInfoDouble(ACCOUNT_BALANCE) > 200)//Make Operations
     {
      if(Ask >= Value_Max && Number_Positions_Buy(Magic_Number) == 0 && ObjectFind(0,"Blue Line") >= 0 && Only_One == 0)  //Make Buy
        {
         double LOTAJE = NormalizeDouble(Volume(Risk_Type, Value_Risk,MathAbs(Value_Max-Value_Min)),Digits_);
         int error;
         ulong BUY_ = 0;

         if(Aplly_SL == 1)
            BUY_  = Apply_Order(ORDER_TYPE_BUY, Magic_Number, Symbol(), 0, 0, LOTAJE, Ask, error);
         else
            BUY_  = Apply_Order(ORDER_TYPE_BUY, Magic_Number, Symbol(), 0, Value_Min, LOTAJE, Ask, error);

         if(BUY_ > 0)
           {
            ObjectDelete(0,"Blue Line");

            if(Only_A_Operation == 0)
               Only_One++;
           }
        }

      if(Bid <= Value_Min && Number_Positions_Sell(Magic_Number) == 0 && ObjectFind(0,"Red Line") >= 0 && Only_One == 0)   //Make Sell
        {
         double LOTAJE =  NormalizeDouble(Volume(Risk_Type, Value_Risk,MathAbs(Value_Max-Value_Min)),Digits_);
         int error;
         ulong SELL_ = 0;

         if(Aplly_SL == 1)
            SELL_  = Apply_Order(ORDER_TYPE_SELL, Magic_Number, Symbol(), 0, 0, LOTAJE, Bid, error);
         else
            SELL_  = Apply_Order(ORDER_TYPE_SELL, Magic_Number, Symbol(), 0, Value_Max, LOTAJE, Bid, error);

         if(SELL_ > 0)
           {
            ObjectDelete(0,"Red Line");

            if(Only_A_Operation == 0)
               Only_One++;
           }
        }
     }


   if(Apply_Breack_Even == 0 && Number_Positions(Magic_Number) > 0)//Apply Breack Even
      if(Number_Positions(Magic_Number) == 1)
        {
         for(int i=0; i<PositionsTotal(); i++)
            if(PositionSelectByTicket(PositionGetTicket(i)) && PositionGetInteger(POSITION_MAGIC) == Magic_Number && PositionGetString(POSITION_SYMBOL) == Symbol())
               Hour_Operation = PositionGetInteger(POSITION_TIME);

         int error;

         if(TimeCurrent() >= Hour_Operation + (Hours_Apply_Breack_Even*60*60))//Apply Breack Even
            for(int i=0; i<PositionsTotal(); i++)
               if(PositionSelectByTicket(PositionGetTicket(i)) && PositionGetInteger(POSITION_MAGIC) == Magic_Number)
                 {
                  if((ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_BUY && Ask > PositionGetDouble(POSITION_PRICE_OPEN) + 10*MathAbs(Ask - Bid) && (PositionGetDouble(POSITION_SL) < PositionGetDouble(POSITION_PRICE_OPEN) || PositionGetDouble(POSITION_SL) == 0))
                     if(Modify_Operation_SL_TP(PositionGetTicket(i), Magic_Number, Symbol(), PositionGetDouble(POSITION_TP), PositionGetDouble(POSITION_PRICE_OPEN) + (2*Point()), error) && Close_Order_With_BE == 0)
                        for(int i=0; i<PositionsTotal(); i++)
                           if(PositionSelectByTicket(PositionGetTicket(i)) && PositionGetInteger(POSITION_MAGIC) == Magic_Number && PositionGetString(POSITION_SYMBOL) == Symbol())
                              if((ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_BUY)
                                 ObjectDelete(0,"Red Line");
                              else
                                 ObjectDelete(0,"Blue Line");

                  if((ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_SELL && Bid < PositionGetDouble(POSITION_PRICE_OPEN) - 10*MathAbs(Ask - Bid) && (PositionGetDouble(POSITION_SL) > PositionGetDouble(POSITION_PRICE_OPEN) || PositionGetDouble(POSITION_SL) == 0))
                     if(Modify_Operation_SL_TP(PositionGetTicket(i), Magic_Number, Symbol(), PositionGetDouble(POSITION_TP), PositionGetDouble(POSITION_PRICE_OPEN) - (2*Point()), error) && Close_Order_With_BE == 0)
                        for(int i=0; i<PositionsTotal(); i++)
                           if(PositionSelectByTicket(PositionGetTicket(i)) && PositionGetInteger(POSITION_MAGIC) == Magic_Number && PositionGetString(POSITION_SYMBOL) == Symbol())
                              if((ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_BUY)
                                 ObjectDelete(0,"Red Line");
                              else
                                 ObjectDelete(0,"Blue Line");
                 }
        }


   if(Only_A_Operation_Day == 0 && Number_Positions(Magic_Number) > 0)//Permit only a operation per Day
     {
      for(int i=0; i<PositionsTotal(); i++)
         if(PositionSelectByTicket(PositionGetTicket(i)) && PositionGetInteger(POSITION_MAGIC) == Magic_Number && PositionGetString(POSITION_SYMBOL) == Symbol())
            if((ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_BUY)
               ObjectDelete(0,"Red Line");
            else
               ObjectDelete(0,"Blue Line");
     }
//---
  }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|Volume                                                            |
//+------------------------------------------------------------------+
double Volume(int Type_Volume, double Volume, double stop_Loss_)
  {
//---The stop Loss is in Diference between OPen Price and Price Stop Loss in Absolute
   double tick_size  = SymbolInfoDouble(Symbol(),SYMBOL_TRADE_TICK_SIZE);
   double tick_value = SymbolInfoDouble(Symbol(),SYMBOL_TRADE_TICK_VALUE);
   double lot_step   = SymbolInfoDouble(Symbol(),SYMBOL_VOLUME_STEP);

   double lotaje = 0;
   double risk = 0;

   if(tick_size == 0 || tick_value == 0 || lot_step == 0 || Type_Volume == 0)
      return Volume;

   if(Type_Volume == 1)
      risk = AccountInfoDouble(ACCOUNT_BALANCE)*Volume/100;

   if(Type_Volume == 2)
      risk = Volume;

   double Money_Lot_Step = (stop_Loss_/tick_size)*tick_value*lot_step;
   lotaje = NormalizeDouble(((risk/Money_Lot_Step)*lot_step),Digits_);

   if(lotaje < min_lotaje_permit)
      lotaje = min_lotaje_permit;


   if(lotaje > max_lotaje_permit)
      lotaje = max_lotaje_permit;

   return lotaje;
  }
//+------------------------------------------------------------------+


//+------------------------------------------------------------------+
//|Apply Order                                                       |
//+------------------------------------------------------------------+
ulong Apply_Order(ENUM_ORDER_TYPE type_operation, int magic_number, string symbol_, double tp, double sl, double lotaje_, double price_order, int &error)
  {
   error = 0;
   ulong ticket = 0;

   MqlTradeRequest request= {};
   MqlTradeResult  result= {};

   ZeroMemory(request);
   ZeroMemory(result);

   request.action    =     TRADE_ACTION_DEAL;
   request.symbol    =     symbol_;
   request.volume    =     lotaje_;
   request.type      =     type_operation;
   request.price     =     price_order;
   request.deviation =     500;
   request.magic     =     magic_number;
   request.comment   =     "Tgram: @Tony_Programa";

   if(tp>0)
      request.tp    =  tp;

   if(sl>0)
      request.sl   =  sl;

   request.type_filling  = ORDER_FILLING_IOC;
   if(!OrderSend(request,result))
     {
      request.type_filling   = ORDER_FILLING_IOC;
      if(!OrderSend(request,result))
        {
         request.type_filling  = ORDER_FILLING_BOC;
         if(!OrderSend(request,result))
           {
            Print("Error in Open Operation number: ",GetLastError());
            error = GetLastError();
           }
         else
            ticket = result.order;
        }
      else
         ticket = result.order;
     }
   else
      ticket = result.order;

   return ticket;
  }
//+------------------------------------------------------------------+


//+------------------------------------------------------------------+
//|Modify Operation SL_TP                                             |
//+------------------------------------------------------------------+
bool Modify_Operation_SL_TP(ulong ticket, int magic_number, string symbol_, double tp, double sl, int &error)
  {

   error = 0;
   bool Apply = false;

   MqlTradeRequest request= {};
   MqlTradeResult  result= {};

   ZeroMemory(request);
   ZeroMemory(result);

   request.action    =  TRADE_ACTION_SLTP;
   request.position  =  ticket;
   request.symbol    =  symbol_;
   request.magic     =  magic_number;

   if(tp>0)
      request.tp    =  tp;

   if(sl>0)
      request.sl   =  sl;


   request.type_filling   = ORDER_FILLING_FOK;
   if(!OrderSend(request,result))
     {
      request.type_filling   = ORDER_FILLING_IOC;
      if(!OrderSend(request,result))
        {
         request.type_filling  = ORDER_FILLING_BOC;
         if(!OrderSend(request,result))
           {
            Print("Error in Modify nuember: ",GetLastError());
            error = GetLastError();
           }
         else
            Apply = true;
        }
      else
         Apply = true;
     }
   else
      Apply = true;

   return Apply;
  }
//+------------------------------------------------------------------+


//+------------------------------------------------------------------+
//|Number Orders and Positions                                       |
//+------------------------------------------------------------------+
int Number_Orders(int magic_number)
  {
   int Number_Operations = 0;

   for(int i = 0; i<PositionsTotal(); i++)
      if(PositionSelectByTicket(PositionGetTicket(i)) && PositionGetInteger(POSITION_MAGIC) == magic_number)
         Number_Operations++;

   for(int i = 0; i<OrdersTotal(); i++)
      if(OrderGetTicket(i) && OrderGetInteger(ORDER_MAGIC) == magic_number)
         Number_Operations++;

   return Number_Operations;
  }
//+------------------------------------------------------------------+


//+------------------------------------------------------------------+
//|Number Positions                                                  |
//+------------------------------------------------------------------+
int Number_Positions(int magic_number)
  {
   int Number_Operations = 0;

   for(int i = 0; i<PositionsTotal(); i++)
      if(PositionSelectByTicket(PositionGetTicket(i)) && PositionGetInteger(POSITION_MAGIC) == magic_number)
         Number_Operations++;

   return Number_Operations;
  }
//+------------------------------------------------------------------+


//+------------------------------------------------------------------+
//|Number Positions  Buy                                             |
//+------------------------------------------------------------------+
int Number_Positions_Buy(int magic_number)
  {
   int Number_Operations = 0;

   for(int i = 0; i<PositionsTotal(); i++)
      if(PositionSelectByTicket(PositionGetTicket(i)) && PositionGetInteger(POSITION_MAGIC) == magic_number && (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_BUY)
         Number_Operations++;

   return Number_Operations;
  }
//+------------------------------------------------------------------+



//+------------------------------------------------------------------+
//|Number Positions Sell                                             |
//+------------------------------------------------------------------+
int Number_Positions_Sell(int magic_number)
  {
   int Number_Operations = 0;

   for(int i = 0; i<PositionsTotal(); i++)
      if(PositionSelectByTicket(PositionGetTicket(i)) && PositionGetInteger(POSITION_MAGIC) == magic_number && (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_SELL)
         Number_Operations++;

   return Number_Operations;
  }
//+------------------------------------------------------------------+


//+------------------------------------------------------------------+
//|Number Rectabgles                                                 |
//+------------------------------------------------------------------+
int Number_Rectangles()
  {
   int Num_Rectangles = 0;
   for(int i=0; i < ObjectsTotal(0,0,OBJ_RECTANGLE); i++)
      Num_Rectangles++;

   return Num_Rectangles;
  }
//+------------------------------------------------------------------+


//+------------------------------------------------------------------+
//|Number Orders and Positions                                       |
//+------------------------------------------------------------------+
double Profit(int magic_number)
  {
   double profit = 0;

   for(int i = 0; i<PositionsTotal(); i++)
      if(PositionSelectByTicket(PositionGetTicket(i)) && PositionGetInteger(POSITION_MAGIC) == magic_number)
         profit = profit + PositionGetDouble(POSITION_PROFIT);

   return profit;
  }
//+------------------------------------------------------------------+
