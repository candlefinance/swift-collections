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


@frozen
internal struct _DequeSlot {
  
  internal var position: Int

  
  @inline(__always)
  init(at position: Int) {
    assert(position >= 0)
    self.position = position
  }
}

extension _DequeSlot {
  
  @inline(__always)
  internal static var zero: Self { Self(at: 0) }

  
  @inline(__always)
  internal func advanced(by delta: Int) -> Self {
    Self(at: position &+ delta)
  }

  
  @inline(__always)
  internal func orIfZero(_ value: Int) -> Self {
    guard position > 0 else { return Self(at: value) }
    return self
  }
}

extension _DequeSlot: CustomStringConvertible {
  
  internal var description: String {
    "@\(position)"
  }
}

extension _DequeSlot: Equatable {
  
  @inline(__always)
  static func ==(left: Self, right: Self) -> Bool {
    left.position == right.position
  }
}

extension _DequeSlot: Comparable {
  
  @inline(__always)
  static func <(left: Self, right: Self) -> Bool {
    left.position < right.position
  }
}

extension Range where Bound == _DequeSlot {
  
  @inline(__always)
  internal var _count: Int { upperBound.position - lowerBound.position }
}
