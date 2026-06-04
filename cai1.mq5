//+------------------------------------------------------------------+
//|                                              MA_CrossoverEA.mq5  |
//|                         MA21 Crossover + MA50 Trend Confirmation |
//+------------------------------------------------------------------+
#property copyright "MA Crossover EA"
#property version   "1.00"
#property strict

#include <Trade\Trade.mqh>

//--- Input Parameters
input group "=== Moving Average Settings ==="
input int    MA_Fast_Period  = 21;             // Fast MA Period (Signal)
input int    MA_Trend_Period = 50;             // Trend MA Period (Confirmation)
input ENUM_MA_METHOD  MA_Method = MODE_EMA;   // MA Method
input ENUM_APPLIED_PRICE MA_Price = PRICE_CLOSE; // Applied Price

input group "=== Trade Settings ==="
input double LotSize         = 0.1;           // Lot Size
input int    StopLoss_Pips   = 50;            // Stop Loss (pips)
input int    TakeProfit_Pips = 100;           // Take Profit (pips)
input int    Slippage        = 10;            // Max Slippage (points)
input ulong  MagicNumber     = 123456;        // Magic Number

input group "=== Risk Management ==="
input bool   UseTrailingStop = true;          // Use Trailing Stop
input int    TrailingStop_Pips = 30;          // Trailing Stop (pips)
input int    MaxOpenTrades   = 1;             // Max Open Trades at Once

//--- Global Variables
CTrade trade;
int    ma_fast_handle;
int    ma_trend_handle;
double ma_fast[];
double ma_trend[];
double point_value;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
   //--- Set trade object settings
   trade.SetExpertMagicNumber(MagicNumber);
   trade.SetDeviationInPoints(Slippage);
   trade.SetTypeFilling(ORDER_FILLING_FOK);

   //--- Create MA indicator handles
   ma_fast_handle  = iMA(_Symbol, PERIOD_CURRENT, MA_Fast_Period, 0, MA_Method, MA_Price);
   ma_trend_handle = iMA(_Symbol, PERIOD_CURRENT, MA_Trend_Period, 0, MA_Method, MA_Price);

   if(ma_fast_handle == INVALID_HANDLE || ma_trend_handle == INVALID_HANDLE)
   {
      Print("ERROR: Failed to create MA indicators!");
      return INIT_FAILED;
   }

   //--- Set array as series (index 0 = latest bar)
   ArraySetAsSeries(ma_fast, true);
   ArraySetAsSeries(ma_trend, true);

   //--- Calculate point value
   point_value = _Point;
   if(_Digits == 3 || _Digits == 5)
      point_value = _Point * 10;

   Print("MA Crossover EA initialized successfully.");
   Print("Fast MA: ", MA_Fast_Period, " | Trend MA: ", MA_Trend_Period);

   return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   IndicatorRelease(ma_fast_handle);
   IndicatorRelease(ma_trend_handle);
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
   //--- Only process on new bar
   static datetime last_bar_time = 0;
   datetime current_bar_time = iTime(_Symbol, PERIOD_CURRENT, 0);
   if(current_bar_time == last_bar_time)
   {
      //--- Still manage trailing stop on every tick
      if(UseTrailingStop) ManageTrailingStop();
      return;
   }
   last_bar_time = current_bar_time;

   //--- Copy MA values (need at least 3 bars: 0=current, 1=prev, 2=before prev)
   if(CopyBuffer(ma_fast_handle,  0, 0, 3, ma_fast)  < 3) return;
   if(CopyBuffer(ma_trend_handle, 0, 0, 3, ma_trend) < 3) return;

   //--- Get signal
   bool buy_signal  = CheckBuySignal();
   bool sell_signal = CheckSellSignal();

   //--- Execute trades
   if(buy_signal && CountOpenTrades(ORDER_TYPE_BUY) == 0)
   {
      CloseAllTrades(ORDER_TYPE_SELL); // Close any existing sell trades
      if(CountOpenTrades(ORDER_TYPE_BUY) < MaxOpenTrades)
         OpenBuyTrade();
   }
   else if(sell_signal && CountOpenTrades(ORDER_TYPE_SELL) == 0)
   {
      CloseAllTrades(ORDER_TYPE_BUY); // Close any existing buy trades
      if(CountOpenTrades(ORDER_TYPE_SELL) < MaxOpenTrades)
         OpenSellTrade();
   }
}

//+------------------------------------------------------------------+
//| Buy Signal: Price crosses ABOVE MA21 + MA21 > MA50 (uptrend)    |
//+------------------------------------------------------------------+
bool CheckBuySignal()
{
   double prev_close = iClose(_Symbol, PERIOD_CURRENT, 1); // Prev closed bar
   double prev_open  = iOpen(_Symbol,  PERIOD_CURRENT, 1);

   // MA21 Crossover: previous bar was below MA21, current closed bar is above
   bool crossover_up = (prev_open < ma_fast[1]) && (prev_close > ma_fast[1]);

   // Trend confirmation: MA21 is above MA50 (bullish trend)
   bool uptrend = (ma_fast[1] > ma_trend[1]);

   if(crossover_up && uptrend)
   {
      Print("BUY Signal detected | Close: ", prev_close,
            " | MA21: ", ma_fast[1], " | MA50: ", ma_trend[1]);
      return true;
   }
   return false;
}

//+------------------------------------------------------------------+
//| Sell Signal: Price crosses BELOW MA21 + MA21 < MA50 (downtrend) |
//+------------------------------------------------------------------+
bool CheckSellSignal()
{
   double prev_close = iClose(_Symbol, PERIOD_CURRENT, 1);
   double prev_open  = iOpen(_Symbol,  PERIOD_CURRENT, 1);

   // MA21 Crossover: previous bar was above MA21, current closed bar is below
   bool crossover_down = (prev_open > ma_fast[1]) && (prev_close < ma_fast[1]);

   // Trend confirmation: MA21 is below MA50 (bearish trend)
   bool downtrend = (ma_fast[1] < ma_trend[1]);

   if(crossover_down && downtrend)
   {
      Print("SELL Signal detected | Close: ", prev_close,
            " | MA21: ", ma_fast[1], " | MA50: ", ma_trend[1]);
      return true;
   }
   return false;
}

//+------------------------------------------------------------------+
//| Open Buy Trade                                                   |
//+------------------------------------------------------------------+
void OpenBuyTrade()
{
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double sl  = (StopLoss_Pips > 0)   ? ask - StopLoss_Pips * point_value   : 0;
   double tp  = (TakeProfit_Pips > 0) ? ask + TakeProfit_Pips * point_value : 0;

   sl = NormalizeDouble(sl, _Digits);
   tp = NormalizeDouble(tp, _Digits);

   if(trade.Buy(LotSize, _Symbol, ask, sl, tp, "MA Crossover BUY"))
      Print("BUY order opened | Price: ", ask, " | SL: ", sl, " | TP: ", tp);
   else
      Print("ERROR opening BUY: ", trade.ResultRetcodeDescription());
}

//+------------------------------------------------------------------+
//| Open Sell Trade                                                  |
//+------------------------------------------------------------------+
void OpenSellTrade()
{
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double sl  = (StopLoss_Pips > 0)   ? bid + StopLoss_Pips * point_value   : 0;
   double tp  = (TakeProfit_Pips > 0) ? bid - TakeProfit_Pips * point_value : 0;

   sl = NormalizeDouble(sl, _Digits);
   tp = NormalizeDouble(tp, _Digits);

   if(trade.Sell(LotSize, _Symbol, bid, sl, tp, "MA Crossover SELL"))
      Print("SELL order opened | Price: ", bid, " | SL: ", sl, " | TP: ", tp);
   else
      Print("ERROR opening SELL: ", trade.ResultRetcodeDescription());
}

//+------------------------------------------------------------------+
//| Trailing Stop Management                                         |
//+------------------------------------------------------------------+
void ManageTrailingStop()
{
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(!PositionSelectByTicket(ticket)) continue;
      if(PositionGetString(POSITION_SYMBOL) != _Symbol) continue;
      if(PositionGetInteger(POSITION_MAGIC) != MagicNumber) continue;

      long   pos_type   = PositionGetInteger(POSITION_TYPE);
      double pos_sl     = PositionGetDouble(POSITION_SL);
      double trail_dist = TrailingStop_Pips * point_value;

      if(pos_type == POSITION_TYPE_BUY)
      {
         double bid        = SymbolInfoDouble(_Symbol, SYMBOL_BID);
         double new_sl     = NormalizeDouble(bid - trail_dist, _Digits);
         if(new_sl > pos_sl + _Point)
            trade.PositionModify(ticket, new_sl, PositionGetDouble(POSITION_TP));
      }
      else if(pos_type == POSITION_TYPE_SELL)
      {
         double ask    = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
         double new_sl = NormalizeDouble(ask + trail_dist, _Digits);
         if(new_sl < pos_sl - _Point || pos_sl == 0)
            trade.PositionModify(ticket, new_sl, PositionGetDouble(POSITION_TP));
      }
   }
}

//+------------------------------------------------------------------+
//| Count open trades by type for this EA                           |
//+------------------------------------------------------------------+
int CountOpenTrades(ENUM_ORDER_TYPE order_type)
{
   int count = 0;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(!PositionSelectByTicket(ticket)) continue;
      if(PositionGetString(POSITION_SYMBOL) != _Symbol) continue;
      if(PositionGetInteger(POSITION_MAGIC) != MagicNumber) continue;
      if(PositionGetInteger(POSITION_TYPE) == order_type) count++;
   }
   return count;
}

//+------------------------------------------------------------------+
//| Close all trades of a given type                                |
//+------------------------------------------------------------------+
void CloseAllTrades(ENUM_ORDER_TYPE order_type)
{
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(!PositionSelectByTicket(ticket)) continue;
      if(PositionGetString(POSITION_SYMBOL) != _Symbol) continue;
      if(PositionGetInteger(POSITION_MAGIC) != MagicNumber) continue;
      if(PositionGetInteger(POSITION_TYPE) == order_type)
         trade.PositionClose(ticket);
   }
}
//+------------------------------------------------------------------+