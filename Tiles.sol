// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./Users.sol";
import "./Compute.sol";
interface IERC20 {
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function balanceOf(address account) external view returns (uint256);

    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);
}

contract Tiles {
    address admin;
    uint256 public MAX_TILES = 5;
    uint256 public totalTilesUnlocked = 0;
    Users public usercontract;
    Compute public computecontract;

    IERC20 public token;

    struct TileData {
        uint32 id;
        address owner;
        bool isBeingUsed;
        bool isCrop;
        uint8 cropTypeId;
        uint8 factoryTypeId;
        uint8 assetLevel;
        uint256 assetdeploytime;
        uint256 lastClaimedTime;
        uint256 baseLifetimeDays;
    }


    // to check if the tile is already bought or not
    mapping(address => mapping(uint256 => bool)) public tileExists;

    //array to store all the tiles owned by user
    mapping(address => uint32[]) public userOwnedTilesId;
    
    //to store data of tile owned by user
    mapping(address => mapping(uint256 => TileData)) public userTilesData;

    function buyNewTile (uint32 tileId) external {
        require(tileId <= MAX_TILES, "Invalid Tile id");
        require(userTilesData[msg.sender][tileId].owner == address(0), "Tile already owned");

        uint256 price = 3000000 * 10 ** 18;

        require(
            token.transferFrom(msg.sender, address(this), price),
            "Token transfer failed"
        );
        totalTilesUnlocked++;

        TileData memory newTile = TileData ({
            id: tileId,
            owner: msg.sender,
            isBeingUsed: false,
            isCrop: false,
            cropTypeId: 0,
            factoryTypeId: 0,
            assetLevel: 0,
            assetdeploytime: 0,
            lastClaimedTime: 0,
            baseLifetimeDays: 0
        });

        userTilesData[msg.sender][tileId] = newTile;
        userOwnedTilesId[msg.sender].push(tileId);

        tileExists[msg.sender][tileId] = true;
    }

    function plantCrop(uint32 tileId, uint8 cropType) external {
        require(tileId <= MAX_TILES, "Invalid tile id");
        TileData storage tile = userTilesData[msg.sender][tileId];
        require(tile.owner == msg.sender, "Not authorized");
        require(!tile.isBeingUsed, "Tile is already being used");

        uint256 plantCost = 10000 * 10 ** 18;
        require(
            token.transferFrom(msg.sender, address(this), plantCost), 
            "Token payment failed"
        );

        tile.isBeingUsed = true;
        tile.assetdeploytime = block.timestamp;
        tile.assetLevel = 1;
        tile.baseLifetimeDays = 3 days;
        tile.cropTypeId = cropType;
        tile.lastClaimedTime = block.timestamp;
    }


    function buildFactory(uint32 tileId, uint8 factoryType) external {
        require(tileId <= MAX_TILES, "Invalid tile id");
        TileData storage tile = userTilesData[msg.sender][tileId];
        require(tile.owner == msg.sender, "Not authorized");
        require(!tile.isBeingUsed, "Tile is already being used");
        
        uint256 factorycost = 500000 * 10 ** 18;
        require(
            token.transferFrom(msg.sender, address(this), factorycost),
            "Token payment failed"
        );

        tile.isBeingUsed = true;
        tile.assetdeploytime = block.timestamp;
        tile.assetLevel = 1;
        tile.baseLifetimeDays = 0;
        tile.cropTypeId = 0;
        tile.factoryTypeId = factoryType;
        tile.lastClaimedTime = block.timestamp;
    } 
    

    function upgradeAsset(uint32 tileId) external {
        require(tileId <= MAX_TILES, "Invalid tile id");
        TileData storage tile = userTilesData[msg.sender][tileId];
        require(tile.owner == msg.sender, "Not authorized");
        require(tile.isBeingUsed, "Tile is already being used");
        require(tile.assetLevel <= 10, "Max upgrade");

        tile.assetLevel++;
        tile.baseLifetimeDays+= 1 days;
    }

    function claimYield(uint32 tileId) external {
        require(tileId <= MAX_TILES, "Invalid tile id");
        TileData storage tile = userTilesData[msg.sender][tileId];
        require(tile.owner == msg.sender, "Not the owner");
        require(tile.isBeingUsed, "Nothing there");
        
        uint256 fertilizer = usercontract.getUserInventory(msg.sender, 8);
        if (tile.isCrop) {
            require(fertilizer >= 50, "Not enough fertilizers");
            usercontract.updateInventory(msg.sender, 8, 50, false);
            uint8 growthRate  = computecontract.plantYieldCalculator(tile.cropTypeId);

            uint256 timePassed = block.timestamp - tile.lastClaimedTime;
            uint256 maxDuration = tile.baseLifetimeDays + tile.assetLevel - 1;

            if (block.timestamp > maxDuration) {
                // crop has expired
                tile.isBeingUsed = false;
                tile.assetdeploytime = 0;
                tile.assetLevel = 0;
                tile.baseLifetimeDays = 0;
                tile.cropTypeId = 0;
                tile.factoryTypeId = 0;
                tile.lastClaimedTime = 0;
                return;
            }
            uint256 yield = growthRate * (timePassed /60);
            usercontract.updateInventory(msg.sender, tile.cropTypeId, yield, true);
            tile.lastClaimedTime = block.timestamp;
        } else {
            uint256 energy = usercontract.getUserInventory(msg.sender, 6);
            if(tile.factoryTypeId == 1) {
                require(energy >= 100, "Not enough resources");
                computecontract.produceFood(msg.sender);
            } else if(tile.factoryTypeId == 2) {
                computecontract.produceEnergy(msg.sender);
            } else if(tile.factoryTypeId == 3) {
                computecontract.produceBakery(msg.sender);
            } else if(tile.factoryTypeId == 4) {
                computecontract.produceJuice(msg.sender);
            } else if(tile.factoryTypeId == 5) {
                computecontract.produceBiofuel(msg.sender);
            } else {
                revert("Invalid Factory type");
            }
        }
    }

}