//
//  Array.swift
//  sphinx
//
//  Created by Tomas Timinskas on 04/11/2022.
//  Copyright © 2022 sphinx. All rights reserved.
//

import Foundation

extension Array {
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0 ..< Swift.min($0 + size, count)])
        }
    }
    
    func subarray(size: Int) -> [Element] {
        return Array(self[0 ..< Swift.min(size, count)])
    }
    
    func unique(selector: (Element, Element) -> Bool) -> Array<Element> {
        return reduce(Array<Element>()){
            if let last = $0.last {
                return selector(last,$1) ? $0 : $0 + [$1]
            } else {
                return [$1]
            }
        }
    }
}
