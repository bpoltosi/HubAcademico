import XCTest
@testable import CTIA

final class AcademicModelsTests: XCTestCase {
    
    // MARK: - 1. Regra de Ordenação Crescente no Menu (8 -> 22 caracteres)
    func testMenuCharacterOrderingRule() throws {
        let menuItems = [
            "Projetos",              // 8
            "Banco de provas",       // 15
            "Trabalhos acadêmicos",  // 20
            "Material complementar", // 21
            "Cadastre o seu projeto" // 22
        ]
        
        XCTAssertEqual(menuItems[0].count, 8)
        XCTAssertEqual(menuItems[1].count, 15)
        XCTAssertEqual(menuItems[2].count, 20)
        XCTAssertEqual(menuItems[3].count, 21)
        XCTAssertEqual(menuItems[4].count, 22)
        
        XCTAssertTrue(AcademicCatalogLogic.verifyCharacterOrdering(menuItems))
        
        // Verifica se itens fora de ordem falham
        let outOfOrder = ["Trabalhos acadêmicos", "Projetos"]
        XCTAssertFalse(AcademicCatalogLogic.verifyCharacterOrdering(outOfOrder))
    }
    
    // MARK: - 2. Regra de Ordenação Crescente nos Filtros (3 -> 16 caracteres)
    func testFilterCharacterOrderingRule() throws {
        let filterLabels = [
            "Ano",              // 3
            "Área",             // 4
            "Autor",            // 5
            "Curso",            // 5
            "Título",           // 6
            "Matéria",          // 7
            "Melhor avaliação"  // 16
        ]
        
        XCTAssertEqual(filterLabels.first?.count, 3)
        XCTAssertEqual(filterLabels.last?.count, 16)
        XCTAssertTrue(AcademicCatalogLogic.verifyCharacterOrdering(filterLabels))
    }
    
    // MARK: - 3. Validação do Resumo limitado a 200 Caracteres
    func testSummaryCharacterLimitValidation() throws {
        let validSummary = "Protótipo com ESP32 e sensor de som que mede o ruído das oficinas do CTISM em tempo real e emite alerta quando o nível passa de 85 dB, apoiando a prevenção de perdas auditivas."
        
        XCTAssertEqual(validSummary.count, 176)
        XCTAssertLessThanOrEqual(validSummary.count, 200)
        
        let validResult = AcademicCatalogLogic.validateAcademicItem(
            titulo: "Monitor IoT de ruído nas oficinas do CTISM",
            resumo: validSummary,
            area: "Engenharias",
            materia: "Higiene Ocupacional"
        )
        XCTAssertTrue(validResult.isValid)
        XCTAssertEqual(validResult.charCount, 176)
        
        // Testa texto que excede 200 caracteres
        let overLimitText = String(repeating: "A", count: 201)
        let invalidResult = AcademicCatalogLogic.validateAcademicItem(
            titulo: "Projeto Excedente",
            resumo: overLimitText,
            area: "Engenharias",
            materia: "Higiene Ocupacional"
        )
        XCTAssertFalse(invalidResult.isValid)
        XCTAssertNotNil(invalidResult.errors["resumo"])
    }
    
    // MARK: - 4. Filtro de Itens Acadêmicos
    func testFilteringAcademicItems() throws {
        let items = AcademicItem.mockList
        
        // Busca textual por "ruído"
        let filteredByNoise = AcademicCatalogLogic.filterAcademicItems(
            items: items,
            filters: SearchFilters(termoBusca: "ruído")
        )
        XCTAssertEqual(filteredByNoise.count, 2)
        
        // Filtro por melhor avaliação (>= 4.5)
        let filteredBest = AcademicCatalogLogic.filterAcademicItems(
            items: items,
            filters: SearchFilters(melhorAvaliacao: true)
        )
        XCTAssertGreaterThanOrEqual(filteredBest.count, 2)
        for item in filteredBest {
            XCTAssertGreaterThanOrEqual(item.avaliacao, 4.5)
        }
        
        // Filtro por ano 2025
        let filtered2025 = AcademicCatalogLogic.filterAcademicItems(
            items: items,
            filters: SearchFilters(ano: 2025)
        )
        XCTAssertEqual(filtered2025.count, 1)
        XCTAssertEqual(filtered2025.first?.ano, 2025)
    }
    
    // MARK: - 5. Formatação Decimal Brasileira
    func testBrazilianRatingFormat() throws {
        XCTAssertEqual(AcademicCatalogLogic.formatRatingBR(4.8), "4,8")
        XCTAssertEqual(AcademicCatalogLogic.formatRatingBR(4.6), "4,6")
        XCTAssertEqual(AcademicCatalogLogic.formatRatingBR(5.0), "5,0")
    }
    
    // MARK: - 6. Telemetria IoT e Dados Mock
    func testMockItemTelemetryValues() throws {
        let item = AcademicItem.mockNoiseMonitor
        
        XCTAssertEqual(item.tipo, .projeto)
        XCTAssertEqual(item.dbAtual, 82.0)
        XCTAssertEqual(item.limiteDb, 85.0)
        XCTAssertEqual(item.statusAoVivo, "AO VIVO")
        XCTAssertEqual(item.sensorChip, "ESP32 · Wi-Fi")
        XCTAssertEqual(item.avaliacao, 4.8)
        XCTAssertEqual(item.totalAvaliacoes, 37)
        XCTAssertEqual(item.linkTipo, "LinkedIn")
    }
}
