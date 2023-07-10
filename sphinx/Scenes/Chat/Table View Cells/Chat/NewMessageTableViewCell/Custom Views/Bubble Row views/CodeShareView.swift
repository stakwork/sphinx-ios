//
//  CodeShareView.swift
//  sphinx
//
//  Created by James Carucci on 7/10/23.
//  Copyright © 2023 sphinx. All rights reserved.
//

import UIKit
import MarkdownKit

class CodeShareView: UIView {
    
    @IBOutlet weak var markdownLabel: UILabel!
    

    func configureWith(
        codeShareContent: BubbleMessageLayoutState.CodeShareContent,
        codeShareData: MessageTableCellState.CodeShareData?
    ) {
        let loading = false//codeShareData == nil
        
//        loadingWheel.isHidden = !loading
//        webView.isHidden = loading
        
        if !loading {
//            loadingWheel.stopAnimating()
            
            self.loadMarkdownCode(code: codeShareContent.codeBlock)
            //self.testDownLibrary()
            //self.loadBotResponseContent(botHTMLContent:botHTMLContent)
            
            
        } else {
//            loadingWheel.startAnimating()
        }
    }
    
    
    func loadMarkdownCode(code:String){
        if(markdownLabel != nil){
            markdownLabel.numberOfLines = 0
            let markdownParser = MarkdownParser(customElements: [MarkdownSubreddit()])
            let markdown = "```\(code)```"
            markdownLabel.attributedText = markdownParser.parse(markdown)
        }
    }
}
