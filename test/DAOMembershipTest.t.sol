// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {DAOMembership} from "../src/DAOMembership.sol";

contract DAOMembershipTest is Test {
    DAOMembership public daoMembership;

    address owner = makeAddr("owner");
    address alice = makeAddr("alice");
    address bob = makeAddr("bob");

    function setUp() public {
        vm.prank(owner);
        daoMembership = new DAOMembership();
    }

    function testConfirmOwnerMember() public {
        bool membership = daoMembership.isMember_(owner);
        assertEq(membership, true);
    }

    function testapplyForEntry() public {
        vm.startPrank(alice);
        daoMembership.applyForEntry();
        (uint256 nonce, bool applied, , , ) = daoMembership.userApplication_(
            alice
        );

        assertEq(applied, true);
        assertEq(nonce, 1);
        assertEq(daoMembership.totalApplicant(), 1);

        vm.expectRevert("user already applied");
        daoMembership.applyForEntry();
    }

    function testapproveEntry() public {
        vm.startPrank(alice);
        daoMembership.applyForEntry();
        vm.stopPrank();
        vm.startPrank(owner);
        daoMembership.approveEntry(alice);
        assertEq(daoMembership.isMember_(alice), true);
        assertEq(daoMembership.totalMembers(), 2);
    }

    function testVoteToRemoveMember() public {
        vm.startPrank(owner);
        daoMembership.VoteToRemoveMember(alice);
        uint256 RemovalCount = daoMembership.MembershipStatus_(alice);
        assertEq(RemovalCount, 1);
    }

    function testleave() public {
        vm.startPrank(alice);
        daoMembership.applyForEntry();
        vm.stopPrank();
        vm.startPrank(owner);
        daoMembership.approveEntry(alice);
        vm.startPrank(alice);
        daoMembership.leave();
        assertEq(daoMembership.isMember_(alice), false);
        assertEq(daoMembership.isAlumini_(alice), true);
        vm.startPrank(owner);
        assertEq(daoMembership.totalMembers(), 1);
    }

    // function testhasMetRemovalThreshold() public {
    //     bool remove = daoMembership.hasMetRemovalThreshold(alice);
    //     console2.log(remove);
    // }
}
