//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2021 - 2024 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

extension Deque {
  @frozen
  
  struct _Storage {
    
    internal typealias _Buffer = ManagedBufferPointer<_DequeBufferHeader, Element>

    
    internal var _buffer: _Buffer

    
    @inline(__always)
    internal init(_buffer: _Buffer) {
      self._buffer = _buffer
    }
  }
}

extension Deque._Storage: CustomStringConvertible {
  
  internal var description: String {
    "Deque<\(Element.self)>._Storage\(_buffer.header)"
  }
}

extension Deque._Storage {
  
  internal init() {
    self.init(_buffer: _Buffer(unsafeBufferObject: _emptyDequeStorage))
  }

  
  internal init(_ object: _DequeBuffer<Element>) {
    self.init(_buffer: _Buffer(unsafeBufferObject: object))
  }

  
  internal init(minimumCapacity: Int) {
    let object = _DequeBuffer<Element>.create(
      minimumCapacity: minimumCapacity,
      makingHeaderWith: {
        #if os(OpenBSD)
        let capacity = minimumCapacity
        #else
        let capacity = $0.capacity
        #endif
        return _DequeBufferHeader(capacity: capacity, count: 0, startSlot: .zero)
      })
    self.init(_buffer: _Buffer(unsafeBufferObject: object))
  }
}

extension Deque._Storage {
  #if COLLECTIONS_INTERNAL_CHECKS
   @inline(never) @_effects(releasenone)
  internal func _checkInvariants() {
    _buffer.withUnsafeMutablePointerToHeader { $0.pointee._checkInvariants() }
  }
  #else
   @inline(__always)
  internal func _checkInvariants() {}
  #endif // COLLECTIONS_INTERNAL_CHECKS
}

extension Deque._Storage {
  
  @inline(__always)
  internal var identity: AnyObject { _buffer.buffer }


  
  @inline(__always)
  internal var capacity: Int {
    _buffer.withUnsafeMutablePointerToHeader { $0.pointee.capacity }
  }

  
  @inline(__always)
  internal var count: Int {
    _buffer.withUnsafeMutablePointerToHeader { $0.pointee.count }
  }

  
  @inline(__always)
  internal var startSlot: _DequeSlot {
    _buffer.withUnsafeMutablePointerToHeader { $0.pointee.startSlot
    }
  }
}

extension Deque._Storage {
  
  internal typealias Index = Int

  
  internal typealias _UnsafeHandle = Deque._UnsafeHandle

  
  @inline(__always)
  internal func read<R>(_ body: (_UnsafeHandle) throws -> R) rethrows -> R {
    try _buffer.withUnsafeMutablePointers { header, elements in
      let handle = _UnsafeHandle(header: header,
                                 elements: elements,
                                 isMutable: false)
      return try body(handle)
    }
  }

  
  @inline(__always)
  internal func update<R>(_ body: (_UnsafeHandle) throws -> R) rethrows -> R {
    try _buffer.withUnsafeMutablePointers { header, elements in
      let handle = _UnsafeHandle(header: header,
                                 elements: elements,
                                 isMutable: true)
      return try body(handle)
    }
  }
}

extension Deque._Storage {
  /// Return a boolean indicating whether this storage instance is known to have
  /// a single unique reference. If this method returns true, then it is safe to
  /// perform in-place mutations on the deque.
  
  @inline(__always)
  internal mutating func isUnique() -> Bool {
    _buffer.isUniqueReference()
  }

  /// Ensure that this storage refers to a uniquely held buffer by copying
  /// elements if necessary.
  
  @inline(__always)
  internal mutating func ensureUnique() {
    if isUnique() { return }
    self._makeUniqueCopy()
  }

  
  @inline(never)
  internal mutating func _makeUniqueCopy() {
    self = self.read { $0.copyElements() }
  }

  /// The growth factor to use to increase storage size to make place for an
  /// insertion.
  
  @inline(__always)
  internal static var growthFactor: Double { 1.5 }

  
  internal func _growCapacity(
    to minimumCapacity: Int,
    linearly: Bool
  ) -> Int {
    if linearly { return Swift.max(capacity, minimumCapacity) }
    return Swift.max(Int((Self.growthFactor * Double(capacity)).rounded(.up)),
                     minimumCapacity)
  }

  /// Ensure that we have a uniquely referenced buffer with enough space to
  /// store at least `minimumCapacity` elements.
  ///
  /// - Parameter minimumCapacity: The minimum number of elements the buffer
  ///    needs to be able to hold on return.
  ///
  /// - Parameter linearGrowth: If true, then don't use an exponential growth
  ///    factor when reallocating the buffer -- just allocate space for the
  ///    requested number of elements
  
  @inline(__always)
  internal mutating func ensureUnique(
    minimumCapacity: Int,
    linearGrowth: Bool = false
  ) {
    let unique = isUnique()
    if _slowPath(capacity < minimumCapacity || !unique) {
      _ensureUnique(isUnique: unique, minimumCapacity: minimumCapacity, linearGrowth: linearGrowth)
    }
  }

  
  @inline(never)
  internal mutating func _ensureUnique(
    isUnique: Bool,
    minimumCapacity: Int,
    linearGrowth: Bool
  ) {
    if capacity >= minimumCapacity {
      assert(!isUnique)
      self = self.read { $0.copyElements() }
      return
    }

    let minimumCapacity = _growCapacity(to: minimumCapacity, linearly: linearGrowth)
    if isUnique {
      self = self.update { source in
        source.moveElements(minimumCapacity: minimumCapacity)
      }
    } else {
      self = self.read { source in
        source.copyElements(minimumCapacity: minimumCapacity)
      }
    }
  }
}

extension Deque._Storage {
  
  @inline(__always)
  internal func isIdentical(to other: Self) -> Bool {
    self._buffer.buffer === other._buffer.buffer
  }
}
