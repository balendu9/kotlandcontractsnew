// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./Users.sol";
import "./Tiles.sol";
contract Compute {
    address admin;

    constructor() {
        admin = msg.sender;
    }

    uint8 public currentSeason  = 0;
    Users public usercontract;
    Tiles public tilescontract;

    function updateContracts(address _usercontract, address _tilecontract) external {
        require(msg.sender == admin, "Not authorized");
        usercontract = Users(_usercontract);
        tilescontract = Tiles(_tilecontract);
    }

    function updateSeason(uint8 season) external {
        require(msg.sender == admin, "Not authorized");
        currentSeason = season;
    }

    function plantYieldCalculator(uint8 cropType) external view returns(uint8){
        uint8 growthRate = 0;
        
        if (cropType == 1) {
            growthRate = (currentSeason == 1) ? 5 :
                ((currentSeason == 0 || currentSeason == 3) ? 3 : 2);
        } else if (cropType == 2) {
            growthRate = (currentSeason == 2) ? 4 : 
                (currentSeason == 1 ? 3 : 1);
        } else if (cropType == 3) {
            growthRate = (currentSeason == 0) ? 4 : 
                (currentSeason == 1 ? 3 : 1);         
        } else if (cropType == 4) {
            growthRate = (currentSeason == 0) ? 5 :
                ((currentSeason == 1 || currentSeason == 3) ? 3 : 2);
        } else {
            growthRate = 0;
        }

        return growthRate;
    }


    // food => 100
    function produceFood(address _user, uint8 assetlevel) external {
        require(msg.sender == address(tilescontract), "Not authorized");
        uint256 wheat = usercontract.getUserInventory(_user, 1);
        uint256 corn = usercontract.getUserInventory(_user, 2);
        uint256 potato = usercontract.getUserInventory(_user, 3);
        uint256 carrot = usercontract.getUserInventory(_user, 4);

        require(wheat >= 500 || corn >= 500 || potato >= 500 || carrot >= 500, "Not enough resources");

        if(wheat >= 500) {
            usercontract.updateInventory(_user, 1, 500, false);
        } else if(corn >= 500) {
            usercontract.updateInventory(_user, 2, 500, false);
        } else if(potato >= 500) {
            usercontract.updateInventory(_user, 3, 500, false);
        } else if(carrot >= 500) {
            usercontract.updateInventory(_user, 4, 500, false);
        }
        uint256 produce = 100 + (assetlevel - 1) * 20;
        usercontract.updateInventory(_user, 5, produce, true);
    }

    // 100 factory products => 200 energy
    function produceEnergy(address _user, uint8 assetlevel) external {
        require(msg.sender == address(tilescontract), "Not authorized");
        uint256 factorygoods = usercontract.getUserInventory(_user, 7);
        require(factorygoods >= 100, "Not enough resources");
        usercontract.updateInventory(_user, 7, 100, false);
        uint256 produce = 200 + (assetlevel - 1) * 20;
        usercontract.updateInventory(_user, 6, produce, true);
    }

    //wheat, food = 500, 100 => factory goods = 80
    function produceBakery(address _user, uint8 assetlevel) external {
        require(msg.sender == address(tilescontract), "Not authorized");
        uint256 wheat = usercontract.getUserInventory(_user, 1);
        uint256 food = usercontract.getUserInventory(_user, 5);
        require(wheat >= 500 && food >= 100, "Not enough resources");
        usercontract.updateInventory(_user, 1, 500, false);
        usercontract.updateInventory(_user, 5, 100, false);
        uint256 produce = 80 + (assetlevel - 1) * 20;
        usercontract.updateInventory(_user, 7, produce, true);
    }

    // corn 200 carrot 200 => factory good = 90
    function produceJuice(address _user, uint8 assetlevel) external {
        require(msg.sender == address(tilescontract), "Not authorized");
        uint256 corn = usercontract.getUserInventory(_user, 2);
        uint256 carrot = usercontract.getUserInventory(_user, 4);

        require(corn >= 200 && carrot >= 200, "Not enough resources");
        usercontract.updateInventory(_user, 2, 200, false);
        usercontract.updateInventory(_user, 4, 200, false);
        uint256 produce = 90 + (assetlevel - 1) * 20;
        usercontract.updateInventory(_user, 7, produce, true);
    }

    // factory goods 200 => energy 100 fertilizer 1000
    function produceBiofuel(address _user, uint8 assetlevel) external {
        require(msg.sender == address(tilescontract), "Not authorized");
        uint256 factorygoods = usercontract.getUserInventory(_user, 7);
        require(factorygoods >= 200, "Not enough resources");
        usercontract.updateInventory(_user, 7, 200, false);
        uint256 produce1 = 100 + (assetlevel - 1) * 20;
        uint256 produce2 = 1000 + (assetlevel - 1) * 20;
        usercontract.updateInventory(_user, 6, produce1, true);
        usercontract.updateInventory(_user, 8, produce2, true);
    }

}