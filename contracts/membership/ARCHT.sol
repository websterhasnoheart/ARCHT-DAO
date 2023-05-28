// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ARCHT is ERC721URIStorage, Ownable {
    using Address for address payable;
    using Counters for Counters.Counter;

    Counters.Counter public _totalSupply;

    address payable[] public _members;

    uint public tokenId = 0;

    string public baseURI = "";

    struct Application {
        string name;
        address walletAddress;
        string portfolioUrl;
        address[] judges;
        uint confirmationCount;
        mapping(address => bool) confirmations;
    }

    struct Evaluation {
        address requestor;
        address[] evaluators;
        mapping(address => bool) confirmations;
        uint confirmationCount;
    }

    struct RemovalRequest {
        address target;
        uint confirmationCount;
        mapping(address => bool) confirmations;
    }

    mapping(address => string) public _membersInfo;
    mapping(address => uint) public memberToTokenId;
    mapping(address => uint) public ratings;
    mapping(address => Application) public applications;
    mapping(uint => RemovalRequest) public removalRequests;
    mapping(uint => Evaluation) public evaluations;
    uint public evaluationId = 0;
    uint public removalRequestId = 0;

    //Constructor
    constructor(
        address payable member1,
        address payable member2,
        address payable member3
    ) ERC721("ARCHT", "ARCH") {
        require(
            member1 != address(0) &&
                member2 != address(0) &&
                member3 != address(0),
            "Invalid addresses"
        );

        // Add members and mint NFTs
        _members.push(member1);
        tokenId++;
        _mint(member1, tokenId);
        memberToTokenId[member1] = tokenId;

        _members.push(member2);
        tokenId++;
        _mint(member2, tokenId);
        memberToTokenId[member2] = tokenId;

        _members.push(member3);
        tokenId++;
        _mint(member3, tokenId);
        memberToTokenId[member3] = tokenId;
    }

    function genRandomNum() private view returns (uint) {
        // Pseudorandom number generation
        return
            uint(
                keccak256(abi.encodePacked(block.prevrandao, block.timestamp))
            );
    }

    function applyToJoin(
        string memory name,
        address walletAddress,
        string memory portfolioUrl
    ) public payable {
        require(_members.length >= 3, "No enough addresses");
        require(
            address(this).balance >= msg.value,
            "No enough Ether in contract"
        );

        Application storage application = applications[msg.sender];
        application.name = name;
        application.walletAddress = walletAddress;
        application.portfolioUrl = portfolioUrl;

        address payable[] memory tempAddresses = _members;
        for (uint i = 0; i < 3; i++) {
            uint index = genRandomNum() % tempAddresses.length;

            // Send Ether to the member
            tempAddresses[index].sendValue(msg.value / 3);

            // Assign the member to confirm the application
            applications[msg.sender].confirmations[
                tempAddresses[index]
            ] = false;

            // Add the address to the evaluators array
            application.judges.push(tempAddresses[index]);

            // Remove the member from the temporary array
            tempAddresses[index] = tempAddresses[tempAddresses.length - 1];
            assembly {
                mstore(tempAddresses, sub(mload(tempAddresses), 1))
            }
        }
    }

    function confirmApplication(address applicant) public {
        require(
            applications[applicant].confirmations[msg.sender] == false,
            "Already confirmed"
        );

        // Confirm the application
        applications[applicant].confirmations[msg.sender] = true;
        applications[applicant].confirmationCount++;
    }

    function rejectApplication(address applicant) public {
        require(
            applications[applicant].confirmations[msg.sender] == false,
            "Already confirmed/rejected"
        );

        // Reject the application and remove it from the applications mapping
        delete applications[applicant];
    }

    function getApplicationEvaluators(
        address applicant
    ) public view returns (address[] memory) {
        return applications[applicant].judges;
    }

    function getPendingApplications(
        address evaluator
    ) public view returns (address[] memory) {
        address[] memory pendingApplications;

        // Iterate over all applications
        for (uint i = 0; i < _members.length; i++) {
            address applicant = _members[i];
            Application storage application = applications[applicant];

            // Check if evaluator is in the list and hasn't confirmed the application yet
            for (uint j = 0; j < application.judges.length; j++) {
                if (
                    application.judges[j] == evaluator &&
                    application.confirmations[evaluator] == false
                ) {
                    // Add applicant to the pendingApplications array
                    pendingApplications = appendAddress(
                        pendingApplications,
                        applicant
                    );
                    break;
                }
            }
        }

        return pendingApplications;
    }

    // Helper function to append to an address array
    function appendAddress(
        address[] memory arr,
        address addr
    ) private pure returns (address[] memory) {
        address[] memory newArray = new address[](arr.length + 1);
        for (uint i = 0; i < arr.length; i++) {
            newArray[i] = arr[i];
        }
        newArray[arr.length] = addr;
        return newArray;
    }

    function joinDAO() public {
        require(
            applications[msg.sender].confirmationCount >= 3,
            "Application not approved yet"
        );

        _members.push(payable(msg.sender));
        tokenId++;
        _mint(msg.sender, tokenId);
        _totalSupply.increment();
        memberToTokenId[msg.sender] = tokenId;
        delete applications[msg.sender];
    }

    function requestToRemove(address target) public {
        require(_members.length >= 3, "No enough addresses");

        // Increase removalRequestId
        removalRequestId++;

        address payable[] memory tempAddresses = _members;
        for (uint i = 0; i < 3; i++) {
            uint index = genRandomNum() % tempAddresses.length;

            // Assign the member to confirm the removal request
            removalRequests[removalRequestId].confirmations[
                tempAddresses[index]
            ] = false;

            // Remove the member from the temporary array
            tempAddresses[index] = tempAddresses[tempAddresses.length - 1];
            assembly {
                mstore(tempAddresses, sub(mload(tempAddresses), 1))
            }
        }

        removalRequests[removalRequestId].target = target;
    }

    function confirmRemoval(uint requestId) public {
        require(requestId <= removalRequestId, "Invalid request id");
        RemovalRequest storage request = removalRequests[requestId];
        require(
            request.confirmations[msg.sender] == false,
            "Already confirmed"
        );

        // Confirm the removal
        request.confirmations[msg.sender] = true;
        request.confirmationCount++;

        if (request.confirmationCount >= 3) {
            // If 3 or more members confirmed the removal, remove the member
            for (uint i = 0; i < _members.length; i++) {
                if (_members[i] == request.target) {
                    _members[i] = _members[_members.length - 1];
                    _members.pop();
                    break;
                }
            }

            // Burn the NFT associated with the removed member
            _burn(memberToTokenId[request.target]);
            _totalSupply.decrement();
            delete memberToTokenId[request.target];
        }
    }

    function applyForEvaluation(address[] memory evaluators) public {
        require(evaluators.length <= 3, "Too many evaluators");

        // Increase evaluationId
        evaluationId++;

        // Store evaluation request
        Evaluation storage evaluation = evaluations[evaluationId];
        evaluation.requestor = msg.sender;
        evaluation.evaluators = evaluators;
    }

    function confirmEvaluation(uint _evaluationId) public {
        require(_evaluationId <= evaluationId, "Invalid evaluation id");
        Evaluation storage evaluation = evaluations[_evaluationId];
        bool isEvaluator = false;

        for (uint i = 0; i < evaluation.evaluators.length; i++) {
            if (evaluation.evaluators[i] == msg.sender) {
                isEvaluator = true;
                break;
            }
        }

        require(isEvaluator, "Not an evaluator");
        require(
            evaluation.confirmations[msg.sender] == false,
            "Already confirmed"
        );

        // Confirm the evaluation
        evaluation.confirmations[msg.sender] = true;
        evaluation.confirmationCount++;

        // Increase rating for evaluator
        ratings[msg.sender]++;
    }

    function renounceOwnership() public override onlyOwner {
        // Make sure there are enough members to continue running the DAO
        require(
            _members.length >= 3,
            "Must have at least 3 members to renounce ownership"
        );

        super.renounceOwnership();
    }
}
