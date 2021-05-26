//
//  TetrisGameModel.swift
//  Tetris SwiftUI
//
//  Created by Kristoffer Eriksson on 2021-05-26.
//

import SwiftUI

enum BlockType : CaseIterable{
    case i, j, o, z, s, t, l
}

class TetrisGameModel: ObservableObject {
    var numRows: Int
    var numCols: Int
    @Published var gameBoard: [[TetrisGameBlock?]]
    @Published var tetromino: Tetromino?
    
    var timer: Timer?
    var gameSpeed: Double
    
    var shadow: Tetromino? {
        guard var lastShadow = tetromino else {return nil}
        var testShadow = lastShadow
        
        while(isValidTetromino(testTetromino: testShadow)){
            lastShadow = testShadow
            testShadow = lastShadow.moveBy(row: -1, col: 0)
        }
        
        return lastShadow
    }
    
    
    init(numRows: Int = 23, numCols: Int = 10){
        self.numRows = numRows
        self.numCols = numCols
        
        gameBoard = Array(repeating: Array(repeating: nil, count: numRows), count: numCols)
        //tetromino = Tetromino(origin: BlockLocation(row: 22, col: 4), blockType: .i)
        gameSpeed = 0.5
        resumeGame()
    }
    //replaces click func in viewmodel
//    func blockClicked(col: Int, row: Int){
//        print("Row: \(row), Col: \(col)")
//        
//        if gameBoard[col][row] == nil {
//            gameBoard[col][row] = TetrisGameBlock(blockType: BlockType.allCases.randomElement()!)
//        }
//    }
    
    func resumeGame(){
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: gameSpeed, repeats: true, block: runEngine)
    }
    
    func pauseGame(){
        timer?.invalidate()
    }
    
    func runEngine(timer: Timer){
        //check if we need to clear a line
        if clearLines() {
            print("line cleared")
            return
        }
        //Spawn a new block if we can
        guard tetromino != nil else {
            print("Spawning tetromino")
            //tetromino = Tetromino(origin: BlockLocation(row: 22, col: 4), blockType: .i)
            tetromino = Tetromino.createNewTetromino(numRows: numRows, numCols: numCols)
            if !isValidTetromino(testTetromino: tetromino!) {
                pauseGame()
                print("Game Over")
            }
            return
        }
        //move block down if we can
        if moveTetrominoDown() {
            print("Moving tetromino down")
            return
        }
        
        //place block if we can
        print("Placing tetromino")
        placeTetromino()
    }
    
    func moveTetrominoDown() -> Bool {
        return moveTetromino(colOffset: 0, rowOffset: -1)
    }
    
    func moveTetrominoRight() -> Bool {
        return moveTetromino(colOffset: 1, rowOffset: 0)
    }
    
    func moveTetrominoLeft() -> Bool {
        return moveTetromino(colOffset: -1, rowOffset: 0)
    }
    
    func dropTetromino() {
        while(moveTetrominoDown()) {}
    }
    
    func moveTetromino(colOffset: Int, rowOffset: Int) -> Bool {
        
        guard let currentTetromino = tetromino else {return false}
        
        let newTetromino = currentTetromino.moveBy(row: rowOffset, col: colOffset)
        if isValidTetromino(testTetromino: newTetromino){
            
            tetromino = newTetromino
            return true
        }
        
        return false
    }
    
    func rotateTetromino(clockWise: Bool) {
        guard let currentTetromino = tetromino else {return}
        
        let newTetrominoBase = currentTetromino.rotate(clockWise: clockWise)
        let kicks = currentTetromino.getKicks(clockWise: clockWise)
        
        for kick in kicks {
            let newTetromino = newTetrominoBase.moveBy(row: kick.row, col: kick.col)
            if isValidTetromino(testTetromino: newTetromino){
                tetromino = newTetromino
            }
        }
    }
    
    func isValidTetromino(testTetromino: Tetromino) -> Bool {
        for blocks in testTetromino.blocks {
            let row = testTetromino.origin.row + blocks.row
            if row < 0 || row >= numRows{return false}
            
            let col = testTetromino.origin.col + blocks.col
            if col < 0 || col >= numCols {return false}
            
            if gameBoard[col][row] != nil {return false}
        }
        return true
    }
    
    func placeTetromino(){
        guard let currentTetramino = tetromino else {return}
        
        for blocks in currentTetramino.blocks {
            let row = currentTetramino.origin.row + blocks.row
            if row < 0 || row >= numRows{continue}
            
            let col = currentTetramino.origin.col + blocks.col
            if col < 0 || col >= numCols {continue}
            
            gameBoard[col][row] = TetrisGameBlock(blockType: currentTetramino.blockType)
        }
        tetromino = nil
    }
    
    func clearLines() -> Bool {
        var newBoard: [[TetrisGameBlock?]] = Array(repeating: Array(repeating: nil, count: numRows), count: numCols)
        var boardUpdated = false
        var nextRowToCopy = 0
        
        for row in 0...numRows - 1 {
            var clearLine = true
            for column in 0...numCols - 1 {
                clearLine = clearLine && gameBoard[column][row] != nil
            }
            
            if !clearLine {
                for column in 0...numCols - 1 {
                    newBoard[column][nextRowToCopy] = gameBoard[column][row]
                }
                nextRowToCopy += 1
            }
            boardUpdated = boardUpdated || clearLine
        }
        
        if boardUpdated {
            gameBoard = newBoard
        }
        return boardUpdated
    }
    
    
}

struct TetrisGameBlock {
    var blockType: BlockType
}

struct Tetromino {
    var origin: BlockLocation
    var blockType: BlockType
    var rotation: Int
    
    var blocks: [BlockLocation] {
        return Tetromino.getBlocks(blockType: blockType, rotation: rotation)
    }
    
    func moveBy(row: Int, col: Int) -> Tetromino {
        let newOrigin = BlockLocation(row: origin.row + row, col: origin.col + col)
        return Tetromino(origin: newOrigin, blockType: blockType, rotation: rotation)
    }
    
    func rotate(clockWise: Bool) -> Tetromino {
        return Tetromino(origin: origin, blockType: blockType, rotation: rotation + (clockWise ? 1  : -1))
    }
    
    func getKicks(clockWise: Bool) -> [BlockLocation]{
        return Tetromino.getKicks(blockType: blockType, rotation: rotation, clockWise: clockWise)
    }
    
    static func getBlocks(blockType: BlockType, rotation: Int = 0) -> [BlockLocation]{
        let allBlocks = getAllBlocks(blockType: blockType)
        
        var index = rotation % allBlocks.count
        
        if (index < 0) {
            index += allBlocks.count
        }
        
        return allBlocks[index]
    }
    
    static func getKicks(blockType: BlockType, rotation: Int, clockWise: Bool) -> [BlockLocation]{
        let rotationCount = getBlocks(blockType: blockType).count
        
        var index = rotation % rotationCount
        if index < 0 {
            index += rotationCount
        }
        
        var kicks = getAllKicks(blockType: blockType)[index]
        if !clockWise {
            var counterKicks: [BlockLocation] = []
            for kick in kicks {
                counterKicks.append(BlockLocation(row: -1 * kick.row, col: -1 * kick.col))
            }
            kicks = counterKicks
        }
        return kicks
    }
    
    static func getAllKicks(blockType: BlockType) -> [[BlockLocation]] {
            switch blockType {
            case .o:
                return [[BlockLocation(row: 0, col: 0)]]
            case .i:
                return [[BlockLocation(row: 0, col: 0),
                         BlockLocation(row: 0, col: -2),
                         BlockLocation(row: 0, col: 1),
                         BlockLocation(row: -1, col: -2),
                         BlockLocation(row: 2, col: -1)],
                        
                        [BlockLocation(row: 0, col: 0),
                         BlockLocation(row: 0, col: -1),
                         BlockLocation(row: 0, col: 2),
                         BlockLocation(row: 2, col: -1),
                         BlockLocation(row: -1, col: 2)],
                        
                        [BlockLocation(row: 0, col: 0),
                         BlockLocation(row: 0, col: 2),
                         BlockLocation(row: 0, col: -1),
                         BlockLocation(row: 1, col: 2),
                         BlockLocation(row: -2, col: -1)],
                        
                        [BlockLocation(row: 0, col: 0),
                         BlockLocation(row: 0, col: 1),
                         BlockLocation(row: 0, col: -2),
                         BlockLocation(row: -2, col: 1),
                         BlockLocation(row: 1, col: -2)]
                ]
            case .j, .l, .s, .z, .t:
                return [[BlockLocation(row: 0, col: 0),
                         BlockLocation(row: 0, col: -1),
                         BlockLocation(row: 1, col: -1),
                         BlockLocation(row: 0, col: -2),
                         BlockLocation(row: -2, col: -1)],
                        
                        [BlockLocation(row: 0, col: 0),
                         BlockLocation(row: 0, col: 1),
                         BlockLocation(row: -1, col: 1),
                         BlockLocation(row: 2, col: 0),
                         BlockLocation(row: 1, col: 2)],
                        
                        [BlockLocation(row: 0, col: 0),
                         BlockLocation(row: 0, col: 1),
                         BlockLocation(row: 1, col: 1),
                         BlockLocation(row: -2, col: 0),
                         BlockLocation(row: -2, col: 1)],
                        
                        [BlockLocation(row: 0, col: 0),
                         BlockLocation(row: 0, col: -1),
                         BlockLocation(row: -1, col: -1),
                         BlockLocation(row: 2, col: 0),
                         BlockLocation(row: 2, col: -1)]
                ]
            }
        }
    
    static func getAllBlocks(blockType: BlockType) -> [[BlockLocation]] {
            switch blockType {
            case .i:
                return [[BlockLocation(row: 0, col: -1),
                         BlockLocation(row: 0, col: 0),
                         BlockLocation(row: 0, col: 1),
                         BlockLocation(row: 0, col: 2)],
                        
                        [BlockLocation(row: -1, col: 1),
                         BlockLocation(row: 0, col: 1),
                         BlockLocation(row: 1, col: 1),
                         BlockLocation(row: -2, col: 1)],
                        
                        [BlockLocation(row: -1, col: -1),
                         BlockLocation(row: -1, col: 0),
                         BlockLocation(row: -1, col: 1),
                         BlockLocation(row: -1, col: 2)],
                        
                        [BlockLocation(row: -1, col: 0),
                         BlockLocation(row: 0, col: 0),
                         BlockLocation(row: 1, col: 0),
                         BlockLocation(row: -2, col: 0)]]
            case .o:
                return [[BlockLocation(row: 0, col: 0), BlockLocation(row: 0, col: 1), BlockLocation(row: 1, col: 1), BlockLocation(row: 1, col: 0)]]
            case .t:
                return [[BlockLocation(row: 0, col: -1),
                         BlockLocation(row: 0, col: 0),
                         BlockLocation(row: 0, col: 1),
                         BlockLocation(row: 1, col: 0)],
                        
                        [BlockLocation(row: -1, col: 0),
                         BlockLocation(row: 0, col: 0),
                         BlockLocation(row: 0, col: 1),
                         BlockLocation(row: 1, col: 0)],
                        
                        [BlockLocation(row: 0, col: -1),
                         BlockLocation(row: 0, col: 0),
                         BlockLocation(row: 0, col: 1),
                         BlockLocation(row: -1, col: 0)],
                        
                        [BlockLocation(row: 0, col: -1),
                         BlockLocation(row: 0, col: 0),
                         BlockLocation(row: 1, col: 0),
                         BlockLocation(row: -1, col: 0)]]
            case .j:
                return [[BlockLocation(row: 1, col: -1),
                         BlockLocation(row: 0, col: -1),
                         BlockLocation(row: 0, col: 0),
                         BlockLocation(row: 0, col: 1)],
                        
                        [BlockLocation(row: 1, col: 0),
                         BlockLocation(row: 0, col: 0),
                         BlockLocation(row: -1, col: 0),
                         BlockLocation(row: 1, col: 1)],
                        
                        [BlockLocation(row: -1, col: 1),
                         BlockLocation(row: 0, col: -1),
                         BlockLocation(row: 0, col: 0),
                         BlockLocation(row: 0, col: 1)],
                        
                        [BlockLocation(row: 1, col: 0),
                         BlockLocation(row: 0, col: 0),
                         BlockLocation(row: -1, col: 0),
                         BlockLocation(row: -1, col: -1)]]
            case .l:
                return [[BlockLocation(row: 0, col: -1),
                         BlockLocation(row: 0, col: 0),
                         BlockLocation(row: 0, col: 1),
                         BlockLocation(row: 1, col: 1)],
                        
                        [BlockLocation(row: 1, col: 0),
                         BlockLocation(row: 0, col: 0),
                         BlockLocation(row: -1, col: 0),
                         BlockLocation(row: -1, col: 1)],
                        
                        [BlockLocation(row: 0, col: -1),
                         BlockLocation(row: 0, col: 0),
                         BlockLocation(row: 0, col: 1),
                         BlockLocation(row: -1, col: -1)],
                        
                        [BlockLocation(row: 1, col: 0),
                         BlockLocation(row: 0, col: 0),
                         BlockLocation(row: -1, col: 0),
                         BlockLocation(row: 1, col: -1)]]
            case .s:
                return [[BlockLocation(row: 0, col: -1),
                         BlockLocation(row: 0, col: 0),
                         BlockLocation(row: 1, col: 0),
                         BlockLocation(row: 1, col: 1)],
                        
                        [BlockLocation(row: 1, col: 0),
                         BlockLocation(row: 0, col: 0),
                         BlockLocation(row: 0, col: 1),
                         BlockLocation(row: -1, col: 1)],
                        
                        [BlockLocation(row: 0, col: 1),
                         BlockLocation(row: 0, col: 0),
                         BlockLocation(row: -1, col: 0),
                         BlockLocation(row: -1, col: -1)],
                        
                        [BlockLocation(row: 1, col: -1),
                         BlockLocation(row: 0, col: -1),
                         BlockLocation(row: 0, col: 0),
                         BlockLocation(row: -1, col: 0)]]
            case .z:
                return [[BlockLocation(row: 1, col: -1),
                         BlockLocation(row: 1, col: 0),
                         BlockLocation(row: 0, col: 0),
                         BlockLocation(row: 0, col: 1)],
                        
                        [BlockLocation(row: 1, col: 1),
                         BlockLocation(row: 0, col: 1),
                         BlockLocation(row: 0, col: 0),
                         BlockLocation(row: -1, col: 0)],
                        
                        [BlockLocation(row: 0, col: -1),
                         BlockLocation(row: 0, col: 0),
                         BlockLocation(row: -1, col: 0),
                         BlockLocation(row: -1, col: 1)],
                        
                        [BlockLocation(row: 1, col: 0),
                         BlockLocation(row: 0, col: 0),
                         BlockLocation(row: 0, col: -1),
                         BlockLocation(row: -1, col: -1)]]
            }
        }
    
    static func createNewTetromino(numRows: Int, numCols: Int) -> Tetromino {
        let blockType = BlockType.allCases.randomElement()!
        
        var maxRow = 0
        for block in getBlocks(blockType: blockType) {
            maxRow = max(maxRow, block.row)
            
        }
        
        let origin = BlockLocation(row: numRows - 1 - maxRow, col: (numCols - 1) / 2)
        
        return Tetromino(origin: origin, blockType: blockType, rotation: 0)
    }
}

struct BlockLocation {
    var row: Int
    var col: Int
}
