// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import {RaffleFactoryMock} from "test/mocks/RaffleFactoryMock.sol";
import {RaffleMock} from "test/mocks/RaffleMock.sol";
import {VRFConsumerBaseV2Mock} from "test/mocks/VRFConsumerBaseV2Mock.sol";

import "test/helpers/IntegrationTest.sol";

contract RandomProviderTest is IntegrationTest {
    RandomProvider internal randomProvider;
    RaffleFactoryMock internal factoryMock;
    RaffleMock internal raffleMock;
    VRFConsumerBaseV2Mock internal vrfConsumer;

    function setUp() public override {
        super.setUp();

        changePrank(deployer);
        factoryMock = new RaffleFactoryMock();
        raffleMock = new RaffleMock();

        factoryMock.addClooverRaffleToRegister(address(raffleMock));

        vrfConsumer = new VRFConsumerBaseV2Mock();

        randomProvider = new RandomProvider(address(implementationManager), RandomProviderTypes.ChainlinkVRFData({
            vrfCoordinator:address(vrfConsumer),
            keyHash: 0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c,
            callbackGasLimit: 100000,
            requestConfirmations: 5,
            subscriptionId: 123456789
        }));

        changePrank(maintainer);
        implementationManager.changeImplementationAddress(
            ImplementationInterfaceNames.ClooverRaffleFactory, address(factoryMock)
        );
        implementationManager.changeImplementationAddress(
            ImplementationInterfaceNames.RandomProvider, address(randomProvider)
        );
    }

    function test_Initialized() external {
        assertEq(address(randomProvider.COORDINATOR()), address(vrfConsumer));
        assertEq(randomProvider.implementationManager(), address(implementationManager));
        assertEq(randomProvider.clooverRaffleFactory(), address(factoryMock));
        RandomProviderTypes.ChainlinkVRFData memory data = randomProvider.chainlinkVRFData();
        assertEq(data.vrfCoordinator, address(vrfConsumer));
        assertEq(data.keyHash, 0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c);
        assertEq(data.callbackGasLimit, 100000);
        assertEq(data.requestConfirmations, 5);
        assertEq(data.subscriptionId, 123456789);
    }

    function test_RequestRandomNumbers() external {
        raffleMock.requestRandomNumbers(address(randomProvider), 1);
        uint256 requestId = raffleMock.requestId();
        assertEq(randomProvider.requestorAddressFromRequestId(requestId), address(raffleMock));
        assertEq(vrfConsumer.requestIdToNumWords(requestId), 1);
    }

    function test_RequestRandomNumbers_RevertWhen_NotRegisteredRaffle() external {
        RaffleMock raffleMock2 = new RaffleMock();
        vm.expectRevert(Errors.NOT_REGISTERED_RAFFLE.selector);
        raffleMock2.requestRandomNumbers(address(randomProvider), 1);
    }

    function test_FulFillRandomWords() external {
        raffleMock.requestRandomNumbers(address(randomProvider), 1);

        assertEq(raffleMock.randomNumbersLenght(), 0);
        vrfConsumer.callingRawFulFillRandomWorks(address(randomProvider));

        assertGt(raffleMock.randomNumbers(0), 0);
        assertEq(raffleMock.randomNumbersLenght(), 1);
    }
}
