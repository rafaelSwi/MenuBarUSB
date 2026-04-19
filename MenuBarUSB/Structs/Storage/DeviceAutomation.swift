//
//  DeviceAutomation.swift
//  MenuBarUSB
//
//  Created by rafael on 11/04/26.
//

import Foundation

struct DeviceAutomation: Codable, Identifiable {
    let deviceId: String
    var automation: String
    let connect: Bool

    var id: String { deviceId }

    static func encodeToJson(device: DeviceAutomation) throws -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let jsonData = try encoder.encode(device)
        guard let jsonString = String(data: jsonData, encoding: .utf8) else {
            throw NSError(domain: "EncodingError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to convert data to string."])
        }
        return jsonString
    }

    static func decodeFromJson(jsonString: String) throws -> DeviceAutomation {
        guard let jsonData = jsonString.data(using: .utf8) else {
            throw NSError(domain: "DecodingError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to convert string to data."])
        }
        return try JSONDecoder().decode(DeviceAutomation.self, from: jsonData)
    }
}
