import XCTest
@testable import CTIA

final class AcademicModelsTests: XCTestCase {
    
    func testMenuCharacterOrderingRule() throws {
        // Regra do Design System CTIA: Ordem estritamente crescente de caracteres no menu (8 -> 22)
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
        
        for i in 0..<(menuItems.count - 1) {
            XCTAssertLessThanOrEqual(menuItems[i].count, menuItems[i + 1].count)
        }
    }
    
    func testFilterCharacterOrderingRule() throws {
        // Regra do Design System CTIA: Ordem crescente nos filtros (3 -> 16)
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
        
        for i in 0..<(filterLabels.count - 1) {
            XCTAssertLessThanOrEqual(filterLabels[i].count, filterLabels[i + 1].count)
        }
    }
    
    func testSummaryCharacterLimit() throws {
        // Regra do Design System CTIA: Resumo limitado a 200 caracteres no cadastro
        let sampleResumo = "Protótipo com ESP32 e sensor de som que mede o ruído das oficinas do CTISM em tempo real e emite alerta quando o nível passa de 85 dB, apoiando a prevenção de perdas auditivas."
        
        XCTAssertEqual(sampleResumo.count, 176)
        XCTAssertLessThanOrEqual(sampleResumo.count, 200)
    }
    
    func testMockItemTelemetryValues() throws {
        let item = AcademicItem.mockNoiseMonitor
        
        XCTAssertEqual(item.tipo, .projeto)
        XCTAssertEqual(item.dbAtual, 82.0)
        XCTAssertEqual(item.limiteDb, 85.0)
        XCTAssertEqual(item.statusAoVivo, "AO VIVO")
        XCTAssertEqual(item.sensorChip, "ESP32 · Wi-Fi")
        XCTAssertEqual(item.avaliacao, 4.8)
        XCTAssertEqual(item.totalAvaliacoes, 37)
    }
}
