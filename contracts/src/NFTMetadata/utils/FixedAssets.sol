//SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "lib/Solady/src/utils/SSTORE2.sol";

contract FixedAssetReader {
    struct Asset {
        uint128 start;
        uint128 end;
    }

    address public immutable pointer;

    mapping(bytes4 => Asset) public assets;

    function readAsset(bytes4 _sig) public view returns (string memory) {
        return string(SSTORE2.read(pointer, uint256(assets[_sig].start), uint256(assets[_sig].end)));
    }

    constructor(address _pointer, bytes4[] memory _sigs, Asset[] memory _assets) {
        pointer = _pointer;
        require(_sigs.length == _assets.length, "FixedAssetReader: Invalid input");
        for (uint256 i = 0; i < _sigs.length; i++) {
            assets[_sigs[i]] = _assets[i];
        }
    }
}

// This contract is meant to be used only for testing and deployment scripts
// It helps with loading the base64 SVGs during deployment
contract FixedAssetDeployer {
    struct File {
        bytes data;
        uint256 start;
        uint256 end;
    }
    
    mapping(bytes4 => File) public files;
    
    // Function to load SVG data from a deployment script
    function loadSVGData(string memory _name, bytes memory _data) public {
        bytes4 sig = bytes4(keccak256(bytes(_name)));
        uint256 offset = 0;
        
        if (files[sig].data.length > 0) {
            offset = files[sig].end;
        }
        
        files[sig] = File(_data, offset, offset + _data.length);
    }
    
    // Function to store all SVG data and deploy FixedAssetReader
    function deployFixedAssetReader() public returns (FixedAssetReader) {
        // Get all signatures
        bytes4[] memory signatures = new bytes4[](11);
        signatures[0] = bytes4(keccak256("USA.d"));
        signatures[1] = bytes4(keccak256("tBTC"));
        signatures[2] = bytes4(keccak256("wBTC"));
        signatures[3] = bytes4(keccak256("cbBTC"));
        signatures[4] = bytes4(keccak256("sUSDS"));
        signatures[5] = bytes4(keccak256("sfrxUSD"));
        signatures[6] = bytes4(keccak256("sDAI"));
        signatures[7] = bytes4(keccak256("scrvUSD"));
        signatures[8] = bytes4(keccak256("dmSans"));
        signatures[9] = bytes4(keccak256("leverageLogo"));
        signatures[10] = bytes4(keccak256("sfrxETH"));
        
        // Concatenate all SVG data
        bytes memory allData = bytes.concat(
            files[signatures[0]].data,
            files[signatures[1]].data,
            files[signatures[2]].data,
            files[signatures[3]].data,
            files[signatures[4]].data,
            files[signatures[5]].data,
            files[signatures[6]].data,
            files[signatures[7]].data,
            files[signatures[8]].data,
            files[signatures[9]].data,
            files[signatures[10]].data
        );
        
        // Store the data
        address dataPointer = SSTORE2.write(allData);
        
        // Create assets array
        FixedAssetReader.Asset[] memory assets = new FixedAssetReader.Asset[](11);
        
        for (uint256 i = 0; i < 11; i++) {
            bytes4 sig = signatures[i];
            File memory file = files[sig];
            assets[i] = FixedAssetReader.Asset(
                uint128(file.start),
                uint128(file.end)
            );
        }
        
        // Deploy the reader
        return new FixedAssetReader(dataPointer, signatures, assets);
    }
}
