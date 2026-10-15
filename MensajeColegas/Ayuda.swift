import SwiftUI

/// Ayuda integrada en español (mismo formato que Reclamos): ícono + título + explicación, pasos y atajos.
struct TemaAyuda: Identifiable {
    let id = UUID()
    let icono: String
    let titulo: String
    let texto: String
    var pasos: [String] = []
}

struct VistaAyuda: View {
    let app: String
    let intro: String
    let temas: [TemaAyuda]
    let atajos: [(String, String)]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Ayuda de \(app)").font(.title2.bold())
                Text(intro).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
                ForEach(temas) { t in
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: t.icono).font(.title3).frame(width: 26).foregroundStyle(.tint)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(t.titulo).font(.headline)
                            Text(t.texto).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
                            ForEach(Array(t.pasos.enumerated()), id: \.offset) { i, p in
                                Text("\(i + 1). \(p)").font(.callout).fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                }
                if !atajos.isEmpty {
                    Divider()
                    Text("Atajos de teclado").font(.headline)
                    Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 6) {
                        ForEach(atajos, id: \.0) { a in
                            GridRow { Text(a.0).monospaced().bold(); Text(a.1) }
                        }
                    }
                }
            }
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

struct AyudaMensajeColegas: View {
    var body: some View {
        VistaAyuda(
            app: "Mensaje Colegas",
            intro: "Mensaje Colegas redacta mensajes de WhatsApp para los médicos del servicio con el encabezado de urgencia correcto, y los deja listos para pegar en el chat o grupo.",
            temas: [
                TemaAyuda(icono: "list.bullet.rectangle", titulo: "1. Tipo de mensaje",
                          texto: "«Cobertura de turnos» para pedir reemplazos; «Otro mensaje» para cualquier otro aviso."),
                TemaAyuda(icono: "calendar", titulo: "2. Fecha y hora del turno",
                          texto: "Solo en cobertura. La urgencia se calcula sola según cuánto falta: Alta (menos de 72 h), Moderada (3 a 7 días) o Sin urgencia (más de 7 días). En «Urgencia» puedes elegirla a mano."),
                TemaAyuda(icono: "sparkles", titulo: "3. Qué quieres comunicar",
                          texto: "Escribe la idea con tus palabras.",
                          pasos: ["«Redactar con IA» la convierte en un mensaje claro y cordial (requiere Apple Intelligence en el iPhone).", "«Usar mi texto sin IA» la usa tal cual.", "Revisa el «Cuerpo (editable)»; «Corregir con IA» arregla ortografía y redacción."]),
                TemaAyuda(icono: "bubble.left.and.text.bubble.right", titulo: "4. Vista previa en WhatsApp",
                          texto: "Muestra el mensaje como se verá: el encabezado de urgencia, el turno y las horas extras en negrita."),
                TemaAyuda(icono: "paperplane", titulo: "5. Enviar",
                          texto: "«Copiar mensaje» lo deja en el portapapeles; «Pegar en WhatsApp» abre WhatsApp con el texto listo para elegir el chat o grupo; «Elegir app» sirve para WhatsApp Business u otra."),
                TemaAyuda(icono: "square.and.pencil", titulo: "Nuevo",
                          texto: "El botón de arriba a la derecha borra todo para empezar otro mensaje."),
            ],
            atajos: [])
    }
}
