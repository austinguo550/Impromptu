//
//  GET+ViewController.swift
//  SceneDetector
//
//  Created by Austin Guo on 8/13/17.
//  Copyright © 2017 Ray Wenderlich. All rights reserved.
//

import Foundation

extension ViewController {
  
  // Austin: - Code added
  
  enum Genius {
    case SONG
    case LYRICS
  }
  
  // Returns a string (ultimately the lyrics)
  func httpGet(callType: Genius, query: String) {  // HTTP GET for Genius API
    // Create configuration object
    let config = URLSessionConfiguration.default
    // Authorization to use my API access token
    let headers = ["Authorization" : "Bearer \(Constants.OAUTHToken)"]
    config.httpAdditionalHeaders = headers
    let session = URLSession(configuration: config)
    
    var running = false
    
    // produce url, query or nonquery
    var urlComponents : URLComponents
    
    switch callType {
    case .SONG:
      urlComponents = URLComponents(string: "https://api.genius.com/search")!
      let queryItem = URLQueryItem(name: "q", value: query)
      urlComponents.queryItems = [queryItem]
    case .LYRICS:
      urlComponents = URLComponents(string: "https://api.genius.com" + query)!
    default:
      print("This get request is not supported yet")
      return
    }
    
    let url = urlComponents.url // type URL
    //print(String(describing: url))
    let task = session.dataTask(with: url!) {
      (data, response, error) in
      // handle response and error in closure, pass data off to helper methods iff successful
      if let httpResponse = response as? HTTPURLResponse {
        //print(String(describing: httpResponse))
        let dataString = String(data: data!, encoding: String.Encoding(rawValue: String.Encoding.utf8.rawValue))
        //print("Datastring \(dataString)")
        switch callType {
        case .SONG:
          self.extractSongTitle(data: data!)
        case .LYRICS:
          self.extractLyrics(data: data!)
        default:
          print("This get request is not supported yet")
          return
        }
      }
      running = false
    }
    
    running = true
    task.resume()
    
    while running {
      print("Waiting...")
      sleep(1)
    }

  }
  
  func extractSongTitle(data: Data) {
    var json = [String:Any]()
    do {
      json = try JSONSerialization.jsonObject(with: data, options: []) as! [String : Any]
    } catch let parseError as NSError {
      self.errorMessage += "JSONSerialization error: \(parseError.localizedDescription)\n"
      print(self.errorMessage)
      return
    }
    //print("JSON content \(json)")
    // Unwrap all successive layers of JSON
    guard let response = json["response"] as? [String: AnyObject], let hits = response["hits"] as? [AnyObject], let result = hits[0]["result"] as? [String: AnyObject] , let api_path = result["api_path"] else {
      self.errorMessage += "Dictionary does not contain api_path key"
      print(self.errorMessage)
      return
    }
    print("API Path is \(api_path)")
    httpGet(callType: Genius.LYRICS, query: api_path as! String)
    // set global
    self.song = api_path as! String
  }
  
  func extractLyrics(data: Data) {  // sets the lyrics field
    var lyrics: String?
    var json = [String:Any]()
    do {
      json = try JSONSerialization.jsonObject(with: data, options: []) as! [String: Any]
    } catch let parseError as NSError {
      self.errorMessage += "JSONSerialization error: \(parseError.localizedDescription)\n"
      print(self.errorMessage)
      return
    }
    //print("JSON content \(json)")
    // Unwrap all successive layers of JSON
    guard let response = json["response"] as? [String: AnyObject], let song = response["song"] as? [String: AnyObject], let path = song["path"] else {
      self.errorMessage += "Dictionary does not contain api_path key"
      print(self.errorMessage)
      return
    }
    print("Path is \(path)")
    // extract HTML page
    guard var html = extractHTML(path: "https://genius.com" + (path as! String)) else {
      print("HTML not extracted")
      return
    }
    //print("Raw HTML is \(html)")
    lyrics = processHTML(html: html)
    print("Lyrics are \(String(describing: lyrics))")
    self.lyrics = lyrics!
  }
  
  func extractHTML(path: String) -> String? {    // pass full path
    var returnValue : String?
    guard let url = URL(string: path) else {
      print("URL \(path) is not reachable")
      returnValue = "False"
      return returnValue
    }
    do {
      let html = try String(contentsOf: url, encoding: .ascii)
      //print("HTML \(html)")
      returnValue = html
    } catch let error {
      print("Error: \(error)")
    }
    return returnValue
  }
  
  func processHTML(html: String) -> String? {
    // extract lyrics class
    var regex: NSRegularExpression
    var range: NSRange
    do {
      regex = try NSRegularExpression(pattern: ".*(<div class=\"lyrics\".*?</div>).*", options: NSRegularExpression.Options.dotMatchesLineSeparators)
    } catch let error {
      print("Error \(error)")
      fatalError()
    }
    range = NSMakeRange(0, html.characters.count)
    print("HTML has \(html.characters.count) characters")
    guard var lyrics = regex.stringByReplacingMatches(in: html, options: [], range: range, withTemplate: "$1") as? String else {
      print("Can't unwrap lyrics")
      fatalError()
    }
    
    // remove script content
    do {
      regex = try NSRegularExpression(pattern: "<script.*?</script>", options: NSRegularExpression.Options.dotMatchesLineSeparators)
    } catch let error {
      print("Error \(error)")
      fatalError()
    }
    range = NSMakeRange(0, lyrics.characters.count)
    print("HTML now has \(lyrics.characters.count) characters")
    lyrics = regex.stringByReplacingMatches(in: lyrics, options: [], range: range, withTemplate: "")
    
    // remove tags
    do {
      regex = try NSRegularExpression(pattern: "<.*?>", options: NSRegularExpression.Options.dotMatchesLineSeparators)
    } catch let error {
      print("Error \(error)")
      fatalError()
    }
    range = NSMakeRange(0, lyrics.characters.count)
    print("HTML now has \(lyrics.characters.count) characters")
    lyrics = regex.stringByReplacingMatches(in: lyrics, options: [], range: range, withTemplate: "")
    return lyrics
  }
  
}
