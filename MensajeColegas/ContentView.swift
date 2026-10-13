import SwiftUI

struct ContentView: View {
    @State private var tipo: TipoMensaje = .cobertura
    @State private var fechaTurno = Calendar.current.date(byAdding: .day, value: 1, to: .now)!
    @State private var urgenciaManual: Urgencia?          // nil = automática
    @State private var urgenciaIA: Urgencia = .sin
    @State private var borrador = ""
    @State private var cuerpo = ""
    @State private var redactando = false
    @State private var corrigiendo = false
    @State private var error: String?
    @State private var copiado = false
    @FocusState private var foco: Bool
    @Environment(\.openURL) private var openURL

    private var urgenciaAuto: Urgencia {
        tipo == .cobertura ? Reglas.urgenciaCobertura(turno: fechaTurno) : urgenciaIA
    }
    private var urgencia: Urgencia { urgenciaManual ?? urgenciaAuto }
    private var mensaje: String {
        Reglas.mensaje(urgencia: urgencia, cuerpo: tipo == .cobertura ? Reglas.horasExtras(cuerpo) : cuerpo)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Tipo", selection: $tipo) {
                        ForEach(TipoMensaje.allCases) { Text($0.rawValue).tag($0) }
                    }
                    .pickerStyle(.segmented)
                    if tipo == .cobertura {
                        DatePicker("Turno", selection: $fechaTurno)
                    }
                    Picker("Urgencia", selection: $urgenciaManual) {
                        Text("Automática: \(nombre(urgenciaAuto))").tag(Urgencia?.none)
                        ForEach(Urgencia.allCases.reversed()) { Text(nombre($0)).tag(Urgencia?.some($0)) }
                    }
                    Text(vistaWhatsApp(Reglas.encabezado(urgencia))).font(.headline)
                }

                Section("Qué quieres comunicar") {
                    TextEditor(text: $borrador)
                        .frame(minHeight: 110)
                        .focused($foco)
                    Button {
                        Task { await redactar() }
                    } label: {
                        HStack {
                            Label("Redactar con IA", systemImage: "sparkles")
                            if redactando { Spacer(); ProgressView() }
                        }
                    }
                    .disabled(borrador.isEmpty || redactando || !Redactor.disponible)
                    Button("Usar mi texto sin IA", systemImage: "text.alignleft") {
                        cuerpo = borrador; foco = false
                    }
                    .disabled(borrador.isEmpty)
                    if !Redactor.disponible {
                        Text(Redactor.motivoNoDisponible).font(.footnote).foregroundStyle(.secondary)
                    }
                    if let error { Text(error).font(.footnote).foregroundStyle(.red) }
                }

                if !cuerpo.isEmpty {
                    Section("Cuerpo (editable)") {
                        TextEditor(text: $cuerpo).frame(minHeight: 160).focused($foco)
                        Button {
                            Task { await corregir() }
                        } label: {
                            HStack {
                                Label("Corregir con IA", systemImage: "checkmark.seal")
                                if corrigiendo { Spacer(); ProgressView() }
                            }
                        }
                        .disabled(corrigiendo || !Redactor.disponible)
                    }
                    Section("Vista previa en WhatsApp") {
                        Text(vistaWhatsApp(mensaje))
                            .textSelection(.enabled)
                            .padding(10)
                            .background(Color.green.opacity(0.15), in: .rect(cornerRadius: 10))
                    }
                    Section {
                        Button(copiado ? "Copiado" : "Copiar mensaje",
                               systemImage: copiado ? "checkmark" : "doc.on.doc") {
                            UIPasteboard.general.string = mensaje
                            copiado = true
                            Task { try? await Task.sleep(for: .seconds(2)); copiado = false }
                        }
                        Button("Pegar en WhatsApp", systemImage: "paperplane") { abrir("whatsapp") }
                        ShareLink("Elegir app (WhatsApp Business, otra)…", item: mensaje)
                    } footer: {
                        Text("WhatsApp se abre con el mensaje listo; ahí eliges el chat o grupo.")
                    }
                }
            }
            .navigationTitle("Mensaje Colegas")
            .toolbar {
                ToolbarItem(placement: .keyboard) { Button("Listo") { foco = false } }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Nuevo", systemImage: "square.and.pencil") {
                        borrador = ""; cuerpo = ""; error = nil; urgenciaManual = nil; urgenciaIA = .sin
                    }
                }
            }
        }
    }

    private func nombre(_ u: Urgencia) -> String {
        tipo == .cobertura ? u.nombreCobertura : u.nombreOtro
    }

    private func redactar() async {
        foco = false; redactando = true; error = nil
        defer { redactando = false }
        do {
            let r = try await Redactor.redactar(tipo: tipo, borrador: borrador,
                                                fechaTurno: tipo == .cobertura ? fechaTurno : nil)
            cuerpo = Reglas.limpiar(r.cuerpo)
            urgenciaIA = Urgencia(rawValue: r.urgencia) ?? .sin
        } catch {
            self.error = "No se pudo redactar: \(String(describing: error))"
        }
    }

    private func corregir() async {
        foco = false; corrigiendo = true; error = nil
        defer { corrigiendo = false }
        do { cuerpo = Reglas.limpiar(try await Redactor.corregir(cuerpo)) }
        catch { self.error = "No se pudo corregir: \(String(describing: error))" }
    }

    private func abrir(_ esquema: String) {
        UIPasteboard.general.string = mensaje
        let t = mensaje.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? ""
        guard let url = URL(string: "\(esquema)://send?text=\(t)") else { return }
        openURL(url) { ok in
            if !ok { error = "No encontré esa app. El mensaje quedó copiado: pégalo donde quieras." }
        }
    }

    /// Muestra *negrita*, _cursiva_ y ~tachado~ como los dibuja WhatsApp.
    private func vistaWhatsApp(_ t: String) -> AttributedString {
        var md = t.replacingOccurrences(of: #"(?<![\w*])\*(\S(?:[^*\n]*\S)?)\*(?![\w*])"#, with: "**$1**", options: .regularExpression)
        md = md.replacingOccurrences(of: #"(?<![\w~])~(\S(?:[^~\n]*\S)?)~(?![\w~])"#, with: "~~$1~~", options: .regularExpression)
        return (try? AttributedString(markdown: md, options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace)))
            ?? AttributedString(t)
    }
}
