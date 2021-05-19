pragma solidity ^0.6.0;

//SPDX-License-Identifier: MIT
contract Ownable {
    address payable _owner;

    constructor() public {
        _owner = msg.sender;
    }

    modifier onlyOwner() {
        require(isOWner(), "You are not the owner ");
        _;
    }

    function isOWner() public view returns (bool) {
        return (msg.sender == _owner);
    }
}

contract Item {
    uint256 public PriceInWei;

    uint256 public index;

    uint256 public pricePaid;

    ItemManager parentContract;

    constructor(
        ItemManager _parentContract,
        uint256 _PriceInWei,
        uint256 _index
    ) public {
        PriceInWei = _PriceInWei;
        index = _index;
        parentContract = _parentContract;
    }

    receive() external payable {
        require(pricePaid == 0, "Item is paid already ");
        require(PriceInWei == msg.value, "Only full payments allowed ");
        pricePaid += msg.value;
        //address(parentContract).transfer(msg.value);
        (bool success, ) =
            address(parentContract).call.value(msg.value)(
                abi.encodeWithSignature("triggerPayment(uint256)", index)
            );
        require(success, "the transaction wasn't successful,cancelling");
    }

    fallback() external {}
}

contract ItemManager is Ownable {
    enum Supplychain {Created, Paid, Delivered}

    struct S_item {
        Item _item;
        string _identifier;
        uint256 _itemPrice;
        ItemManager.Supplychain _state;
    }
    mapping(uint256 => S_item) public items;
    uint256 itemIndex;
    event SupplyChainStep(
        uint256 _itemIndex,
        uint256 _step,
        address _itemAddress
    );

    function createItem(string memory _identifier, uint256 _itemPrice)
        public
        onlyOwner
    {
        Item item = new Item(this, _itemPrice, itemIndex);
        items[itemIndex]._item = item;
        items[itemIndex]._identifier = _identifier;
        items[itemIndex]._itemPrice = _itemPrice;
        items[itemIndex]._state = Supplychain.Created;
        emit SupplyChainStep(
            itemIndex,
            uint256(items[itemIndex]._state),
            address(item)
        );
        itemIndex++;
    }

    function triggerPayment(uint256 _itemIndex) public payable {
        require(
            items[_itemIndex]._itemPrice == msg.value,
            "Only full payments accepted"
        );
        require(
            items[_itemIndex]._state == Supplychain.Created,
            "Item is further in the chain"
        );
        items[_itemIndex]._state = Supplychain.Paid;

        emit SupplyChainStep(
            _itemIndex,
            uint256(items[_itemIndex]._state),
            address(items[_itemIndex]._item)
        );
    }

    function triggerDelivery(uint256 _itemIndex) public {
        require(
            items[_itemIndex]._state == Supplychain.Paid,
            "item is further in the chain "
        );
        items[_itemIndex]._state = Supplychain.Delivered;

        emit SupplyChainStep(
            _itemIndex,
            uint256(items[_itemIndex]._state),
            address(items[_itemIndex]._item)
        );
    }
}
