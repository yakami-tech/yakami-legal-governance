// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title RegistroDeUsuariosComRecompensa
 * @author Helen Araujo - YAKAMI TECH (Governança & Compliance)
 * * =========================================================================
 * 📚 FUNDAMENTAÇÃO TEÓRICA OBRIGATÓRIA (ITEM 7 DA TAREFA)
 * =========================================================================
 * 1. O QUE É GAS? 
 * Gas é a unidade de medida do esforço computacional necessário para executar 
 * operações na rede. Serve para prevenir spam e remunerar mineradores/validadores. [cite: 636]
 * * 2. COMO FUNCIONA A EVM?
 * A Ethereum Virtual Machine é o ambiente de execução descentralizado que garante
 * que o código seja processado de forma idêntica em todos os nós da rede. [cite: 637]
 * * 3. DIFERENÇA PARA CONTRATOS TRADICIONAIS:
 * Diferente dos contratos em papel, smart contracts são autoexecutáveis, 
 * imutáveis e não dependem de intermediários centrais para validação. [cite: 638]
 * =========================================================================
 */

contract RegistroDeUsuariosComRecompensa {

    struct Auditor {
        string nomeInstituicao; 
        bool autorizado;        
        uint256 saldoCreditos;  // Simulação de token (ERC-20 conceitual) [cite: 628]
        uint256 dataRegistro;   // Prova de anterioridade para o INPI
    }

    mapping(address => Auditor) public auditores; // Armazenamento [cite: 615]
    address public autoridadeCertificadora; 

    // Eventos obrigatórios [cite: 624-626]
    event UsuarioRegistrado(address indexed carteira, string nome);
    event RecompensaEnviada(address indexed carteira, uint256 valor);

    // Erros customizados para otimização de Gas
    error AcessoNegado();
    error AuditorJaRegistrado();

    modifier somenteCertificadora() {
        if (msg.sender != autoridadeCertificadora) revert AcessoNegado();
        _;
    }

    constructor() {
        autoridadeCertificadora = msg.sender;
    }

    /**
     * @dev Registra um novo auditor no sistema de compliance. [cite: 618]
     */
    function registrarUsuario(string memory _nome) public {
        if (auditores[msg.sender].autorizado) revert AuditorJaRegistrado(); // Segurança [cite: 633]
        require(bytes(_nome).length > 0, "Nome obrigatorio"); // Validação [cite: 632]

        auditores[msg.sender] = Auditor({
            nomeInstituicao: _nome,
            autorizado: true,
            saldoCreditos: 0,
            dataRegistro: block.timestamp
        });

        emit UsuarioRegistrado(msg.sender, _nome);
    }

    /**
     * @dev Consulta dados e saldo de créditos ambientais. [cite: 619]
     */
    function consultarUsuario(address _carteira) public view returns (string memory nome, uint256 saldo) {
        Auditor memory a = auditores[_carteira];
        return (a.nomeInstituicao, a.saldoCreditos);
    }

    /**
     * @dev Distribui recompensas por auditoria validada. [cite: 622, 630]
     */
    function recompensarUsuario(address _carteira, uint256 _quantidade) public somenteCertificadora {
        require(auditores[_carteira].autorizado, "Destinatario nao autorizado");
        
        auditores[_carteira].saldoCreditos += _quantidade;

        emit RecompensaEnviada(_carteira, _quantidade);
    }

    /**
     * 📌 CASO DE USO REAL (ITEM 8 DA TAREFA):
     * Este contrato é a base do sistema de compliance da YAKAMI TECH. Ele atua como 
     * um "Cartório Digital" que registra órgãos auditores (ex: IBAMA, Verra) e 
     * emite créditos de preservação (RWA) de forma imutável. Isso gera uma Prova 
     * de Anterioridade essencial para o registro de software no INPI e garante 
     * a integridade dos dados ambientais da Amazônia no mercado internacional. 
     */
}