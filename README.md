# Algorithmic-Trading-System-for-MetaTrader-5

MA21 Crossover EA is an automated Forex trading Expert Advisor (EA) developed in MQL5 for MetaTrader 5.

The strategy combines:

21 EMA crossover entry signals
50 EMA trend confirmation
Automated trade execution
Stop Loss and Take Profit management
Trailing Stop functionality
Position management using Magic Numbers

The objective is to reduce human intervention and execute trades systematically based on predefined technical rules.

Strategy Logic
Buy Conditions

A Buy trade is opened when:

Price crosses above the 21 EMA
21 EMA is above the 50 EMA
No existing Buy position is active
Sell Conditions

A Sell trade is opened when:

Price crosses below the 21 EMA
21 EMA is below the 50 EMA
No existing Sell position is active
Risk Management

The EA includes:

Fixed lot sizing
Stop Loss
Take Profit
Trailing Stop
Maximum open trade control
Automatic position closing on opposite signals
Features

✅ Fully Automated Trading

✅ EMA Trend Confirmation

✅ Buy/Sell Signal Detection

✅ Trailing Stop Management

✅ Magic Number Support

✅ Position Filtering

✅ New Candle Execution Logic

✅ MT5 Compatible

**Input Parameters
**Parameter	                Description

MA_Fast_Period	          Fast EMA Period (Default 21)

MA_Trend_Period	          Trend EMA Period (Default 50)

LotSize	                  Trade Lot Size

StopLoss_Pips            	Stop Loss Distance

TakeProfit_Pips          	Take Profit Distance

TrailingStop_Pips	        Trailing Stop Distance

MaxOpenTrades	            Maximum Simultaneous Trades

MagicNumber	              Unique Trade Identifier



Trading Workflow

Market Data
↓
EMA 21 Calculation
↓
EMA 50 Trend Confirmation
↓
Signal Generation
↓
Trade Execution
↓
Risk Management
↓
Trailing Stop Adjustment

Requirements
MetaTrader 5
MQL5 Compiler
Forex Broker Supporting MT5
Installation
Open MetaTrader 5.
Navigate to:

File → Open Data Folder

Copy the EA file into:

MQL5/Experts/

Restart MetaTrader 5.
Compile the EA using MetaEditor.
Attach the EA to a chart.
Enable Auto Trading.
Future Improvements
Multi-Timeframe Confirmation
ATR-Based Stop Loss
Dynamic Position Sizing
News Filter
Risk Percentage Calculation
Dashboard Interface
Machine Learning Trade Filtering
Author

Indra Kumar K

B.Tech Computer Science & Engineering

MetaTrader 5 Algorithmic Trading Project
