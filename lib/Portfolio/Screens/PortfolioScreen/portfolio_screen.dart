import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:tradingapp/GetApiService/apiservices.dart';
import 'package:tradingapp/Position/Screens/PositionScreen/position_screen.dart';
import 'package:tradingapp/Sockets/market_feed_scoket.dart';
import 'package:tradingapp/Position/Models/TradeOrderModel/tradeOrder_model.dart';
import 'package:tradingapp/Utils/exchangeConverter.dart';

class PortfolioScreen extends StatefulWidget {
  const PortfolioScreen({super.key});

  @override
  State<PortfolioScreen> createState() => _PortfolioScreenState();
}

class _PortfolioScreenState extends State<PortfolioScreen> {
  double totalInvestedValue = 0.0;
  double overallGain = 0.0;
  double mainBalance = 0.0;
  double todaysGain = 0.0;
  bool isSorted = false;
  List<Positions>? _positions;
  List<String> isAToZorZToA = [];
  List<String> isLowToHighOrHighToLow = [];
  List<String> daysPLIsLowToHighOrHighToLow = [];
  List<String> overAllPLIsLowToHighOrHighToLow = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Holdings'),
        actions: [
          IconButton(
              onPressed: () {},
              icon: Icon(
                Icons.search_rounded,
                color: Colors.black,
              )),
          IconButton(
              onPressed: () {
                _showFilterBottomSheet(context);
              },
              icon: Icon(
                Icons.filter_list_alt,
                color: Colors.black,
              )),
          // IconButton(
          //     onPressed: () async {
          //       var token = await getToken();
          //       print(token);
          //     },
          //     icon: Icon(Icons.abc_rounded))
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(10),
              height: 130,
              decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.blue.shade100.withOpacity(0.1),
                      Colors.blueGrey.shade700.withOpacity(0.4),
                    ],
                  ),
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(10)),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                      child: Text(
                    "₹${mainBalance.toStringAsFixed(2)}",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  )),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        overallGain.toString().startsWith('-')
                            ? Icons.arrow_downward
                            : Icons.arrow_upward,
                        color: overallGain.toString().startsWith('-')
                            ? Colors.red
                            : Colors.green,
                        size: 15,
                      ),
                      Text("Overall Gain"),
                      SizedBox(
                        width: 10,
                      ),
                      Text(
                        "₹${overallGain.toStringAsFixed(2)}",
                        style: TextStyle(
                            color: overallGain.toString().startsWith('-')
                                ? Colors.red
                                : Colors.green),
                      ),
                      SizedBox(
                        width: 10,
                      ),
                      Text(
                        "(${(totalInvestedValue != 0 ? (overallGain / totalInvestedValue) * 100 : 0).toStringAsFixed(2)}%)",
                      ),
                    ],
                  ),
                  SizedBox(
                    height: 10,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Invested Value"),
                          SizedBox(
                            width: 10,
                          ),
                          Text(
                            "₹${totalInvestedValue.toStringAsFixed(2)}",
                            style: TextStyle(color: Colors.black),
                          ),
                        ],
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Icon(
                                todaysGain.toString().startsWith('-')
                                    ? Icons.arrow_downward
                                    : Icons.arrow_upward,
                                color: todaysGain.toString().startsWith('-')
                                    ? Colors.red
                                    : Colors.green,
                                size: 16,
                              ),
                              Text("Today's Gain")
                            ],
                          ),
                          Row(
                            children: [
                              Text(
                                "₹${todaysGain.toStringAsFixed(2)}",
                                style: TextStyle(
                                    color: todaysGain.toString().startsWith('-')
                                        ? Colors.red
                                        : Colors.green),
                              ),
                              Text(
                                  "(${(totalInvestedValue != 0 ? (todaysGain / totalInvestedValue) * 100 : 0).toStringAsFixed(2)}%)"),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                child: ChangeNotifierProvider(
                  create: (context) => PositionProvider()..getPosition(),
                  child: Consumer<PositionProvider>(
                    builder: (context, positionProvider, child) {
                      if (positionProvider.positions == null) {
                        return Center(child: CircularProgressIndicator());
                      } else if (positionProvider.positions!.isEmpty) {
                        return Center(
                          child: Text(
                            "You have no positions. Place an order to open a new position",
                            textAlign: TextAlign.center,
                          ),
                        );
                      } else {
                        if (positionProvider.positions != null &&
                            positionProvider.positions!.isNotEmpty) {
                          totalInvestedValue = 0.0;
                          overallGain = 0.0;
                          todaysGain = 0.0;

                          for (var position in positionProvider.positions!) {
                            var exchangeSegment = position.exchangeSegment;
                            var exchangeInstrumentID =
                                position.exchangeInstrumentId;
                            ApiService().MarketInstrumentSubscribe(
                              ExchangeConverter()
                                  .getExchangeSegmentNumber(exchangeSegment)
                                  .toString(),
                              exchangeInstrumentID.toString(),
                            );

                            double investedValue = (position.quantity ?? 0.0) *
                                double.parse(
                                    position.buyAveragePrice.toString());

                            final marketData = context
                                .read<MarketFeedSocket>()
                                .getDataById(
                                    int.parse(exchangeInstrumentID.toString()));
                            var lastTradedPrice = marketData?.price ?? 0.0;

                            double previousClosePrice = double.tryParse(
                                    marketData?.close.toString() ??
                                        lastTradedPrice.toString()) ??
                                0.0;

                            double lastTradedPriceDouble = lastTradedPrice
                                    is double
                                ? lastTradedPrice
                                : double.tryParse(lastTradedPrice.toString()) ??
                                    0.0;

                            double lastTradedPrice1 = double.tryParse(
                                    marketData?.price.toString() ?? '0') ??
                                0.0;

                            double totalBenefits = (lastTradedPriceDouble -
                                    double.parse(
                                        position.buyAveragePrice.toString())) *
                                (position.quantity ?? 0.0);

                            double todaysPositionGain =
                                (lastTradedPrice1 - previousClosePrice) *
                                    (position.quantity ?? 0.0);
                            todaysGain += todaysPositionGain;

                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              setState(() {
                                overallGain += totalBenefits;
                                totalInvestedValue += investedValue;
                                mainBalance = overallGain + totalInvestedValue;
                              });
                            });
                          }
                        }
                        return Consumer<MarketFeedSocket>(
                          builder: (context, marketFeedSocket, child) {
                            return ListView.builder(
                              shrinkWrap: true,
                              physics: BouncingScrollPhysics(),
                              itemCount: isSorted == true
                                  ? _positions?.length
                                  : positionProvider.positions!.length,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 8.0),
                              itemBuilder: (context, index) {
                                var position = isSorted == true
                                    ? _positions![index]
                                    : positionProvider.positions![index];

                                var quantity = position.quantity;
                                var orderAvgLastTradedPrice =
                                    position.actualBuyAveragePrice;
                                var exchangeSegment = position.exchangeSegment;
                                var exchangeInstrumentID =
                                    position.exchangeInstrumentId;
                                final marketData = marketFeedSocket.getDataById(
                                    int.parse(exchangeInstrumentID.toString()));
                                var lastTradedPrice =
                                    marketData?.price.toString() ??
                                        'Loading...';
                                double? totalBenefits;
                                if (lastTradedPrice != 'Loading...') {
                                  totalBenefits =
                                      (double.parse(lastTradedPrice) -
                                              double.parse(position
                                                  .buyAveragePrice
                                                  .toString())) *
                                          (quantity);
                                }

                                // double todaysPositionGain = (lastTradedPrice - previousClosePrice) *
                                //     quantity;
                                //
                                // double investedValue = quantity *
                                //     (position.buyAveragePrice ?? 0.0);

                                return Padding(
                                  padding: const EdgeInsets.all(5.0),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      boxShadow: [
                                        BoxShadow(
                                            color: Colors.grey,
                                            blurRadius: 0.5,
                                            spreadRadius: 0.05,
                                            offset: Offset(0, 1))
                                      ],
                                      color: Colors.white,
                                      shape: BoxShape.rectangle,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Column(
                                        children: [
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  position.tradingSymbol,
                                                  style: TextStyle(
                                                      fontSize: 13,
                                                      fontWeight:
                                                          FontWeight.w600),
                                                ),
                                              ),
                                              Text(
                                                totalBenefits != null
                                                    ? totalBenefits
                                                        .toStringAsFixed(2)
                                                    : 'Loading...',
                                                style: TextStyle(
                                                    color: totalBenefits
                                                            .toString()
                                                            .startsWith('-')
                                                        ? Colors.red
                                                        : Colors.green),
                                              ),
                                            ],
                                          ),
                                          SizedBox(
                                            height: 2,
                                          ),
                                          Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Row(
                                                  children: [
                                                    SizedBox(
                                                      width: 10,
                                                    ),
                                                    Text("DEL"),
                                                  ],
                                                ),
                                                Row(
                                                  children: [
                                                    Text(
                                                      marketData != null
                                                          ? marketData.price
                                                              .toString()
                                                          : 'Loading...',
                                                      style: TextStyle(
                                                          color: marketData !=
                                                                  null
                                                              ? (marketData
                                                                      .price
                                                                      .toString()
                                                                      .startsWith(
                                                                          '-')
                                                                  ? Colors.red
                                                                  : Colors
                                                                      .green)
                                                              : Colors.black),
                                                    ),
                                                    Text(
                                                        '(${marketData != null ? marketData.percentChange.toString() : 'Loading...'}%)'),
                                                  ],
                                                )
                                              ]),
                                          SizedBox(
                                            height: 2,
                                          ),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Row(
                                                children: [
                                                  Text(
                                                    // "Qty: ${positionProvider.positions![index].quantity.toString()}",
                                                    "Qty: ${position.quantity.toString()}",
                                                    style: TextStyle(
                                                        fontSize: 15,
                                                        fontWeight:
                                                            FontWeight.w600),
                                                  ),
                                                  SizedBox(
                                                    width: 10,
                                                  ),
                                                  // Text(positionProvider.positions![index].exchangeSegment.toString())
                                                  Text(position.exchangeSegment
                                                      .toString())
                                                ],
                                              ),
                                              Text(
                                                // "Avg: ${positionProvider.positions![index].buyAveragePrice.toStringAsFixed(2)}",
                                                "Avg: ${position.buyAveragePrice.toStringAsFixed(2)}",
                                                style: TextStyle(),
                                              ),
                                            ],
                                          ),
                                          SizedBox(
                                            height: 2,
                                          ),
                                          // Display Invested Value
                                          // Row(
                                          //   mainAxisAlignment:
                                          //   MainAxisAlignment.spaceBetween,
                                          //   children: [
                                          //     Text(
                                          //       "Invested: ₹${investedValue.toStringAsFixed(2)}",
                                          //       style: TextStyle(
                                          //           fontSize: 15,
                                          //           fontWeight: FontWeight.w600),
                                          //     ),
                                          //   ],
                                          // ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        );
                      }
                    },
                  ),
                ),
              ),
            ),
            SizedBox(
              height: 100,
            ),
          ],
        ),
      ),
    );
  }

  void _showFilterBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      builder: (BuildContext context) {
        return ChangeNotifierProvider<PositionProvider>(
          create: (context) => PositionProvider()..getPosition(),
          child: Consumer<PositionProvider>(
            builder: (context, value, child) {
              return StatefulBuilder(
                builder: (BuildContext context, StateSetter setState) {
                  return LayoutBuilder(
                    builder: (context, constraints) {
                      double contentHeight = 600;
                      return Container(
                        padding: EdgeInsets.all(16.0),
                        constraints: BoxConstraints(
                          maxHeight: contentHeight > constraints.maxHeight
                              ? constraints.maxHeight
                              : contentHeight,
                        ),
                        child: contentHeight > constraints.maxHeight
                            ? SingleChildScrollView(
                                child: _buildBottomSheetContent(
                                    context, value, setState),
                              )
                            : _buildBottomSheetContent(
                                context, value, setState),
                      );
                    },
                  );
                },
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildBottomSheetContent(
      BuildContext context, PositionProvider value, StateSetter setState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Sort & Filter',
                style: TextStyle(fontSize: 27, fontWeight: FontWeight.bold)),
            Spacer(),
            InkWell(
              onTap: () {
                if (isAToZorZToA.contains('alphabeticalAZ')) {
                  setState(() {
                    // isSorted = true;
                    // _positions = value.sortPositionsByAlphabet(true, value.positions?.toList());
                  });
                }
                if (isAToZorZToA.contains('alphabeticalZA')) {
                  setState(() {
                    // isSorted = true;
                    // _positions = value.sortPositionsByAlphabet(false, value.positions?.toList());
                  });
                }
                if (isLowToHighOrHighToLow.contains('LowToHigh')) {
                  setState(() {
                    isSorted = true;
                    _positions = value.sortByCMV(true, value.positions?.toList());
                  });
                }
                if (isLowToHighOrHighToLow.contains('HighToLow')) {
                  setState(
                    () {
                      isSorted = true;
                      _positions = value.sortByCMV(false, value.positions?.toList(),
                      );
                    },
                  );
                }
                Navigator.pop(context);
              },
              child: Container(
                height: 35,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(05),
                  border: Border.all(color: Colors.black),
                  color: Colors.white,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10.0),
                  child: Center(
                    child: Text(
                      "Apply",
                      style: GoogleFonts.inter(
                        color: Colors.black,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(
              width: 10,
            ),
            InkWell(
              onTap: () {
                setState(() {
                  isAToZorZToA.clear();
                  isLowToHighOrHighToLow.clear();
                  daysPLIsLowToHighOrHighToLow.clear();
                  overAllPLIsLowToHighOrHighToLow.clear();
                });
              },
              child: Container(
                height: 35,
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(05),
                    border: Border.all(color: Colors.black),
                    color: Colors.white),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10.0),
                  child: Center(
                    child: Text(
                      "Clear",
                      style: GoogleFonts.inter(
                        color: Colors.black,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 10),
        Text('Alphabetically',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w400)),
        SizedBox(height: 10),
        Row(
          children: [
            // ElevatedButton(
            //   onPressed: () {
            //     setState(() {
            //       if (selectedOptions.contains('alphabeticalAZ')) {
            //         selectedOptions.remove('alphabeticalAZ');
            //       } else {
            //         selectedOptions.add('alphabeticalAZ');
            //       }
            //     });
            //     // setState(() {
            //     //   isSorted = true;
            //     //   _positions = value.sortPositionsByAlphabet(true, value.positions?.toList());
            //     // });
            //     // Navigator.pop(context);
            //   },
            //   style: ButtonStyle(
            //     backgroundColor: selectedOptions.contains('alphabeticalAZ')
            //         ? MaterialStateProperty.all(Colors.blue)
            //         : MaterialStateProperty.all(Colors.grey),
            //   ),
            //   child: Text('A-Z'),
            // ),
            InkWell(
              onTap: () {
                setState(() {
                  isAToZorZToA.clear();
                  isAToZorZToA.add('alphabeticalAZ');
                  isSorted = true;
                  _positions = value.sortPositionsByAlphabet(
                      true, value.positions?.toList());
                });
              },
              child: Container(
                height: 30,
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(05),
                    color: isAToZorZToA.contains('alphabeticalAZ')
                        ? Colors.grey[200]
                        : Colors.white,
                    border: Border.all(color: Colors.black)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15.0),
                  child: Center(
                    child: Text(
                      'A-Z',
                      style:
                          GoogleFonts.inter(color: Colors.black, fontSize: 13),
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(width: 10),
            InkWell(
              onTap: () {
                setState(() {
                  isAToZorZToA.clear();
                  isAToZorZToA.add('alphabeticalZA');
                  isSorted = true;
                  _positions = value.sortPositionsByAlphabet(
                      false, value.positions?.toList());
                });
              },
              child: Container(
                height: 30,
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(05),
                    color: isAToZorZToA.contains('alphabeticalZA')
                        ? Colors.grey[200]
                        : Colors.white,
                    border: Border.all(color: Colors.black)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15.0),
                  child: Center(
                    child: Text(
                      'Z-A',
                      style:
                          GoogleFonts.inter(color: Colors.black, fontSize: 13),
                    ),
                  ),
                ),
              ),
            ),
            // ElevatedButton(
            //   onPressed: () {
            //     // setState(() {
            //     //   isSorted = true;
            //     //   _positions = value.sortPositionsByAlphabet(false, value.positions?.toList());
            //     // });
            //     // Navigator.pop(context);
            //     setState(() {
            //       if (selectedOptions.contains('alphabeticalZA')) {
            //         selectedOptions.remove('alphabeticalZA');
            //       } else {
            //         selectedOptions.add('alphabeticalZA');
            //       }
            //     });
            //   },
            //   style: ButtonStyle(
            //     backgroundColor: selectedOptions.contains('alphabeticalZA')
            //         ? MaterialStateProperty.all(Colors.blue)
            //         : MaterialStateProperty.all(Colors.grey),
            //   ),
            //   child: Text('Z-A'),
            // ),
          ],
        ),
        SizedBox(height: 20),
        Text('Current Market Value (CMV)',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w400)),
        SizedBox(height: 10),
        Row(
          children: [
            InkWell(
              onTap: () {
                setState(() {
                  isLowToHighOrHighToLow.clear();
                  isLowToHighOrHighToLow.add('LowToHigh');
                });
              },
              child: Container(
                height: 30,
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(05),
                    color: isLowToHighOrHighToLow.contains('LowToHigh')
                        ? Colors.grey[200]
                        : Colors.white,
                    border: Border.all(color: Colors.black)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15.0),
                  child: Center(
                    child: Text(
                      'Low to High',
                      style:
                          GoogleFonts.inter(color: Colors.black, fontSize: 13),
                    ),
                  ),
                ),
              ),
            ),
            // ElevatedButton(
            //   onPressed: () {
            //     setState(() {
            //       isSorted = true;
            //       _positions = value.sortByCMV(true, value.positions?.toList());
            //     });
            //     Navigator.pop(context);
            //   },
            //   child: Text('Low to High'),
            // ),
            SizedBox(width: 10),
            InkWell(
              onTap: () {
                setState(() {
                  isLowToHighOrHighToLow.clear();
                  isLowToHighOrHighToLow.add('HighToLow');
                });
              },
              child: Container(
                height: 30,
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(05),
                    color: isLowToHighOrHighToLow.contains('HighToLow')
                        ? Colors.grey[200]
                        : Colors.white,
                    border: Border.all(color: Colors.black)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15.0),
                  child: Center(
                    child: Text(
                      'High to Low',
                      style:
                          GoogleFonts.inter(color: Colors.black, fontSize: 13),
                    ),
                  ),
                ),
              ),
            ),
            // ElevatedButton(
            //   onPressed: () {
            //     setState(() {
            //       isSorted = true;
            //       _positions = value.sortByCMV(false, value.positions?.toList());
            //     });
            //     Navigator.pop(context);
            //   },
            //   child: Text('High to Low'),
            // ),
          ],
        ),
        SizedBox(height: 20), // Space between sections
        Text("Day's P/L",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w400)),
        SizedBox(height: 10),
        Row(
          children: [
            InkWell(
              onTap: () {
                setState(() {
                  daysPLIsLowToHighOrHighToLow.clear();
                  daysPLIsLowToHighOrHighToLow.add('DaysLowToHigh');
                });
              },
              child: Container(
                height: 30,
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(05),
                    color:
                        daysPLIsLowToHighOrHighToLow.contains('DaysLowToHigh')
                            ? Colors.grey[200]
                            : Colors.white,
                    border: Border.all(color: Colors.black)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15.0),
                  child: Center(
                    child: Text(
                      'Low to High',
                      style:
                          GoogleFonts.inter(color: Colors.black, fontSize: 13),
                    ),
                  ),
                ),
              ),
            ),
            // ElevatedButton(
            //   onPressed: () {
            //     setState(() {
            //       isSorted = true;
            //       // _positions = value.sortPositionsByDaysPL(true, value.positions?.toList());
            //     });
            //     Navigator.pop(context);
            //   },
            //   child: Text('Low to High'),
            // ),
            SizedBox(width: 10),
            InkWell(
              onTap: () {
                setState(() {
                  daysPLIsLowToHighOrHighToLow.clear();
                  daysPLIsLowToHighOrHighToLow.add('DaysHighToLow');
                });
              },
              child: Container(
                height: 30,
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(05),
                    color:
                        daysPLIsLowToHighOrHighToLow.contains('DaysHighToLow')
                            ? Colors.grey[200]
                            : Colors.white,
                    border: Border.all(color: Colors.black)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15.0),
                  child: Center(
                    child: Text(
                      'High to Low',
                      style:
                          GoogleFonts.inter(color: Colors.black, fontSize: 13),
                    ),
                  ),
                ),
              ),
            ),
            // ElevatedButton(
            //   onPressed: () {
            //     setState(() {
            //       isSorted = true;
            //       // _positions = value.sortPositionsByDaysPL(false, value.positions?.toList());
            //     });
            //     Navigator.pop(context);
            //   },
            //   child: Text('High to Low'),
            // ),
          ],
        ),
        SizedBox(height: 20), // Space between sections
        Text('Overall P/L',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w400)),
        SizedBox(height: 10),
        Row(
          children: [
            // ElevatedButton(
            //   onPressed: () {
            //     setState(() {
            //       isSorted = true;
            //       // _positions = value.sortPositionsByOverallPL(true, value.positions?.toList());
            //     });
            //     Navigator.pop(context);
            //   },
            //   child: Text('Low to High'),
            // ),
            InkWell(
              onTap: () {
                setState(() {
                  overAllPLIsLowToHighOrHighToLow.clear();
                  overAllPLIsLowToHighOrHighToLow.add('OverAllLowToHigh');
                });
              },
              child: Container(
                height: 30,
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(05),
                    color: overAllPLIsLowToHighOrHighToLow
                            .contains('OverAllLowToHigh')
                        ? Colors.grey[200]
                        : Colors.white,
                    border: Border.all(color: Colors.black)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15.0),
                  child: Center(
                    child: Text(
                      'Low to High',
                      style:
                          GoogleFonts.inter(color: Colors.black, fontSize: 13),
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(width: 10),
            InkWell(
              onTap: () {
                setState(() {
                  overAllPLIsLowToHighOrHighToLow.clear();
                  overAllPLIsLowToHighOrHighToLow.add('OverAllHighToLow');
                });
              },
              child: Container(
                height: 30,
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(05),
                    color: overAllPLIsLowToHighOrHighToLow
                            .contains('OverAllHighToLow')
                        ? Colors.grey[200]
                        : Colors.white,
                    border: Border.all(color: Colors.black)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15.0),
                  child: Center(
                    child: Text(
                      'High to Low',
                      style:
                          GoogleFonts.inter(color: Colors.black, fontSize: 13),
                    ),
                  ),
                ),
              ),
            ),
            // ElevatedButton(
            //   onPressed: () {
            //     setState(() {
            //       isSorted = true;
            //       // _positions = value.sortPositionsByOverallPL(false, value.positions?.toList());
            //     });
            //     Navigator.pop(context);
            //   },
            //   child: Text('High to Low'),
            // ),
          ],
        ),
      ],
    );
  }
}

class HoldingProvider with ChangeNotifier {
  List<Holdings>? _holdingsvalues;

  String searchTerm = '';

  List<Holdings>? get holdingValues => _holdingsvalues;

  Future<void> GetHoldings() async {
    final apiService = ApiService();
    final response =
        await apiService.GetHoldings(); // Call your API function here
    _holdingsvalues = Holdings.fromJsonList(response);

    notifyListeners();
  }

  void setSearchTerm(String term) {
    searchTerm = term;
    notifyListeners();
  }
}

class HoldingsPortfolioScreen extends StatefulWidget {
  @override
  _PHoldingsPortfolioScreenState createState() =>
      _PHoldingsPortfolioScreenState();
}

class _PHoldingsPortfolioScreenState extends State<HoldingsPortfolioScreen> {
  String search = '';
  List<Holdings> filteredPositions = [];

  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => PositionProvider()..getPosition(),
      child: Consumer<PositionProvider>(
        builder: (context, positionProvider, child) {
          if (positionProvider.positions == null) {
            return Center(child: CircularProgressIndicator());
          } else if (positionProvider.positions!.isEmpty) {
            return Center(
                child: Text(
              "You have no positions. Place an order to open a new position",
              textAlign: TextAlign.center,
            ));
          } else {
            if (positionProvider.positions != null &&
                positionProvider.positions!.isNotEmpty) {
              for (var position in positionProvider.positions!) {
                var exchangeSegment = position.exchangeSegment;
                var exchangeInstrumentID = position.exchangeInstrumentId;
                ApiService().MarketInstrumentSubscribe(
                    ExchangeConverter()
                        .getExchangeSegmentNumber(exchangeSegment)
                        .toString(),
                    exchangeInstrumentID.toString());
              }
            }
            return Consumer<MarketFeedSocket>(
                builder: (context, marketFeedSocket, child) {
              return ListView.builder(
                shrinkWrap: true,
                itemCount: positionProvider.positions!.length,
                padding:
                    const EdgeInsets.symmetric(vertical: 8.0), // Add this line
                itemBuilder: (context, index) {
                  var position = positionProvider.positions![index];

                  var quentity = position.quantity;
                  var orderAvglastTradedPrice = position.actualBuyAveragePrice;
                  var exchangeSegment = position.exchangeSegment;
                  var exchangeInstrumentID = position.exchangeInstrumentId;
                  final marketData = marketFeedSocket
                      .getDataById(int.parse(exchangeInstrumentID.toString()));
                  var lastTradedPrice =
                      marketData?.price.toString() ?? 'Loading...';
                  double? TotalBenifits;
                  if (lastTradedPrice != 'Loading...') {
                    TotalBenifits = (double.parse(lastTradedPrice) -
                            double.parse(
                                position.buyAveragePrice.toString() ?? '0')) *
                        (quentity ?? 0.0);
                  }
                  // print(positionProvider.positions![index].exchangeInstrumentID);
                  return Padding(
                    padding: const EdgeInsets.all(5.0),
                    child: Container(
                      decoration: BoxDecoration(
                        boxShadow: [
                          BoxShadow(
                              color: Colors.grey,
                              blurRadius: 0.5,
                              spreadRadius: 0.05,
                              offset: Offset(0, 1))
                        ],
                        color: Colors.white,
                        shape: BoxShape.rectangle,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    positionProvider
                                        .positions![index].tradingSymbol,
                                    style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600),
                                  ),
                                ),
                                Text(
                                  TotalBenifits != null
                                      ? TotalBenifits.toStringAsFixed(2)
                                      : 'Loading...',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ],
                            ),
                            SizedBox(
                              height: 2,
                            ),
                            Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      // Text(
                                      //   positionProvider
                                      //       .positions![index].orderSide,
                                      //   style: TextStyle(
                                      //     color: positionProvider
                                      //                 .positions![index]
                                      //                 .orderSide
                                      //                 .toString() ==
                                      //             'BUY'
                                      //         ? Colors.green
                                      //         : Colors.red,
                                      //   ),
                                      // ),
                                      SizedBox(
                                        width: 10,
                                      ),
                                      Text("DEL"),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      Text(
                                        marketData != null
                                            ? marketData.price.toString()
                                            : 'Loading...',
                                        style: TextStyle(color: Colors.red),
                                      ),
                                      Text(
                                          '(${marketData != null ? marketData.percentChange.toString() : 'Loading...'}%)'),
                                    ],
                                  )
                                ]),
                            SizedBox(
                              height: 2,
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      "Qty: ${positionProvider.positions![index].quantity.toString()}",
                                      style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600),
                                    ),
                                    SizedBox(
                                      width: 10,
                                    ),
                                    Text(positionProvider
                                        .positions![index].exchangeSegment
                                        .toString())
                                  ],
                                ),
                                Text(
                                  "Avg: ${positionProvider.positions![index].buyAveragePrice.toStringAsFixed(2)}",
                                  style: TextStyle(),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            });
          }
        },
      ),
    );
  }
}
