//
//  TetrisGameView.swift
//  Tetris SwiftUI
//
//  Created by Kristoffer Eriksson on 2021-05-26.
//

import SwiftUI

struct TetrisGameView: View {
    
    //maybe use @StateObject here ?
    @ObservedObject var tetrisGame = TetrisGameViewModel()
    
    var body: some View {
        GeometryReader { geo in // (geometry: GeometryProxy) in
            self.drawBoard(boundingRect: geo.size)
        }
        .gesture(tetrisGame.getMoveGesture())
        .gesture(tetrisGame.getRotateGesture())
    }
    
    func drawBoard(boundingRect: CGSize) -> some View {
        let cols = self.tetrisGame.numCols
        let rows = self.tetrisGame.numRows
        
        //making a block the right size
        let blockSize = min(boundingRect.width / CGFloat(cols), boundingRect.height / CGFloat(rows))
        
        //setting padding on top and bottom
        let xOffset = (boundingRect.width - blockSize * CGFloat(cols)) / 2
        let yOffset = (boundingRect.height - blockSize * CGFloat(rows)) / 2
        
        //fixing performance, loading color before init
        let gameBoard = self.tetrisGame.gameBoard
        
        return ForEach(0...cols - 1, id: \.self){ col in //(col: Int) in
            ForEach(0...rows - 1, id: \.self){ row in //(row: Int) in
                
                //drawing rectangle, can use another shape or a standard CGSizes
                Path { path in
                    //Inverting positions of blocks to start (0:0) in left bottom corner
                    let x = xOffset + blockSize * CGFloat(col)
                    let y = boundingRect.height - yOffset - blockSize * CGFloat(row + 1)
                    
                    //yOffset draws from top to bottom, inverted
                    
                    let rect = CGRect(x: x, y: y, width: blockSize, height: blockSize)
                    path.addRect(rect)
                }
                .fill(gameBoard[col][row].color)
//                .onTapGesture {
//                    self.tetrisGame.squareClicked(row: row, col: col)
//                }
            }
        }
    }
}

struct TetrisGameView_Previews: PreviewProvider {
    static var previews: some View {
        TetrisGameView()
    }
}
