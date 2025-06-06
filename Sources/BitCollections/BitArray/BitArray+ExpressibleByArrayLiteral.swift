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

extension BitArray: ExpressibleByArrayLiteral {
  /// Creates an instance initialized with the given elements.
  
  public init(arrayLiteral elements: Bool...) {
    self.init(elements)
  }
}
