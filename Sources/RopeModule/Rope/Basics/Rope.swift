//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2023 - 2024 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

/// An ordered data structure of `Element` values that organizes itself into a tree.
/// The rope is augmented by the commutative group specified by `Element.Summary`, enabling
/// quick lookup operations.
@frozen // Not really! This module isn't ABI stable.
public struct Rope<Element: RopeElement> {
  internal var _root: _Node?
  internal var _version: _RopeVersion
  public init() {
    self._root = nil
    self._version = _RopeVersion()
  }
  internal init(root: _Node?) {
    self._root = root
    self._version = _RopeVersion()
  }
  internal var root: _Node {
    @inline(__always) get { _root.unsafelyUnwrapped }
    @inline(__always) _modify { yield &_root! }
  }
  public init(_ value: Element) {
    self._root = .createLeaf(_Item(value))
    self._version = _RopeVersion()
  }
}

extension Rope: Sendable where Element: Sendable {}

extension Rope {
  internal mutating func _ensureUnique() {
    guard _root != nil else { return }
    root.ensureUnique()
  }
}

extension Rope {
  public var isSingleton: Bool {
    guard _root != nil else { return false }
    return root.isSingleton
  }
}

extension Rope {
  public func isIdentical(to other: Self) -> Bool {
    self._root?.object === other._root?.object
  }
}
