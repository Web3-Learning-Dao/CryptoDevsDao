const { expect } = require('chai');
const { ethers, deployments } = require('hardhat');
const keccak256 = require('keccak256');
const { testArgs } = require('../utils/configs');
const { setupProof, contractsReady } = require('../utils/helpers');

const _args = testArgs();
const _governorSettings = {
    cryptoDevsToken: _args[2].cryptoDevsToken.governorNFT,
    cryptoDevsNFT: _args[2].cryptoDevsNFT.governorNFT,
};

const _Votes = {
    Against: 0,
    For: 1,
    Abstain: 2,
};
  
describe('Governor', function () {
    before(async function () {
        await setupProof(this);
        console.log("setupProof successed");
    });

    beforeEach(async function () {
        // @dev the order of these deployments is important
        // make sure your custom fixtures are in the last.
        await deployments.fixture(['Mocks']);
        await contractsReady(this, true)();
    
        this.voters = this.whitelistAccounts;
        this.votersAddresses = this.whitelistAddresses;
        this.receiver = await ethers.getContract('CallReceiverMock');
    
        // Proposal for testing
        this.proposal = [
          // targets
          [this.receiver.address],
          // value (of ETH)
          [0],
          // calldata
          [this.receiver.interface.encodeFunctionData('mockFunction()', [])],
          // description
          '<proposal description>',
        ];
    
        this.shortProposal = [
          this.proposal[0],
          this.proposal[1],
          this.proposal[2],
          keccak256(this.proposal.slice(-1).find(Boolean)),
        ];
    
        this.proposalId = await this.governorNFT.hashProposal(...this.shortProposal);
        console.log("proposalId===> ",proposalId);
    });

    it('deployment check', async function () {
        // Make sure membership governorNFT works properly
        console.log("start===> deployment check");
        expect(await this.governorNFT.name()).to.be.equal(_args[0].name + '-MembershipGovernor');
        expect(await this.governorNFT.token()).to.be.equal(this.membership.address);
        expect(await this.governorNFT.votingDelay()).to.be.equal(_governorSettings.membership.votingDelay);
        expect(await this.governorNFT.votingPeriod()).to.be.equal(
          _governorSettings.membership.votingPeriod
        );
        expect(await this.governorNFT.proposalThreshold()).to.be.equal(
          _governorSettings.membership.proposalThreshold
        );
        expect(await this.governorNFT.quorum(0)).to.be.equal(0);
        expect(await this.governorNFT.timelock()).to.be.equal(this.treasury.address);
    
        // Make sure share governorNFT works properly
        expect(await this.governorToken .name()).to.be.equal(_args[0].name + '-TokenGovernor');
        expect(await this.governorToken .token()).to.be.equal(await this.membership.shareToken());
        expect(await this.governorToken .votingDelay()).to.be.equal(_governorSettings.share.votingDelay);
        expect(await this.governorToken .votingPeriod()).to.be.equal(
          _governorSettings.share.votingPeriod
        );
        expect(await this.governorToken .proposalThreshold()).to.be.equal(
          _governorSettings.share.proposalThreshold
        );
        expect(await this.governorToken .quorum(0)).to.be.equal(0);
        expect(await this.governorToken .timelock()).to.be.equal(this.treasury.address);
    
        // Can use `this.voters.forEach` to expect test cases
        this.voters.forEach(async (adr, idx) => {
          expect(await this.governorToken.balanceOf(this.votersAddresses[idx])).to.be.equal(1);
          expect(await this.governorToken.getVotes(this.votersAddresses[idx])).to.be.equal(1);
        });
      });

      describe('#propose', function () {
        it('Should able to make a valid propose', async function () {
          await expect(
            this.governorNFT
              .connect(this.owner)
              .functions['propose(address[],uint256[],bytes[],string)'](...this.proposal)
          ).to.emit(this.governorNFT, 'ProposalCreated');
        });
    
        // this.accounts[5] is not a voter
        it('Should not able to make a valid propose if user do not hold a NFT membership', async function () {
          await expect(
            this.governorNFT
              .connect(await ethers.getSigner(this.accounts[5]))
              .functions['propose(address[],uint256[],bytes[],string)'](...this.proposal)
          ).to.be.revertedWith('GovernorCompatibilityBravo: proposer votes below proposal threshold');
        });
      });

      describe('#vote', function () {
        it('Should able to cast votes on a valid proposal', async function () {
          await expect(
            this.governorNFT
              .connect(this.owner)
              .functions['propose(address[],uint256[],bytes[],string)'](...this.proposal)
          ).to.emit(this.governorNFT, 'ProposalCreated');
          // this.deadline = await this.governorNFT.proposalDeadline(this.proposalId);
          // this.snapshot = await this.governorNFT.proposalSnapshot(this.proposalId);
    
          // await time.advanceBlockTo(this.snapshot + 1);
    
          // First vote, check event `VoteCast`
          await expect(this.governorNFT.connect(this.voters[1]).castVote(this.proposalId, _Votes.For))
            .to.emit(this.governorNFT, 'VoteCast')
            .withArgs(this.votersAddresses[1], this.proposalId, _Votes.For, 1, '');
    
          // Check `hasVoted` func
          expect(
            await this.governorNFT
              .connect(this.voters[1])
              .hasVoted(this.proposalId, this.votersAddresses[1])
          ).to.be.equal(true);
    
          // Another vote, check event `VoteCast`
          await expect(
            this.governorNFT
              .connect(this.voters[2])
              .castVoteWithReason(this.proposalId, _Votes.For, "I don't like this proposal")
          )
            .to.emit(this.governorNFT, 'VoteCast')
            .withArgs(
              this.votersAddresses[2],
              this.proposalId,
              _Votes.For,
              1,
              "I don't like this proposal"
            );
    
          // fastforward
          // await time.advanceBlockTo(this.deadline + 1);
    
          // Add proposal to queue
          await expect(
            this.governorNFT.functions['queue(address[],uint256[],bytes[],bytes32)'](...this.shortProposal)
          ).to.emit(this.governorNFT, 'ProposalQueued');
    
          // await time.increase(3600);
    
          // Excute
          // excutor can be any address but function is triggered by `timelock` as `msg.sender`
          await expect(
            this.governorNFT.functions['execute(address[],uint256[],bytes[],bytes32)'](
              ...this.shortProposal
            )
          )
            .to.emit(this.governorNFT, 'ProposalExecuted')
            .to.emit(this.treasury, 'CallExecuted')
            .to.emit(this.receiver, 'MockFunctionCalled');
        });
    
        // this.accounts[5] is not a voter
        it('Should not able to cast vote if user do not hold a NFT membership', async function () {
          await expect(
            this.governorNFT
              .connect(this.owner)
              .functions['propose(address[],uint256[],bytes[],string)'](...this.proposal)
          ).to.emit(this.governorNFT, 'ProposalCreated');
    
          await expect(
            this.governorNFT
              .connect(await ethers.getSigner(this.accounts[5]))
              .castVote(this.proposalId, _Votes.For)
          ).to.be.revertedWith('VotesBelowProposalThreshold()');
        });
      });
});