//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2022 - 2024 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

extension _HashNode {
  /// An unsafe view of the data stored inside a node in the hash tree, hiding
  /// the mechanics of accessing storage from the code that uses it.
  ///
  /// Handles do not own the storage they access -- it is the client's
  /// responsibility to ensure that handles (and any pointer values generated
  /// by them) do not escape the closure call that received them.
  ///
  /// A handle can be either read-only or mutable, depending on the method used
  /// to access it. In debug builds, methods that modify data trap at runtime if
  /// they're called on a read-only view.
  
  @frozen
  internal struct UnsafeHandle {
    
    internal typealias Element = (key: Key, value: Value)

    
    internal let _header: UnsafeMutablePointer<_HashNodeHeader>

    
    internal let _memory: UnsafeMutableRawPointer

    #if DEBUG
    
    internal let _isMutable: Bool
    #endif

    
    internal init(
      _ header: UnsafeMutablePointer<_HashNodeHeader>,
      _ memory: UnsafeMutableRawPointer,
      isMutable: Bool
    ) {
      self._header = header
      self._memory = memory
      #if DEBUG
      self._isMutable = isMutable
      #endif
    }
  }
}

extension _HashNode.UnsafeHandle {
  
  @inline(__always)
  func assertMutable() {
#if DEBUG
    assert(_isMutable)
#endif
  }
}

extension _HashNode.UnsafeHandle {
   @inline(__always)
  static func read<R>(
    _ node: _UnmanagedHashNode,
    _ body: (Self) throws -> R
  ) rethrows -> R {
    try node.ref._withUnsafeGuaranteedRef { storage in
      try storage.withUnsafeMutablePointers { header, elements in
        try body(Self(header, UnsafeMutableRawPointer(elements), isMutable: false))
      }
    }
  }

   @inline(__always)
  static func read<R>(
    _ storage: _RawHashStorage,
    _ body: (Self) throws -> R
  ) rethrows -> R {
    try storage.withUnsafeMutablePointers { header, elements in
      try body(Self(header, UnsafeMutableRawPointer(elements), isMutable: false))
    }
  }

   @inline(__always)
  static func update<R>(
    _ node: _UnmanagedHashNode,
    _ body: (Self) throws -> R
  ) rethrows -> R {
    try node.ref._withUnsafeGuaranteedRef { storage in
      try storage.withUnsafeMutablePointers { header, elements in
        try body(Self(header, UnsafeMutableRawPointer(elements), isMutable: true))
      }
    }
  }

   @inline(__always)
  static func update<R>(
    _ storage: _RawHashStorage,
    _ body: (Self) throws -> R
  ) rethrows -> R {
    try storage.withUnsafeMutablePointers { header, elements in
      try body(Self(header, UnsafeMutableRawPointer(elements), isMutable: true))
    }
  }
}

extension _HashNode.UnsafeHandle {
   @inline(__always)
  internal var itemMap: _Bitmap {
    get {
      _header.pointee.itemMap
    }
    nonmutating set {
      assertMutable()
      _header.pointee.itemMap = newValue
    }
  }

   @inline(__always)
  internal var childMap: _Bitmap {
    get {
      _header.pointee.childMap
    }
    nonmutating set {
      assertMutable()
      _header.pointee.childMap = newValue
    }
  }

   @inline(__always)
  internal var byteCapacity: Int {
    _header.pointee.byteCapacity
  }

   @inline(__always)
  internal var bytesFree: Int {
    get { _header.pointee.bytesFree }
    nonmutating set {
      assertMutable()
      _header.pointee.bytesFree = newValue
    }
  }

   @inline(__always)
  internal var isCollisionNode: Bool {
    _header.pointee.isCollisionNode
  }

   @inline(__always)
  internal var collisionCount: Int {
    get { _header.pointee.collisionCount }
    nonmutating set {
      assertMutable()
      _header.pointee.collisionCount = newValue
    }
  }

   @inline(__always)
  internal var collisionHash: _Hash {
    get {
      assert(isCollisionNode)
      return _memory.load(as: _Hash.self)
    }
    nonmutating set {
      assertMutable()
      assert(isCollisionNode)
      _memory.storeBytes(of: newValue, as: _Hash.self)
    }
  }

   @inline(__always)
  internal var _childrenStart: UnsafeMutablePointer<_HashNode> {
    _memory.assumingMemoryBound(to: _HashNode.self)
  }

   @inline(__always)
  internal var hasChildren: Bool {
    _header.pointee.hasChildren
  }

   @inline(__always)
  internal var childCount: Int {
    _header.pointee.childCount
  }

  
  internal func childBucket(at slot: _HashSlot) -> _Bucket {
    guard !isCollisionNode else { return .invalid }
    return childMap.bucket(at: slot)
  }

   @inline(__always)
  internal var childrenEndSlot: _HashSlot {
    _header.pointee.childrenEndSlot
  }

  
  internal var children: UnsafeMutableBufferPointer<_HashNode> {
    UnsafeMutableBufferPointer(start: _childrenStart, count: childCount)
  }

  
  internal func childPtr(at slot: _HashSlot) -> UnsafeMutablePointer<_HashNode> {
    assert(slot.value < childCount)
    return _childrenStart + slot.value
  }

  
  internal subscript(child slot: _HashSlot) -> _HashNode {
    unsafeAddress {
      UnsafePointer(childPtr(at: slot))
    }
    nonmutating unsafeMutableAddress {
      assertMutable()
      return childPtr(at: slot)
    }
  }

  
  internal var _itemsEnd: UnsafeMutablePointer<Element> {
    (_memory + _header.pointee.byteCapacity)
      .assumingMemoryBound(to: Element.self)
  }

   @inline(__always)
  internal var hasItems: Bool {
    _header.pointee.hasItems
  }

   @inline(__always)
  internal var itemCount: Int {
    _header.pointee.itemCount
  }

  
  internal func itemBucket(at slot: _HashSlot) -> _Bucket {
    guard !isCollisionNode else { return .invalid }
    return itemMap.bucket(at: slot)
  }

   @inline(__always)
  internal var itemsEndSlot: _HashSlot {
    _header.pointee.itemsEndSlot
  }

  
  internal var reverseItems: UnsafeMutableBufferPointer<Element> {
    let c = itemCount
    return UnsafeMutableBufferPointer(start: _itemsEnd - c, count: c)
  }

  
  internal func itemPtr(at slot: _HashSlot) -> UnsafeMutablePointer<Element> {
    assert(slot.value <= itemCount)
    return _itemsEnd.advanced(by: -1 &- slot.value)
  }

  
  internal subscript(item slot: _HashSlot) -> Element {
    unsafeAddress {
      UnsafePointer(itemPtr(at: slot))
    }
    nonmutating unsafeMutableAddress {
      assertMutable()
      return itemPtr(at: slot)
    }
  }

  
  internal func clear() {
    assertMutable()
    _header.pointee.clear()
  }
}

extension _HashNode.UnsafeHandle {
  
  internal var hasSingletonItem: Bool {
    _header.pointee.hasSingletonItem
  }

  
  internal var hasSingletonChild: Bool {
    _header.pointee.hasSingletonChild
  }

  
  internal var isAtrophiedNode: Bool {
    hasSingletonChild && self[child: .zero].isCollisionNode
  }
}
