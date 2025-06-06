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


@frozen // Not really! This module isn't ABI stable.
internal struct _RopeVersion {
  // FIXME: Replace this probabilistic mess with atomics when Swift gets its act together.
   internal var _value: UInt

  
  internal init() {
    var rng = SystemRandomNumberGenerator()
    _value = rng.next()
  }

  
  internal init(_ value: UInt) {
    self._value = value
  }
}

extension _RopeVersion: Equatable {
  
  internal static func ==(left: Self, right: Self) -> Bool {
    left._value == right._value
  }
}

extension _RopeVersion {
  
  internal mutating func bump() {
    _value &+= 1
  }

  
  internal mutating func reset() {
    var rng = SystemRandomNumberGenerator()
    _value = rng.next()
  }
}
