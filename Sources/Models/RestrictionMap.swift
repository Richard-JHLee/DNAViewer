//
//  RestrictionMap.swift
//  DNAViewer
//
//  Created by AI Assistant on 2025-10-18.
//

import Foundation

struct RestrictionMap {
    let hits: [RestrictionEnzyme: [RestrictionSite]]
    let totalSites: Int
    
    func sitesForEnzyme(_ enzyme: RestrictionEnzyme) -> Int {
        return hits[enzyme]?.count ?? 0
    }
}
