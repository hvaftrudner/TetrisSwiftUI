//
//  TetrisGameViewModel.swift
//  Tetris SwiftUI
//
//  Created by Kristoffer Eriksson on 2021-05-26.
//

import SwiftUI
import Combine

class TetrisGameViewModel: ObservableObject {
    
    @Published var tetrisGameModel = TetrisGameModel()
    
    //Passing values from gamemodel
    var numRows: Int {tetrisGameModel.numRows}
    var numCols: Int {tetrisGameModel.numCols}
    //Removed published before gameboard, you cant have a published computet property
    var gameBoard: [[TetrisGameSquare]] {
        var board = tetrisGameModel.gameBoard.map {$0.map(convertToSquare)}
        
        if let shadow = tetrisGameModel.shadow {
            for blockLocation in shadow.blocks {
                board[blockLocation.col + shadow.origin.col][blockLocation.row + shadow.origin.row] = TetrisGameSquare(color: getShadowColor(blocktype: shadow.blockType))
            }
        }
        
        if let tetromino = tetrisGameModel.tetromino {
            for blockLocation in tetromino.blocks {
                board[blockLocation.col + tetromino.origin.col][blockLocation.row + tetromino.origin.row] = TetrisGameSquare(color: getColor(blocktype: tetromino.blockType))
            }
        }
        
        return board
    }
    
    var lastRotateAngle: Angle?
    
    //All contruction in gameModel
    var lastMoveLocation: CGPoint?
    var anyCancellable: AnyCancellable?
    //using combine to make a custom publisher
    init(){
        anyCancellable = tetrisGameModel.objectWillChange.sink {
            self.objectWillChange.send()
        }
    }

    
    func convertToSquare(block: TetrisGameBlock?) -> TetrisGameSquare {
        return TetrisGameSquare(color: getColor(blocktype: block?.blockType))
    }
    
    func getColor(blocktype: BlockType?) -> Color {
        switch blocktype {
        case .i :
            return Color.tetrisBlue
        case .j :
            return Color.tetrisCyan
        case .l :
            return Color.tetrisGreen
        case .z :
            return Color.tetrisPurple
        case .s :
            return Color.tetrisOrange
        case .o :
            return Color.tetrisRandom
        case .t :
            return Color.tetrisRed
        case .none : // can use default here
            return Color.tetrisBlack
        }
    }
    
    func getShadowColor(blocktype: BlockType?) -> Color {
        switch blocktype {
        case .i :
            return Color.tetrisBlueShadow
        case .j :
            return Color.tetrisCyanShadow
        case .l :
            return Color.tetrisGreenShadow
        case .z :
            return Color.tetrisPurpleShadow
        case .s :
            return Color.tetrisOrangeShadow
        case .o :
            return Color.tetrisRandomShadow
        case .t :
            return Color.tetrisRedShadow
        case .none : // can use default here
            return Color.tetrisBlack
        }
    }
    
//    func squareClicked(row: Int, col: Int){
//
//        //Old logic
////        if gameBoard[col][row].color == Color.tetrisBlack {
////            gameBoard[col][row].color = Color.tetrisRed
////        } else {
////            gameBoard[col][row].color = Color.tetrisBlack
////        }
//
//        tetrisGameModel.blockClicked(col: col, row: row)
//    }
    
    func getMoveGesture() -> some Gesture {
        return DragGesture()
            .onChanged(onMoveChanged(value:))
            .onEnded(onMoveEnded(_:))
    }
    
    func getRotateGesture() -> some Gesture {
        let tap = TapGesture()
                    .onEnded({self.tetrisGameModel.rotateTetromino(clockWise: true)})
        
        let rotate = RotationGesture()
            .onChanged(onRotateChanged(value:))
            .onEnded(onRotateEnded(value:))
        
        return tap.simultaneously(with: rotate)
    }
    
    func onRotateChanged(value: RotationGesture.Value) {
        guard let start = lastRotateAngle else {
            lastRotateAngle = value
            return
        }
        
        let diff = value - start
        if diff.degrees > 10 {
            tetrisGameModel.rotateTetromino(clockWise: true)
            lastRotateAngle = value
            return
        } else if diff.degrees < -10 {
            tetrisGameModel.rotateTetromino(clockWise: false)
            lastRotateAngle = value
            return
        }
    }
    
    func onRotateEnded(value: RotationGesture.Value){
        lastRotateAngle = nil
    }
    
    func onMoveChanged(value: DragGesture.Value){
        guard let start = lastMoveLocation else {
            lastMoveLocation = value.location
            return
        }
        
        let xDiff = value.location.x - start.x
        if xDiff > 10 {
            print("moving right")
            let _ = tetrisGameModel.moveTetrominoRight()
            lastMoveLocation = value.location
            return
        }
        if xDiff < -10 {
            print("moving left")
            let _ = tetrisGameModel.moveTetrominoLeft()
            lastMoveLocation = value.location
            return
        }
        
        let yDiff = value.location.y - start.y
        if yDiff > 10 {
            print("moving down")
            let _ = tetrisGameModel.moveTetrominoDown()
            lastMoveLocation = value.location
            return
            
        }
        if yDiff < -10 {
            print("dropping")
            let _ = tetrisGameModel.dropTetromino()
            lastMoveLocation = value.location
            return
        }
    }
    func onMoveEnded(_: DragGesture.Value){
        lastMoveLocation = nil
    }
}

struct TetrisGameSquare {
    var color: Color
}
