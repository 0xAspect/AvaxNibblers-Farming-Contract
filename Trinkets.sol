
pragma solidity 0.8.3;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


interface IRats {
   function currentLevel(uint) external view returns(uint);
   function ownerOf(uint) external view returns(address);
   function tokenOfOwnerByIndex(address, uint) external view returns(uint);
   function balanceOf(address) external view returns (uint);
    function mintTime(uint) external view returns(uint);
}


contract Trinkets is Ownable, ERC20("Sewer Trinkets", "TRINK") {

    //emissions modifier 
    uint mod = 100;

    bool earningLive = false;
    uint liveTime = 0;

    mapping(uint256 => uint256) public startTime;

	event TrinketsSent(address indexed user, uint256 reward);

   address ratFactoryAddr;

    function setRatFactoryAddr(address _factory) public onlyOwner {
        ratFactoryAddr = _factory;
    }
 
	constructor(address _initRatFactoryAddr){
        setRatFactoryAddr(_initRatFactoryAddr);
    }

	function gatherGoLive () external onlyOwner {
        earningLive = true;
        liveTime = block.timestamp;
	}

    function pauseGather () external onlyOwner(){
        earningLive = false;
    }
    
    
    function setMod(uint _mod) external onlyOwner {
        mod = _mod;
	}

    function calculateYield(uint _id) public view returns(uint){
        
        if (earningLive == true){
            uint level = IRats(ratFactoryAddr).currentLevel(_id);
            uint baseYield =  gatherTime(_id) / 100;
            uint levelMultiplier = 10 + ((level - 1)* 2); 
            uint finalYield = ((baseYield * levelMultiplier) * mod ) / 100;
            return finalYield; 
        } else {
            return 0;
        }
    }
    function gatherTime(uint _id) public view returns(uint){
        
            uint end = block.timestamp;
            uint start = 0;
            //if never claimed trinkets check the mintTime of the NFT
            if (startTime[_id] == 0){
                uint mintTime = IRats(ratFactoryAddr).mintTime(_id);
                //if the mint time is before the ERC20 farming golive then set the farming start time to the farming start date and vice versa.
                if (mintTime < liveTime) {
                    start = liveTime;
                } else {
                    start = mintTime;
                }
            //if NFT has ERC20 claimed before then it will have a startime Mapping
            } else {
                start  = startTime[_id];
            }
            //return the difference between mint/gather or golive and current block in seconds
            return end - start;

    }

	function claimTrinkets(uint _id) public {

            uint yield = calculateYield(_id);
            address owner = IRats(ratFactoryAddr).ownerOf(_id);
            if (yield > 0) {
                startTime[_id] = block.timestamp;
                _mint(owner, yield * 100000000000000000);
                emit TrinketsSent(owner, yield);
            }

	}
 

    function claimTrinketsAllRats(address _address) public {
        uint bal = IRats(ratFactoryAddr).balanceOf(_address);
        uint totalYield;
        for (uint i = 0; i < bal; i++){
            uint id = IRats(ratFactoryAddr).tokenOfOwnerByIndex(_address, i);
            totalYield = totalYield + calculateYield(id);
            startTime[id] = block.timestamp;
        }
        if (totalYield > 0) {
                _mint(_address, totalYield * 100000000000000000);
                emit TrinketsSent(_address, totalYield);
            }
    }
    function totalUnclaimedTrinkets(address _address ) public view returns(uint){
        uint unclaimedYield;
        uint bal = IRats(ratFactoryAddr).balanceOf(_address);
        for (uint i = 0; i < bal; i++){
            uint id = IRats(ratFactoryAddr).tokenOfOwnerByIndex(_address, i);
            uint ratYield = calculateYield(id);
            unclaimedYield = unclaimedYield + ratYield;
        }
        return unclaimedYield;
    }

	function burn(address _from, uint256 _amount) external {
		require(msg.sender == address(ratFactoryAddr));
		_burn(_from, _amount);
	}

}