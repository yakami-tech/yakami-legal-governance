// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

/**
 * @title YakamiAuditRegistry (Método RRDA - Rastreabilidade Regulatória de Dados)
 * @author Helen Araújo & Erick Mattos — YAKAMI TECH (Governança & Compliance)
 * @notice Contrato Inteligente da Camada YAKAMI-NET para registro imutável de órgãos ambientais, 
 *         credenciamento de auditores e validação criptográfica de ativos (RWA / Créditos de Carbono).
 * @dev Desenvolvido como evidência técnica do Método RRDA (PROFNIT) e alinhado ao Programa ProSAME / AEB.
 */

contract YakamiAuditRegistry {

    // Categorização dos Órgãos Reguladores
    enum EsferaRegulatoria { Federal, EstadualAmazonia, EspacialPropriedade, Internacional }

    struct OrgaoRegulador {
        string sigla;               // Ex: "IBAMA", "IPAAM", "AEB", "VERRA"
        string nomeCompleto;        // Ex: "Instituto Brasileiro do Meio Ambiente"
        EsferaRegulatoria esfera;   // Categoria regulatória
        bool ativo;                 // Status de homologação na rede
    }

    struct Auditor {
        string nomeInstituicao; 
        string siglaOrgaoVincular;  // Sigla do órgão regulador atrelado
        bool autorizado;        
        uint256 saldoCreditos;      // Saldo de ativos de preservação (RWA / Carbono)
        uint256 dataRegistro;       // Prova de anterioridade imutável (INPI / AEB)
    }

    // Mapeamentos de Estado
    mapping(address => Auditor) public auditores;
    mapping(string => OrgaoRegulador) public orgaosReguladores;
    
    address public autoridadeCertificadora; // YAKAMI Tech (Governança Core)

    // Eventos Oficiais de Auditoria
    event OrgaoReguladorCadastrado(string indexed sigla, string nomeCompleto, EsferaRegulatoria esfera);
    event AuditorRegistrado(address indexed carteira, string nome, string siglaOrgao);
    event CreditoEmitido(address indexed carteiraAuditor, uint256 quantidade, string hashReferencia);

    // Erros Customizados para Economia de Gás
    error AcessoNegado();
    error AuditorJaRegistrado();
    error OrgaoNaoCadastrado();
    error AuditorNaoAutorizado();

    modifier somenteCertificadora() {
        if (msg.sender != autoridadeCertificadora) revert AcessoNegado();
        _;
    }

    constructor() {
        autoridadeCertificadora = msg.sender;

        // =========================================================================
        // 🏛️ INICIALIZAÇÃO DA MATRIZ NACIONAL DE ÓRGÃOS REGULADORES
        // =========================================================================
        
        // 1. ÂMBITO FEDERAL
        _cadastrarOrgao("IBAMA", "Inst. Bras. do Meio Ambiente e dos Rec. Nat. Renovaveis", EsferaRegulatoria.Federal);
        _cadastrarOrgao("ICMBio", "Instituto Chico Mendes de Conservacao da Biodiversidade", EsferaRegulatoria.Federal);
        _cadastrarOrgao("MAPA_CAR", "Ministerio da Agricultura / Cadastro Ambiental Rural", EsferaRegulatoria.Federal);
        _cadastrarOrgao("SFB", "Servico Florestal Brasileiro", EsferaRegulatoria.Federal);
        _cadastrarOrgao("ANA", "Agencia Nacional de Aguas e Saneamento Basico", EsferaRegulatoria.Federal);

        // 2. ÂMBITO ESTADUAL (AMAZÔNIA LEGAL)
        _cadastrarOrgao("IPAAM", "Instituto de Protecao Ambiental do Amazonas (AM)", EsferaRegulatoria.EstadualAmazonia);
        _cadastrarOrgao("SEMA_AM", "Secretaria de Estado do Meio Ambiente do Amazonas", EsferaRegulatoria.EstadualAmazonia);
        _cadastrarOrgao("SEMAS_PA", "Secretaria de Meio Ambiente e Sustentabilidade do Para", EsferaRegulatoria.EstadualAmazonia);
        _cadastrarOrgao("SEDAM_RO", "Sec. de Estado do Desenvolvimento Ambiental de Rondonia", EsferaRegulatoria.EstadualAmazonia);
        _cadastrarOrgao("IMAC_AC", "Instituto de Meio Ambiente do Acre", EsferaRegulatoria.EstadualAmazonia);
        _cadastrarOrgao("SEMA_MT", "Secretaria de Estado de Meio Ambiente de Mato Grosso", EsferaRegulatoria.EstadualAmazonia);
        _cadastrarOrgao("SEMA_AP", "Secretaria de Estado do Meio Ambiente do Amapa", EsferaRegulatoria.EstadualAmazonia);
        _cadastrarOrgao("FEMARH_RR", "Fundacao Estadual do Meio Ambiente e Rec. Hidricos de Roraima", EsferaRegulatoria.EstadualAmazonia);
        _cadastrarOrgao("NATURATINS", "Instituto do Natureza do Tocantins", EsferaRegulatoria.EstadualAmazonia);

        // 3. ESPAÇO, CIÊNCIA & PROPRIEDADE INTELECTUAL
        _cadastrarOrgao("AEB", "Agencia Espacial Brasileira (ProSAME / YAKAMI-SAT)", EsferaRegulatoria.EspacialPropriedade);
        _cadastrarOrgao("INPI", "Instituto Nacional da Propriedade Industrial (Metodo RRDA)", EsferaRegulatoria.EspacialPropriedade);

        // 4. PADRÕES INTERNACIONAIS (MERCADO DE CARBONO / ESG)
        _cadastrarOrgao("VERRA", "Verra Verified Carbon Standard (VCS)", EsferaRegulatoria.Internacional);
        _cadastrarOrgao("GOLD_STD", "Gold Standard for the Global Goals", EsferaRegulatoria.Internacional);
    }

    /**
     * @dev Função interna para cadastrar órgãos reguladores na implantação.
     */
    function _cadastrarOrgao(string memory _sigla, string memory _nome, EsferaRegulatoria _esfera) internal {
        orgaosReguladores[_sigla] = OrgaoRegulador({
            sigla: _sigla,
            nomeCompleto: _nome,
            esfera: _esfera,
            ativo: true
        });
        emit OrgaoReguladorCadastrado(_sigla, _nome, _esfera);
    }

    /**
     * @notice Cadastra dinamicamente novos órgãos reguladores ambientais.
     */
    function adicionarOrgaoRegulador(
        string memory _sigla, 
        string memory _nomeCompleto, 
        EsferaRegulatoria _esfera
    ) public somenteCertificadora {
        _cadastrarOrgao(_sigla, _nomeCompleto, _esfera);
    }

    /**
     * @notice Registra um auditor atrelado a um órgão ambiental homologado.
     * @param _nome Razão social ou nome do auditor legal.
     * @param _siglaOrgao Sigla do órgão vinculador (ex: "IBAMA", "IPAAM", "AEB").
     */
    function registrarAuditor(string memory _nome, string memory _siglaOrgao) public {
        if (auditores[msg.sender].autorizado) revert AuditorJaRegistrado();
        if (!orgaosReguladores[_siglaOrgao].ativo) revert OrgaoNaoCadastrado();
        require(bytes(_nome).length > 0, "Nome obrigatorio");

        auditores[msg.sender] = Auditor({
            nomeInstituicao: _nome,
            siglaOrgaoVincular: _siglaOrgao,
            autorizado: true,
            saldoCreditos: 0,
            dataRegistro: block.timestamp
        });

        emit AuditorRegistrado(msg.sender, _nome, _siglaOrgao);
    }

    /**
     * @notice Emite e valida créditos ambientais/telemetria com atestação de hash criptográfico.
     * @param _carteiraAuditor Carteira do auditor credenciado.
     * @param _quantidade Quantidade de unidades ambientais ou de dados validados.
     * @param _hashReferencia Hash do relatório/telemetria gerado no YAKAMI-FLOW ou YAKAMI-SAT.
     */
    function emitirCreditoAmbiental(
        address _carteiraAuditor, 
        uint256 _quantidade, 
        string memory _hashReferencia
    ) public somenteCertificadora {
        if (!auditores[_carteiraAuditor].autorizado) revert AuditorNaoAutorizado();

        auditores[_carteiraAuditor].saldoCreditos += _quantidade;

        emit CreditoEmitido(_carteiraAuditor, _quantidade, _hashReferencia);
    }

    /**
     * @notice Consulta dados de verificação de um auditor cadastrado.
     */
    function consultarAuditor(address _carteira) public view returns (
        string memory nome, 
        string memory orgaoVincular, 
        uint256 saldo, 
        uint256 dataRegistro
    ) {
        Auditor memory a = auditores[_carteira];
        return (a.nomeInstituicao, a.siglaOrgaoVincular, a.saldoCreditos, a.dataRegistro);
    }
}
