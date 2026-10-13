import Foundation
import FoundationModels

@Generable
struct Redaccion {
    @Guide(description: "Cuerpo del mensaje de WhatsApp, sin saludo inicial")
    var cuerpo: String
    @Guide(description: "Urgencia del contenido: 0 normal, 1 urgente, 2 muy urgente", .range(0...2))
    var urgencia: Int
}

/// Redacción con el modelo de Apple Intelligence del propio equipo: sin clave, sin internet, sin costo.
enum Redactor {
    static var disponible: Bool { SystemLanguageModel.default.isAvailable }

    static var motivoNoDisponible: String {
        switch SystemLanguageModel.default.availability {
        case .available: ""
        case .unavailable(.deviceNotEligible): "Este equipo no es compatible con Apple Intelligence."
        case .unavailable(.appleIntelligenceNotEnabled): "Activa Apple Intelligence en Ajustes para redactar con IA."
        case .unavailable(.modelNotReady): "El modelo de Apple Intelligence aún se está descargando."
        case .unavailable: "Apple Intelligence no está disponible."
        }
    }

    static let instrucciones = """
    Actúas como un experto en redacción profesional, con formación en lingüística y experiencia \
    operativa en servicios médicos de urgencias. Redactas mensajes de WhatsApp que un médico jefe \
    envía a los médicos bajo su coordinación.
    Reglas:
    - Escribe solo el cuerpo del mensaje. No incluyas saludo inicial: la app antepone "Estimados colegas".
    - Tono formal, claro, directo y respetuoso. Evita ambigüedades: fechas, horarios y lugares explícitos.
    - Ortografía y gramática impecables en español de Chile.
    - Mensaje breve, fácil de adaptar y reutilizar en contextos similares.
    - Formato de WhatsApp: *negrita* con un asterisco solo para datos clave. Nada de Markdown, títulos ni emojis.
    - No inventes datos que no se entregaron. Si falta uno imprescindible, escribe [completar].
    - Puedes cerrar con un agradecimiento breve. Sin firma.
    """

    static func redactar(tipo: TipoMensaje, borrador: String, fechaTurno: Date?) async throws -> Redaccion {
        let session = LanguageModelSession(instructions: instrucciones)
        var prompt = "Tipo de mensaje: \(tipo == .cobertura ? "solicitud de cobertura de turnos" : "comunicación general (no es cobertura de turnos)").\n"
        if let f = fechaTurno {
            prompt += "Fecha del turno: \(f.formatted(.dateTime.weekday(.wide).day().month(.wide).hour().minute().locale(Locale(identifier: "es_CL")))).\n"
        }
        if tipo == .cobertura {
            prompt += "Indica que los turnos son *con pago de horas extras* (en negrita).\n"
        }
        prompt += "Lo que quiero comunicar:\n\(borrador)"
        return try await session.respond(to: prompt, generating: Redaccion.self).content
    }

    /// Corrige ortografía, gramática y claridad sin cambiar el contenido.
    static func corregir(_ texto: String) async throws -> String {
        let session = LanguageModelSession(instructions: instrucciones)
        let prompt = "Corrige ortografía, gramática, puntuación y claridad del siguiente cuerpo de mensaje. "
            + "Conserva el contenido, los datos y el formato *negrita*. Devuelve solo el texto corregido:\n\n\(texto)"
        return try await session.respond(to: prompt).content
    }
}
