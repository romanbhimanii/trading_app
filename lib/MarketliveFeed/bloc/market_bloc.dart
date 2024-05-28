import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';


part 'market_event.dart';
part 'market_state.dart';

class MarketBloc extends Bloc<MarketEvent, MarketState> {
  MarketBloc() : super(MarketInitial()) {
    on<MarketDataReceived>((event, emit) {
      
final lastTradedPrice = event.data['Touchline']['LastTradedPrice'].toString();
final percentChange = event.data['Touchline']['PercentChange'].toString();

      final newState = MarketDataLoaded(lastTradedPrice, percentChange);
      print(newState);
      
    });
  }
}