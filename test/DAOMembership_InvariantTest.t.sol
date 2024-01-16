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

    function invariant_owner_is_Always_a_member() public {
        bool ownerMembership = daoMembership.isMember_(owner);
        assertEq(ownerMembership, true);
    }

    function test_NonMemberCannotVote() public {
        vm.startPrank(bob);
        vm.expectRevert();
        daoMembership.VoteToRemoveMember(alice);
    }

    function testFuzz_approveEntry(address member) public {
        vm.startPrank(member);
        daoMembership.applyForEntry();
        vm.stopPrank();
        vm.startPrank(owner);
        daoMembership.approveEntry(member);
        assertEq(daoMembership.isMember_(member), true);
        assertEq(daoMembership.totalMembers(), 2);
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

    function testVoteToRemoveMember() public {
        vm.startPrank(owner);
        daoMembership.VoteToRemoveMember(alice);
        uint256 RemovalCount = daoMembership.MembershipStatus_(alice);
        assertEq(RemovalCount, 1);
    }

    function testFuzz_leave(address memberToleave) public {
        vm.startPrank(memberToleave);
        daoMembership.applyForEntry();
        vm.stopPrank();
        vm.startPrank(owner);
        daoMembership.approveEntry(memberToleave);
        vm.startPrank(memberToleave);
        daoMembership.leave();
        assertEq(daoMembership.isMember_(memberToleave), false);
        assertEq(daoMembership.isAlumini_(memberToleave), true);
        vm.startPrank(owner);
        assertEq(daoMembership.totalMembers(), 1);
    }
}
