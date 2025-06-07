// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Tiles.sol";
import "./Compute.sol";
contract Users {

    address admin;
    Tiles public tilescontract;
    Compute public computecontract;
    
    struct UserData {
        address userAddress;
        uint32 totalTilesOwned;
        uint32 tilesUnderUse;
        uint32 userExperience;
        bool exists;
        mapping(uint8 => uint256) inventory;
    }

    mapping(address => UserData) public users;
    function updateContracts(address _tilescontract, address _computecontract) external {
        require(msg.sender == admin, "Not authorized");
        tilescontract = Tiles(_tilescontract);
        computecontract = Compute(_computecontract);
    }

    modifier onlyKotContracts() {
        require(msg.sender == address(tilescontract) || msg.sender == address(computecontract), "Not authorized");
        _;
    }


    function getUserInventory(address user, uint8 resource) external view returns(uint256) {
        return users[user].inventory[uint8(resource)];
    }
    

    function updateInventory(
        address _user, uint8 resource, uint256 amount, bool increase
    ) external onlyKotContracts {
        if (increase) {
            users[_user].inventory[resource] += amount;
        } else {
            users[_user].inventory[resource] -= amount;
        }
    }


}