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

/// A type-erased node in a hash tree. This doesn't know about the user data
/// stored in the tree, but it has access to subtree counts and it can be used
/// to freely navigate within the tree structure.
///
/// This construct is powerful enough to implement APIs such as `index(after:)`,
/// `distance(from:to:)`, `index(_:offsetBy:)` in non-generic code.

@frozen
internal struct _RawHashNode {
  
  internal var storage: _RawHashStorage

  
  internal var count: Int

  
  internal init(storage: _RawHashStorage, count: Int) {
    self.storage = storage
    self.count = count
  }
}

extension _RawHashNode {
  @inline(__always)
  internal func read<R>(_ body: (UnsafeHandle) -> R) -> R {
    storage.withUnsafeMutablePointers { header, elements in
      body(UnsafeHandle(header, UnsafeRawPointer(elements)))
    }
  }
}

extension _RawHashNode {
   @inline(__always)
  internal var unmanaged: _UnmanagedHashNode {
    _UnmanagedHashNode(storage)
  }

   @inline(__always)
  internal func isIdentical(to other: _UnmanagedHashNode) -> Bool {
    other.ref.toOpaque() == Unmanaged.passUnretained(storage).toOpaque()
  }
}

extension _RawHashNode {
  
  internal func validatePath(_ path: _UnsafePath) {
    var l = _HashLevel.top
    var n = self.unmanaged
    while l < path.level {
      let slot = path.ancestors[l]
      precondition(slot < n.childrenEndSlot)
      n = n.unmanagedChild(at: slot)
      l = l.descend()
    }
    precondition(n == path.node)
    if path._isItem {
      precondition(path.nodeSlot < n.itemsEndSlot)
    } else {
      precondition(path.nodeSlot <= n.childrenEndSlot)
    }
  }
}
