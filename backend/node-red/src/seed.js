// =====================================================================
// Hub Acadêmico · Dados de exemplo
//   msg.topic = "iniciar"          cria os exemplos só na primeira vez
//   msg.topic = "restaurar"        apaga projetos, cadeiras e avaliações e recria
//                                  os exemplos (os usuários são mantidos)
//   msg.topic = "limpar-exemplos"  remove só as publicações de exemplo e os votos
//                                  delas, para começar a usar de verdade
// As publicações são fictícias; os cursos são os oferecidos pelo CTISM.
// =====================================================================

const CHAVE = 'hub_db';
const INSTITUICAO = 'CTISM – UFSM';

const CADEIRAS = [
    { id: '22C09EDB-0EC5-509C-9323-E79595B228FF', nome: 'Desenvolvimento Web' },
    { id: '684B5672-8F62-5E56-A189-C1C1A990AEEB', nome: 'Eletricidade Básica' },
    { id: 'D2A8CFA0-653B-5AF8-B65B-AF734DD20DAC', nome: 'Ergonomia' },
    { id: '598191FC-98A7-52E0-BDA9-DB206348D7FA', nome: 'Higiene Ocupacional' },
    { id: 'A0B6286F-2796-5FD9-B73E-5E20B1C3228F', nome: 'Manufatura Aditiva' },
    { id: '4CAE5F03-0F3A-5F62-BD15-0912EB5CAF14', nome: 'Microcontroladores' },
    { id: 'D11CF57C-EF08-526F-9409-7DBFE96E4B31', nome: 'Prevenção de Riscos em Máquinas' },
    { id: 'F497AD3D-5D88-5224-ABC7-8E9BC74E8DA3', nome: 'Redes de Computadores I' },
    { id: '9660533F-E50B-5216-96C9-3DF968926CF2', nome: 'Segurança de Redes' },
    { id: 'C998B693-DD64-54E1-AC5D-CF3847F2394D', nome: 'Sistemas Embarcados' }
];

const EXEMPLOS = [
    {
        id: '3C657F19-D52A-5F45-AE46-BC31046D13C3', tipo: 'projeto', ano: 2026,
        titulo: 'Monitor IoT de ruído nas oficinas do CTISM',
        descricao: 'Protótipo com ESP32 e sensor de som que mede o ruído das oficinas do CTISM em tempo real e emite alerta quando o nível passa de 85 dB, apoiando a prevenção de perdas auditivas.',
        imagemURL: 'asset://capa-monitor-ruido', link: 'https://example.com/hub-academico/monitor-ruido', plataforma: 'linkedin',
        area: 'engenharias', subarea: 'Engenharia de Produção', cadeira: 'Higiene Ocupacional',
        curso: 'Técnico em Segurança do Trabalho',
        autores: ['Ana Clara Machado', 'Lucas Ferreira'],
        media: 4.8, quant: 37, dias: 2
    },
    {
        id: 'F40E46BC-DF8C-53D5-B16F-759162D6B227', tipo: 'trabalho', ano: 2026,
        titulo: 'Dosimetria de ruído na oficina de soldagem',
        descricao: 'Medições com dosímetro durante aulas práticas de soldagem, comparadas aos limites da NR-15, com recomendações de protetores auriculares e de rodízio das atividades.',
        imagemURL: 'asset://capa-dosimetria', link: 'https://example.com/hub-academico/dosimetria', plataforma: 'blog',
        area: 'engenharias', subarea: 'Engenharia de Produção', cadeira: 'Higiene Ocupacional',
        curso: 'Técnico em Segurança do Trabalho',
        autores: ['Bruna Teixeira'],
        media: 4.6, quant: 21, dias: 5
    },
    {
        id: '1490DF63-6FF1-59F1-873B-9E4C55066D48', tipo: 'prova', ano: 2026,
        titulo: 'Prova de Higiene Ocupacional – 2026/1',
        descricao: 'Primeira avaliação do semestre, com questões sobre agentes físicos, limites de tolerância e uso de EPIs. Inclui o gabarito comentado.',
        imagemURL: 'asset://capa-prova-higiene', link: null, plataforma: 'outro',
        area: 'saude', subarea: 'Saúde Coletiva', cadeira: 'Higiene Ocupacional',
        curso: 'Técnico em Segurança do Trabalho',
        autores: ['Turma 2026/1'],
        media: 4.5, quant: 12, dias: 9
    },
    {
        id: '5D53CA11-EF7D-5823-B5D4-724D8DA80503', tipo: 'projeto', ano: 2025,
        titulo: 'Estufa automatizada com ESP32 e sensores de umidade',
        descricao: 'Controle de irrigação e ventilação de uma estufa didática com sensores de solo e de ar, painel web em tempo real e alertas pelo celular.',
        imagemURL: 'asset://capa-estufa', link: 'https://example.com/hub-academico/estufa', plataforma: 'instagram',
        area: 'engenharias', subarea: 'Engenharia Elétrica', cadeira: 'Sistemas Embarcados',
        curso: 'Técnico em Internet das Coisas Integrado ao Ensino Médio',
        autores: ['Pedro Henrique Lopes', 'Júlia Martins'],
        media: 4.7, quant: 18, dias: 40
    },
    {
        id: 'BD327E0E-2BF6-5A4B-9609-F4DF21501F33', tipo: 'trabalho', ano: 2026,
        titulo: 'Análise de vulnerabilidades em redes Wi-Fi',
        descricao: 'Estudo de configurações comuns de roteadores, testes em laboratório isolado e um guia de boas práticas para proteger redes domésticas e de pequenas empresas.',
        imagemURL: 'asset://capa-wifi', link: 'https://example.com/hub-academico/wifi', plataforma: 'blog',
        area: 'exatas', subarea: 'Ciência da Computação', cadeira: 'Segurança de Redes',
        curso: 'Curso Superior de Tecnologia em Segurança Cibernética',
        autores: ['Rafael Costa'],
        media: 4.4, quant: 9, dias: 12
    },
    {
        id: '77478356-56C0-59DE-9ABE-A94D5A433B39', tipo: 'projeto', ano: 2025,
        titulo: 'Braço robótico didático impresso em 3D',
        descricao: 'Braço de quatro eixos impresso em PLA, acionado por servomotores e Arduino, para ensinar cinemática e programação nas aulas de fabricação.',
        imagemURL: 'asset://capa-braco-robotico', link: 'https://example.com/hub-academico/braco-robotico', plataforma: 'youtube',
        area: 'engenharias', subarea: 'Engenharia Mecânica', cadeira: 'Manufatura Aditiva',
        curso: 'Curso Superior de Tecnologia em Fabricação Mecânica',
        autores: ['Gabriel Souza', 'Larissa Prado'],
        media: 4.9, quant: 25, dias: 60
    },
    {
        id: '16B50825-18E3-55FC-80B9-535279A01B07', tipo: 'prova', ano: 2025,
        titulo: 'Prova de Eletricidade Básica – 2025/2',
        descricao: 'Avaliação com circuitos em série e em paralelo, Lei de Ohm e potência elétrica. Questões objetivas e dissertativas.',
        imagemURL: 'asset://capa-prova-eletricidade', link: null, plataforma: 'outro',
        area: 'engenharias', subarea: 'Engenharia Elétrica', cadeira: 'Eletricidade Básica',
        curso: 'Técnico em Eletrotécnica',
        autores: ['Turma 2025/2'],
        media: 4.2, quant: 15, dias: 90
    },
    {
        id: 'C69CD2E5-D3AF-55C0-A30C-086CA69A4BB3', tipo: 'material', ano: 2026,
        titulo: 'Apostila de segurança em máquinas (NR-12)',
        descricao: 'Resumo ilustrado dos requisitos da NR-12, com exemplos de proteções, dispositivos de parada de emergência e uma lista de verificação para as oficinas.',
        imagemURL: 'asset://capa-apostila-nr12', link: 'https://example.com/hub-academico/nr12', plataforma: 'blog',
        area: 'engenharias', subarea: 'Engenharia de Produção', cadeira: 'Prevenção de Riscos em Máquinas',
        curso: 'Técnico em Segurança do Trabalho',
        autores: ['Monitoria de Segurança do Trabalho'],
        media: 4.8, quant: 40, dias: 20
    },
    {
        id: '8C08A1F4-D7EA-5CA2-B2F2-D47A1ABCAF67', tipo: 'material', ano: 2025,
        titulo: 'Videoaulas de Arduino para iniciantes',
        descricao: 'Série de vídeos curtos sobre entradas e saídas digitais, sensores analógicos e comunicação serial, com os códigos usados em aula.',
        imagemURL: 'asset://capa-arduino', link: 'https://example.com/hub-academico/arduino', plataforma: 'youtube',
        area: 'engenharias', subarea: 'Engenharia Elétrica', cadeira: 'Microcontroladores',
        curso: 'Técnico em Automação Industrial',
        autores: ['Diego Ramos'],
        media: 4.6, quant: 22, dias: 75
    },
    {
        id: 'B3D302B3-DE7D-5C0F-9576-E9DF7C263587', tipo: 'trabalho', ano: 2025,
        titulo: 'Ergonomia nos laboratórios de informática',
        descricao: 'Avaliação de postura, altura das mesas e iluminação em dois laboratórios, com propostas de ajustes de baixo custo e orientações de pausas.',
        imagemURL: 'asset://capa-ergonomia', link: 'https://example.com/hub-academico/ergonomia', plataforma: 'linkedin',
        area: 'saude', subarea: 'Saúde Coletiva', cadeira: 'Ergonomia',
        curso: 'Técnico em Segurança do Trabalho',
        autores: ['Fernanda Alves', 'Tiago Nunes'],
        media: 4.3, quant: 11, dias: 100
    },
    {
        id: 'C507AB1B-3494-558B-8599-CBE687BCB895', tipo: 'projeto', ano: 2026,
        titulo: 'Site acessível para a biblioteca do colégio',
        descricao: 'Catálogo on-line com contraste ajustável, leitura por voz e navegação por teclado, seguindo as recomendações do eMAG e da WCAG.',
        imagemURL: 'asset://capa-site-acessivel', link: 'https://example.com/hub-academico/biblioteca', plataforma: 'github',
        area: 'exatas', subarea: 'Ciência da Computação', cadeira: 'Desenvolvimento Web',
        curso: 'Técnico em Informática para Internet Integrado ao Ensino Médio',
        autores: ['Isadora Ribeiro'],
        media: 4.5, quant: 14, dias: 15
    },
    {
        id: 'CBE337DB-4AB3-5810-ADC6-F904D064E18C', tipo: 'prova', ano: 2026,
        titulo: 'Prova de Redes de Computadores I – 2026/1',
        descricao: 'Questões sobre modelo OSI, endereçamento IPv4, sub-redes e comandos básicos de diagnóstico, com espaço para os cálculos.',
        imagemURL: 'asset://capa-prova-redes', link: null, plataforma: 'outro',
        area: 'exatas', subarea: 'Ciência da Computação', cadeira: 'Redes de Computadores I',
        curso: 'Curso Superior de Tecnologia em Redes de Computadores',
        autores: ['Turma 2026/1'],
        media: 4.1, quant: 8, dias: 7
    }
];

function dataISO(diasAtras) {
    return new Date(Date.now() - diasAtras * 86400000).toISOString().replace(/\.\d{3}Z$/, 'Z');
}

function novoId() {
    return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, function (c) {
        const r = Math.random() * 16 | 0;
        return (c === 'x' ? r : (r & 0x3 | 0x8)).toString(16).toUpperCase();
    });
}

function contar(db) {
    return Object.keys(db.projetos).length + ' publicações, ' + Object.keys(db.cadeiras).length +
        ' cadeiras, ' + Object.keys(db.users).length + ' usuários e ' + Object.keys(db.avaliacoes).length + ' avaliações';
}

// A primeira versão do fluxo guardava o banco em "ctia_db": os dados passam para o nome novo.
if (!global.get(CHAVE) && global.get('ctia_db')) {
    global.set(CHAVE, global.get('ctia_db'));
}

let db = global.get(CHAVE);
if (!db || typeof db !== 'object') db = { versao: 1 };
['projetos', 'cadeiras', 'users', 'avaliacoes'].forEach(function (t) {
    if (!db[t] || typeof db[t] !== 'object') db[t] = {};
});

const acao = msg.topic === 'restaurar' || msg.topic === 'limpar-exemplos' ? msg.topic : 'iniciar';

if (acao === 'iniciar' && db.iniciadoEm) {
    node.status({ fill: 'grey', shape: 'ring', text: 'banco carregado' });
    msg.payload = 'Banco do Hub Acadêmico carregado: ' + contar(db) + '.';
    return msg;
}

if (acao === 'limpar-exemplos') {
    Object.keys(db.projetos).forEach(function (id) {
        if (db.projetos[id].exemplo) delete db.projetos[id];
    });
    Object.keys(db.avaliacoes).forEach(function (id) {
        if (!db.projetos[db.avaliacoes[id].projetoId]) delete db.avaliacoes[id];
    });
    const emUso = {};
    Object.values(db.projetos).forEach(function (p) { emUso[p.cadeiraId] = true; });
    // Só sai a cadeira de exemplo que ficou sem publicações; as criadas pela turma ficam.
    Object.keys(db.cadeiras).forEach(function (id) {
        const deExemplo = CADEIRAS.some(function (c) { return c.id === id; });
        if (deExemplo && !emUso[id]) delete db.cadeiras[id];
    });
    db.iniciadoEm = db.iniciadoEm || dataISO(0);
    global.set(CHAVE, db);
    node.status({ fill: 'blue', shape: 'dot', text: 'exemplos removidos' });
    msg.payload = 'Exemplos removidos. Ficaram ' + contar(db) + '.';
    return msg;
}

if (acao === 'restaurar') {
    db.projetos = {};
    db.cadeiras = {};
    db.avaliacoes = {};
}

CADEIRAS.forEach(function (c) {
    db.cadeiras[c.id] = { id: c.id, nome: c.nome, criadoEm: dataISO(0) };
});

EXEMPLOS.forEach(function (e) {
    const cadeira = CADEIRAS.find(function (c) { return c.nome === e.cadeira; });
    db.projetos[e.id] = {
        id: e.id, tipo: e.tipo, titulo: e.titulo, descricao: e.descricao, autores: e.autores,
        ano: e.ano, area: e.area, subarea: e.subarea, cadeiraId: cadeira.id, userId: null, instituicao: INSTITUICAO,
        curso: e.curso, link: e.link, plataforma: e.plataforma, imagemURL: e.imagemURL,
        criadoEm: dataISO(e.dias), exemplo: true
    };
    // Votos de demonstração (4 e 5 estrelas) que chegam perto da média do exemplo.
    const cincos = Math.max(0, Math.min(e.quant, Math.round((e.media - 4) * e.quant)));
    for (let i = 0; i < e.quant; i++) {
        const a = { id: novoId(), projetoId: e.id, userId: null, nota: i < cincos ? 5 : 4, criadoEm: dataISO(e.dias), exemplo: true };
        db.avaliacoes[a.id] = a;
    }
});

db.iniciadoEm = db.iniciadoEm || dataISO(0);
global.set(CHAVE, db);
node.status({ fill: 'green', shape: 'dot', text: acao === 'restaurar' ? 'exemplos restaurados' : 'banco criado' });
msg.payload = (acao === 'restaurar' ? 'Exemplos restaurados: ' : 'Banco do Hub Acadêmico criado: ') + contar(db) + '.';
return msg;
