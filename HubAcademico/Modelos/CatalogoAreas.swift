import Foundation

// Gerado por ferramentas/catalogo/gerar_catalogo.py a partir da tabela do CNPq
// e dos currículos da UFSM. Não edite à mão: ajuste os dados e rode-o de novo.
// Só entram subáreas com ao menos uma disciplina no catálogo atual da UFSM.

extension AreaConhecimento {
    /// Grandes áreas na ordem da tabela do CNPq (a mesma da lista enviada).
    static let naOrdemDoCNPq: [AreaConhecimento] = [.exatas, .agrarias, .biologicas, .saude, .humanas, .sociaisAplicadas, .engenharias, .linguisticaLetrasArtes]

    /// Nome completo da grande área, como na tabela do CNPq.
    var nomeCompleto: String {
        switch self {
        case .exatas: "Ciências Exatas e da Terra"
        case .agrarias: "Ciências Agrárias"
        case .biologicas: "Ciências Biológicas"
        case .saude: "Ciências da Saúde"
        case .humanas: "Ciências Humanas"
        case .sociaisAplicadas: "Ciências Sociais Aplicadas"
        case .engenharias: "Engenharias"
        case .linguisticaLetrasArtes: "Linguística, Letras e Artes"
        }
    }

    /// Subáreas com disciplinas no catálogo da UFSM, na ordem da tabela do CNPq.
    /// "Agronomia/Ciência do Solo" indica a subárea Ciência do Solo dentro de Agronomia.
    var subareas: [String] {
        switch self {
        case .exatas:
            [
                "Astronomia",
                "Ciência da Computação",
                "Física",
                "Geociências",
                "Matemática",
                "Oceanografia",
                "Probabilidade e Estatística",
                "Química",
            ]
        case .agrarias:
            [
                "Agronomia/Agrometeorologia",
                "Agronomia/Ciência do Solo",
                "Agronomia/Extensão Rural",
                "Agronomia/Fitossanidade",
                "Agronomia/Fitotecnia",
                "Agronomia/Floricultura, Parques e Jardins",
                "Ciência e Tecnologia de Alimentos/Ciência de Alimentos",
                "Ciência e Tecnologia de Alimentos/Engenharia de Alimentos",
                "Ciência e Tecnologia de Alimentos/Tecnologia de Alimentos",
                "Engenharia Agrícola",
                "Medicina Veterinária/Clínica e Cirurgia Animal",
                "Medicina Veterinária/Inspeção de Produtos de Origem Animal",
                "Medicina Veterinária/Medicina Veterinária Preventiva",
                "Medicina Veterinária/Patologia Animal",
                "Medicina Veterinária/Reprodução Animal",
                "Recursos Florestais e Engenharia Florestal",
                "Recursos Pesqueiros e Engenharia de Pesca",
                "Zootecnia/Ecologia dos Animais Domésticos e Etologia",
                "Zootecnia/Genética e Melhoramento dos Animais Domésticos",
                "Zootecnia/Nutrição e Alimentação Animal",
                "Zootecnia/Pastagem e Forragicultura",
                "Zootecnia/Produção Animal",
            ]
        case .biologicas:
            [
                "Biofísica",
                "Biologia Geral",
                "Bioquímica",
                "Botânica",
                "Ecologia",
                "Farmacologia",
                "Fisiologia",
                "Genética",
                "Imunologia",
                "Microbiologia",
                "Morfologia",
                "Parasitologia",
                "Zoologia",
            ]
        case .saude:
            [
                "Educação Física",
                "Enfermagem",
                "Farmácia",
                "Fisioterapia e Terapia Ocupacional",
                "Fonoaudiologia",
                "Medicina/Clínica Médica",
                "Medicina/Cirurgia",
                "Medicina/Saúde Materno-Infantil",
                "Medicina/Psiquiatria",
                "Medicina/Anatomia Patológica e Patologia Clínica",
                "Medicina/Radiologia Médica",
                "Medicina/Medicina Legal e Deontologia",
                "Nutrição",
                "Odontologia",
                "Saúde Coletiva",
            ]
        case .humanas:
            [
                "Antropologia",
                "Arqueologia",
                "Ciência Política",
                "Educação/Fundamentos da Educação",
                "Educação/Administração Educacional",
                "Educação/Planejamento e Avaliação Educacional",
                "Educação/Ensino-Aprendizagem",
                "Educação/Currículo",
                "Educação/Tópicos Especiais em Educação",
                "Filosofia",
                "Geografia",
                "História",
                "Psicologia",
                "Sociologia",
            ]
        case .sociaisAplicadas:
            [
                "Administração",
                "Arquitetura e Urbanismo",
                "Arquivologia",
                "Comunicação",
                "Demografia",
                "Desenho Industrial",
                "Direito",
                "Economia",
                "Planejamento Urbano e Regional",
                "Serviço Social",
                "Turismo",
            ]
        case .engenharias:
            [
                "Engenharia Acústica",
                "Engenharia Aeroespacial",
                "Engenharia Biomédica",
                "Engenharia Civil",
                "Engenharia de Materiais e Metalúrgica",
                "Engenharia de Minas",
                "Engenharia de Produção",
                "Engenharia de Transportes",
                "Engenharia Elétrica",
                "Engenharia Mecânica",
                "Engenharia Nuclear",
                "Engenharia Química",
                "Engenharia Sanitária",
            ]
        case .linguisticaLetrasArtes:
            [
                "Artes/Artes Plásticas",
                "Artes/Dança",
                "Artes/Música",
                "Artes/Teatro",
                "Letras",
                "Linguística",
            ]
        }
    }
}
