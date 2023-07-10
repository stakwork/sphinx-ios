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
    
    @IBOutlet private var contentView: UIView!
    
    @IBOutlet weak var markdownLabel: UILabel!
    @IBOutlet weak var loadingWheel: UIActivityIndicatorView!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    private func setup() {
        Bundle.main.loadNibNamed("CodeShareView", owner: self, options: nil)
        addSubview(contentView)
        contentView.frame = self.bounds
        contentView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
    }
    

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
        markdownLabel.backgroundColor = UIColor.Sphinx.Body
        markdownLabel.numberOfLines = 0
        let markdownParser = MarkdownParser(customElements: [MarkdownSubreddit()])
        markdownParser.code.color = UIColor.green
        markdownParser.code.textBackgroundColor = UIColor.clear
        let markdown = "\(code)"
        markdownLabel.attributedText = markdownParser.parse(markdown)
    }
}


class MarkdownSubreddit: MarkdownLink {

  private static let regex = "(^|\\s|\\W)(/?r/(\\w+)/?)"

  override var regex: String {
    return MarkdownSubreddit.regex
  }

    override func match(_ match: NSTextCheckingResult,
                             attributedString: NSMutableAttributedString) {
        let subredditName = attributedString.attributedSubstring(from: match.range(at: 3)).string
    let linkURLString = "http://reddit.com/r/\(subredditName)"
    formatText(attributedString, range: match.range, link: linkURLString)
    addAttributes(attributedString, range: match.range, link: linkURLString)
  }

}
