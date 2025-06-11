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


    mapping(address => uint256) public spent;
    mapping(address => uint256) public earned;
    mapping(address => uint256) public currentCropCount;
    mapping(address => uint256) public currentFactoryCount;
    mapping(address => uint256) public totalCropCount;
    mapping(address => uint256) public totalFactoryCount;
    

    modifier onlyKotContracts() {
        require(msg.sender == address(tilescontract) || msg.sender == address(computecontract), "Not authorized");
        _;
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


    // ===============================
    //    leaderboard
    // ===============================

    address[] public topPlayers;
    mapping(address => string) public usernames;

    function updateLeaderBoard(address _user) internal {
        if(!users[_user].exists) return;

        bool exists = false;
        for (uint256 i = 0; i < topPlayers.length; i++) {
            if (topPlayers[i] == _user) {
                exists = true;
                break;
            }
        }

        if (!exists) {
            topPlayers.push(_user);
        }
        //sorting leaderboard by exp
        for(uint256 i = 0; i < topPlayers.length; i++) {
            for (uint256 j = i+1; j < topPlayers.length; j++) {
                if (users[topPlayers[j]].userExperience > users[topPlayers[i]].userExperience) {
                    (topPlayers[i], topPlayers[j]) = (topPlayers[j], topPlayers[i]);
                }
            }
        }

        // only 100 players
        if (topPlayers.length > 100) {
            topPlayers.pop();
        }
    }


    function getLeaderboard() external view returns (address[] memory, uint32[] memory) {
        uint256 len = topPlayers.length;
        address[] memory playerAddresses = new address[](len);
        uint32[] memory playerExperience = new uint32[](len);

        for(uint8 i = 0; i< len; i++) {
            playerAddresses[i] = topPlayers[i];
            playerExperience[i] = users[topPlayers[i]].userExperience;
        }

        return(playerAddresses ,playerExperience);

    }




    // ===============================
    //    GETTER
    // ===============================

    function getUserData(address _user) external view returns(
        address userAddress, uint32 totalTilesOwned, uint32 tilesUnderUse, uint32 userExperience, bool exists
    ) {
        require(users[_user].exists, "User doesnt exist");
        UserData storage userData = users[_user];
        return (
            userData.userAddress,
            userData.totalTilesOwned,
            userData.tilesUnderUse,
            userData.userExperience,
            userData.exists
        );
    }

    function getUserInventory(address user, uint8 resource) external view returns(uint256) {
        return users[user].inventory[uint8(resource)];
    }


    uint8 public totalresources = 9;

    function getUserAllInventory(address user) external view returns (uint256[] memory) {
        uint256[] memory inventoryData = new uint256[](totalresources);
        
        for (uint8 i =0; i < totalresources; i++) {
            inventoryData[i] = users[user].inventory[i];
        }

        return inventoryData;
    }

    

}