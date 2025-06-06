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

extension SortedSet: Hashable where Element: Hashable {
  /// Hashes the essential components of this value by feeding them
  /// into the given hasher.
  /// - Parameter hasher: The hasher to use when combining
  ///     the components of this instance.
  /// - Complexity: O(`self.count`)
  
  public func hash(into hasher: inout Hasher) {
    hasher.combine(self.count)
    for element in self {
      hasher.combine(element)
    }
  }
}
