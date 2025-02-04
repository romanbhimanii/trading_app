import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:tradingapp/Authentication/GetApiService/apiservices.dart';
import 'package:tradingapp/Screens/buy_sell_screen.dart';
import 'package:tradingapp/Screens/instrument_details_screen.dart';
import 'package:tradingapp/Screens/search_screen.dart';
import 'package:tradingapp/Authentication/auth_services.dart';
import 'package:tradingapp/Sockets/market_feed_scoket.dart';
import 'package:tradingapp/sqlite_database/dbhelper.dart';
import 'package:tradingapp/master/nscm_database.dart';
import 'package:tradingapp/master/nscm_provider.dart';

class MarketWatchScreen extends StatefulWidget {
  @override
  _MarketWatchScreenState createState() => _MarketWatchScreenState();
}

class _MarketWatchScreenState extends State<MarketWatchScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late TabController _tabController;
  List<Map<String, dynamic>> _watchlistItems = [];
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _watchlistItems.length, vsync: this);
    WidgetsBinding.instance.addObserver(this);
    initializeDatabase();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      initializeDatabase();
    }
  }

  Future<void> initializeDatabase() async {
    _watchlistItems = await DatabaseHelper.instance.fetchWatchlists();
    setState(() {
      _tabController =
          TabController(length: _watchlistItems.length, vsync: this);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SearchScreen(
                    onReturn: () => initializeDatabase(),
                  ),
                ),
              );
            },
            icon: Icon(Icons.search),
          ),
        ],
        title: Text('Watchlist'),
        bottom: _tabController != null
            ? TabBar(
                controller: _tabController,
                isScrollable: true,
                tabs: _watchlistItems
                    .map((item) => Tab(text: item['name'] as String))
                    .toList(),
              )
            : null,
      ),
      body: TabBarView(
        controller: _tabController,
        children: _watchlistItems
            .map(
              (item) => WatchlistTab(
                watchlistId: item['id'] as int,
              ),
            )
            .toList(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          String? itemName = await showDialog(
            context: context,
            builder: (BuildContext context) {
              return AddWatchlistDialog();
            },
          );
          initializeDatabase();

          if (itemName != null) {
            await DatabaseHelper.instance.addWatchlist(itemName);
            initializeDatabase();
          }
        },
        child: Icon(Icons.add),
      ),
    );
  }
}

class WatchlistTab extends StatefulWidget {
  final int watchlistId;

  const WatchlistTab({required this.watchlistId});

  @override
  _WatchlistTabState createState() => _WatchlistTabState();
}

class _WatchlistTabState extends State<WatchlistTab>
    with WidgetsBindingObserver {
  List<Map<String, dynamic>> _instruments = [];
  String close = "";
  late Timer _timer;
  bool _isReordering = false;
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
// void dispose() {
//     String exchangeSegments = _instruments.map((e) => e['exchangeSegment'].toString()).join(',');
//   String exchangeInstrumentIds = _instruments.map((e) => e['exchange_instrument_id'].toString()).join(',');
//     // Call your function here
//   ApiService().UnsubscribeMarketInstrument(exchangeSegments.toString(), exchangeInstrumentIds.toString());

//     super.dispose();
//   }
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    fetchInstruments();
    SubscribedmarketData();

    DatabaseHelper.instance.updateAllCloseValues();
    _timer =
        Timer.periodic(Duration(seconds: 5), (timer) => fetchInstruments());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      fetchInstruments();
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(WatchlistTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    fetchInstruments();
  }

  Future<void> SubscribedmarketData() async {
    //final marketSocket = Provider.of<MarketFeedSocket>(context);
    final instruments = await DatabaseHelper.instance
        .fetchInstrumentsByWatchlist(widget.watchlistId);
    _instruments = List<Map<String, dynamic>>.from(instruments);
    for (var instrument in _instruments) {
      final exchangeInstrumentID =
          instrument['exchange_instrument_id'] as String;
      final exchangeSegment = instrument['exchangeSegment'].toString();

      ApiService().MarketInstrumentSubscribe(
          exchangeSegment.toString(), exchangeInstrumentID.toString());
    }
  }

  Future<void> fetchInstruments() async {
    final instruments = await DatabaseHelper.instance
        .fetchInstrumentsByWatchlist(widget.watchlistId);
    if (_instruments.length != instruments.length) {
      SubscribedmarketData();
    }

    setState(() {
      _instruments = List<Map<String, dynamic>>.from(instruments);
    });
  }

  Stream<String> streamInstrumentDetails(
      String exchangeInstrumentID, String ExchangeSegment) async* {
    while (true) {
      final instrumentDetails =
          await fetchInstrumentDetails(exchangeInstrumentID, ExchangeSegment);
      yield jsonEncode(instrumentDetails);
    }
  }



  Future<List<String>> fetchAllCloseValues(
      List<Map<String, dynamic>> instruments) async {
    var closeValues = <String>[];
    for (var instrument in instruments) {
      var token = instrument['exchange_instrument_id'];
      var closeValue = await NscmDatabase().getCloseValue(token);
      closeValues.add(closeValue);
    }
    return closeValues;
  }

  String getExchangeSegmentName(int exchangeSegment) {
    switch (exchangeSegment) {
      case 1:
        return 'NSECM';
      case 2:
        return 'NSEFO';
      case 3:
        return 'NSECD';
      case 11:
        return 'BSECM';
      case 12:
        return 'BSEFO';
      case 13:
        return 'BSECD';
      default:
        return 'Unknown';
    }
  }

  @override
  Widget build(BuildContext context) {
    final marketSocket = Provider.of<MarketFeedSocket>(context);
    
    return Padding(
      padding: const EdgeInsets.all(1.0),
      child: GestureDetector(
        onLongPress: () async {
          showModalBottomSheet(
            context: context,
            builder: (context) {
              return ReorderableListView.builder(
                itemCount: _instruments.length,
                itemBuilder: (context, index) {
                  final instrument = _instruments[index];
                  return ListTile(
                    key: ValueKey(instrument['id']),
                    title: Text(instrument['display_name']),
                    leading: Icon(Icons.drag_handle),
                  );
                },
                onReorder: (oldIndex, newIndex) {
                  setState(() {
                    if (oldIndex < newIndex) {
                      newIndex -= 1;
                    }
                    final Map<String, dynamic> item =
                        _instruments.removeAt(oldIndex);
                    _instruments.insert(newIndex, item);
                    _dbHelper.updateOrderIndex(item['id'], newIndex);
                  });
                },
              );
            },
          );
        },
        child: ListView.separated(
          separatorBuilder: (context, index) => Divider(
            color: Colors.grey,
          ),
          itemCount: _instruments.length,
          itemBuilder: (context, index) {
            final instrument = _instruments[index];
            final exchangeInstrumentID =
                instrument['exchange_instrument_id'] as String;

            final exchangeSegment = instrument['exchangeSegment'].toString();
            final displayName = instrument['display_name'] as String;

            final closevalue1 = instrument['close'].toString();
            return Consumer<MarketFeedSocket>(
              builder: (context, data, child) {
                final marketData =
                    data.getDataById(int.parse(exchangeInstrumentID));
                final priceChange = marketData != null
                    ? double.parse(marketData.price) - double.parse(closevalue1)
                    : 0;
                final priceChangeColor =
                    priceChange > 0 ? Colors.green : Colors.red;
                if (marketData != null) {
                  return GestureDetector(
                    onTap: () {
                      // Navigator.push(
                      //   context,
                      //   MaterialPageRoute(
                      //     builder: (context) => InstrumentDetailsScreen(
                           
                      //     ),
                      //   ),
                      // );
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => BuySellScreen(
                            exchangeInstrumentId: exchangeInstrumentID,exchangeSegment: exchangeSegment,lastTradedPrice: marketData.price, close: closevalue1,displayName: displayName,
                          ),
                        ),
                      );
                    
                    },
                    onLongPress: () {
                      showModalBottomSheet(
                        context: context,
                        builder: (context) {
                          return ReorderableListView.builder(
                            itemCount: _instruments.length,
                            itemBuilder: (context, index) {
                              final instrument = _instruments[index];
                              return ListTile(
                                key: ValueKey(instrument['id']),
                                title: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(instrument['display_name']),
                                    IconButton(onPressed: (){
                                      _dbHelper.deleteInstrumentByExchangeInstrumentId(widget.watchlistId, exchangeInstrumentID);
                                      Navigator.pop(context);
                                    }, icon: Icon(Icons.delete))
                                  ],
                                ),
                                leading: Icon(Icons.drag_handle),
                              );
                            },
                            onReorder: (oldIndex, newIndex) {
                              setState(() {
                                if (oldIndex < newIndex) {
                                  newIndex -= 1;
                                }
                                final Map<String, dynamic> item =
                                    _instruments.removeAt(oldIndex);
                                _instruments.insert(newIndex, item);
                                _dbHelper.updateOrderIndex(
                                    item['id'], newIndex);
                                //MarketWatchScreen.initializeDatabase();
                              });
                            },
                          );
                        },
                      );
                    },
                    child: SingleChildScrollView(
                      child: Container(
                        padding: EdgeInsets.fromLTRB(15, 0, 15, 0),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(displayName,
                                    style:
                                        TextStyle(fontWeight: FontWeight.w400)),
                                Row(
                                  children: [
                                    Text(
                                      marketData.price.toString(),
                                      style: TextStyle(color: priceChangeColor),
                                    ),
                                    // Icon(
                                    //   priceChangeIcon,
                                    //   color: priceChangeColor,
                                    //   size: 12,
                                    // ),
                                  ],
                                )
                              ],
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      '$displayName:  - ',
                                      style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500),
                                    ),
                                    Text(
                                      getExchangeSegmentName(
                                          int.parse(exchangeSegment)),
                                      style: TextStyle(fontSize: 12),
                                    )
                                  ],
                                ),
                                Row(
                                  children: [
                                    Text(priceChange.toStringAsFixed(2),
                                        style:
                                            TextStyle(color: priceChangeColor)),
                                    Text(
                                      "(${marketData.percentChange}%)",
                                      style: TextStyle(color: priceChangeColor),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                } else {
                  return Center(child: CircularProgressIndicator());
                }
              },
            );
          },
        ),
      ),
    );
  }
}

Future<Map<String, String>> fetchInstrumentDetails(
    String exchangeInstrumentID, String exchangeSegment) async {
  try {
    String? token = await getToken();
    final url = 'http://14.97.72.10:3000/apimarketdata/instruments/quotes';
    final payload = jsonEncode({
      "instruments": [
        {
          "exchangeSegment": exchangeSegment,
          "exchangeInstrumentID": exchangeInstrumentID
        }
      ],
      "xtsMessageCode": 1501,
      "publishFormat": "JSON"
    });

    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': '$token',
      },
      body: payload,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      if (data != null && data.containsKey('result')) {
        final listQuotesJson = data['result']['listQuotes'][0];
        final listQuotes = jsonDecode(listQuotesJson);
        final lastTradedPrice = listQuotes['Touchline']['LastTradedPrice'];

        final openPrice = listQuotes['Touchline']['Open'];
        final highPrice = listQuotes['Touchline']['High'];
        final lowPrice = listQuotes['Touchline']['Low'];
        final closePrice = listQuotes['Touchline']['Close'];
        final percentChange = listQuotes['Touchline']['PercentChange'];
        return {
          'LastTradedPrice': lastTradedPrice.toString(),
          'Open': openPrice.toString(),
          'High': highPrice.toString(),
          'Low': lowPrice.toString(),
          'Close': closePrice.toString(),
          'PercentChange': percentChange.toString(),
        };
      } else {
        print('Invalid data received from the server');
        throw Exception('Invalid data received from the server');
      }
    } else {
      print('Failed to fetch instrument details');
      throw Exception('Failed to fetch instrument details');
    }
  } on SocketException {
    print('No Internet connection');
    throw 'No Internet connection';
  } on HttpException {
    print('Could not find the service');
    throw 'Could not find the service';
  } on FormatException {
    print('Bad response format');
    throw 'Bad response format';
  } catch (e) {
    print("Exception caught: $e");
    rethrow;
  }
}

class AddWatchlistDialog extends StatefulWidget {
  @override
  _AddWatchlistDialogState createState() => _AddWatchlistDialogState();
}

class _AddWatchlistDialogState extends State<AddWatchlistDialog> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Add to Watchlist'),
      content: TextField(
        controller: _controller,
        decoration: InputDecoration(labelText: 'Name'),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(_controller.text.trim());
          },
          child: Text('Add'),
        ),
      ],
    );
  }
}
