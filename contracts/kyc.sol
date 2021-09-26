pragma solidity ^0.5.9;

contract KYC{

    uint bankCount;
    address admin;

    struct Customer {
        string userName;    
        address bank;
        string customerData;
        bool kycStatus;
        uint downVotes;
        uint upVotes;
    }
    
    struct Bank {
        string name;
        address ethAddress;
        string regNumber;
        uint complaintsRecoreded;
        uint kycCount;
        bool isAllowedToVote;
    }

    struct KycRequest {
        string userName;
        address bankAddress;
        string customerData;
    }

    mapping(string => KycRequest) kycRequestList;

    mapping(string => Customer) customers;

    mapping(address => Bank) banks;
    
    mapping(address => string[]) customerVotes;
    
    mapping(address => string[]) bankComplaints;

    constructor() public {
        bankCount = 0;
        admin = msg.sender;
    }

    //Banking Functions
    
    function addCustomer(string memory _userName, string memory _customerData) isBank() public {
        require(customers[_userName].bank == address(0), "Customer is already present, please call modifyCustomer to edit the customer data");
        customers[_userName].userName = _userName;
        customers[_userName].customerData = _customerData;
        customers[_userName].bank = msg.sender;
    }
    
    function viewCustomer(string memory _userName) isBank() public view returns (string memory, string memory, address, bool, uint, uint)  {
        require(customers[_userName].bank != address(0), "Customer is not present in the database");
        return (customers[_userName].userName, 
                customers[_userName].customerData, 
                customers[_userName].bank,
                customers[_userName].kycStatus,
                customers[_userName].upVotes,
                customers[_userName].downVotes);
    }
    
    function modifyCustomer(string memory _userName, string memory _newcustomerData) isBank() public {
        require(customers[_userName].bank != address(0), "Customer is not present in the database");
        customers[_userName].customerData = _newcustomerData;
        customers[_userName].upVotes = 0;
        customers[_userName].downVotes = 0;
        delete kycRequestList[_userName];
    }

    function addRequest(string memory _userName, string memory _customerData) isBank() public{
        require(customers[_userName].bank != address(0), "Customer is not present in the database");
        require(kycRequestList[_userName].bankAddress == address(0), "KYC Request for this customer is already present!");
        kycRequestList[_userName].userName = _userName;
        kycRequestList[_userName].customerData = _customerData;
        kycRequestList[_userName].bankAddress = msg.sender;
        banks[msg.sender].kycCount +=1;

    }

    function removeRequest(string memory _userName) isBank() public{
        require(kycRequestList[_userName].bankAddress != address(0), "KYC Request for this customer is not present!");
        banks[kycRequestList[_userName].bankAddress].kycCount -= 1;
        delete kycRequestList[_userName];
        
    }
      
    function upvoteCustomer(string memory _userName) isBank() hasAlreadyVoted(_userName) isAllowedToVote() public{
        customerVotes[msg.sender].push(customers[_userName].userName);
        customers[_userName].upVotes += 1;
        changeKycStatus(_userName);
    }  

    function downvoteCustomer(string memory _userName) isBank() hasAlreadyVoted(_userName) isAllowedToVote() public{
        customerVotes[msg.sender].push(customers[_userName].userName);
        customers[_userName].downVotes -= 1;
        changeKycStatus(_userName);
    }  
    
    function changeKycStatus(string memory _userName) internal{
        if (customers[_userName].upVotes > customers[_userName].downVotes) {
            customers[_userName].kycStatus = true;
        }
        if (customers[_userName].downVotes > (bankCount/3)) {
            customers[_userName].kycStatus = false;
        }
    }

    function getBankComplaints(address _bankAddress) isBank() public view returns (uint) {
        return banks[_bankAddress].complaintsRecoreded;
    }  

    function viewBankDetails(address _bankAddress) isBank() public view returns (string memory, address, string memory, uint, uint, bool) {
        require(banks[_bankAddress].ethAddress != address(0), "Invalid address! Bank does not exist. ");
        return (banks[_bankAddress].name,
                banks[_bankAddress].ethAddress,
                banks[_bankAddress].regNumber,
                banks[_bankAddress].complaintsRecoreded,
                banks[_bankAddress].kycCount,
                banks[_bankAddress].isAllowedToVote);
    }  

    function reportBank(string memory _bankName, address _bankAddress) isBank() hasAlreadyReportedBank(_bankName) public{
        bankComplaints[msg.sender].push(_bankName);
        banks[_bankAddress].complaintsRecoreded += 1; 
        if (banks[_bankAddress].complaintsRecoreded > (bankCount/3)) {
            banks[_bankAddress].isAllowedToVote = false;
        }
    }

    //Admin Functions

    function addBank(string memory _bankName, address _bankAddress, string memory _regNumber) isAdmin() public{
        require(banks[_bankAddress].ethAddress == address(0), "Bank with this address is already present");
        banks[_bankAddress].name = _bankName;
        banks[_bankAddress].ethAddress = _bankAddress;
        banks[_bankAddress].regNumber = _regNumber;
        banks[_bankAddress].complaintsRecoreded = 0;
        banks[_bankAddress].kycCount = 0;
        banks[_bankAddress].isAllowedToVote = true;
        bankCount += 1;
    }

    function removeBank(address _bankAddress) isAdmin() public{
        delete banks[_bankAddress];
        bankCount -= 1;
    }

    function modifyIsAllowedToVote(address _bankAddress, bool updatedValue) isAdmin() public{
        require(banks[_bankAddress].ethAddress != address(0), "Bank with this Name is not present");
        require(updatedValue == true || updatedValue == false , "Invalid Input");
        banks[_bankAddress].isAllowedToVote = updatedValue;
    }

    modifier isAdmin {
        require(msg.sender == admin, "Only Admins can trigger this function!");
        _;
    }

    modifier isBank {
        require(banks[msg.sender].ethAddress != address(0), "Only Banks can trigger this function!");
        _;
    }

    modifier hasAlreadyVoted (string memory _userName) {
        string[] memory voted = customerVotes[msg.sender];
        for (uint i=0; i < voted.length; i++){
            if (keccak256(bytes(voted[i])) == keccak256(bytes(_userName))){
               revert("Your bank has already voted for this customer"); 
            }
        }
        _;
    }    

    modifier isAllowedToVote {
        require(banks[msg.sender].isAllowedToVote == true, "Your bank is not allowed to vote!");
        _;
    }
    
    modifier hasAlreadyReportedBank (string memory _bankName) {
        string[] memory complaints = bankComplaints[msg.sender];
        for (uint i=0; i < complaints.length; i++){
            if (keccak256(bytes(complaints[i])) == keccak256(bytes(_bankName))){
               revert("You have already reported this bank"); 
            }
        }
        _;
    }

}    


