// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./Users.sol";

contract Market {
    address public admin;
    IERC20 public token;

    constructor() {
        admin = msg.sender;
    }

    Users public usercontract;

    uint8 totalTypes = 9;

    struct MarketListing {
        address seller;
        uint8 resourceType;
        uint32 amount;
        uint256 pricePerUnit;
        bool isActive;
    }

    mapping(uint256 => MarketListing) public marketListing;
    uint256 public nextListingId;

    struct ResourceAnalytics {
        uint64 totalUnitsSold;
        uint256 totalRevenue;
        uint256 averagePrice;
        uint256 lastPrice;
        uint256 minPrice;
        uint256 maxPrice;
        uint256 lastUpdatedTime;
    }

    mapping(uint8 => ResourceAnalytics) public resourceAnalytics;

    struct ListingAnalytics {
        uint64 totalUnitsListed;
        uint256 totalListingValue;
        uint64 totalListings;
        uint256 averageListingPrice;
        uint256 lastUpdatedTime;
    }

    mapping(uint8 => ListingAnalytics) public listingAnalytics;

    struct PricePoint {
        uint256 price;
        uint256 timestamp;
    }
    mapping(uint8 => PricePoint[]) public priceHistory;


    struct DailyPriceSummary {
        uint256 low;
        uint256 high;
        uint256 total;
        uint256 count;
        uint256 average;
    }
    mapping(uint8 => mapping(uint256 => DailyPriceSummary)) public dailyPriceSummary;


    function listIResorceForSale(uint8 _resourceType, uint32 _amount, uint256 _pricePerUnit) external {
        require(_amount > 0, "Amount should be more than 0");
        uint256 amount = usercontract.getUserInventory(msg.sender, _resourceType);
        require(amount >= _amount, "Not enough resources");
        usercontract.updateInventory(msg.sender, _resourceType, _amount, false);
        marketListing[nextListingId] = MarketListing({
            seller: msg.sender,
            resourceType: _resourceType,
            amount: _amount,
            pricePerUnit: _pricePerUnit,
            isActive: true
        });

        ListingAnalytics storage la = listingAnalytics[_resourceType];
        la.totalUnitsListed += _amount;
        la.totalListingValue += (_pricePerUnit * _amount);
        la.totalListings += 1;
        la.lastUpdatedTime = block.timestamp;
        nextListingId++;

        if(la.totalUnitsListed > 0) {
            la.averageListingPrice = la.totalListingValue / la.totalUnitsListed;
        }
    }

    function buyListedResource(
        uint256 listingId, uint32 buyAmount
    ) external {
        MarketListing storage listing = marketListing[listingId];
        require(listing.isActive, "Listing not available");
        require(buyAmount > 0 && buyAmount <= listing.amount, "Invalid buy amount");
        uint256 totalCost = listing.pricePerUnit * buyAmount;
        require(
            token.transferFrom(msg.sender, listing.seller, totalCost), "Token transfer failed"
        );
        
        usercontract.updateInventory(msg.sender, listing.resourceType, buyAmount, true);
        
        marketListing[listingId].amount -= buyAmount;
        if(marketListing[listingId].amount == 0) {
            marketListing[listingId].isActive = false;
        }

        
        ResourceAnalytics storage ra = resourceAnalytics[listing.resourceType];
        ra.totalUnitsSold += buyAmount;
        ra.totalRevenue += totalCost;
        ra.lastPrice = listing.pricePerUnit;
        ra.lastUpdatedTime = block.timestamp;

        if (ra.minPrice == 0 || listing.pricePerUnit < ra.minPrice) {
            ra.minPrice = listing.pricePerUnit;
        }
        if (listing.pricePerUnit > ra.maxPrice) {
            ra.maxPrice = listing.pricePerUnit;
        }
        if (ra.totalUnitsSold > 0) {
            ra.averagePrice = ra.totalRevenue / ra.totalUnitsSold;
        }

        PricePoint memory point = PricePoint({
            price: listing.pricePerUnit,
            timestamp: block.timestamp
        });

        priceHistory[listing.resourceType].push(point);
        uint256 day = block.timestamp / 1 days;
        DailyPriceSummary storage summary = dailyPriceSummary[listing.resourceType][day];

        if(summary.count == 0) {
            summary.low = listing.pricePerUnit;
            summary.high = listing.pricePerUnit;
        } else {
            if (listing.pricePerUnit < summary.low) summary.low = listing.pricePerUnit;
            if (listing.pricePerUnit > summary.high) summary.high = listing.pricePerUnit;
        }

        summary.total += listing.pricePerUnit;
        summary.count += 1;
        summary.average = summary.total / summary.count;


    }



    function getListingAnalytics() external view returns (
        uint8[] memory resourceIds,
        uint64[] memory listedUnits,
        uint256[] memory avgListingPrices,
        uint64[] memory totalListings,
        uint64[] memory soldUnits,
        uint256[] memory avgSoldPrices,
        uint256[] memory totalRevenues,
        uint256[] memory minPrices,
        uint256[] memory maxPrices,
        uint256[] memory lastSoldTimes
    ) {
    
        resourceIds = new uint8[](totalTypes);
        listedUnits = new uint64[](totalTypes);
        avgListingPrices = new uint256[](totalTypes);
        totalListings = new uint64[](totalTypes);
        soldUnits = new uint64[](totalTypes);
        avgSoldPrices = new uint256[](totalTypes);
        totalRevenues = new uint256[](totalTypes);
        minPrices = new uint256[](totalTypes);
        maxPrices = new uint256[](totalTypes);
        lastSoldTimes = new uint256[](totalTypes);

        for (uint8 i = 0; i < totalTypes; i++) {
            ListingAnalytics memory la = listingAnalytics[i];
            ResourceAnalytics memory ra = resourceAnalytics[i];

            resourceIds[i] = i;
            listedUnits[i] = la.totalUnitsListed;
            avgListingPrices[i] = la.averageListingPrice;
            totalListings[i] = la.totalListings;

            soldUnits[i] = ra.totalUnitsSold;
            avgSoldPrices[i] = ra.averagePrice;
            totalRevenues[i] = ra.totalRevenue;
            minPrices[i] = ra.minPrice;
            maxPrices[i] = ra.maxPrice;
            lastSoldTimes[i] = ra.lastUpdatedTime;
        }

    }


    function getResourceAnalytics(uint8 resourceType) external view returns (
        uint64 totalUnitsSold,
        uint256 totalRevenue,
        uint256 averagePrice,
        uint256 lastPrice,
        uint256 minPrice,
        uint256 maxPrice,
        uint256 lastUpdatedTime
    ) {
        ResourceAnalytics memory analytics = resourceAnalytics[resourceType];
        return (
            analytics.totalUnitsSold,
            analytics.totalRevenue,
            analytics.averagePrice,
            analytics.lastPrice,
            analytics.minPrice,
            analytics.maxPrice,
            analytics.lastUpdatedTime
        );
    }

    function getMarketListing(uint256 listingId) external view returns (
        address seller,
        uint8 resourceType,
        uint32 amount,
        uint256 pricePerUnit,
        bool isActive
    ) {
        MarketListing memory listing = marketListing[listingId];
        return (
            listing.seller,
            listing.resourceType,
            listing.amount,
            listing.pricePerUnit,
            listing.isActive
        );
    }

    function getAllMarketListings()
        external
        view
        returns (
            uint256[] memory listingIds,
            address[] memory sellers,
            uint8[] memory resourceTypes,
            uint32[] memory amounts,
            uint256[] memory pricePerUnits
        )
    {
        uint256 count = 0;

        // First, count active listings
        for (uint256 i = 0; i < nextListingId; i++) {
            if (marketListing[i].isActive) {
                count++;
            }
        }

        // Then fill arrays
        listingIds = new uint256[](count);
        sellers = new address[](count);
        resourceTypes = new uint8[](count);
        amounts = new uint32[](count);
        pricePerUnits = new uint256[](count);

        uint256 index = 0;
        for (uint256 i = 0; i < nextListingId; i++) {
            MarketListing memory m = marketListing[i];
            if (m.isActive) {
                listingIds[index] = i;
                sellers[index] = m.seller;
                resourceTypes[index] = m.resourceType;
                amounts[index] = m.amount;
                pricePerUnits[index] = m.pricePerUnit;
                index++;
            }
        }
    }




}