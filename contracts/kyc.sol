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

    mapping(string => Customer) customers;

    mapping(address => Bank) banks;

    constructor() {
        bankCount =0;
        admin = msg.sender;
    }

    //Banking Functions
    
    function addCustomer(string memory _userName, string memory _customerData) public {
        require(customers[_userName].bank == address(0), "Customer is already present, please call modifyCustomer to edit the customer data");
        customers[_userName].userName = _userName;
        customers[_userName].data = _customerData;
        customers[_userName].bank = msg.sender;
    }
    
    function viewCustomer(string memory _userName) public view returns (string memory, string memory, address) {
        require(customers[_userName].bank != address(0), "Customer is not present in the database");
        return (customers[_userName].userName, customers[_userName].data, customers[_userName].bank);
    }
    
    function modifyCustomer(string memory _userName, string memory _newcustomerData) public {
        require(customers[_userName].bank != address(0), "Customer is not present in the database");
        customers[_userName].data = _newcustomerData;
    }

    function addRequest(string memory _userName, string memory _customerData) isBank() public{

    }

    function removeRequest(string memory _userName) isBank() public{
        
    }
      
    function upvoteCustomer(string memory _userName) isBank() public{
        
    }  

    function downvoteCustomer(string memory _userName) isBank() public{
        
    }  

    function getBankComplaints(address _bankAddress) isBank() public{
        
    }  

    function viewBankDetails(address _bankAddress) isBank() public{
        
    }  

    function reportBank(string memory _bankName, address _bankAddress) isBank() public{
        
    }

    //Admin Functions

    function addBank(string memory _bankName) isAdmin() public{
        
    }

    function removeBank(string memory _bankName) isAdmin() public{
        
    }

    function modifyIsAllowedToVote(string memory _bankName) isAdmin() public{
        
    }




    modifier isAdmin {
        require(msg.sender == admin, "Only Admins can trigger this function!");
        _;
    }

    modifier isBank {
        require(banks[msg.sender] != 0, "Only Banks can trigger this function!");
        _;
    }    

}    


