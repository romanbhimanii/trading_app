part of 'market_bloc.dart';


abstract class MarketState extends Equatable {
  const MarketState();
}

class MarketInitial extends MarketState {
  @override
  List<Object?> get props => [];
}

class MarketDataLoaded extends MarketState {
  final String lastTradedPrice;
  final String percentChange;

  MarketDataLoaded(this.lastTradedPrice, this.percentChange);

  @override
  List<Object?> get props => [lastTradedPrice, percentChange];
}
class MarketDataReceivedState extends MarketState {
  final dynamic data;

  const MarketDataReceivedState(this.data);

  @override
  List<Object?> get props => [data];
}
