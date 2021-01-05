//
//  CalendarChart.swift
//  CONTRIBUTIONSExtension
//
//  Created by Bo-Young PARK on 12/28/20.
//

import SwiftUI

struct CalendarChart<Index: View>: View {
    let rows: Int = 7    //일주일 7일
    let columns: Int    //TODO: 추후 widget family update시 사용
    let spacing: CGFloat = 3.0
    let index: (Int, Int) -> Index
    
    var body: some View {
        HStack(alignment: .center, spacing: spacing) {
            ForEach(0..<columns, id: \.self) { row in
                VStack(alignment: .center, spacing: spacing) {
                    ForEach(0..<rows, id: \.self) { column in
                        index(row, column)
                    }
                }
            }
        }
    }
    
    init(columns: Int, @ViewBuilder index: @escaping (Int, Int) -> Index) {
        self.columns = columns
        self.index = index
    }
}
