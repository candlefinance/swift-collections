//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2021 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

extension SortedDictionary: Sequence {
  
  public func forEach(_ body: (Element) throws -> Void) rethrows {
    try self._root.forEach(body)
  }
  
  /// An iterator over the elements of the sorted dictionary
  public struct Iterator: IteratorProtocol {
    
    internal var _iterator: _Tree.Iterator
    
    
    @inline(__always)
    internal init(_base: SortedDictionary) {
      self._iterator = _base._root.makeIterator()
    }
    
    /// Advances to the next element and returns it, or nil if no next element exists.
    ///
    /// - Returns: The next element in the underlying sequence, if a next element exists;
    ///     otherwise, `nil`.
    /// - Complexity: O(1) amortized over the entire sequence.
    
    public mutating func next() -> Element? {
      return self._iterator.next()
    }
  }
  
  /// Returns an iterator over the elements of the sorted dictionary.
  ///
  /// - Complexity: O(log(`self.count`))
  
  public __consuming func makeIterator() -> Iterator {
    return Iterator(_base: self)
  }
}

#if swift(>=5.5)
extension SortedDictionary.Iterator: @unchecked Sendable
where Key: Sendable, Value: Sendable {}
#endif
