//
//  HardwareSound.swift
//  MenuBarUSB
//
//  Created by Rafael Neuwirth on 14/11/25.
//

import SwiftUI

struct HardwareSound: Codable {
    let uniqueId: String
    let titleKey: String
    let connect: String
    let disconnect: String?

    static subscript(_ key: String) -> HardwareSound? {
        for i in HardwareSound.all {
            if i.uniqueId == key {
                return i
            }
        }
        for i in CSM.Sound.all {
            if i.uniqueId == key {
                return i
            }
        }
        return nil
    }

    static let win_modern = HardwareSound(uniqueId: "WIN_MODERN", titleKey: "win_modern", connect: "win_modern_connect", disconnect: "win_modern_disconnect")
    static let win_old = HardwareSound(uniqueId: "WIN_OLD", titleKey: "win_old", connect: "win_old_connect", disconnect: "win_old_disconnect")
    static let win_xp = HardwareSound(uniqueId: "WIN_XP", titleKey: "win_xp", connect: "win_xp_connect", disconnect: "win_xp_disconnect")
    static let ubuntu = HardwareSound(uniqueId: "L_UBUNTU", titleKey: "linux_ubuntu", connect: "ubuntu_connect", disconnect: "ubuntu_disconnect")
    static let mint = HardwareSound(uniqueId: "L_MINT", titleKey: "linux_mint", connect: "mint_connect", disconnect: "mint_disconnect")
    static let nx = HardwareSound(uniqueId: "NX", titleKey: "NX", connect: "nx_notification", disconnect: "ounce_tap")
    static let ounce = HardwareSound(uniqueId: "OUNCE", titleKey: "Ounce", connect: "ounce_connect", disconnect: "ounce_disconnect")
    static let revolution = HardwareSound(uniqueId: "REVOLUTION", titleKey: "Revolution", connect: "revolution_connect", disconnect: "revolution_disconnect")
    static let citrus = HardwareSound(uniqueId: "CITRUS", titleKey: "Citrus", connect: "citrus_connect", disconnect: "citrus_disconnect")
    static let heist = HardwareSound(uniqueId: "HEIST", titleKey: "heist", connect: "heist_connect", disconnect: "heist_disconnect")
    static let man = HardwareSound(uniqueId: "MAN", titleKey: "generic_man", connect: "man_connected", disconnect: "man_disconnected")
    static let woman = HardwareSound(uniqueId: "WOMAN", titleKey: "generic_woman", connect: "woman_connected", disconnect: "woman_disconnected")
    static let orbis = HardwareSound(uniqueId: "ORBIS", titleKey: "Orbis", connect: "orbis_connect", disconnect: "orbis_disconnect")
    static let oberon = HardwareSound(uniqueId: "OBERON", titleKey: "Oberon", connect: "oberon_connect", disconnect: "oberon_disconnect")
    static let xenon = HardwareSound(uniqueId: "XENON", titleKey: "Xenon", connect: "xenon_connect", disconnect: "xenon_disconnect")
    static let durango = HardwareSound(uniqueId: "DURANGO", titleKey: "Durango", connect: "durango_connect", disconnect: "durango_disconnect")

    static var all: [HardwareSound] {
        var all = [
            HardwareSound.win_modern,
            HardwareSound.win_old,
            HardwareSound.win_xp,
            HardwareSound.ubuntu,
            HardwareSound.mint,
            HardwareSound.nx,
            HardwareSound.ounce,
            HardwareSound.revolution,
            HardwareSound.citrus,
            HardwareSound.orbis,
            HardwareSound.oberon,
            HardwareSound.xenon,
            HardwareSound.durango,
            HardwareSound.heist,
            HardwareSound.man,
            HardwareSound.woman,
        ]
        all.append(contentsOf: CSM.Sound.all)
        return all
    }
}
