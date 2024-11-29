######################################################
# Enhancements Implemented:
# 
# 1. Increased Number of Boxes and Targets
#
#    Locations in code:
#    - `genBoxPos` and `genBoxPosEnd` LABEL: Repeats the box generation process.
#    - `genTargetPos` and `genTargetPosEnd` LABEL: Repeats the target generation process.
#    - `removeUnsolvableBox` FUNCTION: Removes unsolvable boxes.
#
#    Implementation details:
#    - The number of boxes and targets is based on user input (level).
#    - Boxes and targets are generated randomly inside the game board, 
#      keeping the outermost rows and columns clear to improve solvability.
#    - A maximum of 20 attempts is set to prevent infinite loops during random generation.
#    - Remove potential unsolvable boxes if they appear in the following configurations 
#      (where `b` is the newly placed box):
#          B        or      B b         or        b B        or        b
#        B b                 B                    B                    B
#    - This ensures all boxes can be moved, making the game solvable.
#
# 2. Multi-Player Mode
#
#    Locations in code:
#    - `recordPlayer` FUNCTION: Records the player's move count on the leaderboard.
#    - `gameMainLoopEnd` LABEL: Call recordPlayer at the end each time player finished game.
#    - `gameEnd` LABEL: Prints the leaderboard at the end of the game.
#    - `askPlayerNumber` LABEL: Asks for the number of players and allocates memory for 
#                               player scores and the leaderboard.
#
#    Implementation details:
#    - The user inputs the number of players at the start.
#    - Two arrays (`playerScore` and `playerLeaderboard`) are dynamically allocated to store
#      player moves and positions on the leaderboard.
#    - After each player's turn, their move count is inserted into the correct position in 
#      the sorted player score array using an insertion sort approach.
#    - At the end of the game, the leaderboard is printed, displaying the player rankings.
#
# ----------------------------------------------------
# 
# Random Number Generation FUNCTION:
#
#    - I use Linear congruential generator (LCG) algorithm to repleace the
#      original notrand function.
#    - The LCG parameters are based on the cc65 implementation.
#    - The first seed is generated using the time syscall at the start of the game.
#
#    Location in code:
#    - `LCGRandom` FUNCTION: Generates random numbers using a Linear Congruential Generator (LCG).
#    - `seed`, `m`, `a`, `c` VARIABLES: Are LCG parameters located in the `.data` section.
#
######################################################
.data
gridBaseAddress:       .word 0
girdBackup: .word 0

# Parameters for the linear congruential generator (LCG)
# These values are based on the LCG implementation used in cc65
seed: .word 0        # seed for LCG and will be generate random when game starts
m: .word 8388608     # modulus for LCG
a: .word 65793       # multiplier for LCG
c: .word 4282663     # increment for LCG

# Player count secontion
totalPlayer: .word 1 # The total number of player
# Player leaderboard 
playerLeaderboard: .word 0  # The base address of the player leaderboard
playerScore: .word 0 # The base address of the player score

# The total number of boxes
totalBox: .half 2   # The number of box
boxLeft:  .half 2   # The number of box left
# The size of the grid and the pos of the character
gridsize:   .byte 8,8
character:  .byte 0,0
characterStartPos: .byte 0,0

welcomeMsg: .string "~~~Welcome to the word best Sokoban game~~~\n"
gameExistMsg:   .string "\nGame exist\n"
askRow: .string "Row number (5 to 255): "
askCol: .string "Column number: (5 to 255): "
askLevel: .string "Please enter the level number (MAX level "
askPlayer: .string "Please enter the number of player: "
invalidPlayer: .string "Invalid player number! Try again: "
invalidRow: .string "Invalid row number! Try again: "
invalidCol: .string "Invalid column number! Try again: "
invalidLevel: .string "Invalid level number! Try again: "
invalidCommand: .string "Invalid command! please try again!\n"
finishMsg: .string "Congratulations! You have finished the game!\n"
playerChangeMsg: .string "Now is Player"
turnMsg: .string " turn!!!!\n"
playerMsg: .string "~~~Player"
isPlayingMsg: .string " is playing~~~\n"
stepCountMsg: .string " step count: "
LeaderboardMsg: .string "====== Leaderboard ======\n"

.text
.globl _start

_start:

    # Initial all the value to defualt
    li sp, 0x80000000

    # Initial the character position to 0,0
    la t0, character
    sb zero, 0(t0)
    sb zero, 1(t0)
        
    # Initial the seed
    li a7, 30
    ecall             # time syscall (returns milliseconds)
    la t0, seed
    lw a0, 0(t0)      # store the seed

    # Print the welcome message
    la a0, welcomeMsg
    li a7, 4
    ecall

    la a0, askPlayer
askPlayerNumber:
    # ask the player number
    li a7, 4
    ecall
    li a7, 5
    ecall
    
    mv t0, a0
    la a0, invalidPlayer
    # If the player number is less than 0, then ask again
    ble t0, zero, askPlayerNumber
    
    mv a0, t0
    # store the player number and init the array size
    la t0, totalPlayer
    sw a0, 0(t0)
    slli a0, a0, 2
    sub sp, sp, a0
    andi sp, sp, -4
    la t1, playerScore
    sw sp, 0(t1)

    sub sp, sp, a0
    andi sp, sp, -4
    la t1, playerLeaderboard
    sw sp, 0(t1)

    la a0, askRow   # load the row number message
askRowNumber:
    # ask the row number of the gameboard
    li a7, 4
    ecall
    li a7, 5
    ecall

    # If the row number is less than 5, then ask again
    li t0, 5
    mv t1, a0
    la a0, invalidRow
    blt t1, t0, askRowNumber

    # store the row number
    la t0, gridsize
    sb t1, 0(t0)
    
    la a0, askCol   # load the column number message
askColNumber:
    # ask the column number of the gameboard
    li a7, 4
    ecall
    li a7, 5
    ecall
    # If the column number is less than 5, then ask again
    li t0, 5
    mv t1, a0
    la a0, invalidCol
    blt t1, t0, askColNumber

    # store the column number
    la t0, gridsize
    sb t1, 1(t0)
    
    # init the gameboard size and store the base address
    # make sure the memory is allocated for the grid 
    # is multiple of 4. otherwise, the sp will not be
    # aligned to 4
    lbu t1, 0(t0)
    lbu t2, 1(t0)
    mul t0, t1, t2
    sub sp, sp, t0
    andi sp, sp, -4
    la t1, gridBaseAddress
    sw sp, 0(t1)
    sub sp, sp, t0
    andi sp, sp, -4
    la t1, girdBackup
    sw sp, 0(t1)

    # calculate the max LEVEL
    la t0, gridsize
    lbu t1, 0(t0)
    lbu t2, 1(t0)
    addi t1, t1, -4
    addi t2, t2, -4
    mul t5, t1, t2
    li t6, 1
    # If any of the dimension is 5, then the max box number is t1 * t2
    # If not then the max box number is t1 * t2 / 2
    beq t1, t6, printAskLevelNumber
    beq t2, t6, printAskLevelNumber
    li t2, 2
    div t5, t5, t2   # the max level is half of the grid size
    bne t5, zero, printAskLevelNumber
    li t5, 1
printAskLevelNumber:
    la a0, askLevel  # load the level number message
    # ask the level number
    li a7, 4
    ecall
    # print the max level number
    mv a0, t5
    li a7, 1
    ecall
    # print ) and : and space
    li a0, 41 # )
    li a7, 11
    ecall
    li a0, 58 # :
    li a7, 11
    ecall
    li a0, 32 # space
    li a7, 11
    ecall
    j askLevelNumber
reAskLevelNumber:
    la a0, invalidLevel
    li a7, 4
    ecall
askLevelNumber:
    # get the level number
    li a7, 5
    ecall

    mv t2, a0
    # If the level number is less than 1 or greater than the max level, then ask again
    ble t2, zero, reAskLevelNumber

    # using the level number to set the max box number
    la t0, totalBox
    sh t2, 0(t0)

    # generate the gameboard
    lw a0, gridBaseAddress
    jal initGameBoard

    lw a0, girdBackup
    jal initGameBoard

    # generate and set the coordinates for the box, characterand target
    lw s0, gridBaseAddress
    la s1, gridsize

    li s10, 20 # the max try number
    li s11, 0
    # the box part
genBoxPos:
    ble s10, zero, genBoxPosEnd # if reach the max try number then stop the loop

    lbu a0, 0(s1)
    lbu a1, 1(s1)
    addi a0, a0, -4

    addi a1, a1, -4
    jal genRandomCordinate
    addi s2, a0, 2
    addi s3, a1, 2

    # try set the box in the board
    mv a0, s2
    mv a1, s3
    mv a2, s0 # put the grid base address to a2
    jal setBoxLocation

    addi s10, s10, -1

    beqz a0, genBoxPos # if a0 == 0 then genBoxPos (try again)
    
    li s10, 20 # reset the max try number
    
    # make a backup of the box location
    mv a0, s2
    mv a1, s3
    lw a2, girdBackup
    jal setBoxLocation

    addi s11, s11, 1
    lh t0, totalBox
    blt s11, t0, genBoxPos # keep generate the box until reach the total box number
genBoxPosEnd:
    la t0, totalBox  # store the actual box number that generated
    sh s11, 0(t0)

    # remove the unsolvable box
    jal removeUnsolvableBox

    lh t0, totalBox
    la t1, boxLeft
    sh t0, 0(t1)
genCharacterPos:
    # the character part
    lbu a0, 0(s1)
    lbu a1, 1(s1)
    addi a0, a0, -2
    addi a1, a1, -2
    jal genRandomCordinate
    addi s2, a0, 1
    addi s3, a1, 1

    # try set the character in the board
    mv a0, s2
    mv a1, s3
    mv a2, s0   # put the grid base address to a2
    jal setCharacterLocation
    beqz a0, genCharacterPos # if a0 == 0 then genCharacterPos (try again)

    # make a backup of the character location
    la t0, characterStartPos
    sb s2, 0(t0)
    sb s3, 1(t0)
    
    # the target part
    li s11, 0
genTargetPos:
    lbu a0, 0(s1)
    lbu a1, 1(s1)
    addi a0, a0, -2
    addi a1, a1, -2
    jal genRandomCordinate
    addi s2, a0, 1
    addi s3, a1, 1

    # try set the target in the board
    mv a0, s2
    mv a1, s3
    mv a2, s0   # put the grid base address to a2
    jal setTargetLocation
    beqz a0, genTargetPos # if a0 == 0 then genTargetPos (try again)

    # make a backup of the target location
    mv a0, s2
    mv a1, s3
    lw a2, girdBackup
    jal setTargetLocation

    addi s11, s11, 1
    lh t0, totalBox
    blt s11, t0, genTargetPos # keep generate the target until reach the total target number

# --- GAME MAIN ---
    li s3, 0 # player move counter
    li s4, 0 # player number
    gameMainLoop:
        # print the player number
        la a0, playerMsg
        li a7, 4
        ecall
        addi a0, s4, 1
        li a7, 1
        ecall
        la a0, isPlayingMsg
        li a7, 4
        ecall

        lw a0, gridBaseAddress
        jal printBoard
        # get the user input
        # 101 (e): exit game
        # 114 (r): reset the game board
        # 112 (p) : restart game
        li a7, 12
        ecall
        # check if the user want to exit the game
        li t0, 101
        beq a0, t0, exit
        # check if the user want to restart the game
        li t0, 112
        bne a0, t0, checkReset
        li a0, 10 # new line
        li a7, 11 
        ecall
        j _start
    checkReset:
        # check user want to reset the game board
        li t0, 114
        bne a0, t0, checkMove

        jal resetGameBoard
        j gameMainLoopEnd
    checkMove:
        # move the character
        jal moveCharacter
        bne a0, zero, moveSeccuess # if the move is success record the step

        # If the move is not success, then print the invalid command message
        la a0, invalidCommand
        li a7, 4
        ecall
        j gameMainLoop
    moveSeccuess:
        addi s3, s3, 1
    gameMainLoopEnd:
        li a0, 10 # new line
        li a7, 11 
        ecall
        
        lh t0, boxLeft
        bne t0, zero, gameMainLoop # if still have target left, then continue the game

        # print the player number
        la a0, playerMsg
        li a7, 4
        ecall
        addi a0, s4, 1
        li a7, 1
        ecall
        la a0, isPlayingMsg
        li a7, 4
        ecall
        lw a0, gridBaseAddress
        jal printBoard

        # print the finish message
        la a0, finishMsg
        li a7, 4
        ecall

        mv a0, s3
        mv a1, s4
        jal recordPlayer
        
        addi s4, s4, 1
        lw t0, totalPlayer
        bge s4, t0, gameEnd
        
        jal resetGameBoard
        li s3, 0
        la a0, playerChangeMsg
        li a7, 4
        ecall
        addi a0, s4, 1
        li a7, 1
        ecall
        la a0, turnMsg
        li a7, 4
        ecall
        j gameMainLoop
gameEnd:
    # print the score board message
    la a0, LeaderboardMsg
    li a7, 4
    ecall

    # print the player leaderboard
    lw t0, playerScore          # load base address for playerScore
    lw t3, playerLeaderboard    # load base address for playerLeaderboard
    lw t1, totalPlayer          # the total number of player
    li t2, 0                    # player number counter
    printLeaderboard:
        # print the place of the player
        addi a0, t2, 1
        li a7, 1
        ecall
        # ~PlayerX step count: Y
        la a0, playerMsg
        li a7, 4
        ecall
        lw a0, 0(t3)
        # addi a0, t2, 1
        li a7, 1
        ecall

        la a0, stepCountMsg
        li a7, 4
        ecall
        lw a0, 0(t0)
        li a7, 1
        ecall

        li a0, 10 # new line
        li a7, 11
        ecall

        addi t0, t0, 4
        addi t3, t3, 4
        addi t2, t2, 1
        blt t2, t1, printLeaderboard


exit:
    li sp, 0x80000000
    la a0, gameExistMsg
    li a7, 4
    ecall

    li a7, 10
    ecall
    
    
# --- HELPER FUNCTIONS ---

############################################
# Record the player move count to the leaderboard
#
# Arguments: the player move count in a0
#            the player number in a1
# Return: none
############################################
recordPlayer:
    lw t0, playerScore
    lw t6, playerLeaderboard
    addi t1, a1, -1     # t1 = j
    bne a1, zero, searchThePosForPlayer

    sw a0, 0(t0)
    addi a1, a1, 1
    sw a1, 0(t6)
    j recordPlayerEnd
searchThePosForPlayer:
    # a0 = key, a1=key'
    li t2, 0
    blt t1, t2, searchThePosForPlayerEnd  # If j < 0 then over
    
    # ----- For player score ----- #
    slli t4, t1, 2
    add t4, t4, t0
    lw t2, 0(t4)    # t2 = a[j]
    bge a0, t2, searchThePosForPlayerEnd  # If key >= a[j] then over
    
    addi t5, t1, 1
    slli t5, t5, 2
    add t5, t5, t0  # t5 = a[j+1]
    sw t2, 0(t5)    # a[j+1] = a[j]

    # ----- For player leaderboard ----- #

    slli t4, t1, 2
    add t4, t4, t6
    lw t2, 0(t4)    # t2' = b[j]

    addi t5, t1, 1
    slli t5, t5, 2
    add t5, t5, t6  # t5' = b[j+1]
    sw t2, 0(t5)    # b[j+1] = b[j]
    
    # ----- over ----- #

    addi t1, t1, -1 # j--
    j searchThePosForPlayer
searchThePosForPlayerEnd:
    addi t1, t1, 1
    slli t1, t1, 2
    add t2, t1, t0
    add t3, t1, t6

    sw a0, 0(t2)    # a[j+1]=key
    addi a1, a1, 1
    sw a1, 0(t3)    # b[j+1]=key'
recordPlayerEnd:
    jr ra

############################################
# Move the character based on user input
#
# Arguments: 
#   a0 - the input direction to move the character
#        119 (w): move up
#        97  (a): move left
#        115 (s): move down
#        100 (d): move right
#
# Return: 
#   1 if the input direction is valid and the character is moved
#   0 otherwise
############################################
moveCharacter:
    addi sp, sp, -16
    sw ra, 0(sp)
    sw s0, 4(sp)
    sw s1, 8(sp)
    sw s11, 12(sp)

    li s11, -1 # move negative direction
    li t0, 119 # move up
    beq a0, t0, moveVertical
    li t0, 97 # move left
    beq a0, t0, moveHorizontal
    
    li s11, 1 # positive direction
    li t0, 115 # move down
    beq a0, t0, moveVertical
    li t0, 100 # move right
    beq a0, t0, moveHorizontal

    li a0, 0
    j moveCharacterEnd
#################
# move the character up or down
#################
moveVertical:

    # load the character location
    la t0, character
    lbu s0, 0(t0)    # the row location of the character
    lbu s1, 1(t0)    # the column location of the character

    add a0, s0, s11
    mv a1, s1
    lw a2, gridBaseAddress
    jal getElemAndPosByCordinate
    
    # check if current location is a box
    li t0, 66 # B
    beq a0, t0, moveBoxVertical # if a0 == box
    li t0, 98 # b
    beq a0, t0, moveBoxVertical # if a0 == box on target

    j moveVerticalEnd
moveBoxVertical:
    add a0, s0, s11
    add a0, a0, s11
    mv a1, s1
    lw a2, gridBaseAddress
    jal setBoxLocation
    beqz a0, moveEnd

    add a0, s0, s11
    mv a1, s1
    lw a2, gridBaseAddress
    jal setToSpaceByCordinate

    # check if the orignal box is on the target
    # If it is, then add one to the boxLeft
    add a0, s0, s11
    mv a1, s1
    lw a2, girdBackup
    jal getElemAndPosByCordinate
    li t4, 46 # .

    bne a0, t4, moveVerticalEnd
    
    la t0, boxLeft
    lh t1, 0(t0)
    addi t1, t1, 1
    sh t1, 0(t0)
moveVerticalEnd:
    add a0, s0, s11
    mv a1, s1
    lw a2, gridBaseAddress
    jal setCharacterLocation

    j moveEnd

#################
# move the character left or right
#################
moveHorizontal:

    # load the character location
    la t0, character
    lbu s0, 0(t0)    # the row location of the character
    lbu s1, 1(t0)    # the column location of the character

    mv a0, s0
    add a1, s1, s11
    lw a2, gridBaseAddress
    jal getElemAndPosByCordinate
    
    # check if current location is a box
    li t0, 66 # B
    beq a0, t0, moveBoxHorizontal # if a0 == box
    li t0, 98 # b
    beq a0, t0, moveBoxHorizontal # if a0 == box on target

    j moveHorizontalEnd
moveBoxHorizontal:
    mv a0, s0
    add a1, s1, s11
    add a1, a1, s11
    lw a2, gridBaseAddress
    jal setBoxLocation
    beqz a0, moveEnd
    
    mv a0, s0
    add a1, s1, s11
    lw a2, gridBaseAddress
    jal setToSpaceByCordinate

    # check if the orignal box is on the target
    # If it is, then add one to the boxLeft
    mv a0, s0
    add a1, s1, s11
    lw a2, girdBackup
    jal getElemAndPosByCordinate
    li t4, 46 # .

    bne a0, t4, moveHorizontalEnd
    
    la t0, boxLeft
    lh t1, 0(t0)
    addi t1, t1, 1
    sh t1, 0(t0)
moveHorizontalEnd:
    mv a0, s0
    add a1, s1, s11
    lw a2, gridBaseAddress
    jal setCharacterLocation
############
moveEnd:
    li a0, 1 # move success
moveCharacterEnd:
    lw ra, 0(sp)
    lw s0, 4(sp)
    lw s1, 8(sp)
    lw s11, 12(sp)
    addi sp, sp, 16
    jr ra


############################################
# Reset the game board to the original state
#
# Arguments: none
# Return: none
############################################
resetGameBoard:
    addi sp, sp, -4
    sw ra, 0(sp)
    la t0, gridsize
    lbu t1, 0(t0) # load number of row to t1
    lbu t2, 1(t0) # load number of column to t2

    mul t0, t1, t2

    lw t1, gridBaseAddress
    lw t2, girdBackup

    li t3, 0
    whileLoopResetGameBoard:
        lbu t4, 0(t2)
        sb t4, 0(t1)
        addi t1, t1, 1
        addi t2, t2, 1
        addi t3, t3, 1
        blt t3, t0, whileLoopResetGameBoard
    
    # reset the character location
    la t0, characterStartPos
    lbu a0, 0(t0)
    lbu a1, 1(t0)

    la t0, character
    li t1, 0
    sb t0, 0(t0)
    sb t0, 1(t0)
    
    lw a2, gridBaseAddress
    jal setCharacterLocation

    # reset the box number
    lh t0, totalBox
    la t1, boxLeft
    sh t0, 0(t1)

    lw ra, 0(sp)
    addi sp, sp, 4
    jr ra

############################################
# Remove the unsolvable box
#
# Arguments: none
# Return: none
############################################
removeUnsolvableBox:
    addi sp, sp, -20
    sw ra, 0(sp)
    sw s0, 4(sp)
    sw s1, 8(sp)
    sw s2, 12(sp)
    sw s3, 16(sp)

    la t5, gridsize

    lbu s0, 0(t5) # load number of row to s0
    lbu s1, 1(t5) # load number of column to s1
    addi s0, s0, -1
    addi s1, s1, -1
    
    # s11[s2][s3] = s11 + (s2 * s1 + s3) 
    
    li s2, 2 # initialize row pointer s2
    whileLoopCheckRow:
        li s3, 2 # initialize column pointer s3
       
        whileLoopCheckCol:

            mv a0, s2
            mv a1, s3
            jal checkRandomPosIsSovble
            bne a0, zero, whileLoopCheckColEnd

            # remove the box
            mv a0, s2
            mv a1, s3
            lw a2, gridBaseAddress
            jal setToSpaceByCordinate
            mv a0, s2
            mv a1, s3
            lw a2, girdBackup
            jal setToSpaceByCordinate

            la t0, totalBox
            lh t1, 0(t0)
            addi t1, t1, -1
            sh t1, 0(t0)

        whileLoopCheckColEnd:
            addi s3, s3, 1 # column pointer ++
            
            blt s3, s1, whileLoopCheckCol # if s3 < number_of_columns, continue goto next the column


        addi s2, s2, 1 # row pointer ++
        blt s2, s0, whileLoopCheckRow # if s2 < number_of_rows, continue goto next the row
    
    lw ra, 0(sp)
    lw s0, 4(sp)
    lw s1, 8(sp)
    lw s2, 12(sp)
    lw s3, 16(sp)
    addi sp, sp, 20
    jr ra        


############################################
# Check if the random position is solvable
#
# Arguments: the row and column number of the character in a0, a1
# Return: 1 if the random position is solvable, 0 otherwise
############################################
checkRandomPosIsSovble:
    addi sp, sp, -12
    sw ra, 0(sp)
    sw s0, 4(sp)
    sw s1, 8(sp)
    
    mv s0, a0
    mv s1, a1

    # If there is no box then no need to check
    lw a2, gridBaseAddress
    jal getElemAndPosByCordinate
    li t0, 66
    bne a0, t0, posIsSovble

    # Now Check if the box is placed in any of the
    # following configurations (b is the box being placed):
    #   B                        B                         
    # B b   or     B b      or   b B          b B
    #                B                        B
    
    # check first two case
    mv a0, s0
    addi a1, s1, -1
    lw a2, gridBaseAddress
    jal getElemAndPosByCordinate
    li t0, 32
    beq a0, t0, checkSecondTwoCase
    
    addi a0, s0, -1
    mv a1, s1
    lw a2, gridBaseAddress
    jal getElemAndPosByCordinate
    li t0, 32
    bne a0, t0, posNotSovble
    addi a0, s0, 1
    mv a1, s1
    lw a2, gridBaseAddress
    jal getElemAndPosByCordinate
    li t0, 32
    bne a0, t0, posNotSovble
checkSecondTwoCase:
    mv a0, s0
    addi a1, s1, 1
    lw a2, gridBaseAddress
    jal getElemAndPosByCordinate
    li t0, 32
    beq a0, t0, posIsSovble
    
    addi a0, s0, -1
    mv a1, s1
    lw a2, gridBaseAddress
    jal getElemAndPosByCordinate
    li t0, 32
    bne a0, t0, posNotSovble
    addi a0, s0, 1
    mv a1, s1
    lw a2, gridBaseAddress
    jal getElemAndPosByCordinate
    li t0, 32
    bne a0, t0, posNotSovble
posIsSovble:
    li a0, 1
    j checkRandomPosIsSovbleEnd
posNotSovble:
    li a0, 0
checkRandomPosIsSovbleEnd:
    lw ra, 0(sp)
    lw s0, 4(sp)
    lw s1, 8(sp)
    addi sp, sp, 12
    jr ra

############################################
# Calculate the index of the element in the grid
# Note: this will using t0-t3
#
# Arguments: the row and column number of the element in a0, a1
# Return: the index of the element in the grid
############################################
calculateIdx:

    la t1, gridsize
    lbu t2, 1(t1)

    mul t3, a0, t2
    add t3, t3, a1

    mv a0, t3
    ret


############################################
# Set the element in the grid to space by the cordinate
#
# Arguments: the row and column number of the element in a0, a1
#            the base address of the grid in a2
# Return: none
############################################
setToSpaceByCordinate:
    addi sp, sp, -4
    sw ra, 0(sp)
    
    jal calculateIdx
    
    # lw t0, gridBaseAddress
    add a0, a0, a2

    li t3, 32
    sb t3, 0(a0)

    lw ra, 0(sp)
    addi sp, sp, 4
    ret

############################################
# Get the element and its addressin a given grid by the cordinate
#
# Arguments: the row and column number of the element in a0, a1
#            the base address of the grid in a2             
# Return: the element in the grid at the given row and column in a0
#         the element address in a1
############################################
getElemAndPosByCordinate:
    addi sp, sp, -8
    sw ra, 0(sp)
    sw s0, 4(sp)

    mv s0, a2 # store the base address of the grid

    jal calculateIdx
    add t0, a0, s0 # get the actual address of the element

    # Get element
    lbu a0, 0(t0)
    mv a1, t0

    lw ra, 0(sp)
    lw s0, 4(sp)
    addi sp, sp, 8
    ret

############################################
# Generate two random numbers between 
# 0 to a0 (exclusive) and 0 to a1 (exclusive) 
#
# Arguments: take two integer to the row and column of the gameboard
#            in a0, a1
# Return: two random number where 0 <= num1 < a0 and 0 <= num2 < a1
############################################
genRandomCordinate:
    addi sp, sp, -12
    sw ra, 0(sp)
    sw s0, 4(sp)
    sw s1, 8(sp)

    mv s1, a1

    jal LCGRandom
    mv s0, a0
    mv a0, s1
    
    jal LCGRandom
    mv t1, a0
    mv a0, s0
    mv a1, t1

    lw ra, 0(sp)
    lw s0, 4(sp)
    lw s1, 8(sp)
    addi sp, sp, 12
    jr ra

############################################
# Generate a random number between 0 (inclusive) to a0 (exclusive)
# Using the linear congruential generator algorithm [1].
# The algorithm is based on the LCG implementation used in cc65. [2]
#
# Reference:
# [1] Thomson, W. E. 1958. Linear congruential generator.
#     Retrieved from https://en.wikipedia.org/wiki/Linear_congruential_generator/.
# [2] Cadot, S. "rand.s". cc65. Retrieved from 
#     https://github.com/cc65/cc65/blob/06bb95d19788e3326738ee968b49dd11d18ca790/libsrc/common/rand.s/.
# 
# Arguments: an integer MAX in a0
# Return: A number from 0 (inclusive) to MAX (exclusive)
############################################
LCGRandom:
    mv t3, a0
    # seed = (a * seed + c) % modulus
    # t0: new seed
    # t1: temp reg
    lw t0, seed
    lw t1, a
    mul t0, t1, t0 # seed = a * seed
    
    lw t1, c
    add t0, t0, t1 # seed = seed + c
    
    lw t1, m
    remu t0, t0, t1 # seed = seed % modulus
    
    la t1, seed    # load the address of seed
    sw t0, 0(t1)   # store the new seed

    # Extract bits 22..8
    srli t0, t0, 8        # Right shift by 8 bits, now bit 22 is at position 14
    li t1, 0x7FFF         # Load 0x7FFF into t1 (15 bits)
    and t0, t0, t1        # Mask to extract lower 15 bits (bits 22..8 originally)

    # return seed % MAX
    mv a0, t0
    remu a0, a0, t3   # modulus on bottom bits
    jr ra


############################################
# Initial a new game board according to size
# with a given grid
#
# s0: store the gameboard at base address 0x10000000
# s1: row (0) and column (1) of the gameboard
# 88 (X) means wall
# 32 (space) means path
# 80 (P) means character
# 66 (B) means box
# 46 (.) means target
#
# Arguments: a0 is the base address of the grid
# Return: none
############################################
initGameBoard:

    addi sp, sp, -12
    sw ra, 0(sp)
    sw s0, 4(sp)
    sw s1, 8(sp)

    mv s0, a0
    la s1, gridsize

    lbu t0, 0(s1) # load number of row to t0
    lbu t1, 1(s1) # load number of column to t1
    
    # s0[t2][t3] = s0 + (t2 * t1 + t3) 
    
    li t2, 0 # initialize row pointer t2
    whileLoopInitBoard1:
        li t3, 0 # initialize column pointer t3
        mul t4, t2, t1 # t4 = row_index * number_of_columns
        add t4, t4, s0 # add the base address to get the actual address of the element
        whileLoopInitBoard2:
            # initialize the board

            # check if the location is an edge
            mv a0, t2
            mv a1, t3

            addi sp, sp, -4
            sb t0, 0(sp)
            jal checkIsEdge
            lbu t0, 0(sp)
            addi sp, sp, 4
            
            bne a0, zero, setWall # if a0 != 0 then setWall
            
            li t5, 32 # space
            j whileLoopInitBoard2End

            setWall:

                li t5, 88 # X
            
            whileLoopInitBoard2End:

                sb t5, 0(t4) # set the element in the board

                addi t3, t3, 1 # column counter ++
                addi t4, t4, 1 # move to the next element
                
                blt t3, t1, whileLoopInitBoard2 # if t3 < number_of_columns, continue to initialize the column

        addi t2, t2, 1 # row pointer ++
        blt t2, t0, whileLoopInitBoard1 # if t2 < number_of_rows, continue to initialize the row

    lw ra, 0(sp)
    lw s0, 4(sp)
    lw s1, 8(sp)
    addi sp, sp, 12
    jr ra


############################################
# Check if the location is an edge
#
# Arguments: the row and column number of the location in a0, a1
# Return: 1 if the location is an edge, 0 otherwise
############################################
checkIsEdge:
    la t6, gridsize

    beqz a0, checkIsEdgeTrue # if a0 == 0 then checkIsEdgeTrue
    beqz a1, checkIsEdgeTrue # if a1 == 0 then checkIsEdgeTrue

    lbu t0, 0(t6) # load the number of row to t0
    addi a0, a0, 1
    beq a0, t0, checkIsEdgeTrue # if a0 == t0 then checkIsEdgeTrue
    
    lbu t0, 1(t6) # load the number of column to t0
    addi a1, a1, 1
    beq a1, t0, checkIsEdgeTrue # if a1 == t0 then checkIsEdgeTrue
    
    li a0, 0
    jr ra
checkIsEdgeTrue:
    li a0, 1
    jr ra


############################################
# Set the character in the board at the given location
#    
# Arguments: the row and column number of the character in a0, a1
#            the base address of the grid in a2
# Return: 1 if the character is in a valid location, 0 otherwise
############################################
setCharacterLocation:
    addi sp, sp, -12
    sw ra, 0(sp)
    sw s0, 4(sp)
    sw s1, 8(sp)

    mv s0, a0
    mv s1, a1

    # character
    jal getElemAndPosByCordinate # element in a0, element address in a1

    # check if the new location is a free valid location
    li t3, 32   # space
    beq a0, t3, setCharacterLocationSeccess
    li t3, 46   # .
    beq a0, t3, setCharacterLocationSeccess

    li a0, 0
    j setCharacterLocationEnd
setCharacterLocationSeccess:
    addi sp, sp, -8
    sw s0, 0(sp)
    sw s1, 4(sp)

    li t4, 80 # P
    sb t4, 0(a1) # set the character in the board

    la t0, character
    lbu t1, 0(t0)
    beqz t1, setCharacterLocationSeccessEnd

    # set the old location to space or target
    la t0, character
    lbu s0, 0(t0)
    lbu s1, 1(t0)

    mv a0, s0
    mv a1, s1
    lw a2, gridBaseAddress
    jal setToSpaceByCordinate

    mv a0, s0
    mv a1, s1
    lw a2, girdBackup
    jal getElemAndPosByCordinate
    li t4, 46 # .
    bne a0, t4, setCharacterLocationSeccessEnd

    mv a0, s0
    mv a1, s1
    lw a2, gridBaseAddress
    jal setTargetLocation
setCharacterLocationSeccessEnd:
    lw s0, 0(sp)
    lw s1, 4(sp)
    addi sp, sp, 8
updateCharacterLocation:
    la t0, character
    sb s0, 0(t0) # record the row number for character
    sb s1, 1(t0) # record the column number for character

    li a0, 1
setCharacterLocationEnd:
    lw ra, 0(sp)
    lw s0, 4(sp)
    lw s1, 8(sp)
    addi sp, sp, 12
    jr ra


############################################
# Set the box in the board at the given location
#
# Arguments: the row and column number of the box in a0, a1
#            the base address of the grid in a2
# Return: 1 if the box is in a valid location, 0 otherwise
############################################
setBoxLocation:
    addi sp, sp, -4
    sw ra, 0(sp)

    jal getElemAndPosByCordinate # element in a0, element address in a1

    # check if the box is in a valid location
    li t3, 32   # space
    li t4, 66   # B
    beq a0, t3, setBoxLocationSeccess # if t2 == space (t3) then setBoxLocationSeccess

    li t3, 46   # .
    li t4, 98   # b (box on target)
    beq a0, t3, boxTouchTarget # if t2 == target (t3) then boxTouchTarget
    li a0, 0
    j setBoxLocationEnd
boxTouchTarget:
    la t0, boxLeft
    lh t1, 0(t0)
    addi t1, t1, -1
    sh t1, 0(t0)
setBoxLocationSeccess:
    # li t4, 66 # B
    sb t4, 0(a1) # set the box in the board
    li a0, 1
setBoxLocationEnd:
    lw ra, 0(sp)
    addi sp, sp, 4
    jr ra


############################################
# Set the target in the board at the given location
#
# Arguments: the row and column number of the target in a0, a1
#            the base address of the grid in a2
# Return: 1 if the target is in a valid location, 0 otherwise
############################################
setTargetLocation:
    addi sp, sp, -4
    sw ra, 0(sp)

    # target
    jal getElemAndPosByCordinate # element in a0, element address in a1

    # check if the target is in a valid location
    li t3, 32   # space
    beq a0, t3, setTargetLocationSeccess # if t2 == space (t3) then setTargetLocationSeccess
    li a0, 0
    j setTargetLocationEnd
setTargetLocationSeccess:
    li t4, 46 # .
    sb t4, 0(a1) # set the target in the board
    li a0, 1
setTargetLocationEnd:
    lw ra, 0(sp)
    addi sp, sp, 4
    jr ra


############################################
# Print the gameboard using the given grid
#
# Arguments: the base address of the grid in a0
# Return: none
############################################
printBoard:
    mv t6, a0
    la t5, gridsize

    lbu t0, 0(t5) # load number of row to t0
    lbu t1, 1(t5) # load number of column to t1
    
    # t6[t2][t3] = t6 + (t2 * t1 + t3) 
    
    li t2, 0 # initialize row pointer t2
    whileLoopPrintRow:
        li t3, 0 # initialize column pointer t3
        mul t4, t2, t1 # t4 = row_index * number_of_columns
        add t4, t4, t6 # add the base address to get the actual address of the element
        whileLoopPrintCol:

            lbu a0, 0(t4) # load the current element to a0
            li a7, 11 # system call number 11 to print character
            ecall # print the character

            li a0, 32 # space
            li a7, 11 # system call number 11 to print character
            ecall # print the space

            addi t3, t3, 1 # column pointer ++
            addi t4, t4, 1 # move to the next element
            
            blt t3, t1, whileLoopPrintCol # if t3 < number_of_columns, continue goto next the column

        li a0, 10 # new line
        li a7, 11 # system call number 11 to print character
        ecall # print the new line

        addi t2, t2, 1 # row pointer ++
        blt t2, t0, whileLoopPrintRow # if t2 < number_of_rows, continue goto next the row
    jr ra                        
