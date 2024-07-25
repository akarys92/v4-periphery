// SPDX-License-Identifier: UNLICENSED
import {ERC721} from "solmate/tokens/ERC721.sol";

/**
 * @title HookRegistry
 * @dev An ERC721 based registry for managing hook contracts used in Uniswap V4.
 */

contract HookRegistry is ERC721 {
    uint256 private _tokenIdCounter;

    struct HookMetadata {
        address hookAddress; 
        string description;
        string contact;
        string source;
        address[] auditors;
    }

    mapping(uint256 => HookMetadata) public hookMetadata;
    mapping(uint256 => address) private hookOwners;

    event HookMinted(uint256 tokenId, address owner, string description, string contact, string source);
    event MetadataUpdated(uint256 tokenId, string newDescription, string newContact, string newSource);
    event AuditorAdded(uint256 tokenId, address auditor);

    constructor() ERC721("HookRegistry", "HOOK") {}

    /**
     * @dev Modifier to check if the caller is the owner of the hook.
     * @param tokenId The ID of the token representing the hook.
     */
    modifier onlyHookOwner(uint256 tokenId) {
        require(msg.sender == hookOwners[tokenId], "Not the owner");
        _;
    }
    /**
     * @dev Mints a new Hook NFT.
     * @param hookAddress The address of the hook contract.
     * @param nonce The nonce used during the deployment of the hook contract.
     * @param description The description of the hook.
     * @param contact The contact information of the hook developer.
     * @param source The link to the source code for the hook.
     */
    function mintHookNFT(
        address hookAddress,
        uint256 nonce,
        string memory description,
        string memory contact,
        string memory source
    ) external {

        require(calculateAddress(msg.sender, nonce) == hookAddress, "Not the deployer of the hook");

        uint256 tokenId = _tokenIdCounter++;
        _mint(msg.sender, tokenId);
        hookOwners[tokenId] = msg.sender;
        
        hookMetadata[tokenId] = HookMetadata({
            hookAddress: hookAddress,
            description: description,
            contact: contact,
            source: source,
            auditors: new address[](0)
        });

        emit HookMinted(tokenId, msg.sender, description, contact, source);
    }

    /**
     * @dev Updates the metadata link of an existing Hook NFT.
     * @param tokenId The ID of the token representing the hook.
     * @param newDescription The new description of the hook.
     * @param newContact The new contact information of the hook developer.
     * @param newSource The new source link for the hook.
     */
    function updateMetadataLink(uint256 tokenId, string memory newDescription, string memory newContact, string memory newSource) external onlyHookOwner(tokenId) {
        hookMetadata[tokenId].description = newDescription;
        hookMetadata[tokenId].contact = newContact;
        hookMetadata[tokenId].source = newSource;
        emit MetadataUpdated(tokenId, newDescription, newContact, newSource);
    }

    /**
     * @dev Signs an audit for a Hook NFT.
     * @param tokenId The ID of the token representing the hook.
     */
    function signAudit(uint256 tokenId) external {
        HookMetadata storage metadata = hookMetadata[tokenId];
        metadata.auditors.push(msg.sender);
        emit AuditorAdded(tokenId, msg.sender);
    }

    /**
     * @dev Checks if a Hook NFT is audited by a specific auditor.
     * @param tokenId The ID of the token representing the hook.
     * @param auditor The address of the auditor.
     * @return bool True if the hook is audited by the specified auditor, false otherwise.
     */
    function isAuditedBy(uint256 tokenId, address auditor) external view returns (bool) {
        HookMetadata storage metadata = hookMetadata[tokenId];
        for (uint256 i = 0; i < metadata.auditors.length; i++) {
            if (metadata.auditors[i] == auditor) {
                return true;
            }
        }
        return false;
    }

    /**
     * @dev Returns the token URI for a Hook NFT.
     * @param tokenId The ID of the token representing the hook.
     * @return string The metadata of the hook.
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        HookMetadata storage metadata = hookMetadata[tokenId];
        return string(abi.encodePacked(
            '{"description":"', metadata.description,
            '", "contact":"', metadata.contact,
            '", "source":"', metadata.source,
            '"}'
        ));
    }

    /**
     * @dev Calculates the expected address of a contract deployed by a specific address with a given nonce. 
     * @param deployer The address of the deployer.
     * @param nonce The nonce used during the contract deployment.
     * @return address The calculated contract address.
     */
    function calculateAddress(address deployer, uint256 nonce) internal pure returns (address) {
        if (nonce == 0x00) return address(uint160(uint256(keccak256(abi.encodePacked(bytes1(0xd6), bytes1(0x94), deployer, bytes1(0x80))))));
        else if (nonce <= 0x7f) return address(uint160(uint256(keccak256(abi.encodePacked(bytes1(0xd6), bytes1(0x94), deployer, bytes1(uint8(nonce)))))));
        else if (nonce <= 0xff) return address(uint160(uint256(keccak256(abi.encodePacked(bytes1(0xd7), bytes1(0x94), deployer, bytes1(0x81), bytes1(uint8(nonce)))))));
        else if (nonce <= 0xffff) return address(uint160(uint256(keccak256(abi.encodePacked(bytes1(0xd8), bytes1(0x94), deployer, bytes1(0x82), uint16(nonce))))));
        else if (nonce <= 0xffffff) return address(uint160(uint256(keccak256(abi.encodePacked(bytes1(0xd9), bytes1(0x94), deployer, bytes1(0x83), uint24(nonce))))));
        return address(uint160(uint256(keccak256(abi.encodePacked(bytes1(0xda), bytes1(0x94), deployer, bytes1(0x84), uint32(nonce))))));
    }
}

