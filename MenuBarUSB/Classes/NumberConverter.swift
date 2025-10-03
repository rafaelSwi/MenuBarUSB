//
//  NumberConverter.swift
//  MenuBarUSB
//
//  Created by Rafael Neuwirth on 25/09/25.
//

import SwiftUI
import Foundation

final class NumberConverter {
    
    @AppStorage(StorageKeys.numberRepresentation)
    private var storedRepresentation: String = NumberRepresentation.base10.rawValue
    
    var number: Int
    
    init(_ value: Int) {
        self.number = value
    }
    
    func convert() -> String {
        let representation = NumberRepresentation(rawValue: storedRepresentation) ?? .base10
        
        switch representation {
        case .base10:
            return toDecimal()
        case .egyptian:
            return toEgyptian()
        case .greek:
            return toGreek()
        case .roman:
            return toRoman()
        }
    }
}
