//
//  CamouflagedDevices.swift
//  MenuBarUSB
//
//  Created by Rafael Neuwirth Swierczynski on 02/09/25.
//

import Foundation

struct CamouflagedDevice: Codable, Identifiable {
    let deviceId: String
    
    var id: String { deviceId }
    
    static func encodeToJson(device: CamouflagedDevice) throws -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let jsonData = try encoder.encode(device)
        guard let jsonString = String(data: jsonData, encoding: .utf8) else {
            throw NSError(domain: "EncodingError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to convert data to string."])
        }
        return jsonString
    }
    
    static func decodeFromJson(jsonString: String) throws -> CamouflagedDevice {
        guard let jsonData = jsonString.data(using: .utf8) else {
            throw NSError(domain: "DecodingError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to convert string to data."])
        }
        return try JSONDecoder().decode(CamouflagedDevice.self, from: jsonData)
    }
}
