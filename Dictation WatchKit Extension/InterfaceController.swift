//
//  InterfaceController.swift
//  Dictation WatchKit Extension
//
//  Created by Stuart Varrall on 18/06/2015.
//  Copyright © 2015 Stuart Varrall. All rights reserved.
//

import WatchKit
import Foundation


class InterfaceController: WKInterfaceController {

    var previousDictation:NSURL?
    
    @IBOutlet var dictationTable: WKInterfaceTable!
    
    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
        
        // Configure interface objects here.
    }

    @IBAction func dictateMenuAction() {
        newDictatation()
    }
    
    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        setupTable()
        super.willActivate()
    }

    func setupTable() {
        dictationTable.setNumberOfRows(previousDictations().count, withRowType: "Dictation Row")
        
        for (index, dictationUrl) in previousDictations().enumerate() {
            if let row = dictationTable.rowControllerAtIndex(index) as? DictationRow {
                row.name.setText(dictationUrl.lastPathComponent)
                row.timeAgo.setDate(NSDate().dateByAddingTimeInterval(Double(-60*index)))

            }
        }
    }
    
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }

    func playAction(playUrl:NSURL?) {
        if let url = playUrl {
            
            let options = [WKMediaPlayerControllerOptionsAutoplayKey: true]
            
            presentMediaPlayerControllerWithURL(url, options: options, completion: { (didPlayToEnd:Bool, endTime:NSTimeInterval, error:NSError?) -> Void in
                if didPlayToEnd {
                    print("completed playing")
                } else {
                    print("played until \(endTime)")
                }
            })
        } else {
            print("nothing to play")
        }
    }
    
    
    override func table(table: WKInterfaceTable, didSelectRowAtIndex rowIndex: Int) {
        playAction(previousDictations()[rowIndex])
    }
    
    func newDictatation() {
        
        let directory = NSFileManager.defaultManager().containerURLForSecurityApplicationGroupIdentifier("group.fpstudios.dictation")
        let timeAtRecording = NSDate.timeIntervalSinceReferenceDate()
        let recordingName = "recording-\(timeAtRecording).mp4"
        
        
        if let outputURL = directory?.URLByAppendingPathComponent(recordingName) {
            presentAudioRecordingControllerWithOutputURL(outputURL, preset: WKAudioRecordingPreset.NarrowBandSpeech, maximumDuration: 300, actionTitle: nil) { (didSave:Bool, error:NSError?) -> Void in
                if didSave {
                    print("Saved Audio")
                    
                    let extensionDirectory = NSFileManager.defaultManager().URLsForDirectory(NSSearchPathDirectory.DocumentDirectory, inDomains: NSSearchPathDomainMask.UserDomainMask).first
                    
                    if let outputExtensionURL = extensionDirectory?.URLByAppendingPathComponent(recordingName) {
//                        let success:Bool?
                        
                        do {
                            try NSFileManager.defaultManager().moveItemAtURL(outputURL, toURL: outputExtensionURL)
                            self.previousDictation = outputURL
                            print("moved audio")
                        }
                        catch {
                            print("somethign went wrong moving file")
                        }
                    }
                }
                if error != nil{
                    print(error?.localizedDescription)
                }
            }
        } else {
            print("URL ERROR")
        }
    }
    
    func previousDictations() -> [NSURL] {
        
        var dicationURLs: [NSURL] = []
        
        let defaultManager = NSFileManager.defaultManager()
        
        if let directory = defaultManager.URLsForDirectory(NSSearchPathDirectory.DocumentDirectory, inDomains: NSSearchPathDomainMask.UserDomainMask).first {
        
            let dictationEnumerator = defaultManager.enumeratorAtURL(directory, includingPropertiesForKeys: [NSURLNameKey], options: NSDirectoryEnumerationOptions.SkipsHiddenFiles, errorHandler: nil)
            
            while let url = dictationEnumerator?.nextObject() as? NSURL {
                if url.lastPathComponent?.pathExtension == "mp4" {
                    dicationURLs.append(url)
                }
            }
        }
        
        return dicationURLs
    }
}
