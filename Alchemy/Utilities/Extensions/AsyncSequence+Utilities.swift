import ConcurrencyExtras

extension AsyncSequence {
    public var stream: AsyncStream<Element> {
        eraseToStream()
    }
}
