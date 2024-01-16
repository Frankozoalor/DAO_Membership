// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/utils/Pausable.sol";

contract DAOMembership is Pausable {
    struct Application {
        uint256 nonce;
        bool applied;
        uint256 approvalCount;
        uint256 disapprovalCount;
        bool approved;
    }

    struct MembershipStatus {
        uint256 RemovalCount;
    }

    uint256 public totalApplicant;
    uint256 private NoOfMembers;

    mapping(address user => bool member) public isMember_;
    mapping(address user => bool Alumini) public isAlumini_;
    mapping(address user => Application) public userApplication_;
    mapping(address member => bool voted) public voted_;
    mapping(address member => bool voted) public votedForMemberRemoval;
    mapping(address member => MembershipStatus) public MembershipStatus_;

    modifier _IsMember() {
        require(isMember_[msg.sender] == true, "caller is not a member");
        _;
    }

    constructor() {
        isMember_[msg.sender] = true;
        NoOfMembers++;
    }

    //To apply for membership of DAO
    function applyForEntry() external whenNotPaused {
        require(
            isMember_[msg.sender] == false && isAlumini_[msg.sender] == false,
            "user currently a member or Alumini"
        );
        require(
            userApplication_[msg.sender].nonce == 0,
            "user already applied"
        );
        Application storage application = userApplication_[msg.sender];
        application.nonce++;
        application.applied = true;
        totalApplicant++;
    }

    //To approve the applicant for membership of DAO
    function approveEntry(address _applicant) external whenNotPaused _IsMember {
        // require(approve == true, "approve cannot be false for entry");
        Application storage application = userApplication_[_applicant];
        require(application.applied == true, "user hasn't applied");
        require(!voted_[msg.sender], "user has voted");
        voted_[msg.sender] = true;
        application.approvalCount++;
        bool threshold = hasMetApprovalThreshold(_applicant);
        if (threshold) {
            application.approved = true;
            isMember_[_applicant] = true;
            NoOfMembers++;
        }
    }

    function hasMetApprovalThreshold(
        address applicant_
    ) internal view returns (bool) {
        uint256 noOfApplicant = totalApplicant;
        uint256 approvalThreshold = (noOfApplicant * 30) / 100; // 30% approval threshold
        return userApplication_[applicant_].approvalCount >= approvalThreshold;
    }

    function hasMetDisapprovalThreshold(
        address applicant_
    ) internal view returns (bool) {
        uint256 noOfApplicant = totalApplicant;
        uint256 approvalThreshold = (noOfApplicant * 70) / 100; // 70% approval threshold
        return
            userApplication_[applicant_].disapprovalCount >= approvalThreshold;
    }

    // function hasMetThreshold(
    //     address applicant_,
    //     bool approve
    // ) internal view returns (bool) {
    //     uint256 noOfApplicant = totalApplicant;
    //     uint256 thresholdPercentage = approve ? 30 : 70;
    //     uint256 Threshold = (noOfApplicant * thresholdPercentage) / 100; // 30% approval threshold
    //     if (approve) {
    //         return userApplication_[applicant_].approvalCount >= Threshold;
    //     } else {
    //         return userApplication_[applicant_].disapprovalCount >= Threshold;
    //     }
    // }

    function hasMetRemovalThreshold(
        address applicant_
    ) public view returns (bool) {
        uint256 noOfMemebers_ = NoOfMembers;
        uint256 approvalThreshold = (noOfMemebers_ * 70) / 100; // 70% approval threshold
        return MembershipStatus_[applicant_].RemovalCount >= approvalThreshold;
    }

    //To disapprove the applicant for membership of DAO
    function disapproveEntry(
        address _applicant
    ) external _IsMember whenNotPaused {
        // require(approval == false, "approval cant be true");
        Application storage application = userApplication_[_applicant];
        require(application.applied == true, "user hasn't applied");
        require(!voted_[msg.sender], "user has voted");
        voted_[msg.sender] = true;
        application.disapprovalCount++;

        bool approvalThreshold = hasMetDisapprovalThreshold(_applicant);
        if (approvalThreshold) {
            delete userApplication_[msg.sender];
        }
    }

    //To remove a member from DAO
    function VoteToRemoveMember(
        address _memberToRemove
    ) external _IsMember whenNotPaused {
        require(
            msg.sender != _memberToRemove,
            "Caller cant be member to remove"
        );
        require(!votedForMemberRemoval[msg.sender], "Member already voted");
        votedForMemberRemoval[msg.sender] = true;
        MembershipStatus_[_memberToRemove].RemovalCount++;

        if (hasMetRemovalThreshold(_memberToRemove)) {
            delete isMember_[_memberToRemove];
            isAlumini_[_memberToRemove] = true;
        }
        if (NoOfMembers != 0) {
            NoOfMembers--;
        } else if (NoOfMembers == 0) {
            _pause();
        }
    }

    //To leave DAO
    function leave() external _IsMember whenNotPaused {
        if (isAlumini_[msg.sender] == false) {
            isAlumini_[msg.sender] = true;
            delete isMember_[msg.sender];
        }
        if (NoOfMembers != 0) {
            unchecked {
                NoOfMembers--;
            }
        } else {
            _pause();
        }
    }

    //To check membership of DAO
    function isMember(
        address _user
    ) external view _IsMember whenNotPaused returns (bool) {
        return isMember_[_user];
    }

    //To check total number of members of the DAO
    function totalMembers()
        public
        view
        _IsMember
        whenNotPaused
        returns (uint256)
    {
        return NoOfMembers;
    }

    function userApplication() public view returns (Application memory) {
        return userApplication_[msg.sender];
    }
}
