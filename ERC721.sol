// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import "Ownable.sol";
import "IERC721.sol";

abstract contract ERC721 is Ownable, IERC721, IERC721TokenReceiver{

    //Mapping from token ID to owner address
    mapping(uint256 => address) public owners;

    //Mapping from owner address to token count
    mapping(address => uint256) public balances;

    //Mappping from tokenID to approved addresses
    mapping(uint256 => address) public tokenApprovals;

    //Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) public operatorApprovals;


    //Verifies inputted address if the NFT can be transferred to this address
    function verifyAddress(address _addr) internal virtual {
        require(_addr != address(0), "Invalid address");
    }

    //Verifies the ownership of an NFT/token 
    function verifyOwnership(address _addr, uint256 _tokenId) internal virtual {
        require(owners[_tokenId] == _addr, "Invalid, this is not the owner");
    }

    //Verifies your approval
    function verifyApproval(address _addr, uint256 _tokenId) internal virtual {
        require(owners[_tokenId] == _addr || tokenApprovals[_tokenId] == _addr, "Invalid, address not approved/does not own the token");
    }

    //Verify token
    function verifyToken(uint256 _tokenId) internal virtual {
        require(owners[_tokenId] != address(0), "Invalid, token does not exist");
    }


    //Returns the owner of the NFT
    function ownerOf(uint256 _tokenId) external view override returns(address) {
        return owners[_tokenId];
    }

    //Returns the amount of token the _addr holds
    function balanceOf(address _addr) external view override returns(uint256){
        return balances[_addr];
    }

    //Creates a new NFT and assigns it to an address
    function mint(address _to, uint256 _tokenId) external {
        owners[_tokenId] = _to;
        balances[_to] += 1;
    }

    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes calldata data) external {
        verifyAddress(_from);
        verifyAddress(_to);
        verifyOwnership(_from, _tokenId);

        balances[msg.sender] -= 1;
        balances[_to] += 1;
        owners[_tokenId] = _to;
        tokenApprovals[_tokenId] = address(0);
        
        uint32 size;
        assembly {
            size := extcodesize(_to)
        }
        if(size > 0){
            IERC721TokenReceiver receiver = IERC721TokenReceiver(_to);
            require(receiver.ERC721TokenReceived(msg.sender, _from, _tokenId, data) == bytes4(keccak256("ERC721TokenReceived(address,address,uint256,bytes")));
        }
        emit Transfer(_from, _to, _tokenId);
    }

    //When a user transfers NFT to specified address 
    function transferFrom(address _from, address _to, uint256 _tokenId) public override{
        verifyAddress(_from);
        verifyAddress(_to);
        verifyOwnership(_from, _tokenId);

        balances[_from] -= 1;
        balances[_to] += 1;
        owners[_tokenId] = _to;
        emit Transfer(_from, _to, _tokenId);
    }

    function approve(address _to, uint256 _tokenId) external override{
        require(_to != msg.sender, "Invalid address");
        verifyAddress(_to);
        verifyApproval(msg.sender, _tokenId);
        verifyToken(_tokenId);

        tokenApprovals[_tokenId] = _to;
        emit Approval(owners[_tokenId], _to, _tokenId);
    }
   
    function getApproved(uint256 _tokenId) external override returns(address){
        verifyToken(_tokenId);
        return tokenApprovals[_tokenId];
    }

    function setApprovalForAll(address _operator, bool _approved) external override {
        require(_operator != address(0) && _operator != msg.sender, "Invalid");
        require(_operator != owner);
        operatorApprovals[msg.sender][_operator] = _approved;
        emit ApprovalForAll(msg.sender, _operator, _approved);
    }

    function isApprovedForAll(address _owner, address _operator) external view override returns(bool) {
        return operatorApprovals[_owner][_operator];
    }

}