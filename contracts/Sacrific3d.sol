pragma solidity ^0.4.24;
import "./HourglassInterface.sol";
import "./Oraclize.sol";

contract Sacrific3d is usingOraclize{
    
    struct Stage {
        uint8 numberOfPlayers;
        uint256 blocknumber;
        bool finalized;
        mapping (uint8 => address) slotXplayer;
        mapping (address => bool) players;
    }
    
    HourglassInterface p3dContract;// = Hourglass(0xB3775fB83F7D12A36E0475aBdD1FCA35c091efBe);
   
    //a small part of every winners share of the sacrificed players offer is used to purchase p3d instead
    uint256 public P3D_SHARE;
    
    uint8 public MAX_PLAYERS_PER_STAGE;
    uint256 public OFFER_SIZE;
    
    uint256 public p3dPerStage;
    //not sacrificed players receive their offer back and also a share of the sacrificed players offer 
    uint256 public winningsPerRound;
    
    mapping(address => uint256) private playerVault;
    mapping(uint256 => Stage) private stages;
    uint256 private numberOfFinalizedStages;
    
    uint256 public numberOfStages = 0;
    
    event SacrificeOffered(address indexed player);
    event SacrificeChosen(address indexed sarifice);
    event EarningsWithdrawn(address indexed player, uint256 indexed amount);
    event StageInvalidated(uint256 indexed stage);
    
    modifier isValidOffer()
    {
        require(msg.value == OFFER_SIZE);
        _;
    }
    
    modifier canPayFromVault()
    {
        require(playerVault[msg.sender] >= OFFER_SIZE);
        _;
    }
    
    modifier hasEarnings()
    {
        require(playerVault[msg.sender] > 0);
        _;
    }
    
    modifier prepareStage()
    {
        //create a new stage if current has reached max amount of players
        if(stages[numberOfStages - 1].numberOfPlayers == MAX_PLAYERS_PER_STAGE) {
           stages[numberOfStages] = Stage(0, 0, false);
           numberOfStages++;
        }
        _;
    }
    
    modifier isNewToStage()
    {
        require(stages[numberOfStages - 1].players[msg.sender] == false);
        _;
    }
    
    constructor(address hourglass, uint256 p3dShare, uint8 maxPlayersPerStage, uint256 offerSize)
        public
    {
        require(offerSize >= 0.0001 ether);
        require(maxPlayersPerStage > 1 && maxPlayersPerStage < 256);
        require(p3dShare < maxPlayersPerStage * offerSize);
        P3D_SHARE = p3dShare;
        MAX_PLAYERS_PER_STAGE = maxPlayersPerStage;
        OFFER_SIZE = offerSize;
        p3dPerStage = P3D_SHARE * (MAX_PLAYERS_PER_STAGE - 1);
        winningsPerRound = OFFER_SIZE + OFFER_SIZE / (MAX_PLAYERS_PER_STAGE - 1) - P3D_SHARE;
        p3dContract = HourglassInterface(hourglass);
        stages[0] = Stage(0, 0, false);
        numberOfStages = 1;
        oraclize_setProof(proofType_Ledger);
    }
    
    function() external payable {}
    
    function generatePRNG() internal {
        uint N = 7; // number of random bytes we want the datasource to return
        uint delay = 0; // number of seconds to wait before the execution takes place
        uint callbackGas = 200000; // amount of gas we want Oraclize to set for the callback function
        oraclize_newRandomDSQuery(delay, N, callbackGas); // this function internally generates the correct oraclize_query and returns its queryId
    }

    function __callback(bytes32 _queryId, string _result, bytes _proof) public { 
        require(msg.sender == oraclize_cbAddress());
        
        if (oraclize_randomDS_proofVerify__returnCode(_queryId, _result, _proof) != 0) {
            // the proof verification has failed, do we need to take any action here? (depends on the use case)
        } else {
            // the proof verification has passed
            // now that we know that the random number was safely generated, let's use it..
            uint8 randomNumber = uint8(keccak256(abi.encodePacked(_result))) % MAX_PLAYERS_PER_STAGE; 
            tryFinalizeStage(randomNumber);
        }
    }

    function offerAsSacrifice()
        external
        payable
        isValidOffer
        prepareStage
        isNewToStage
    {
        acceptOffer();
        
        //try to choose a sacrifice in an already full stage (finalize a stage)
        generatePRNG();
    }
    
    function offerAsSacrificeFromVault()
        external
        canPayFromVault
        prepareStage
        isNewToStage
    {
        playerVault[msg.sender] -= OFFER_SIZE;
        
        acceptOffer();
        
        generatePRNG();
    }
    
    function withdraw()
        external
        hasEarnings
    {
        generatePRNG();
        
        uint256 amount = playerVault[msg.sender];
        playerVault[msg.sender] = 0;
        
        emit EarningsWithdrawn(msg.sender, amount); 
        
        msg.sender.transfer(amount);
    }
    
    function myEarnings()
        external
        view
        hasEarnings
        returns(uint256)
    {
        return playerVault[msg.sender];
    }
    
    function currentPlayers()
        external
        view
        returns(uint256)
    {
        return stages[numberOfStages - 1].numberOfPlayers;
    }
    
    function acceptOffer()
        private
    {
        Stage storage currentStage = stages[numberOfStages - 1];
        
        assert(currentStage.numberOfPlayers < MAX_PLAYERS_PER_STAGE);
        
        address player = msg.sender;
        
        //add player to current stage
        currentStage.slotXplayer[currentStage.numberOfPlayers] = player;
        currentStage.numberOfPlayers++;
        currentStage.players[player] = true;
        
        emit SacrificeOffered(player);
        
        //add blocknumber to current stage when the last player is added
        if(currentStage.numberOfPlayers == MAX_PLAYERS_PER_STAGE) {
            currentStage.blocknumber = block.number;
        }
    }
    
    function tryFinalizeStage(uint8 winner)
        private
    {
        assert(numberOfStages >= numberOfFinalizedStages);
        
        //there are no stages to finalize
        if(numberOfStages == numberOfFinalizedStages) {return;}
        
        Stage storage stageToFinalize = stages[numberOfFinalizedStages];
        
        assert(!stageToFinalize.finalized);
        
        //stage is not ready to be finalized
        if(stageToFinalize.numberOfPlayers < MAX_PLAYERS_PER_STAGE) {return;}
        
        assert(stageToFinalize.blocknumber != 0);
        
        //check if blockhash can be determined
        if(block.number - 256 <= stageToFinalize.blocknumber) {
            //blocknumber of stage can not be equal to current block number -> blockhash() won't work
            if(block.number == stageToFinalize.blocknumber) {return;}
                
            //determine sacrifice
            address sacrifice = stageToFinalize.slotXplayer[winner];
            
            emit SacrificeChosen(sacrifice);
            
            //allocate winnings to survivors
            allocateSurvivorWinnings(sacrifice);
            
            //allocate p3d dividends to sacrifice if existing
            uint256 dividends = p3dContract.myDividends(true);
            if(dividends > 0) {
                p3dContract.withdraw();
                playerVault[sacrifice]+= dividends;
            }
            
            //purchase p3d (using ref)
            p3dContract.buy.value(p3dPerStage)(address(msg.sender));
        } else {
            invalidateStage(numberOfFinalizedStages);
            
            emit StageInvalidated(numberOfFinalizedStages);
        }
        //finalize stage
        stageToFinalize.finalized = true;
        numberOfFinalizedStages++;
    }
    
    function allocateSurvivorWinnings(address sacrifice)
        private
    {
        for (uint8 i = 0; i < MAX_PLAYERS_PER_STAGE; i++) {
            address survivor = stages[numberOfFinalizedStages].slotXplayer[i];
            if(survivor != sacrifice) {
                playerVault[survivor] += winningsPerRound;
            }
        }
    }
    
    function invalidateStage(uint256 stageIndex)
        private
    {
        Stage storage stageToInvalidate = stages[stageIndex];
        
        for (uint8 i = 0; i < MAX_PLAYERS_PER_STAGE; i++) {
            address player = stageToInvalidate.slotXplayer[i];
            playerVault[player] += OFFER_SIZE;
        }
    }
}
