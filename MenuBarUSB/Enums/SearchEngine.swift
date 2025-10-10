//
//  SearchEngine.swift
//  MenuBarUSB
//
//  Created by Rafael Neuwirth on 03/10/25.
//

enum SearchEngine: String, CaseIterable {
    case google = "Google"
    case bing = "Bing"
    case duckDuckGo = "DuckDuckGo"
    case yahoo = "Yahoo"
    case naver = "Naver"
    case daum = "Daum"
    case baidu = "Baidu"
    case yandex = "Yandex"
    case ecosia = "Ecosia"
    case startpage = "Startpage"
    case qwant = "Qwant"
    case ask = "Ask"
    case aol = "AOL"
    case searx = "Searx"
    case gibiru = "Gibiru"
    case wolframAlpha = "Wolfram"
    case metager = "MetaGer"
    case swisscows = "Swisscows"

    var searchURL: String {
        switch self {
        case .google: return "https://www.google.com/search?q="
        case .bing: return "https://www.bing.com/search?q="
        case .duckDuckGo: return "https://duckduckgo.com/?q="
        case .yahoo: return "https://search.yahoo.com/search?p="
        case .naver: return "https://search.naver.com/search.naver?query="
        case .daum: return "https://search.daum.net/search?q="
        case .baidu: return "https://www.baidu.com/s?wd="
        case .yandex: return "https://yandex.com/search/?text="
        case .ecosia: return "https://www.ecosia.org/search?q="
        case .startpage: return "https://www.startpage.com/do/dsearch?query="
        case .qwant: return "https://www.qwant.com/?q="
        case .ask: return "https://www.ask.com/web?q="
        case .aol: return "https://search.aol.com/aol/search?q="
        case .searx: return "https://searx.org/?q="
        case .gibiru: return "https://gibiru.com/results.html?q="
        case .wolframAlpha: return "https://www.wolframalpha.com/input/?i="
        case .metager: return "https://www.metager.org/meta/meta.ger3?eingabe="
        case .swisscows: return "https://swisscows.com/web?query="
        }
    }
}
