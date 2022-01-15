/// Used so `Relationship` types can know not to decode themselves properly from
/// an `SQLDecoder`.
protocol SQLDecoder: Decoder {}
