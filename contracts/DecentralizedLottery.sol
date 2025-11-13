// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/// @title DecentralizedLottery
/// @notice Simple decentralized lottery for class/demo. NOT production-grade randomness.
/// @dev Uses CEI pattern. For production randomness, integrate Chainlink VRF (see notes).
contract DecentralizedLottery {
    // ============ STATE VARIABLES ============
    address public owner;

    // Configuration (fixed)
    uint public constant TICKET_PRICE = 0.01 ether;
    uint public constant ROUND_DURATION = 5 minutes;

    // Round state
    uint public roundNumber;
    uint public roundEndTime;
    address[] private players; // repeated entries allowed (one entry per ticket)
    address public lastWinner;
    uint public lastPrizeAmount;
    bool public lastRoundHadWinner;

    // Prevent double-picking for a round
    mapping(uint => bool) public winnerPickedForRound;

    // Randomness nonce (pseudo-random only)
    uint private nonce;

    // History (simple)
    mapping(uint => address) public roundWinner;
    mapping(uint => uint) public roundPrize;

    // ============ EVENTS ============
    event RoundStarted(uint indexed roundNumber, uint endTime);
    event TicketPurchased(address indexed player, uint ticketCount);
    event WinnerSelected(uint indexed roundNumber, address indexed winner, uint prize);
    event RoundReset(uint indexed roundNumber);

    // ============ MODIFIERS ============
    modifier onlyOwner() {
        require(msg.sender == owner, "only owner");
        _;
    }

    modifier roundActive() {
        require(isRoundActive(), "round is not active");
        _;
    }

    modifier roundEnded() {
        require(!isRoundActive() && roundEndTime != 0, "round still active or not started");
        _;
    }

    // ============ CONSTRUCTOR ============
    constructor() {
        owner = msg.sender;
        roundNumber = 0;
    }

    // ============ OWNER ACTIONS ============
    /// @notice Owner starts a new round. Clears previous players and sets end time.
    function startNewRound() external onlyOwner {
        // If a previous round is active, disallow starting a new one
        require(!isRoundActive(), "current round still active");

        // Prepare next round
        roundNumber += 1;
        roundEndTime = block.timestamp + ROUND_DURATION;

        // Clear players (safe: this doesn't move funds)
        delete players;

        // reset picked flag for this round (should be false by default)
        winnerPickedForRound[roundNumber] = false;

        emit RoundStarted(roundNumber, roundEndTime);
    }

    // ============ PARTICIPANT ACTIONS ============
    /// @notice Buy tickets. msg.value must be multiple of TICKET_PRICE.
    /// @dev Adds sender address once per ticket (multiple entries allowed).
    function buyTickets() external payable roundActive {
        require(msg.value >= TICKET_PRICE, "insufficient ETH sent");
        // Accept only exact multiples to avoid rounding issues; refund not implemented here
        require(msg.value % TICKET_PRICE == 0, "send a multiple of ticket price");

        uint tickets = msg.value / TICKET_PRICE;
        // Add msg.sender to players array 'tickets' times
        for (uint i = 0; i < tickets; i++) {
            players.push(msg.sender);
        }

        emit TicketPurchased(msg.sender, tickets);
    }

    // ============ WINNER SELECTION ============
    /// @notice Select winner after round ends. Anyone can call.
    /// @dev Uses pseudo-randomness (block attributes) — insecure for high-value lotteries.
    ///      For production, replace randomness with Chainlink VRF or another oracle.
    function pickWinner() external roundEnded returns (address) {
        require(players.length > 0, "no players in round");
        require(!winnerPickedForRound[roundNumber], "winner already picked for this round");

        // Generate pseudo-random index (insecure, FOR DEMO ONLY)
        uint rand = _random();
        uint idx = rand % players.length;
        address winner = players[idx];

        // Effects: update state BEFORE transferring funds (CEI)
        uint prize = address(this).balance; // all ETH in contract belongs to winner for this round
        lastWinner = winner;
        lastPrizeAmount = prize;
        lastRoundHadWinner = true;

        // Persist history
        roundWinner[roundNumber] = winner;
        roundPrize[roundNumber] = prize;
        winnerPickedForRound[roundNumber] = true;

        // Reset players array for safety / next round. (We do this before transfer).
        delete players;
        emit RoundReset(roundNumber);

        // Interaction: transfer prize to winner
        (bool sent, ) = payable(winner).call{value: prize}("");
        require(sent, "transfer failed");

        emit WinnerSelected(roundNumber, winner, prize);
        return winner;
    }

    // ============ VIEWS / HELPERS ============
    function isRoundActive() public view returns (bool) {
        return (roundEndTime > block.timestamp) && (roundEndTime != 0);
    }

    function getTimeRemaining() external view returns (uint) {
        if (!isRoundActive()) return 0;
        return roundEndTime - block.timestamp;
    }

    function getPlayerCount() external view returns (uint) {
        return players.length;
    }

    function getPrizePool() external view returns (uint) {
        return address(this).balance;
    }

    /// @notice Returns a snapshot copy of players (pay attention to gas if large)
    function getPlayers() external view returns (address[] memory) {
        return players;
    }

    /// @notice Returns the winner and prize for a specific round (if available)
    function getRoundResult(uint _roundNumber) external view returns (address winner, uint prize) {
        winner = roundWinner[_roundNumber];
        prize = roundPrize[_roundNumber];
    }

    // ============ INTERNAL UTILITIES ============
    function _random() internal returns (uint) {
        // WARNING: insecure pseudo-random. Use Chainlink VRF for production.
        nonce++;
        return uint(keccak256(abi.encodePacked(block.timestamp, block.prevrandao, msg.sender, nonce)));
    }

    // ============ FALLBACKS ============
    receive() external payable {
        // accept ETH; prefer explicit buyTickets() as it records entries
    }

    fallback() external payable {
        // accept ETH sent by mistake
    }
}
