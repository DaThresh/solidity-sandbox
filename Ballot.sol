// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

contract Ballot {
  struct Voter {
    uint weight;
    bool voted;
    address delegate;
    uint vote;
  }

  struct Proposal {
    bytes32 name;
    uint voteCount;
  }

  address public chairperson;

  mapping(address => Voter) public voters;

  Proposal[] public proposals;

  constructor(bytes32[] memory proposalNames) {
    chairperson = msg.sender;
    voters[chairperson].weight = 1;
    
    for (uint i = 0; i < proposalNames.length; i++) {
      proposals.push(Proposal({
        name: proposalNames[i],
        voteCount: 0
      }));
    }
  }

  function giveRightToVote(address voter) external {
    require(msg.sender == chairperson, "Only chairperson can give the right to vote");
    require(!voters[voter].voted, "The voter already voted");
    require(voters[voter].weight == 0, "The voter already has voting privileges");
    voters[voter].weight = 1;
  }

  function giveBulkRightToVote(address[] memory voterAddresses) external {
    require(msg.sender == chairperson, "You must be the chairperson to give the right to vote");
    for(uint a = 0; a < voterAddresses.length; a++) {
      address currentAddress = voterAddresses[a];
      require(!voters[currentAddress].voted, "The voter already voted!");
      require(voters[currentAddress].weight == 0, "The voter already has the right to vote");
      voters[currentAddress].weight = 1;
    }
  }

  function delegate(address to) external {
    Voter storage sender = voters[msg.sender];

    require(!sender.voted, "You already voted");
    require(msg.sender != to, "You cannot delegate yourself");

    while (voters[to].delegate != address(0)) {
      to = voters[to].delegate;
      require(to != msg.sender, "Found loop in delegation");
    }

    Voter storage delegate_ = voters[to];

    require(delegate_.weight >= 1, "Cannot delegate to vote a person that has no rights");
    sender.voted = true;
    sender.delegate = to;
    if (delegate_.voted) {
      proposals[delegate_.vote].voteCount += sender.weight;
    } else {
      delegate_.weight += sender.weight;
    }
  }

  function vote(uint proposal) external {
    Voter storage voter = voters[msg.sender];
    require(voter.weight > 0, "You have no right to vote!");
    require(!voter.voted, "You already voted!");
    voter.voted = true;
    voter.vote = proposal;

    proposals[proposal].voteCount += voter.weight;
  }

  function winningProposal() public view returns (uint winningProposal_) {
    uint winningVoteCount_ = 0;
    for (uint p = 0; p < proposals.length; p++) {
      if (proposals[p].voteCount > winningVoteCount_) {
        winningVoteCount_ = proposals[p].voteCount;
        winningProposal_ = p;
      }
    }
  }

  function winnerName() public view returns (bytes32 winnerName_) {
    winnerName_ = proposals[winningProposal()].name;
  }
}
