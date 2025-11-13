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
    private let key: String
    private let defaultValue: T

    init(wrappedValue: T, _ key: String) {
        self.key = key
        defaultValue = wrappedValue
        if UserDefaults.standard.data(forKey: key) == nil {
            let data = try? JSONEncoder().encode(wrappedValue)
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    var wrappedValue: T {
        get {
            guard let data = UserDefaults.standard.data(forKey: key),
                  let value = try? JSONDecoder().decode(T.self, from: data)
            else { return defaultValue }
            return value
        }
        nonmutating set {
            let data = try? JSONEncoder().encode(newValue)
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    var projectedValue: Binding<T> {
        Binding(
            get: { self.wrappedValue },
            set: { self.wrappedValue = $0 }
        )
    }
}
