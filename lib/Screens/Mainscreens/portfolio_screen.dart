import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:tradingapp/Authentication/GetApiService/apiservices.dart';
import 'package:tradingapp/Sockets/market_feed_scoket.dart';
import 'package:tradingapp/model/tradeOrder_model.dart';

class PortfolioScreen extends StatefulWidget {
  const PortfolioScreen({super.key});

  @override
  State<PortfolioScreen> createState() => _PortfolioScreenState();
}

class _PortfolioScreenState extends State<PortfolioScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Portfolio')),
      body: SingleChildScrollView(
        child: Container(
          padding: EdgeInsets.all(20),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(10),
                height: 130,
                decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(10)),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                        child: Text(
                      "₹45678",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    )),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.arrow_upward,
                          color: Colors.green,
                          size: 16,
                        ),
                        Text("Overall Gain"),
                        SizedBox(
                          width: 10,
                        ),
                        Text(
                          "₹345678",
                          style: TextStyle(color: Colors.green),
                        ),
                        SizedBox(
                          width: 10,
                        ),
                        Text("+(10.42%)")
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
                              "₹345678",
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
                                  Icons.arrow_upward,
                                  color: Colors.green,
                                  size: 16,
                                ),
                                Text("Today's Gain")
                              ],
                            ),
                            Row(
                              children: [
                                Text(
                                  "₹345678",
                                  style: TextStyle(color: Colors.black),
                                ),
                                Text("+(10.42%)"),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              FutureBuilder(
                  future: ApiService().GetHoldings(),
                  builder: (BuildContext context, AsyncSnapshot snapshot) {
                    var data = snapshot.data;
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return CircularProgressIndicator();
                    }
                    return Container(
                      height: 500,
                      child: ListView.builder(
          
                        itemBuilder: (BuildContext context, int index) {
                          data = data[index];
                          return ListTile(
                            title: Text('Item $index'),
                            subtitle: Text('₹345678'),
                          );
                        },
                        itemCount: data.length,
                      ),
                    );
                  }),
           HoldingsPortfolioScreen() ],
          ),
        ),
      ),
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
  @override
  List<Holdings> filteredPositions = [];
  int getExchangeSegmentNumber(String exchangeSegment) {
    switch (exchangeSegment) {
      case 'NSECM':
        return 1;
      case 'NSEFO':
        return 2;
      case 'NSECD':
        return 3;
      case 'BSECM':
        return 11;
      case 'BSEFO':
        return 12;
      case 'BSECD':
        return 13;
      default:
        return 0; // Return 0 or any other number for 'Unknown'
    }
  }

  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => HoldingProvider()..GetHoldings(),
      child: Consumer<HoldingProvider>(
        builder: (context, HoldingProvider, child) {


          if (HoldingProvider.holdingValues == null) {
            return Center(child: CircularProgressIndicator());
          } else if (HoldingProvider.holdingValues!.isEmpty) {
            return Center(
                child: Text(
              "You have no positions. Place an order to open a new position",
              textAlign: TextAlign.center,
            ));
          } else {
            if (HoldingProvider.holdingValues != null &&
                HoldingProvider.holdingValues!.isNotEmpty) {
              for (var holdingValues in HoldingProvider.holdingValues!) {
                var exchangeSegment = holdingValues.exchangeNSEInstrumentId;
                var exchangeInstrumentID = holdingValues.exchangeBSEInstrumentId;

                ;
                ApiService().MarketInstrumentSubscribe(
                    getExchangeSegmentNumber(exchangeSegment).toString(),
                    exchangeInstrumentID.toString());
              }
            }
            
            return Consumer<MarketFeedSocket>(
                builder: (context, marketFeedSocket, child) {
              return ListView.builder(
                shrinkWrap: true,
                itemCount: HoldingProvider.holdingValues!.length,
                padding:
                    const EdgeInsets.symmetric(vertical: 8.0), // Add this line
                itemBuilder: (context, index) {
                  var holdings = HoldingProvider.holdingValues![index];

                  var quentity = holdings.holdingQuantity.toString();
                  var orderAvglastTradedPrice = holdings.buyAvgPrice;
                  var exchangeSegment = holdings.exchangeNSEInstrumentId;
                  var exchangeInstrumentID = holdings.exchangeNSEInstrumentId;
                  final marketData = marketFeedSocket
                      .getDataById(int.parse(exchangeInstrumentID.toString()));
                  var lastTradedPrice =
                      marketData?.price.toString() ?? 'Loading...';
                  double? TotalBenifits;
                  if (lastTradedPrice != 'Loading...') {
                    TotalBenifits = (double.parse(lastTradedPrice) -
                            double.parse(
                                holdings.buyAvgPrice.toString() ?? '0')) *
                        (double.parse(quentity));
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
                                    holdings
                                        .exchangeNSEInstrumentId
                                        .toString(),
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
                                      "Qty: ${holdings.holdingQuantity.toString()}",
                                      style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600),
                                    ),
                                    SizedBox(
                                      width: 10,
                                    ),
                                    Text(holdings
                                        .exchangeNSEInstrumentId
                                        .toString())
                                  ],
                                ),
                                Text(
                                  "Avg: ${holdings.buyAvgPrice.toString()}",
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
