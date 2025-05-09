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

/// The storage header in a hash tree node. This includes data about the
/// current size and capacity of the node's storage region, as well as
/// information about the currently occupied hash table buckets.
internal struct _HashNodeHeader {
  internal var itemMap: _Bitmap
  internal var childMap: _Bitmap
  internal var _byteCapacity: UInt32
  internal var _bytesFree: UInt32
  internal init(byteCapacity: Int) {
    assert(byteCapacity >= 0 && byteCapacity <= UInt32.max)
    self.itemMap = .empty
    self.childMap = .empty
    self._byteCapacity = UInt32(truncatingIfNeeded: byteCapacity)
    self._bytesFree = self._byteCapacity
  }
}

extension _HashNodeHeader {
  @inline(__always)
  internal var byteCapacity: Int {
    get { Int(truncatingIfNeeded: _byteCapacity) }
  }
  internal var bytesFree: Int {
    @inline(__always)
    get { Int(truncatingIfNeeded: _bytesFree) }
    set {
      assert(newValue >= 0 && newValue <= UInt32.max)
      _bytesFree = UInt32(truncatingIfNeeded: newValue)
    }
  }
}

extension _HashNodeHeader {
  @inline(__always)
  internal var isEmpty: Bool {
    return itemMap.isEmpty && childMap.isEmpty
  }

  @inline(__always)
  internal var isCollisionNode: Bool {
    !itemMap.isDisjoint(with: childMap)
  }

  @inline(__always)
  internal var hasChildren: Bool {
    itemMap != childMap && !childMap.isEmpty
  }

  @inline(__always)
  internal var hasItems: Bool {
    !itemMap.isEmpty
  }
  internal var childCount: Int {
    itemMap == childMap ? 0 : childMap.count
  }
  internal var itemCount: Int {
    (itemMap == childMap
     ? Int(truncatingIfNeeded: itemMap._value)
     : itemMap.count)
  }
  internal var hasSingletonChild: Bool {
    itemMap.isEmpty && childMap.hasExactlyOneMember
  }
  internal var hasSingletonItem: Bool {
    if itemMap == childMap {
      return itemMap._value == 1
    }
    return childMap.isEmpty && itemMap.hasExactlyOneMember
  }

  @inline(__always)
  internal var childrenEndSlot: _HashSlot {
    _HashSlot(childCount)
  }

  @inline(__always)
  internal var itemsEndSlot: _HashSlot {
    _HashSlot(itemCount)
  }
  internal var collisionCount: Int {
    get {
      assert(isCollisionNode)
      return Int(truncatingIfNeeded: itemMap._value)
    }
    set {
      assert(isCollisionNode || childMap.isEmpty)
      assert(newValue > 0 && newValue < _Bitmap.Value.max)
      itemMap._value = _Bitmap.Value(truncatingIfNeeded: newValue)
      childMap = itemMap
    }
  }
}

extension _HashNodeHeader {
  internal mutating func clear() {
    itemMap = .empty
    childMap = .empty
    bytesFree = byteCapacity
  }
}
