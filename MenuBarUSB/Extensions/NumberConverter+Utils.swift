//
//  NumberConverter+Utils.swift
//  MenuBarUSB
//
//  Created by Rafael Neuwirth on 25/09/25.
//

import Foundation

extension NumberConverter {
    private var integerPart: Int {
        Int(number)
    }

    private var fractionalPart: Double {
        Double(number - integerPart)
    }

    func toDecimal(maxFractionDigits: Int = 10) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = maxFractionDigits
        formatter.minimumFractionDigits = 0
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter.string(from: NSNumber(value: number)) ?? String(number)
    }

    func toBinary(maxFractionBits: Int = 16) -> String {
        let intPart = abs(integerPart)
        var result = String(intPart, radix: 2)
        let frac = fractionalPart
        if frac > 0 {
            var f = frac
            var bits = ""
            for _ in 0 ..< maxFractionBits {
                f *= 2
                if f >= 1 {
                    bits.append("1")
                    f -= 1
                } else {
                    bits.append("0")
                }
                if f == 0 { break }
            }
            result += "." + bits
        }
        if number < 0 { result = "-" + result }
        return result
    }

    func toHex(maxFractionDigits: Int = 8) -> String {
        let intPart = abs(integerPart)
        var result = String(intPart, radix: 16).uppercased()
        let frac = fractionalPart
        if frac > 0 {
            var f = frac
            var digits = ""
            let hexDigits = Array("0123456789ABCDEF")
            for _ in 0 ..< maxFractionDigits {
                f *= 16
                let idx = Int(floor(f))
                digits.append(hexDigits[idx])
                f -= Double(idx)
                if f == 0 { break }
            }
            result += "." + digits
        }
        if number < 0 { result = "-" + result }
        return result
    }

    func toRoman() -> String {
        let romanValues = [
            1000: "M", 900: "CM", 500: "D", 400: "CD",
            100: "C", 90: "XC", 50: "L", 40: "XL",
            10: "X", 9: "IX", 5: "V", 4: "IV", 1: "I",
        ]
        var remainder = abs(integerPart)
        var result = ""
        for (value, symbol) in romanValues.sorted(by: { $0.key > $1.key }) {
            let count = remainder / value
            if count > 0 {
                result += String(repeating: symbol, count: count)
                remainder -= value * count
            }
        }
        if fractionalPart > 0 {
            result += " (≈\(String(format: "%.4g", fractionalPart)))"
        }
        if number < 0 { result = "-" + result }
        return result
    }

    func toGreek() -> String {
        let greekNumbers = [
            900: "ϡ", 800: "ω", 700: "ψ", 600: "χ", 500: "φ",
            400: "υ", 300: "τ", 200: "σ", 100: "ρ",
            90: "ϟ", 80: "π", 70: "ο", 60: "ξ", 50: "ν",
            40: "μ", 30: "λ", 20: "κ", 10: "ι",
            9: "θ", 8: "η", 7: "ζ", 6: "ϛ", 5: "ε",
            4: "δ", 3: "γ", 2: "β", 1: "α",
        ]

        var remainder = abs(integerPart)
        var result = ""
        for (value, symbol) in greekNumbers.sorted(by: { $0.key > $1.key }) {
            let count = remainder / value
            if count > 0 {
                result += String(repeating: symbol, count: count)
                remainder -= value * count
            }
        }
        if fractionalPart > 0 {
            let approx = approximateFraction(fractionalPart, maxDenominator: 100)
            result += " (\(approx.n)/\(approx.d))"
        }
        if number < 0 { result = "-" + result }
        return result
    }

    func toEgyptian(maxUnitFractionTerms: Int = 10) -> String {
        let egyptianNumbers: [Int: String] = [
            1: "𓏺",
            10: "𓎆",
            100: "𓍢",
            1000: "𓆼",
            10000: "𓂭",
            100_000: "𓆐",
            1_000_000: "𓁨",
        ]

        var remainder = abs(integerPart)
        var result = ""
        for (value, symbol) in egyptianNumbers.sorted(by: { $0.key > $1.key }) {
            let count = remainder / value
            if count > 0 {
                result += String(repeating: symbol, count: count)
                remainder -= value * count
            }
        }

        if fractionalPart > 0 {
            let terms = egyptianFractionDecompose(fractionalPart, maxTerms: maxUnitFractionTerms)
            let fracStr = terms.map { "1/\($0)" }.joined(separator: " + ")
            result += result.isEmpty ? fracStr : " " + fracStr
        }

        if number < 0 { result = "-" + result }
        return result
    }

    private func egyptianFractionDecompose(_ frac: Double, maxTerms: Int = 10) -> [Int] {
        var f = frac
        var terms: [Int] = []
        var count = 0
        while f > 1e-12, count < maxTerms {
            let denom = Int(ceil(1.0 / f))
            terms.append(denom)
            f -= 1.0 / Double(denom)
            count += 1
            if denom > 1_000_000 { break }
        }
        return terms
    }

    private func approximateFraction(_ value: Double, maxDenominator: Int = 100) -> (n: Int, d: Int) {
        var bestN = 0, bestD = 1
        var bestError = Double.greatestFiniteMagnitude
        for d in 1 ... maxDenominator {
            let n = Int(round(value * Double(d)))
            let error = abs(value - Double(n) / Double(d))
            if error < bestError {
                bestError = error
                bestN = n
                bestD = d
                if error == 0 { break }
            }
        }
        return (bestN, bestD)
    }
}
