//SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract Ownable is Context {

    address private _owner;
    address private _previousOwner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    // function renounceOwnership() public virtual onlyOwner {
    //     emit OwnershipTransferred(_owner, address(0));
    //     _owner = address(0);
    // }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

}

contract BestCityCanada is ERC20, Ownable{

    bool public PAUSED; // Temporarily Pause Voting
    bool public UNI_VOTING; // One Person One Vote Only ?
    uint private MINIMUM_TOKEN_REQUIRED = 1*10**decimals(); // Price per Vote

    uint32 private Voting_Start_Time;
    uint32 private time_limit = uint32(2 days); // 2 days

    constructor() ERC20("VoteMyCity", "VMC"){
        _mint(msg.sender, 1000*10**decimals());
        Voting_Start_Time = uint32(block.timestamp);
    }

    enum BestCity {
        Toronto,
        Calgary,
        Quebec,
        Vancouver,
        Ottawa
    }

    // Modifiers
    modifier VotingOpen() {
        require(uint32(block.timestamp) < Voting_Start_Time+time_limit, "Voting Closed");
        require(!PAUSED, "Voting Paused");
        _;
    }

    modifier LegalVoter() {
        require(balanceOf(msg.sender) >= MINIMUM_TOKEN_REQUIRED, "Insufficient Token Bal");
        require(!UNI_VOTING || !hasVoted[msg.sender], "Voted already");
        _;
    }

    // Mappings
    mapping(BestCity => uint) public voteCount;
    mapping(address => bool) public hasVoted;

    // Events
    event VoteCasted(address voter, BestCity city);
    event VotingPaused(string);
    event VotingResumed(string);

    // Pause Voting Indefinitely
    function pauseVoting() onlyOwner external returns(bool){
        require(!PAUSED, "Voting already Paused");
        PAUSED = !PAUSED;
        emit VotingPaused("Voting Paused");
        return PAUSED;
    }

    // Resume Voting Immediately
    function resumeVoting() onlyOwner external returns(bool){
        require(PAUSED, "Voting not Paused");
        PAUSED = !PAUSED;
        emit VotingResumed("Voting Resumed");
        return PAUSED;
    }

    // Appending multiple string
    function append(string memory a, string memory b) internal pure returns (string memory) {
        return string(abi.encodePacked(a, b));
    }

    // View total votes
    function TotalVotes() public view returns(string memory, string memory, string memory, string memory, string memory){
        string memory vc_t = append("Toronto: ", Strings.toString(voteCount[(BestCity.Toronto)]));
        string memory vc_c = append("Calgary: ", Strings.toString(voteCount[(BestCity.Calgary)]));
        string memory vc_q = append("Quebec:  ", Strings.toString(voteCount[(BestCity.Quebec)]));
        string memory vc_v = append("Vancouver:",Strings.toString(voteCount[(BestCity.Vancouver)]));
        string memory vc_o = append("Ottawa:  ", Strings.toString(voteCount[(BestCity.Ottawa)]));
        return (vc_t, vc_c, vc_q, vc_v, vc_o);
    }

    // Casting a vote
    function castVote(BestCity city) external VotingOpen LegalVoter returns(bool){
        require(uint(city)<5, "Invalid choice");
        transfer(address(this), MINIMUM_TOKEN_REQUIRED);
        voteCount[city]++;
        if(!hasVoted[msg.sender]){
            hasVoted[msg.sender]=true;
        }
        emit VoteCasted(msg.sender, city);
        return true;
    }

    // transfer tokens or ETH from contract to owner
    function safeTransfer() external onlyOwner {
        transferFrom(address(this), owner(), balanceOf(address(this)));
        if(address(this).balance>0){
            payable(msg.sender).transfer(address(this).balance);
        }
    }

}
