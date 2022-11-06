//SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "./verifier.sol";

contract SparkZ is ERC1155 {
    enum JourneyType {
        Ride,
        Move,
        Attack
    }
    struct Journey {
        JourneyType journeyType;
        uint256 startLocation; // locationId
        uint256 startTime; // Timestamp
        uint256 endLocation; // locationId
        uint256 endTime;
        uint256 sparkz;
        uint256 shadowz;
        uint256 timeTaken;
    }
    Journey journey;

    struct User {
        string name;
        string hometown;
        string country;
        uint256 sparkz;
        uint256 shadowz;
        bool isVerified;
    }
    User user;

    struct Location {
        PlaceType placeType;
        address registerAddress;
        address owner;
        uint256 level;
        string locationName;
        uint256 locationId;
        bytes32 locationHash;
        int latitude;
        int longitude;
        uint256 sparkz;
        uint256 shadowz;
    }
    Location location;

    enum PlaceType {
        Public_Park,
        Skate_Park,
        Soccer_Field,
        Basketball_Court,
        Playground,
        Outdoor_Gym,
        ArtGallery_Museum,
        Stadium,
        Beach,
        Recycling_Deposit,
        Bus_Stop,
        Library,
        University,
        Church_Temple,
        Government_Office
    }

    uint256 public locationId;
    // Verifier generated by ZK-circuit
    address verifierAddress = 0x5FD6eB55D12E759a21C09eF703fe0CBa1DC9d88D;
    address[] public registeredUsers;

    mapping(address => User) public addressToUserDetail;
    mapping(address => Journey) public addressToJourneyDetail;
    mapping(address => uint[]) public addressToOwnedLocationIds;
    mapping(address => bool) public userRegistered;
    mapping(uint256 => Location) public locationIdToLocationDetail;
    mapping(uint256 => string) uris;

    event LocationAdded(
        address indexed _from,
        address _registerAddress,
        address _owner,
        uint256 _locationId,
        uint256 _level,
        PlaceType _placeType,
        uint256 _sparkz,
        uint256 _shadowz,
        string _locationName,
        bytes32 _locationHash,
        int _latitude,
        int _longitude
    );
    event UserRegistered(
        address indexed _from,
        string _name,
        string _homeTown,
        string _country,
        uint256 _sparkz,
        uint256 _shadowz
        // int[] _ownedLocations
    );
    event JourneyRegistered(
        address indexed _from,
        JourneyType _journeyType,
        uint256 _startLocation,
        uint256 _endLocation,
        uint256 _startTime,
        uint256 _endTime,
        uint256 _sparkz,
        uint256 _shadowz,
        uint256 _timeTaken,
        uint256 _sparkzUser,
        uint256 _shadowzUser
    );

    constructor() ERC1155("") {
        locationId = 0;
        owner = msg.sender;
    }

    address owner;

    modifier isOwner(address _address) {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }
    modifier isUserRegistered(address _address) {
        require(userRegistered[_address], "This user is not registered");
        _;
    }
    modifier isVerifiedUser(address _address) {
        require(addressToUserDetail[_address].isVerified == true, "This user is not verified");
        _;
    }
    modifier locationIdExists(uint256 _locationId) {
        require(_locationId <= locationId, "This location id doesn't exist");
        _;
    }

    /**
     * @dev Registering user in the game
     */
    function registerUser(
        string memory _name,
        string memory _hometown,
        string memory _country
    ) public {
        require(
            userRegistered[msg.sender] == false,
            "You are already registered"
        );

        userRegistered[msg.sender] = true;
        registeredUsers.push(msg.sender);

        addressToUserDetail[msg.sender].name = _name;
        addressToUserDetail[msg.sender].hometown = _hometown;
        addressToUserDetail[msg.sender].country = _country;
        addressToUserDetail[msg.sender].sparkz = 0;
        addressToUserDetail[msg.sender].shadowz = 0;
        // addressToUserDetail[msg.sender].ownedLocationsId[0] = -1;
        addressToUserDetail[msg.sender].isVerified = false;

        emit UserRegistered(
            msg.sender,
            addressToUserDetail[msg.sender].name,
            addressToUserDetail[msg.sender].hometown,
            addressToUserDetail[msg.sender].country,
            addressToUserDetail[msg.sender].sparkz,
            addressToUserDetail[msg.sender].shadowz
            // addressToUserDetail[msg.sender].ownedLocationsId
        );
    }

    function verfiyUser(address userAddress) public isOwner(msg.sender) {
        addressToUserDetail[userAddress].isVerified = true;
    }

    function upgradePlace(
        uint256 _locationId,
        uint256 _shadowz,
        uint256 _level
    ) public {
        require (_shadowz > locationIdToLocationDetail[_locationId].level * 1000, "Not enough shadowz to upgrade the place");
        require (_level > locationIdToLocationDetail[_locationId].level, "Cannot downgrade the level of the place");
        transferShadowz(_locationId, _shadowz, msg.sender);
        locationIdToLocationDetail[_locationId].level = _level;
    }

    function registerJourney(
        JourneyType _journeyType,
        uint256 _startLocationId,
        uint256 _startTime,
        uint256 _endLocationId,
        uint256 _endTime,
        uint256 _sparkz,
        uint256 _shadowz
    ) public isUserRegistered(msg.sender) {
        // check for enum if required
        int status;
        if (_journeyType == JourneyType(2)) {
            status = attack(_endLocationId, _sparkz, msg.sender);
        } else {
        addressToJourneyDetail[msg.sender].journeyType = _journeyType;
        addressToJourneyDetail[msg.sender].startLocation = _startLocationId;
        addressToJourneyDetail[msg.sender].endLocation = _endLocationId;
        addressToJourneyDetail[msg.sender].startTime = _startTime;
        addressToJourneyDetail[msg.sender].endTime = _endTime;
        addressToJourneyDetail[msg.sender].sparkz = _sparkz;
        addressToJourneyDetail[msg.sender].shadowz = _shadowz;
        addressToJourneyDetail[msg.sender].timeTaken = _endTime - _startTime;
        addressToUserDetail[msg.sender].sparkz += _sparkz;
        addressToUserDetail[msg.sender].shadowz += _shadowz;
        }

        emit JourneyRegistered(
            msg.sender,
            addressToJourneyDetail[msg.sender].journeyType,
            addressToJourneyDetail[msg.sender].startLocation,
            addressToJourneyDetail[msg.sender].endLocation,
            addressToJourneyDetail[msg.sender].startTime,
            addressToJourneyDetail[msg.sender].endTime,
            addressToJourneyDetail[msg.sender].sparkz,
            addressToJourneyDetail[msg.sender].shadowz,
            addressToJourneyDetail[msg.sender].timeTaken,
            addressToUserDetail[msg.sender].sparkz,
            addressToUserDetail[msg.sender].shadowz
        );
    }
    function attack(
        uint256 _locationId,
        uint256 _sparkz,
        address _address
    ) public returns (int) {
        require (_sparkz > locationIdToLocationDetail[_locationId].sparkz, "Not enough sparkz to attack");
        transferSparkz(_locationId, _sparkz, _address);
        locationIdToLocationDetail[_locationId].owner = _address;
        return 1;
    }

    function verifyLocation(
        uint256[2] memory a,
        uint256[2][2] memory b,
        uint256[2] memory c,
        uint256[1] memory input
    ) public view isUserRegistered(msg.sender) {
        bool isVerified = Verifier(address(verifierAddress)).verifyProof(
            a,
            b,
            c,
            input
        );
        require(isVerified == true, "Location not verified");
    }

    function addLocation(
        uint256 _placeType,
        string memory _locationName,
        int _latitude,
        int _longitude,
        string memory _ipfsuri
    ) public isVerifiedUser(msg.sender) {
        // updating the place struct
        locationIdToLocationDetail[locationId].placeType = PlaceType(_placeType);
        locationIdToLocationDetail[locationId].registerAddress = msg.sender;
        locationIdToLocationDetail[locationId].owner = msg.sender;
        locationIdToLocationDetail[locationId].level = 0;
        locationIdToLocationDetail[locationId].locationName = _locationName;
        locationIdToLocationDetail[locationId].locationId = locationId;
        locationIdToLocationDetail[locationId].latitude = _latitude;
        locationIdToLocationDetail[locationId].longitude = _longitude;
        locationIdToLocationDetail[locationId].locationHash = hash(_locationName);
        locationIdToLocationDetail[locationId].sparkz = 0;
        locationIdToLocationDetail[locationId].shadowz = 0;
        addressToOwnedLocationIds[msg.sender].push(locationId);

        //registration results in the place being minted as an nft. the nft id will be the same as the placeId
        mint(msg.sender, locationId, 1, "");
        setTokenUri(locationId, _ipfsuri);
        emit LocationAdded(
            msg.sender,
            locationIdToLocationDetail[locationId].registerAddress,
            locationIdToLocationDetail[locationId].owner,
            locationId,
            locationIdToLocationDetail[locationId].level,
            locationIdToLocationDetail[locationId].placeType,
            locationIdToLocationDetail[locationId].sparkz,
            locationIdToLocationDetail[locationId].shadowz,
            locationIdToLocationDetail[locationId].locationName,
            locationIdToLocationDetail[locationId].locationHash,
            locationIdToLocationDetail[locationId].latitude,
            locationIdToLocationDetail[locationId].longitude
        );
        locationId += 1;
    }

    // function getCities() public view returns (Location[] memory) {
    //     Location[] memory id = new Location[](locationId);
    //     for (uint256 i = 0; i < locationId; i++) {
    //         Location storage locationTemp = locationIdToLocationDetail[i];
    //         id[i] = locationTemp;
    //     }
    //     return id;
    // }

    // function getUsers() public view returns (User[] memory) {
    //     User[] memory users = new User[](registeredUsers.length);
    //     for (uint256 i = 0; i < registeredUsers.length; ++i) {
    //         User storage userTemp = addressToUserDetail[registeredUsers[i]];
    //         users[i] = userTemp;
    //     }
    //     return users;
    // }

    function transferSparkz(uint256 _locationId, uint256 _sparkz, address _address) public {
        require(addressToUserDetail[_address].sparkz > _sparkz, "Not enough sparkz");
        addressToUserDetail[_address].sparkz -= _sparkz;
        locationIdToLocationDetail[_locationId].sparkz += _sparkz;
    }
    function transferShadowz(uint256 _locationId, uint256 _shadowz, address _address) public {
        require(addressToUserDetail[_address].shadowz > _shadowz, "Not enough shadowz");
        addressToUserDetail[_address].shadowz -= _shadowz;
        locationIdToLocationDetail[_locationId].shadowz += _shadowz;
    }

    function hash(string memory _string) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(_string));
    }

    // Minting and metadata

    function mint(
        address account,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        _mint(account, id, amount, data);
    }

    function uri(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        return (uris[_tokenId]);
    }

    function setTokenUri(uint256 _tokenId, string memory _uri) internal {
        require(bytes(uris[_tokenId]).length == 0, "Cannot set uri twice");
        uris[_tokenId] = _uri;
    }
}
