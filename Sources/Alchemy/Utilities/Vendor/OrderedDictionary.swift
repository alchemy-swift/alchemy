/// Courtesy of https://github.com/lukaskubanek/OrderedDictionary
///
/// A generic collection for storing key-value pairs in an ordered manner.
///
/// Same as in a dictionary all keys in the collection are unique and have an associated value.
/// Same as in an array, all key-value pairs (elements) are kept sorted and accessible by
/// a zero-based integer index.
public struct OrderedDictionary<Key: Hashable, Value>: BidirectionalCollection {

    // ======================================================= //
    // MARK: - Type Aliases
    // ======================================================= //

    /// The type of the key-value pair stored in the ordered dictionary.
    public typealias Element = (key: Key, value: Value)

    /// The type of the index.
    public typealias Index = Int

    /// The type of the indices collection.
    public typealias Indices = CountableRange<Int>

    /// The type of the contiguous subrange of the ordered dictionary's elements.
    ///
    /// - SeeAlso: OrderedDictionarySlice
    public typealias SubSequence = OrderedDictionarySlice<Key, Value>

    // ======================================================= //
    // MARK: - Initialization
    // ======================================================= //

    /// Initializes an empty ordered dictionary.
    public init() {
        self._orderedKeys = [Key]()
        self._keysToValues = [Key: Value]()
    }

    /// Initializes an empty ordered dictionary with preallocated space for at least the specified
    /// number of elements.
    public init(minimumCapacity: Int) {
        self.init()
        self.reserveCapacity(minimumCapacity)
    }

    /// Initializes an ordered dictionary from a regular unsorted dictionary by sorting it using
    /// the given sort function.
    ///
    /// - Parameter unsorted: The unsorted dictionary.
    /// - Parameter areInIncreasingOrder: The sort function which compares the key-value pairs.
    public init(
        unsorted: Dictionary<Key, Value>,
        areInIncreasingOrder: (Element, Element) throws -> Bool
    ) rethrows {
        let keysAndValues = try Array(unsorted).sorted(by: areInIncreasingOrder)

        self.init(
            uniqueKeysWithValues: keysAndValues,
            minimumCapacity: unsorted.count
        )
    }

    /// Initializes an ordered dictionary from a sequence of values keyed by a unique key extracted
    /// from the value using the given closure.
    ///
    /// - Parameter values: The sequence of values.
    /// - Parameter extractKey: The closure which extracts a key from the value. The returned keys
    ///   must be unique for all values from the sequence.
    public init<S: Sequence>(
        values: S,
        uniquelyKeyedBy extractKey: (Value) throws -> Key
    ) rethrows where S.Element == Value {
        self.init(uniqueKeysWithValues: try values.map { value in
            return (try extractKey(value), value)
        })
    }

    /// Initializes an ordered dictionary from a sequence of values keyed by a unique key extracted
    /// from the value using the given key path.
    ///
    /// - Parameter values: The sequence of values.
    /// - Parameter keyPath: The key path to use for extracting a key from the value. The extracted
    ///   keys must be unique for all values from the sequence.
    public init<S: Sequence>(
        values: S,
        uniquelyKeyedBy keyPath: KeyPath<Value, Key>
    ) where S.Element == Value {
        self.init(uniqueKeysWithValues: values.map { value in
            return (value[keyPath: keyPath], value)
        })
    }

    /// Initializes an ordered dictionary from a sequence of key-value pairs.
    ///
    /// - Parameter keysAndValues: A sequence of key-value pairs to use for the new ordered
    ///   dictionary. Every key in `keysAndValues` must be unique.
    public init<S: Sequence>(
        uniqueKeysWithValues keysAndValues: S
    ) where S.Element == Element {
        self.init(
            uniqueKeysWithValues: keysAndValues,
            minimumCapacity: keysAndValues.underestimatedCount
        )
    }

    private init<S: Sequence>(
        uniqueKeysWithValues keysAndValues: S,
        minimumCapacity: Int
    ) where S.Element == Element {
        self.init(minimumCapacity: minimumCapacity)

        for (key, value) in keysAndValues {
            precondition(!containsKey(key), "Sequence of key-value pairs contains duplicate keys")
            self[key] = value
        }
    }

    // ======================================================= //
    // MARK: - Ordered Keys & Values
    // ======================================================= //

    /// A collection containing just the keys of the ordered dictionary in the correct order.
    public var orderedKeys: OrderedDictionaryKeys<Key, Value> {
        return self.lazy.map { $0.key }
    }

    /// A collection containing just the values of the ordered dictionary in the correct order.
    public var orderedValues: OrderedDictionaryValues<Key, Value> {
        return self.lazy.map { $0.value }
    }

    // ======================================================= //
    // MARK: - Dictionary
    // ======================================================= //

    /// Converts itself to a common unsorted dictionary.
    public var unorderedDictionary: Dictionary<Key, Value> {
        return _keysToValues
    }

    // ======================================================= //
    // MARK: - Indices
    // ======================================================= //

    /// The indices that are valid for subscripting the ordered dictionary.
    public var indices: Indices {
        return _orderedKeys.indices
    }

    /// The position of the first key-value pair in a non-empty ordered dictionary.
    public var startIndex: Index {
        return _orderedKeys.startIndex
    }

    /// The position which is one greater than the position of the last valid key-value pair in the
    /// ordered dictionary.
    public var endIndex: Index {
        return _orderedKeys.endIndex
    }

    /// Returns the position immediately after the given index.
    public func index(after i: Index) -> Index {
        return _orderedKeys.index(after: i)
    }

    /// Returns the position immediately before the given index.
    public func index(before i: Index) -> Index {
        return _orderedKeys.index(before: i)
    }

    // ======================================================= //
    // MARK: - Slices
    // ======================================================= //

    /// Accesses a contiguous subrange of the ordered dictionary.
    ///
    /// - Parameter bounds: A range of the ordered dictionary's indices. The bounds of the range
    ///   must be valid indices of the ordered dictionary.
    /// - Returns: The slice view at the ordered dictionary in the specified subrange.
    public subscript(bounds: Range<Index>) -> SubSequence {
        return OrderedDictionarySlice(base: self, bounds: bounds)
    }

    // ======================================================= //
    // MARK: - Key-based Access
    // ======================================================= //

    /// Accesses the value associated with the given key for reading and writing.
    ///
    /// This key-based subscript returns the value for the given key if the key is found in the
    /// ordered dictionary, or `nil` if the key is not found.
    ///
    /// When you assign a value for a key and that key already exists, the ordered dictionary
    /// overwrites the existing value and preservers the index of the key-value pair. If the ordered
    /// dictionary does not contain the key, a new key-value pair is appended to the end of the
    /// ordered dictionary.
    ///
    /// If you assign `nil` as the value for the given key, the ordered dictionary removes that key
    /// and its associated value if it exists.
    ///
    /// - Parameter key: The key to find in the ordered dictionary.
    /// - Returns: The value associated with `key` if `key` is in the ordered dictionary; otherwise,
    ///   `nil`.
    public subscript(key: Key) -> Value? {
        get {
            return value(forKey: key)
        }
        set(newValue) {
            if let newValue = newValue {
                updateValue(newValue, forKey: key)
            } else {
                removeValue(forKey: key)
            }
        }
    }

    /// Returns a Boolean value indicating whether the ordered dictionary contains the given key.
    ///
    /// - Parameter key: The key to be looked up.
    /// - Returns: `true` if the ordered dictionary contains the given key; otherwise, `false`.
    public func containsKey(_ key: Key) -> Bool {
        return _keysToValues[key] != nil
    }

    /// Returns the value associated with the given key if the key is found in the ordered
    /// dictionary, or `nil` if the key is not found.
    ///
    /// - Parameter key: The key to find in the ordered dictionary.
    /// - Returns: The value associated with `key` if `key` is in the ordered dictionary; otherwise,
    ///   `nil`.
    public func value(forKey key: Key) -> Value? {
        return _keysToValues[key]
    }

    /// Updates the value stored in the ordered dictionary for the given key, or appends a new
    /// key-value pair if the key does not exist.
    ///
    /// - Parameter value: The new value to add to the ordered dictionary.
    /// - Parameter key: The key to associate with `value`. If `key` already exists in the ordered
    ///   dictionary, `value` replaces the existing associated value. If `key` is not already a key
    ///   of the ordered dictionary, the `(key, value)` pair is appended at the end of the ordered
    ///   dictionary.
    @discardableResult
    public mutating func updateValue(_ value: Value, forKey key: Key) -> Value? {
        if containsKey(key) {
            let currentValue = _unsafeValue(forKey: key)

            _keysToValues[key] = value

            return currentValue
        } else {
            _orderedKeys.append(key)
            _keysToValues[key] = value

            return nil
        }
    }

    /// Removes the given key and its associated value from the ordered dictionary.
    ///
    /// If the key is found in the ordered dictionary, this method returns the key's associated
    /// value. On removal, the indices of the ordered dictionary are invalidated. If the key is
    /// not found in the ordered dictionary, this method returns `nil`.
    ///
    /// - Parameter key: The key to remove along with its associated value.
    /// - Returns: The value that was removed, or `nil` if the key was not present in the
    ///   ordered dictionary.
    ///
    /// - SeeAlso: remove(at:)
    @discardableResult
    public mutating func removeValue(forKey key: Key) -> Value? {
        guard let index = index(forKey: key) else { return nil }

        let currentValue = self[index].value

        _orderedKeys.remove(at: index)
        _keysToValues[key] = nil

        return currentValue
    }

    /// Removes all key-value pairs from the ordered dictionary and invalidates all indices.
    ///
    /// - Parameter keepCapacity: Whether the ordered dictionary should keep its underlying storage.
    ///   If you pass `true`, the operation preserves the storage capacity that the collection has,
    ///   otherwise the underlying storage is released. The default is `false`.
    public mutating func removeAll(keepingCapacity keepCapacity: Bool = false) {
        _orderedKeys.removeAll(keepingCapacity: keepCapacity)
        _keysToValues.removeAll(keepingCapacity: keepCapacity)
    }

    private func _unsafeValue(forKey key: Key) -> Value {
        let value = _keysToValues[key]
        precondition(value != nil, "Inconsistency error occurred in OrderedDictionary")
        return value!
    }

    // ======================================================= //
    // MARK: - Index-based Access
    // ======================================================= //

    /// Accesses the key-value pair at the specified position.
    ///
    /// The specified position has to be a valid index of the ordered dictionary. The index-base
    /// subscript returns the key-value pair corresponding to the index.
    ///
    /// - Parameter position: The position of the key-value pair to access. `position` must be
    ///   a valid index of the ordered dictionary and not equal to `endIndex`.
    /// - Returns: A tuple containing the key-value pair corresponding to `position`.
    ///
    /// - SeeAlso: update(:at:)
    public subscript(position: Index) -> Element {
        precondition(indices.contains(position), "OrderedDictionary index is out of range")

        let key = _orderedKeys[position]
        let value = _unsafeValue(forKey: key)

        return (key, value)
    }

    /// Returns the index for the given key.
    ///
    /// - Parameter key: The key to find in the ordered dictionary.
    /// - Returns: The index for `key` and its associated value if `key` is in the ordered
    ///   dictionary; otherwise, `nil`.
    public func index(forKey key: Key) -> Index? {
        #if swift(>=5.0)
        return _orderedKeys.firstIndex(of: key)
        #else
        return _orderedKeys.index(of: key)
        #endif
    }

    /// Returns the key-value pair at the specified index, or `nil` if there is no key-value pair
    /// at that index.
    ///
    /// - Parameter index: The index of the key-value pair to be looked up. `index` does not have to
    ///   be a valid index.
    /// - Returns: A tuple containing the key-value pair corresponding to `index` if the index is
    ///   valid; otherwise, `nil`.
    public func elementAt(_ index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }

    /// Checks whether the given key-value pair can be inserted into to ordered dictionary by
    /// validating the presence of the key.
    ///
    /// - Parameter newElement: The key-value pair to be inserted into the ordered dictionary.
    /// - Returns: `true` if the key-value pair can be safely inserted; otherwise, `false`.
    ///
    /// - SeeAlso: canInsert(key:)
    /// - SeeAlso: canInsert(at:)
    @available(*, deprecated, message: "Use canInsert(key:) with the element's key instead")
    public func canInsert(_ newElement: Element) -> Bool {
        return canInsert(key: newElement.key)
    }

    /// Checks whether a key-value pair with the given key can be inserted into the ordered
    /// dictionary by validating its presence.
    ///
    /// - Parameter key: The key to be inserted into the ordered dictionary.
    /// - Returns: `true` if the key can safely be inserted; ortherwise, `false`.
    ///
    /// - SeeAlso: canInsert(at:)
    public func canInsert(key: Key) -> Bool {
        return !containsKey(key)
    }

    /// Checks whether a new key-value pair can be inserted into the ordered dictionary at the
    /// given index.
    ///
    /// - Parameter index: The index the new key-value pair should be inserted at.
    /// - Returns: `true` if a new key-value pair can be inserted at the specified index; otherwise,
    ///   `false`.
    ///
    /// - SeeAlso: canInsert(key:)
    public func canInsert(at index: Index) -> Bool {
        return index >= startIndex && index <= endIndex
    }

    /// Inserts a new key-value pair at the specified position.
    ///
    /// If the key of the inserted pair already exists in the ordered dictionary, a runtime error
    /// is triggered. Use `canInsert(_:)` for performing a check first, so that this method can
    /// be executed safely.
    ///
    /// - Parameter newElement: The new key-value pair to insert into the ordered dictionary. The
    ///   key contained in the pair must not be already present in the ordered dictionary.
    /// - Parameter index: The position at which to insert the new key-value pair. `index` must be
    ///   a valid index of the ordered dictionary or equal to `endIndex` property.
    ///
    /// - SeeAlso: canInsert(key:)
    /// - SeeAlso: canInsert(at:)
    /// - SeeAlso: update(:at:)
    public mutating func insert(_ newElement: Element, at index: Index) {
        precondition(canInsert(key: newElement.key), "Cannot insert duplicate key in OrderedDictionary")
        precondition(canInsert(at: index), "Cannot insert at invalid index in OrderedDictionary")

        let (key, value) = newElement

        _orderedKeys.insert(key, at: index)
        _keysToValues[key] = value
    }

    /// Checks whether the key-value pair at the given index can be updated with the given key-value
    /// pair. This is not the case if the key of the updated element is already present in the
    /// ordered dictionary and located at another index than the updated one.
    ///
    /// Although this is a checking method, a valid index has to be provided.
    ///
    /// - Parameter newElement: The key-value pair to be set at the specified position.
    /// - Parameter index: The position at which to set the key-value pair. `index` must be a valid
    ///   index of the ordered dictionary.
    public func canUpdate(_ newElement: Element, at index: Index) -> Bool {
        var keyPresentAtIndex = false
        return _canUpdate(newElement, at: index, keyPresentAtIndex: &keyPresentAtIndex)
    }

    /// Updates the key-value pair located at the specified position.
    ///
    /// If the key of the updated pair already exists in the ordered dictionary *and* is located at
    /// a different position than the specified one, a runtime error is triggered. Use
    /// `canUpdate(_:at:)` for performing a check first, so that this method can be executed safely.
    ///
    /// - Parameter newElement: The key-value pair to be set at the specified position.
    /// - Parameter index: The position at which to set the key-value pair. `index` must be a valid
    ///   index of the ordered dictionary.
    ///
    /// - SeeAlso: canUpdate(_:at:)
    /// - SeeAlso: insert(:at:)
    @discardableResult
    public mutating func update(_ newElement: Element, at index: Index) -> Element? {
        // Store the flag indicating whether the key of the inserted element
        // is present at the updated index
        var keyPresentAtIndex = false

        precondition(
            _canUpdate(newElement, at: index, keyPresentAtIndex: &keyPresentAtIndex),
            "OrderedDictionary update duplicates key"
        )

        // Decompose the element
        let (key, value) = newElement

        // Load the current element at the index
        let replacedElement = self[index]

        // If its key differs, remove its associated value
        if (!keyPresentAtIndex) {
            _keysToValues.removeValue(forKey: replacedElement.key)
        }

        // Store the new position of the key and the new value associated with the key
        _orderedKeys[index] = key
        _keysToValues[key] = value

        return replacedElement
    }

    /// Removes and returns the key-value pair at the specified position if there is any key-value
    /// pair, or `nil` if there is none.
    ///
    /// - Parameter index: The position of the key-value pair to remove.
    /// - Returns: The element at the specified index, or `nil` if the position is not taken.
    ///
    /// - SeeAlso: removeValue(forKey:)
    @discardableResult
    public mutating func remove(at index: Index) -> Element? {
        guard let element = elementAt(index) else { return nil }

        _orderedKeys.remove(at: index)
        _keysToValues.removeValue(forKey: element.key)

        return element
    }

    private func _canUpdate(
        _ newElement: Element,
        at index: Index,
        keyPresentAtIndex: inout Bool
    ) -> Bool {
        precondition(indices.contains(index), "OrderedDictionary index is out of range")

        let currentIndexOfKey = self.index(forKey: newElement.key)

        let keyNotPresent = currentIndexOfKey == nil
        keyPresentAtIndex = currentIndexOfKey == index

        return keyNotPresent || keyPresentAtIndex
    }

    // ======================================================= //
    // MARK: - Removing First & Last Elements
    // ======================================================= //

    /// Removes and returns the first key-value pair of the ordered dictionary if it is not empty.
    public mutating func popFirst() -> Element? {
        guard !isEmpty else { return nil }
        return remove(at: startIndex)
    }

    /// Removes and returns the last key-value pair of the ordered dictionary if it is not empty.
    public mutating func popLast() -> Element? {
        guard !isEmpty else { return nil }
        return remove(at: index(before: endIndex))
    }

    /// Removes and returns the first key-value pair of the ordered dictionary.
    public mutating func removeFirst() -> Element {
        precondition(!isEmpty, "Cannot remove key-value pairs from empty OrderedDictionary")
        return remove(at: startIndex)!
    }

    /// Removes and returns the last key-value pair of the ordered dictionary.
    public mutating func removeLast() -> Element {
        precondition(!isEmpty, "Cannot remove key-value pairs from empty OrderedDictionary")
        return remove(at: index(before: endIndex))!
    }

    // ======================================================= //
    // MARK: - Moving Elements
    // ======================================================= //

    /// Moves an existing key-value pair specified by the given key to the new index by removing it
    /// from its original index first and inserting it at the new index. If the movement is
    /// actually performed, the previous index of the key-value pair is returned. Otherwise, `nil`
    /// is returned.
    ///
    /// - Parameter key: The key specifying the key-value pair to move.
    /// - Parameter newIndex: The new index the key-value pair should be moved to.
    /// - Returns: The previous index of the key-value pair if it was sucessfully moved.
    @discardableResult
    public mutating func moveElement(forKey key: Key, to newIndex: Index) -> Index? {
        // Load the previous index and return nil if the index is not found.
        guard let previousIndex = index(forKey: key) else { return nil }

        // If the previous and new indices match, threat it as if the movement was already
        // performed.
        guard previousIndex != newIndex else { return previousIndex }

        // Remove the value for the key at its original index.
        let value = removeValue(forKey: key)!

        // Validate the new index.
        precondition(canInsert(at: newIndex), "Cannot move to invalid index in OrderedDictionary")

        // Insert the element at the new index.
        insert((key: key, value: value), at: newIndex)

        return previousIndex
    }

    // ======================================================= //
    // MARK: - Sorting Elements
    // ======================================================= //

    /// Sorts the ordered dictionary in place, using the given predicate as the comparison between
    /// elements.
    ///
    /// The predicate must be a *strict weak ordering* over the elements.
    ///
    /// - Parameter areInIncreasingOrder: A predicate that returns `true` if its first argument
    ///   should be ordered before its second argument; otherwise, `false`.
    ///
    /// - SeeAlso: MutableCollection.sort(by:), sorted(by:)
    public mutating func sort(
        by areInIncreasingOrder: (Element, Element) throws -> Bool
    ) rethrows {
        _orderedKeys = try _sortedElements(by: areInIncreasingOrder).map { $0.key }
    }

    /// Returns a new ordered dictionary, sorted using the given predicate as the comparison between
    /// elements.
    ///
    /// The predicate must be a *strict weak ordering* over the elements.
    ///
    /// - Parameter areInIncreasingOrder: A predicate that returns `true` if its first argument
    ///   should be ordered before its second argument; otherwise, `false`.
    /// - Returns: A new ordered dictionary sorted according to the predicate.
    ///
    /// - SeeAlso: MutableCollection.sorted(by:), sort(by:)
    /// - MutatingVariant: sort
    public func sorted(
        by areInIncreasingOrder: (Element, Element) throws -> Bool
    ) rethrows -> OrderedDictionary<Key, Value> {
        return OrderedDictionary(uniqueKeysWithValues: try _sortedElements(by: areInIncreasingOrder))
    }

    private func _sortedElements(
        by areInIncreasingOrder: (Element, Element) throws -> Bool
    ) rethrows -> [Element] {
        return try sorted(by: areInIncreasingOrder)
    }

    // ======================================================= //
    // MARK: - Mapping Values
    // ======================================================= //

    /// Returns a new ordered dictionary containing the keys of this ordered dictionary with the
    /// values transformed by the given closure by preserving the original order.
    public func mapValues<T>(
        _ transform: (Value) throws -> T
    ) rethrows -> OrderedDictionary<Key, T> {
        var result = OrderedDictionary<Key, T>()

        for (key, value) in self {
            result[key] = try transform(value)
        }

        return result
    }

    /// Returns a new ordered dictionary containing only the key-value pairs that have non-nil
    /// values as the result of transformation by the given closure by preserving the original
    /// order.
    public func compactMapValues<T>(
        _ transform: (Value) throws -> T?
    ) rethrows -> OrderedDictionary<Key, T> {
        var result = OrderedDictionary<Key, T>()

        for (key, value) in self {
            if let transformedValue = try transform(value) {
                result[key] = transformedValue
            }
        }

        return result
    }

    // ======================================================= //
    // MARK: - Capacity
    // ======================================================= //

    /// The total number of elements that the ordered dictionary can contain without allocating
    /// new storage.
    public var capacity: Int {
        return Swift.min(_orderedKeys.capacity, _keysToValues.capacity)
    }

    /// Reserves enough space to store the specified number of elements, when appropriate
    /// for the underlying types.
    ///
    /// If you are adding a known number of elements to an ordered dictionary, use this method
    /// to avoid multiple reallocations. This method ensures that the underlying types of the
    /// ordered dictionary have space allocated for at least the requested number of elements.
    ///
    /// - Parameter minimumCapacity: The requested number of elements to store.
    public mutating func reserveCapacity(_ minimumCapacity: Int) {
        _orderedKeys.reserveCapacity(minimumCapacity)
        _keysToValues.reserveCapacity(minimumCapacity)
    }

    // ======================================================= //
    // MARK: - Internal Storage
    // ======================================================= //

    /// The backing storage for the ordered keys.
    fileprivate var _orderedKeys: [Key]

    /// The backing storage for the mapping of keys to values.
    fileprivate var _keysToValues: [Key: Value]

}

// ======================================================= //
// MARK: - Subtypes
// ======================================================= //

/// A view into an ordered dictionary whose indices are a subrange of the indices of the ordered
/// dictionary.
public typealias OrderedDictionarySlice<Key: Hashable, Value> = Slice<OrderedDictionary<Key, Value>>

/// A collection containing the keys of the ordered dictionary.
///
/// Under the hood this is a lazily evaluated bidirectional collection deriving the keys from
/// the base ordered dictionary on-the-fly.
public typealias OrderedDictionaryKeys<Key: Hashable, Value> = LazyMapCollection<OrderedDictionary<Key, Value>, Key>

/// A collection containing the values of the ordered dictionary.
///
/// Under the hood this is a lazily evaluated bidirectional collection deriving the values from
/// the base ordered dictionary on-the-fly.
public typealias OrderedDictionaryValues<Key: Hashable, Value> = LazyMapCollection<OrderedDictionary<Key, Value>, Value>

// ======================================================= //
// MARK: - Literals
// ======================================================= //

extension OrderedDictionary: ExpressibleByArrayLiteral {

    /// Initializes an ordered dictionary initialized from an array literal containing a list of
    /// key-value pairs. Every key in `elements` must be unique.
    public init(arrayLiteral elements: Element...) {
        self.init(uniqueKeysWithValues: elements)
    }

}

extension OrderedDictionary: ExpressibleByDictionaryLiteral {

    /// Initializes an ordered dictionary initialized from a dictionary literal. Every key in
    /// `elements` must be unique.
    public init(dictionaryLiteral elements: (Key, Value)...) {
        self.init(uniqueKeysWithValues: elements.map { element in
            let (key, value) = element
            return (key: key, value: value)
        })
    }

}

// ======================================================= //
// MARK: - Equatable Conformance
// ======================================================= //

extension OrderedDictionary: Equatable where Value: Equatable {}

// ======================================================= //
// MARK: - Dictionary Extension
// ======================================================= //

extension Dictionary {

    /// Returns an ordered dictionary containing the key-value pairs from the dictionary, sorted
    /// using the given sort function.
    ///
    /// - Parameter areInIncreasingOrder: The sort function which compares the key-value pairs.
    /// - Returns: The ordered dictionary.
    /// - SeeAlso: OrderedDictionary.init(unsorted:areInIncreasingOrder:)
    public func sorted(
        by areInIncreasingOrder: (Element, Element) throws -> Bool
    ) rethrows -> OrderedDictionary<Key, Value> {
        return try OrderedDictionary(
            unsorted: self,
            areInIncreasingOrder: areInIncreasingOrder
        )
    }

}
