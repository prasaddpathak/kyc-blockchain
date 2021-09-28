pragma solidity ^0.5.9;

contract KYC{

    uint bankCount; //varibale to count number of banks
    address admin; //variable to store the addrres of the admin

    // Structure to store customer information
    struct Customer {
        string userName;    
        address bank;
        string customerData;
        bool kycStatus;
        uint downVotes;
        uint upVotes;
    }
    
    // Structure to store bank information
    struct Bank {
        string name;
        address ethAddress;
        string regNumber;
        uint complaintsRecoreded;
        uint kycCount;
        bool isAllowedToVote;
    }

    // Structure to store KYC Request information
    struct KycRequest {
        string userName;
        address bankAddress;
        string customerData;
    }

    //Mapping to store KYC Requests (User Name => Struct KYC)
    mapping(string => KycRequest) kycRequestList;
    //Mapping to store Customers (User Name => Struct Customer)
    mapping(string => Customer) customers;
    //Mapping to store Banks (Eth Address => Struct Bank)
    mapping(address => Bank) banks;
    //Mapping to store upvotes/downvotes given by the bank to the customers (Bank Eth Address => CustomerNames[])
    mapping(address => string[]) customerVotes;
    //Mapping to store complaints raised by the bank for other banks (Bank Eth Address => BankNames[])
    mapping(address => string[]) bankComplaints;

    //Constructor which sets the count of banks to zero and the admin as the contract deployer
    constructor() public {
        bankCount = 0;
        admin = msg.sender;
    }

    /*****************************************************
    Banking Function :  addCustomer()
    Description : Adds a new customer
    Modifier : isBank() 
    Input : String, String
    Returns : NULL
    *****************************************************/
    function addCustomer(string memory _userName, string memory _customerData) isBank() public {
        require(customers[_userName].bank == address(0), "Customer is already present, please call modifyCustomer to edit the customer data");
        customers[_userName].userName = _userName;
        customers[_userName].customerData = _customerData;
        customers[_userName].bank = msg.sender;
    }
    
    /*****************************************************
    Banking Function :  viewCustomer()
    Description : Returns customer details
    Modifier : isBank() 
    Input : String
    Returns : string, string, address, bool, uint, uint
    *****************************************************/
    function viewCustomer(string memory _userName) isBank() public view returns (string memory, string memory, address, bool, uint, uint)  {
        require(customers[_userName].bank != address(0), "Customer is not present in the database");
        return (customers[_userName].userName, 
                customers[_userName].customerData, 
                customers[_userName].bank,
                customers[_userName].kycStatus,
                customers[_userName].upVotes,
                customers[_userName].downVotes);
    }
    
    /*****************************************************
    Banking Function :  modifyCustomer()
    Description : Modifies customer data
    Modifier : isBank() 
    Input : String, String
    Returns : NULL
    *****************************************************/
    function modifyCustomer(string memory _userName, string memory _newcustomerData) isBank() public {
        require(customers[_userName].bank != address(0), "Customer is not present in the database");
        customers[_userName].customerData = _newcustomerData;
        customers[_userName].upVotes = 0;
        customers[_userName].downVotes = 0;
        delete kycRequestList[_userName];
    }

    /*****************************************************
    Banking Function :  addRequest()
    Description : Adds a KYC Request for the customer
    Modifier : isBank() 
    Input : String, String
    Returns : NULL
    *****************************************************/
    function addRequest(string memory _userName, string memory _customerData) isBank() public{
        require(customers[_userName].bank != address(0), "Customer is not present in the database");
        require(kycRequestList[_userName].bankAddress == address(0), "KYC Request for this customer is already present!");
        kycRequestList[_userName].userName = _userName;
        kycRequestList[_userName].customerData = _customerData;
        kycRequestList[_userName].bankAddress = msg.sender;
        banks[msg.sender].kycCount +=1;

    }

    /*****************************************************
    Banking Function :  removeRequest()
    Description : Removes KYC Request for the customer
    Modifier : isBank() 
    Input : String
    Returns : NULL
    *****************************************************/
    function removeRequest(string memory _userName) isBank() public{
        require(kycRequestList[_userName].bankAddress != address(0), "KYC Request for this customer is not present!");
        banks[kycRequestList[_userName].bankAddress].kycCount -= 1;
        delete kycRequestList[_userName];
        
    }
      
    /*****************************************************
    Banking Function :  upvoteCustomer()
    Description : Increases the upvote count of the customer by 1
    Modifier : isBank(), hasAlreadyVoted(), isAllowedToVote()
    Input : String
    Returns : NA
    *****************************************************/
    function upvoteCustomer(string memory _userName) isBank() hasAlreadyVoted(_userName) isAllowedToVote() public{
        customerVotes[msg.sender].push(customers[_userName].userName);
        customers[_userName].upVotes += 1;
        changeKycStatus(_userName);
    }  

    /*****************************************************
    Banking Function :  downvoteCustomer()
    Description : Increases the downvote count of the customer by 1
    Modifier : isBank(), hasAlreadyVoted(), isAllowedToVote()
    Input : String
    Returns : NA
    *****************************************************/
    function downvoteCustomer(string memory _userName) isBank() hasAlreadyVoted(_userName) isAllowedToVote() public{
        customerVotes[msg.sender].push(customers[_userName].userName);
        customers[_userName].downVotes -= 1;
        changeKycStatus(_userName);
    }  
    
    /*****************************************************
    Internal Function :  changeKycStatus()
    Description : Updates the KYC Status of the customer as per the business rules
    Modifier : NA
    Input : String
    Returns : NA
    *****************************************************/
    function changeKycStatus(string memory _userName) internal{
        if (customers[_userName].upVotes > customers[_userName].downVotes) {
            customers[_userName].kycStatus = true;
        }
        if (customers[_userName].downVotes > (bankCount/3)) {
            customers[_userName].kycStatus = false;
        }
    }

    /*****************************************************
    Bank Function :  getBankComplaints()
    Description : Returns the number of complaints for a given bank
    Modifier : isBank()
    Input : address
    Returns : uint
    *****************************************************/
    function getBankComplaints(address _bankAddress) isBank() public view returns (uint) {
        require(banks[_bankAddress].ethAddress != address(0), "Invalid address! Bank does not exist. ");
        return banks[_bankAddress].complaintsRecoreded;
    }  

    /*****************************************************
    Bank Function :  viewBankDetails()
    Description : Returns the details for a given bank
    Modifier : isBank()
    Input : address
    Returns : string, address, string, uint, uint, bool
    *****************************************************/
    function viewBankDetails(address _bankAddress) isBank() public view returns (string memory, address, string memory, uint, uint, bool) {
        require(banks[_bankAddress].ethAddress != address(0), "Invalid address! Bank does not exist. ");
        return (banks[_bankAddress].name,
                banks[_bankAddress].ethAddress,
                banks[_bankAddress].regNumber,
                banks[_bankAddress].complaintsRecoreded,
                banks[_bankAddress].kycCount,
                banks[_bankAddress].isAllowedToVote);
    }  

    /*****************************************************
    Bank Function :  reportBank()
    Description : Increases the complaintsRecorded for a bank by 1
    Modifier : isBank(), hasAlreadyReportedBank()
    Input : string, address
    Returns : NA
    *****************************************************/
    function reportBank(string memory _bankName, address _bankAddress) isBank() hasAlreadyReportedBank(_bankName) public{
        bankComplaints[msg.sender].push(_bankName);
        banks[_bankAddress].complaintsRecoreded += 1; 
        if (banks[_bankAddress].complaintsRecoreded > (bankCount/3)) {
            banks[_bankAddress].isAllowedToVote = false;
        }
    }

    /*****************************************************
    Admin Function :  addBank()
    Description : Adds a new bank in the system
    Modifier : isAdmin()
    Input : string, address, string
    Returns : NA
    *****************************************************/
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

    /*****************************************************
    Admin Function :  removeBank()
    Description : Removes the bank from the system
    Modifier : isAdmin()
    Input : string, address, string
    Returns : NA
    *****************************************************/
    function removeBank(address _bankAddress) isAdmin() public{
        require(banks[_bankAddress].ethAddress != address(0), "Invalid address! Bank does not exist. ");
        delete banks[_bankAddress];
        bankCount -= 1;
    }

    /*****************************************************
    Admin Function :  modifyIsAllowedToVote()
    Description : Updates the isAllowedToVote flag of the bank
    Modifier : isAdmin()
    Input : address, bool
    Returns : NA
    *****************************************************/
    function modifyIsAllowedToVote(address _bankAddress, bool updatedValue) isAdmin() public{
        require(banks[_bankAddress].ethAddress != address(0), "Bank with this Name is not present");
        require(updatedValue == true || updatedValue == false , "Invalid Input");
        banks[_bankAddress].isAllowedToVote = updatedValue;
    }

    /*****************************************************
    Modifier :  isAdmin()
    Description : Checks if the caller address is Admin
    Input : NA
    Returns : NA
    *****************************************************/
    modifier isAdmin {
        require(msg.sender == admin, "Only Admins can trigger this function!");
        _;
    }

    /*****************************************************
    Modifier :  isBank()
    Description : Checks if the caller address is a Bank
    Input : NA
    Returns : NA
    *****************************************************/
    modifier isBank {
        require(banks[msg.sender].ethAddress != address(0), "Only Banks can trigger this function!");
        _;
    }

    /*****************************************************
    Modifier :  hasAlreadyVoted()
    Description : Checks if the address has already voted for a customer
    Input : string
    Returns : NA
    *****************************************************/
    modifier hasAlreadyVoted (string memory _userName) {
        string[] memory voted = customerVotes[msg.sender];
        for (uint i=0; i < voted.length; i++){
            if (keccak256(bytes(voted[i])) == keccak256(bytes(_userName))){
               revert("Your bank has already voted for this customer"); 
            }
        }
        _;
    }    

    /*****************************************************
    Modifier :  isAllowedToVote()
    Description : Checks if the address is allowed to vote
    Input : NA
    Returns : NA
    *****************************************************/
    modifier isAllowedToVote {
        require(banks[msg.sender].isAllowedToVote == true, "Your bank is not allowed to vote!");
        _;
    }
    
    /*****************************************************
    Modifier :  hasAlreadyReportedBank()
    Description : Checks if the address has already reported the Bank
    Input : string
    Returns : NA
    *****************************************************/
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


