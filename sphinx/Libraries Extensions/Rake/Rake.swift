// Swift implementation of Rapid Automatic Keyword Extraction
// As described in
// Rose, Stuart, Dave Engel, Nick Cramer, and Wendy Cowley.
// "Automatic keyword extraction from individual documents."
// Text Mining: Applications and Theory (2010): 1-20.
//
//
// This keyword extraction algorithm works by identifying parts of speech which typically
// will separate keywords, hereby refered to as stopwords.
// you then remove all instances of stopwords from the text, and tokenize based on what comes between them.
// This provides the list of keywords that appear in the text.
//

import Foundation
import Foundation.NSLinguisticTagger


//MARK: EXTENSIONS
extension String {
    func substring(range: NSRange) -> String {
        let botIndex = self.index(self.startIndex, offsetBy: range.location)
        let newRange = botIndex..<self.index(botIndex, offsetBy: range.length)
        return String(self[newRange])
   }
}

//Convert to NSLinguisticTagger
func isNumber(s: String) -> Bool {
    if let _ = Float(s) {
        return true
    } else if let _ = Int(s){
        return true
    }
    return false
}

//Import a stopWord csv
func importStopWords(stopWordFile: String) -> [String] {
    var stopWords = [String]()
    
    guard let filepath = Bundle.main.path(forResource: stopWordFile.replacingOccurrences(of: ".csv", with: ""), ofType: "csv") else {
        return []
    }
    
    let text = try? String(contentsOfFile: filepath, encoding: .utf8)
    if let words = text?.components(separatedBy: ", ") {
        stopWords = words
    }
    return stopWords
}


// Tokenize words.
// Currently uses regex to find non-words, replaces, and tokenizes between them
// WILL NOT SUPPORT all languages, mainly dialects who dont use whitespace
// Pre: Input text and minimum word size
// Post: Output separated words in an array
//
// Maybe rewrite using NSLinguisticTagger
// Maybe not for this one...
func separateWords(text : String, minWordSize : Int) -> [String] {
    let rePattern = "[^a-zA-Z0-9_\\+\\-/]+"
    var words = [String]()
    let regEx = try! NSRegularExpression(pattern: rePattern, options: [])
    let newSentence = regEx.stringByReplacingMatches(in: text, options: [], range: NSRange(location: 0, length: text.count), withTemplate: " | ")
    let newWords = newSentence.components(separatedBy:  " | ")
    for word in newWords {
        if word.count > minWordSize && word != " " && isNumber(s: word) == false {
            words.append(word)
        }
    }
    //print("separateWords turned \(text) into \(words)")
    return words
}

// Split text into sentences


func splitSentences(text: String) -> [String] {
    var sentences = [String]()
    
    // Update if NSLinguisticTagScheme can stop throwing bug
    if #available(macOS 10.13, *){
        let tagSchemes : [NSLinguisticTagScheme] = [ .tokenType]
        let tagger = NSLinguisticTagger(tagSchemes: tagSchemes, options: 0)
        let options : NSLinguisticTagger.Options = [ .omitPunctuation, .omitWhitespace]
        tagger.string = text
        let range = NSRange(location: 0, length: text.utf16.count)
        tagger.enumerateTags( in: range, unit: .sentence, scheme: .tokenType, options: options, using: { tag, tokenRange, stop in
            let token = (text as NSString).substring(with: tokenRange)
            sentences.append(token)
        })
    
    } else {
        // Fallback on earlier versions

        text.enumerateSubstrings(in: text.startIndex..<text.endIndex, options: .bySentences, { substring, substringRange, enclosingRange, stop in
            sentences.append(substring!)
        })
    }
    return sentences
}

// Pre: Input a string array consisting of the chosen stopwords
// Post: Outputs a string consisting of a constructed regex pattern
// to find all stopWords
func buildStopWordRegex(stopWords : [String]) -> String {
    var stopWordRegexList = [String]()
    var wordRegex = ""
    for word in stopWords {
        wordRegex = "\\b\(word)(?![\\w-])"
        stopWordRegexList.append(wordRegex)
    }
    return stopWordRegexList.joined(separator: " | ")
}


// Separates tokens based on where the occurances of stopwords are.
// Removes stopwords and splits inbetween
// Pre: Input a string array of sentences, and the stopword RegexPattern
// Post: Output a String Array consisting of keywords for the passage
func generateCandidateKeywords(sentenceList: [String], stopwordRegexPattern : String) -> [String]{
    var phraseList = [String]()
    let regEx = try! NSRegularExpression(pattern: stopwordRegexPattern, options: .caseInsensitive)
    for sentence in sentenceList {
        let newSentence = regEx.stringByReplacingMatches(in: sentence, options: [], range: NSRange(location: 0, length: sentence.count), withTemplate: " | ")
        let words = newSentence.components(separatedBy:  " | ")
        for word in words {
            if word != "" && word != " " {
                phraseList.append(word)
            }
        }
    }
    return phraseList
}


// Calculate word scores for input tokens
// These scores are used to give a value to each keyword
// Pre: Tokenized list of keywords
// Post: Value of each word
func calculateWordScores(phraseList:[String]) -> Dictionary<String, Double> {
    var wordFrequency = Dictionary<String, Double>() // Return Dict
    var wordDegree = Dictionary<String, Double>() // Storage for individual word scores
    for phrase in phraseList { // Can either be a single word, or a string of words that represents a keyword
        let wordList = separateWords(text: phrase, minWordSize: 0) // split phrase. Use separateWords to avoid iterating through chars
        let wordListDegree = Double(wordList.count - 1) // Number of Words in keyword
        for word in wordList {
            //print("This word in phraseList is \(word)")
            if wordFrequency[word] == nil{
                wordFrequency.updateValue(0.0, forKey: word)
            }
            wordFrequency.updateValue(wordFrequency[word]! + 1, forKey: word)
            if wordDegree[word] == nil {
                wordDegree.updateValue(0.0, forKey: word)
            }
            wordDegree.updateValue(wordDegree[word]! + wordListDegree, forKey: word)
        }
    }
    for (key, value) in wordFrequency {
        wordDegree.updateValue(wordDegree[key]! + value, forKey: key)
    }
    
    var wordScore = Dictionary<String, Double>()
    for (key, value) in wordFrequency{
        if wordScore[key] == nil {
            wordScore.updateValue(0.0, forKey: key)
        }
        wordScore.updateValue(wordDegree[key]! / value * 1.0, forKey: key)
        //print("updating WordScore for \(key) with value \(wordDegree[key]! / value * 1.0)")
    }
    return wordScore
}


// Assign scores to keywords
// Pre: Have string array consisting of keywords, and a wordScore Dict consisting of scores for the different words that occur in the keywords
// Post: Dict consisting of keywords, and the scores associated to them
func generateCandidateKeywordScores(phraseList: [String], wordScore: Dictionary<String, Double>) -> Dictionary<String, Double> {
    var keywordCandidates = Dictionary<String, Double>()
    for phrase in phraseList {
        if keywordCandidates[phrase] == nil {
            keywordCandidates.updateValue(0.0, forKey: phrase)
        }
        let wordList = separateWords(text: phrase, minWordSize: 0)
        var candidateScore = 0.0
        for word in wordList {
            candidateScore += wordScore[word]!
        }
        keywordCandidates.updateValue(candidateScore, forKey: phrase)
    }
    return keywordCandidates
}

struct Rake {
    var stopWords = [String]()
    var stopWordsPattern = ""
    
    init(){
        stopWords = importStopWords(stopWordFile: "csvStopList.csv")
        stopWordsPattern = buildStopWordRegex(stopWords: stopWords)
    }
    
    func run(text: String) -> Dictionary<String, Double> {
        let sentenceList = splitSentences(text: text)
        let phraseList = generateCandidateKeywords(sentenceList: sentenceList, stopwordRegexPattern: stopWordsPattern)
        let wordScores = calculateWordScores(phraseList: phraseList)
        let keywordCandidates = generateCandidateKeywordScores(phraseList: phraseList, wordScore: wordScores)
        return keywordCandidates
    }
}









