import Foundation

// Reglas del GPT: el encabezado lo arma la app, nunca el modelo.

enum TipoMensaje: String, CaseIterable, Identifiable {
    case cobertura = "Cobertura de turnos"
    case otro = "Otro mensaje"
    var id: String { rawValue }
}

/// Número de 🚨 en el encabezado (0, 1 o 2).
enum Urgencia: Int, CaseIterable, Identifiable {
    case sin = 0, moderada = 1, alta = 2
    var id: Int { rawValue }

    var nombreCobertura: String {
        switch self {
        case .alta: "Alta (menos de 72 h)"
        case .moderada: "Moderada (3 a 7 días)"
        case .sin: "Sin urgencia (más de 7 días)"
        }
    }

    var nombreOtro: String {
        switch self {
        case .sin: "Normal"
        case .moderada: "Urgente"
        case .alta: "Muy urgente"
        }
    }
}

enum Reglas {
    /// <72 h → alta · 72 h a 7 días → moderada · >7 días → sin urgencia.
    static func urgenciaCobertura(turno: Date, ahora: Date = .now) -> Urgencia {
        let horas = turno.timeIntervalSince(ahora) / 3600
        if horas < 72 { return .alta }
        if horas <= 168 { return .moderada }
        return .sin
    }

    static func encabezado(_ u: Urgencia) -> String {
        "👀" + String(repeating: "🚨", count: u.rawValue) + "‼️ *Estimados colegas*"
    }

    /// Saludo + línea en blanco + cuerpo.
    static func mensaje(urgencia: Urgencia, cuerpo: String) -> String {
        encabezado(urgencia) + "\n\n" + limpiar(cuerpo)
    }

    /// En cobertura de turnos, "pago de horas extras" siempre va en negrita; si falta, se agrega.
    static func horasExtras(_ cuerpo: String) -> String {
        let patron = #"\*?((?:con )?pago de horas extras?)\*?"#
        guard cuerpo.range(of: patron, options: [.regularExpression, .caseInsensitive]) != nil else {
            var partes = cuerpo.components(separatedBy: "\n\n")
            partes.insert("*Con pago de horas extras.*", at: min(1, partes.count))
            return partes.joined(separator: "\n\n")
        }
        return cuerpo.components(separatedBy: "\n").map { linea in
            guard let r = linea.range(of: patron, options: [.regularExpression, .caseInsensitive]) else { return linea }
            // ya está dentro de una negrita (*... pago de horas extras ...*): no tocar
            if linea[..<r.lowerBound].contains("*") && linea[r.upperBound...].contains("*") { return linea }
            if linea[r].hasPrefix("*") && linea[r].hasSuffix("*") { return linea }
            return linea.replacingCharacters(in: r, with: "*" + linea[r].trimmingCharacters(in: ["*"]) + "*")
        }.joined(separator: "\n")
    }

    /// Quita un saludo duplicado y convierte **negrita** de Markdown a *negrita* de WhatsApp.
    static func limpiar(_ texto: String) -> String {
        var lineas = texto.replacingOccurrences(of: "**", with: "*")
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .components(separatedBy: "\n")
        while let primera = lineas.first {
            let p = primera.trimmingCharacters(in: .whitespaces)
            let sinAdornos = p.trimmingCharacters(in: CharacterSet.letters.inverted).lowercased()
            if p.isEmpty || sinAdornos.hasPrefix("estimad") && p.count < 40 {
                lineas.removeFirst()
            } else { break }
        }
        return lineas.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
