//
//  Currency.swift
//  CosteReunion
//
//  Monedas que puede elegir el usuario en Ajustes.
//

import Foundation

/// Moneda con la que se muestran los importes.
///
/// El `rawValue` es directamente el código ISO 4217 (p. ej. "EUR"), que es lo
/// que pide `FormatStyle.currency(code:)`. Al ser un `enum` limitamos las
/// opciones a valores válidos (no cabe un código inventado) y persistirlo es
/// tan simple como guardar ese texto.
enum Currency: String, CaseIterable, Identifiable, Codable {
    case eur = "EUR"
    case usd = "USD"
    case gbp = "GBP"
    case jpy = "JPY"
    case chf = "CHF"
    case mxn = "MXN"
    case cad = "CAD"
    case aud = "AUD"

    var id: String { rawValue }

    /// Código ISO que se pasa al formateador de importes.
    var code: String { rawValue }

    /// Texto legible para el selector de Ajustes.
    var displayName: String {
        switch self {
        case .eur: "Euro (€)"
        case .usd: "Dólar EE. UU. (US$)"
        case .gbp: "Libra (£)"
        case .jpy: "Yen (¥)"
        case .chf: "Franco suizo (CHF)"
        case .mxn: "Peso mexicano (MX$)"
        case .cad: "Dólar canadiense (CA$)"
        case .aud: "Dólar australiano (A$)"
        }
    }
}
