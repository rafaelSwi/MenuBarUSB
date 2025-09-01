//
//  CodableAppStorage.swift
//  MenuBarUSB
//
//  Created by Rafael Neuwirth Swierczynski on 31/08/25.
//

import Foundation
import SwiftUI

@propertyWrapper
struct CodableAppStorage<T: Codable>: DynamicProperty {
    @AppStorage private var data: Data
    private let defaultValue: T

    init(wrappedValue: T, _ key: String) {
        self.defaultValue = wrappedValue
        _data = AppStorage(wrappedValue: try! JSONEncoder().encode(wrappedValue), key)
    }

    var wrappedValue: T {
        get {
            (try? JSONDecoder().decode(T.self, from: data)) ?? defaultValue
        }
        nonmutating set {
            data = (try? JSONEncoder().encode(newValue)) ?? Data()
        }
    }

    var projectedValue: Binding<T> {
        Binding(
            get: { self.wrappedValue },
            set: { self.wrappedValue = $0 }
        )
    }
}
