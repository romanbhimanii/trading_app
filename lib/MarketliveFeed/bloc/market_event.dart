part of 'market_bloc.dart';
// Use 'part' with the library name

@immutable
abstract class MarketEvent extends Equatable {
  const MarketEvent();
}

class MarketDataReceived extends MarketEvent {
  final dynamic data;

   MarketDataReceived(this.data);

  @override
  List<Object?> get props => [data];
}