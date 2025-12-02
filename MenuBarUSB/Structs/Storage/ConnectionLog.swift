//
//  ConnectionLog.swift
//  MenuBarUSB
//
//  Created by Rafael Neuwirth on 02/12/25.
//

import Foundation

struct DeviceConnectionLog: Codable, Identifiable {
    let deviceId: String
    let time: Date
    let disconnect: Bool
    var id: String
    
    init(deviceId: String, time: Date, disconnect: Bool) {
        self.deviceId = deviceId
        self.time = time
        self.disconnect = disconnect
        self.id = UUID().uuidString
    }

    static func encodeToJson(device: DeviceConnectionLog) throws -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let jsonData = try encoder.encode(device)
        guard let jsonString = String(data: jsonData, encoding: .utf8) else {
            throw NSError(domain: "EncodingError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to convert data to string."])
        }
        return jsonString
    }

    static func decodeFromJson(jsonString: String) throws -> DeviceConnectionLog {
        guard let jsonData = jsonString.data(using: .utf8) else {
            throw NSError(domain: "DecodingError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to convert string to data."])
        }
        return try JSONDecoder().decode(DeviceConnectionLog.self, from: jsonData)
    }
}
