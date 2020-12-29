//
//  Extensions.swift
//  CONTRIBUTIONSExtension
//
//  Created by Bo-Young PARK on 12/28/20.
//

import Foundation

extension Array {
    func chunked(into size: Int) -> [[Element]] {
        stride(from: 0, to: count, by: size).map {
            Array(self[$0 ..< Swift.min($0 + size, count)])
        }
    }
    
    func element(at index: Int) -> Element? {
        index >= 0 && index < endIndex ? self[index] : nil
    }
}
