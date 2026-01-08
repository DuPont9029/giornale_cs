// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// =============================================================
//                      LIBRARIES & UTILS
// =============================================================

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor(address initialOwner) {
        _transferOwnership(initialOwner);
    }

    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    function toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
}

/**
 * @dev Base64 encoding/decoding.
 */
library Base64 {
    /**
     * @dev Base64 Encoding/Decoding Table
     */
    string internal constant _TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /**
     * @dev Converts a `bytes` to its Bytes32 `string` representation.
     */
    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return "";
        string memory table = _TABLE;
        string memory result = new string(4 * ((data.length + 2) / 3));
        
        bytes memory tableBytes = bytes(table);
        bytes memory resultBytes = bytes(result);
        
        uint256 j = 0;
        for (uint256 i = 0; i < data.length; i += 3) {
            uint256 len = data.length - i;
            uint8 b0 = uint8(data[i]);
            uint8 b1 = len > 1 ? uint8(data[i + 1]) : 0;
            uint8 b2 = len > 2 ? uint8(data[i + 2]) : 0;
            
            resultBytes[j++] = tableBytes[(b0 >> 2) & 0x3F];
            resultBytes[j++] = tableBytes[((b0 & 0x3) << 4) | ((b1 >> 4) & 0xF)];
            resultBytes[j++] = len > 1 ? tableBytes[((b1 & 0xF) << 2) | ((b2 >> 6) & 0x3)] : bytes1('=');
            resultBytes[j++] = len > 2 ? tableBytes[b2 & 0x3F] : bytes1('=');
        }
        return string(resultBytes);
    }
}

// =============================================================
//                      ERC721 IMPLEMENTATION
// =============================================================

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

abstract contract ERC165 is IERC165 {
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

interface IERC721 is IERC165 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function transferFrom(address from, address to, uint256 tokenId) external;
    function approve(address to, uint256 tokenId) external;
    function getApproved(uint256 tokenId) external view returns (address operator);
    function setApprovalForAll(address operator, bool _approved) external;
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

interface IERC721Metadata is IERC721 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

interface IERC721Receiver {
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}

contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Strings for uint256;

    string private _name;
    string private _symbol;

    mapping(uint256 => address) private _owners;
    mapping(address => uint256) private _balances;
    mapping(uint256 => address) private _tokenApprovals;
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return "";
    }

    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _balances[owner];
    }

    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: invalid token ID");
        return owner;
    }

    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not token owner or approved for all"
        );

        _approve(to, tokenId);
    }

    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: invalid token ID");
        return _tokenApprovals[tokenId];
    }

    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    function transferFrom(address from, address to, uint256 tokenId) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");
        _transfer(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");
        _safeTransfer(from, to, tokenId, data);
    }

    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory data) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
    }

    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    function _safeMint(address to, uint256 tokenId, bytes memory data) internal virtual {
        _mint(to, tokenId);
        require(_checkOnERC721Received(address(0), to, tokenId, data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        _owners[tokenId] = address(0);

        emit Transfer(owner, address(0), tokenId);
    }

    function _transfer(address from, address to, uint256 tokenId) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    function _setApprovalForAll(address owner, address operator, bool approved) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory data) private returns (bool) {
        if (to.code.length > 0) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    /// @solidity memory-safe-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    // Hook che useremo per il Soulbound
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual {}
}

// =============================================================
//                      JOURNAL DAO
// =============================================================

/**
 * @title VoxPopuliVoxDei
 * @dev NFT Soulbound che rappresenta un giornale con notizie aggiornabili tramite voto.
 */
contract VoxPopuliVoxDei is ERC721, Ownable {
    using Strings for uint256;

    // Struttura per una notizia/articolo
    struct NewsItem {
        string headline;
        string content;
        uint256 timestamp;
    }

    // Struttura per una proposta di aggiornamento
    struct Proposal {
        string newHeadline;
        string newContent;
        uint256 votesPro;     // Sostituisce voteCount
        uint256 votesContra;  // Nuovo contatore
        uint256 endTime;
        bool executed;
        uint256 cycle;
    }

    // Stato del Giornale
    NewsItem public currentIssue;
    
    // Gestione Proposte
    Proposal[] public proposals;
    mapping(uint256 => mapping(address => uint256)) public hasVoted;
    uint256 public constant VOTING_DURATION = 1 days; // Mainnet: 1 giorno

    // Gestione Proposte Attive (Logica StudentCommittee)
    uint256[] private activeProposalIds;
    mapping(uint256 => uint256) private activeProposalIndex;

    // Counter per i Token ID (rappresenta anche la Total Supply dato che non c'è burn)
    uint256 private _nextTokenId;

    constructor() ERC721("Vox Populi", "VOX") Ownable(msg.sender) {
        // Imposta la prima notizia di default
        currentIssue = NewsItem({
            headline: unicode"Il comitato studentesco rinasca dalle sue ceneri",
            content: unicode"sin dalla sua fondazione, il comitato studentesco, il più importante organo di espressione della volontà studentesca è stato ILLEGALMENTE privato della sua autorità e della sua autonomia, il tutto all'oscuro degli studenti. le leggi violate dalla scuola sono molte, per menzionarle alcune: 1. comma 5 art 4 DPR 10-10-1996 n. 567 che impone al comitato di avere un regolamento per le essemblee e permette di averne uno interno che regoli la sua organizzazione. 2. l'art 4 DPR 10-10-1996 stabilisce che possano essere fondate asscociazioni studentesche extrascolastiche che possono svolgere una serie di attività e questo non è mai stato concesso, 3. gestione economica il comitato può finanziare attività coerenti allo studio con fondi scolastici allocati dal consiglio di istituto o tramite autofinanziamento ma il consiglio di istituto continua a negarci i nostri diritti.",
            timestamp: block.timestamp
        });
    }

    // =============================================================
    //                      MINTING (SOULBOUND)
    // =============================================================

    function subscribe() public {
        require(balanceOf(msg.sender) == 0, "Gia abbonato");
        uint256 tokenId = _nextTokenId++;
        _safeMint(msg.sender, tokenId);
    }

    function airdrop(address to) public onlyOwner {
        require(balanceOf(to) == 0, "Gia abbonato");
        uint256 tokenId = _nextTokenId++;
        _safeMint(to, tokenId);
    }

    /**
     * @dev Blocca i trasferimenti per rendere il token Soulbound (SBT).
     * Usa il hook _beforeTokenTransfer (compatibile con implementazione stile v4 sopra).
     */
    function _beforeTokenTransfer(address from, address to, uint256 /*tokenId*/) internal virtual override {
        // Se 'from' non è zero (non è un mint) e 'to' non è zero (non è un burn), allora è un trasferimento.
        // Lo blocchiamo.
        if (from != address(0) && to != address(0)) {
            revert("VoxPopuliVoxDei: Questo NFT e' Soulbound e non puo' essere trasferito");
        }
    }

    // =============================================================
    //                      GOVERNANCE (VOTO)
    // =============================================================

    /**
     * @dev Crea una proposta per aggiornare la notizia del giorno.
     */
    /**
     * @dev Crea una NUOVA proposta (append in coda).
     */
    function proposeUpdate(string memory _headline, string memory _content) public {
        require(balanceOf(msg.sender) > 0, "Devi essere un abbonato per proporre");

        uint256 proposalId = proposals.length;
        proposals.push(Proposal({
            newHeadline: _headline,
            newContent: _content,
            votesPro: 0,
            votesContra: 0,
            endTime: block.timestamp + VOTING_DURATION,
            executed: false,
            cycle: 1
        }));

        _addToActiveProposals(proposalId);
    }

    /**
     * @dev Ricicla una vecchia proposta (Logica StudentCommittee).
     * Risparmia gas evitando di espandere l'array.
     */
    function reuseProposal(uint256 proposalId, string memory _headline, string memory _content) public {
        require(balanceOf(msg.sender) > 0, "Devi essere un abbonato per proporre");
        require(proposalId < proposals.length, "Proposta inesistente");
        
        Proposal storage p = proposals[proposalId];
        // Possiamo riciclare se eseguita O se scaduta
        require(p.executed || block.timestamp > p.endTime, "Proposta ancora attiva!");

        p.newHeadline = _headline;
        p.newContent = _content;
        p.votesPro = 0;
        p.votesContra = 0;
        p.endTime = block.timestamp + VOTING_DURATION;
        p.executed = false;
        p.cycle++; // Incrementa ciclo

        _addToActiveProposals(proposalId);
    }

    function _addToActiveProposals(uint256 proposalId) internal {
        activeProposalIndex[proposalId] = activeProposalIds.length;
        activeProposalIds.push(proposalId);
    }

    function _removeFromActiveProposals(uint256 proposalId) internal {
        uint256 index = activeProposalIndex[proposalId];
        uint256 lastIndex = activeProposalIds.length - 1;

        if (index != lastIndex) {
            uint256 lastProposalId = activeProposalIds[lastIndex];
            activeProposalIds[index] = lastProposalId;
            activeProposalIndex[lastProposalId] = index;
        }

        activeProposalIds.pop();
        delete activeProposalIndex[proposalId];
    }

    /**
     * @dev Vota per una proposta attiva (Sì o No).
     * @param support true per SÌ, false per NO.
     */
    function vote(uint256 proposalId, bool support) public {
        require(balanceOf(msg.sender) > 0, "Devi essere un abbonato per votare");
        require(proposalId < proposals.length, "Proposta inesistente");
        Proposal storage p = proposals[proposalId];
        
        require(block.timestamp < p.endTime, "Votazione conclusa");
        require(!p.executed, "Gia eseguita");
        require(hasVoted[proposalId][msg.sender] != p.cycle, "Hai gia votato");

        if (support) {
            p.votesPro++;
        } else {
            p.votesContra++;
        }
        
        hasVoted[proposalId][msg.sender] = p.cycle;
    }

    /**
     * @dev Esegue la proposta se il tempo è scaduto e i SÌ vincono.
     * Può essere chiamata da chiunque (public).
     */
    function executeProposal(uint256 proposalId) public {
        require(proposalId < proposals.length, "Proposta inesistente");
        Proposal storage p = proposals[proposalId];

        require(!p.executed, "Gia eseguita");
        require(block.timestamp >= p.endTime, "Votazione ancora in corso");
        
        // Verifica esito: Sì > No
        if (p.votesPro > p.votesContra) {
            _executeProposalLogic(proposalId);
        } else {
            // Se vince il NO o pareggio, la proposta viene marcata come "eseguita" (chiusa) ma senza effetti.
            // Questo libera lo slot per il riciclo.
            p.executed = true;
            _removeFromActiveProposals(proposalId);
        }
    }

    function _executeProposalLogic(uint256 proposalId) internal {
        Proposal storage p = proposals[proposalId];
        p.executed = true;

        currentIssue = NewsItem({
            headline: p.newHeadline,
            content: p.newContent,
            timestamp: block.timestamp
        });

        _removeFromActiveProposals(proposalId);
    }

    // =============================================================
    //                      RENDER SVG (ON-CHAIN)
    // =============================================================

    /**
     * @dev Converte un timestamp in una data leggibile "YYYY-MM-DD".
     * Usiamo un algoritmo semplificato per risparmiare gas.
     */
    function _timestampToString(uint256 timestamp) internal pure returns (string memory) {
        // Algoritmo di conversione (semplificato)
        // Basato su: http://howardhinnant.github.io/date_algorithms.html
        uint256 z = timestamp / 86400 + 719468;
        uint256 era = (z >= 0 ? z : z - 146096) / 146097;
        uint256 doe = z - era * 146097;
        uint256 yoe = (doe - doe/1460 + doe/36524 - doe/146096) / 365;
        uint256 y = yoe + era * 400;
        uint256 doy = doe - (365*yoe + yoe/4 - yoe/100);
        uint256 mp = (5*doy + 2)/153;
        uint256 d = doy - (153*mp+2)/5 + 1;
        uint256 m = mp < 10 ? mp + 3 : mp - 9;
        uint256 year = y + (m <= 2 ? 1 : 0);

        return string(abi.encodePacked(
            Strings.toString(year), "-", 
            (m < 10 ? "0" : ""), Strings.toString(m), "-", 
            (d < 10 ? "0" : ""), Strings.toString(d)
        ));
    }

    /**
     * @dev Genera l'SVG raw in base allo stato attuale di 'currentIssue'.
     */
    function generateSVG() internal view returns (string memory) {
        string memory dateStr = _timestampToString(currentIssue.timestamp);

        return string(abi.encodePacked(
            '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 650">',
            '<style>.base { fill: black; font-family: serif; font-size: 14px; } .head { fill: black; font-weight: bold; font-size: 24px; }</style>',
            '<rect width="100%" height="100%" fill="#f0e6d2" />', // Sfondo color carta
            '<text x="50%" y="40" class="head" dominant-baseline="middle" text-anchor="middle">Vox Populi</text>',
            '<line x1="20" y1="60" x2="330" y2="60" stroke="black" stroke-width="2"/>',
            
            // Data dinamica
            '<text x="50%" y="80" class="base" text-anchor="middle" font-style="italic">', dateStr, '</text>',
            
            // Headline dinamica (multi-line, max 60 chars split in 2 lines of 30)
            '<text x="50%" y="130" class="head" text-anchor="middle" font-size="20">', 
            '<tspan x="50%" dy="0">', _substringSafe(currentIssue.headline, 0, 30), '</tspan>',
            '<tspan x="50%" dy="25">', _substringSafe(currentIssue.headline, 30, 60), '</tspan>',
            '</text>',
            
            // Content snippet (Multi-line centered)
            '<text x="50%" y="200" class="base" text-anchor="middle">', 
            '<tspan x="50%" dy="0">', _substringSafe(currentIssue.content, 0, 50), '</tspan>',
            '<tspan x="50%" dy="20">', _substringSafe(currentIssue.content, 50, 100), '</tspan>',
            '<tspan x="50%" dy="20">', _substringSafe(currentIssue.content, 100, 150), '</tspan>',
            '<tspan x="50%" dy="20">', _substringSafe(currentIssue.content, 150, 200), '</tspan>',
            '<tspan x="50%" dy="20">', _substringSafe(currentIssue.content, 200, 250), '</tspan>',
            '<tspan x="50%" dy="20">', _substringSafe(currentIssue.content, 250, 300), '</tspan>',
            '<tspan x="50%" dy="20">', _substringSafe(currentIssue.content, 300, 350), '</tspan>',
            '<tspan x="50%" dy="20">', _substringSafe(currentIssue.content, 350, 400), '</tspan>',
            '<tspan x="50%" dy="20">', _substringSafe(currentIssue.content, 400, 450), '</tspan>',
            '<tspan x="50%" dy="20">', _substringSafe(currentIssue.content, 450, 500), '</tspan>',
            '<tspan x="50%" dy="20">', _substringSafe(currentIssue.content, 500, 550), '</tspan>',
            '<tspan x="50%" dy="20">', _substringSafe(currentIssue.content, 550, 600), '</tspan>',
            '<tspan x="50%" dy="20">', _substringSafe(currentIssue.content, 600, 650), '</tspan>',
            '<tspan x="50%" dy="20">', _substringSafe(currentIssue.content, 650, 700), '</tspan>',
            '<tspan x="50%" dy="20">', _substringSafe(currentIssue.content, 700, 750), '</tspan>',
            '<tspan x="50%" dy="20">', _substringSafe(currentIssue.content, 750, 800), '</tspan>',
            '<tspan x="50%" dy="20">', _substringSafe(currentIssue.content, 800, 850), '</tspan>',
            '<tspan x="50%" dy="20">', _substringSafe(currentIssue.content, 850, 900), '</tspan>',
            '</text>',
            '<text x="50%" y="630" class="base" font-size="10" text-anchor="middle">Verified by Ethereum</text>',
            '</svg>'
        ));
    }

    /**
     * @dev Helper sicuro per estrarre sottostringhe senza errori out-of-bounds.
     * Restituisce stringa vuota se startIndex è fuori range.
     * Taglia a endIndex o fine stringa.
     */
    function _substringSafe(string memory str, uint256 startIndex, uint256 endIndex) internal pure returns (string memory) {
        bytes memory strBytes = bytes(str);
        if (startIndex >= strBytes.length) return "";
        if (endIndex > strBytes.length) endIndex = strBytes.length;
        return substring(str, startIndex, endIndex);
    }

    function substring(string memory str, uint startIndex, uint endIndex) internal pure returns (string memory) {
        bytes memory strBytes = bytes(str);
        bytes memory result = new bytes(endIndex - startIndex);
        for(uint i = startIndex; i < endIndex; i++) {
            result[i - startIndex] = strBytes[i];
        }
        return string(result);
    }

    /**
     * @dev Override di tokenURI per restituire il JSON Base64 con l'SVG aggiornato.
     */
    function tokenURI(uint256 /*tokenId*/) public view override returns (string memory) {
        string memory svg = generateSVG();
        string memory dateStr = _timestampToString(currentIssue.timestamp);
        
        string memory json = Base64.encode(bytes(string(abi.encodePacked(
            '{"name": "Journal #', dateStr, '",',
            '"description": "Un giornale on-chain aggiornato dalla community.",',
            '"attributes": [',
                '{"trait_type": "Headline", "value": "', currentIssue.headline, '"},',
                '{"trait_type": "Date", "value": "', dateStr, '"}',
            '],',
            '"image": "data:image/svg+xml;base64,', Base64.encode(bytes(svg)), '"}'
        ))));

        return string(abi.encodePacked("data:application/json;base64,", json));
    }
}
