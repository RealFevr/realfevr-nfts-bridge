RFB-08 | Missing or Incomplete Events
✅ suggestion applied

ERB-08 | Use of transferFrom() Over safeTransferFrom() for NFTs in May Lead to Loss of NFTs
✅ suggestion applied

ERB-04 | ERC721HolderUpgradeable Can Be Used
✅ suggestion applied

RFB-02 | Unnecessary storage Specification
comment: ERC20Contracts storage token cannot be memory as it contain a mapping, leaving as it is
✅

RFB-01 | for Loop Optimizations
comment: please read https://soliditylang.org/blog/2023/10/25/solidity-0.8.22-release-announcement/
✅ suggestion applied

ERB-06 | quantity is Always Hardcoded as 1 When takeFees() is Called
✅ suggestion applied

ERB-01 | Perform Checks Before Updates
✅ suggestion applied

RFB-16 | Ineffective Use of Reentrancy Guard
comment: adding nonReentrant to depositSingleERC721 will break the functionality of  depositMultipleERC721
✅

RFB-15 | Check-Effect-Interaction Pattern Violated
comment: this change is breaking some fuzz tests.
As the feeReceiver is owned by the team, this is accepted.
✅

RFB-12 | Missing Input Validation
✅ we leave it as it is to save gas

RFB-07 | Missing Zero Address Validation
comment: we leave it as it is to save gas
✅

RFB-06 | Access Control Roles Should Be Set Inline as Constants
comment: we leave it as it is as it give no gains,
better never write anything in those parts of the contract if they are implementations.
✅

ERB-03 | Unused State Variables
comment: maxNFTsPerTx is used 15 times in the code, 2 times in the core logic.
partially pending

RFH-02 | Inconsistency Between safeMint() and safeMintTo() Use of lastMintedId
✅

ERC-04 | Improper Handling of Daily Limits Between Deposit and Withdraw Actions
✅