//
//  BotResponseView.swift
//  sphinx
//
//  Created by Tomas Timinskas on 05/06/2023.
//  Copyright © 2023 sphinx. All rights reserved.
//

import UIKit
import WebKit
import Down
import MarkdownKit


class BotResponseView: UIView {

    @IBOutlet private var contentView: UIView!
    
    @IBOutlet weak var markdownLabel: UILabel!
    @IBOutlet weak var webView: WKWebView!
    @IBOutlet weak var loadingWheel: UIActivityIndicatorView!
    
    let kWebViewContentPrefix = "<head><meta name=\"viewport\" content=\"width=device-width, height=device-height, shrink-to-fit=YES\"></head><body style=\"font-family: 'Roboto', sans-serif; color: %@; margin:0px !important; padding:0px!important; background: %@;\"><div id=\"bot-response-container\" style=\"background: %@;\">"
    let kWebViewContentSuffix = "</div></body>"
    
    let kDocumentReadyJSCommand = "document.readyState"
    let kGetContainerJSCommand = "document.getElementById(\"bot-response-container\").clientHeight"
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }

    private func setup() {
        Bundle.main.loadNibNamed("BotResponseView", owner: self, options: nil)
        addSubview(contentView)
        contentView.frame = self.bounds
        contentView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        
        webView.isUserInteractionEnabled = false
        webView.scrollView.isScrollEnabled = false
        webView.scrollView.contentInsetAdjustmentBehavior = .never
    }
    
    func configureWith(
        botHTMLContent: BubbleMessageLayoutState.BotHTMLContent,
        botWebViewData: MessageTableCellState.BotWebViewData?
    ) {
        let loading = botWebViewData == nil
        
        loadingWheel.isHidden = !loading
        webView.isHidden = loading
        
        if !loading {
            loadingWheel.stopAnimating()
            
            self.testMarkdownKit()
            //self.testDownLibrary()
            //self.loadBotResponseContent(botHTMLContent:botHTMLContent)
            
            
        } else {
            loadingWheel.startAnimating()
        }
    }
    
    func loadBotResponseContent(botHTMLContent: BubbleMessageLayoutState.BotHTMLContent){
        let backgroundColor = UIColor(cgColor: UIColor.Sphinx.ReceivedMsgBG.resolvedCGColor(with: self)).toHexString()
        let textColor = UIColor(cgColor: UIColor.Sphinx.Text.resolvedCGColor(with: self)).toHexString()

        let contentPrefix = String(format: kWebViewContentPrefix, textColor, backgroundColor, backgroundColor)
        let messageContent = botHTMLContent.html
        let content = "\(contentPrefix)\(messageContent)\(kWebViewContentSuffix)"

        let _ = webView.loadHTMLString(content, baseURL: Bundle.main.bundleURL)
    }
    
    func testMarkdownKit(){
        self.webView.isHidden = true
        
        markdownLabel.numberOfLines = 0
        let markdownParser = MarkdownParser(customElements: [MarkdownSubreddit()])
        let markdown = "**/r/iosprogramming** can be *markdown* as well! ```print('Hello World!');```"
        markdownLabel.attributedText = markdownParser.parse(markdown)
    }
    
    func testDownLibrary(){
        let backgroundColor = UIColor(cgColor: UIColor.Sphinx.ReceivedMsgBG.resolvedCGColor(with: self)).toHexString()
        //let messageContent = botHTMLContent.html
        let textColor = UIColor(cgColor: UIColor.Sphinx.Text.resolvedCGColor(with: self)).toHexString()
        let contentPrefix = String(format: kWebViewContentPrefix, textColor, backgroundColor, backgroundColor)
        let content = "```\nweenis();\n```"//"\(contentPrefix)\(messageContent)\(kWebViewContentSuffix)"
        setupMarkdownView(content: content)
    }
    
    func setupMarkdownView(content:String){
        do{
            let dv = try DownView(frame: self.bounds, markdownString: content,templateBundle: nil)
            let bubbleRadius = self.layer.cornerRadius
            dv.layer.cornerRadius = bubbleRadius
            self.layer.cornerRadius = bubbleRadius
            for view in dv.subviews{
                if let valid_view = view as? UIView{
                    let bubbleRadius = self.layer.cornerRadius
                    valid_view.backgroundColor = UIColor.clear
                    valid_view.layer.cornerRadius = bubbleRadius
                }
            }
            dv.navigationDelegate = self
            self.addSubview(dv)
        }
        catch let error{
            print(error)
        }
    }
    
    func styleView(webView:WKWebView,fontSize:String,fontColor:String,bubbleColor:String){
        let fontChangeJS = """
        code = document.querySelectorAll('.hljs');
          code.forEach((p) => {
            p.style.fontSize = "\(fontSize)px" ;
          });
        paragraphs = document.querySelectorAll('p');
          paragraphs.forEach((p) => {
            p.style.fontSize = "\(fontSize)px" ;
            p.style.color = "\(fontColor)";
          })
        document.body.style.backgroundColor = "\(bubbleColor)";
        """
        
        webView.evaluateJavaScript(fontChangeJS) {(result, error) in
            guard error == nil else {
                print(error!)
                return
            }
            
            print(String(describing: result))
        }
    }

}


extension BotResponseView : WKNavigationDelegate{
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        //printWebViewHTML(webView: webView)//for debug
        styleView(webView: webView, fontSize: "10", fontColor: "#FFFFFF", bubbleColor: "#466085")
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
