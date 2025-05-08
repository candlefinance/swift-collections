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

extension _BTree {
  
  internal struct SubSequence {
    
    internal let _base: _BTree
    
    
    internal var _startIndex: Index
    
    
    internal var _endIndex: Index
    
    
    @inline(__always)
    internal init(base: _BTree, bounds: Range<Index>) {
      self._base = base
      self._startIndex = bounds.lowerBound
      self._endIndex = bounds.upperBound
    }
    
    /// The underlying collection of the subsequence.
    
    @inline(__always)
    internal var base: _BTree { _base }
  }
}

extension _BTree.SubSequence: Sequence {
  
  internal typealias Element = _BTree.Element
  
  
  
  internal struct Iterator: IteratorProtocol {
    
    internal typealias Element = SubSequence.Element
    
    
    internal var _iterator: _BTree.Iterator
    
    
    internal var distanceRemaining: Int
    
    
    @inline(__always)
    internal init(_iterator: _BTree.Iterator, distance: Int) {
      self._iterator = _iterator
      self.distanceRemaining = distance
    }
    
    
    @inline(__always)
    internal mutating func next() -> Element? {
      if distanceRemaining == 0 {
        return nil
      } else {
        distanceRemaining -= 1
        return _iterator.next()
      }
    }
  }
  
  
  @inline(__always)
  internal func makeIterator() -> Iterator {
    let it = _BTree.Iterator(forTree: _base, startingAt: _startIndex)
    let distance = _base.distance(from: _startIndex, to: _endIndex)
    return Iterator(_iterator: it, distance: distance)
  }
}

extension _BTree.SubSequence: BidirectionalCollection {
  
  internal typealias Index = _BTree.Index
  
  
  internal typealias SubSequence = Self
  
  
  
  @inline(__always)
  internal var startIndex: Index { _startIndex }
  
  
  @inline(__always)
  internal var endIndex: Index { _endIndex }
  
  
  @inline(__always)
  internal var count: Int { _base.distance(from: _startIndex, to: _endIndex) }
  
  
  @inline(__always)
  internal func distance(from start: Index, to end: Index) -> Int {
    _base.distance(from: start, to: end)
  }
  
  
  @inline(__always)
  internal func index(before i: Index) -> Index {
    _base.index(before: i)
  }
  
  
  @inline(__always)
  internal func formIndex(before i: inout Index) {
    _base.formIndex(before: &i)
  }
  
  
  
  @inline(__always)
  internal func index(after i: Index) -> Index {
    _base.index(after: i)
  }
  
  
  @inline(__always)
  internal func formIndex(after i: inout Index) {
    _base.formIndex(after: &i)
  }
  
  
  @inline(__always)
  internal func index(_ i: Index, offsetBy distance: Int) -> Index {
    _base.index(i, offsetBy: distance)
  }
  
  
  @inline(__always)
  internal func formIndex(_ i: inout Index, offsetBy distance: Int) {
    _base.formIndex(&i, offsetBy: distance)
  }
  
  
  @inline(__always)
  internal func index(_ i: Index, offsetBy distance: Int, limitedBy limit: Index) -> Index? {
    _base.index(i, offsetBy: distance, limitedBy: limit)
  }
  
  
  @inline(__always)
  internal func formIndex(_ i: inout Index, offsetBy distance: Int, limitedBy limit: Self.Index) -> Bool {
    _base.formIndex(&i, offsetBy: distance, limitedBy: limit)
  }

  
  
  @inline(__always)
  internal subscript(position: Index) -> Element {
    _failEarlyRangeCheck(position, bounds: startIndex..<endIndex)
    return _base[position]
  }
  
  
  public subscript(bounds: Range<Index>) -> SubSequence {
    _failEarlyRangeCheck(bounds, bounds: startIndex..<endIndex)
    return _base[bounds]
  }
  
  // TODO: implement optimized `var indices`
  
  
  @inline(__always)
  public func _failEarlyRangeCheck(_ index: Index, bounds: Range<Index>) {
    _base._failEarlyRangeCheck(index, bounds: bounds)
  }

  
  @inline(__always)
  public func _failEarlyRangeCheck(_ range: Range<Index>, bounds: Range<Index>) {
    _base._failEarlyRangeCheck(range, bounds: bounds)
  }
}

// TODO: implement partial RangeReplaceableCollection methods
