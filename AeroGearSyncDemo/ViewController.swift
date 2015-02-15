//
//  ViewController.swift
//  AeroGearSyncDemo
//
//  Created by Daniel Bevenius on 29/10/14.
//  Copyright (c) 2014 Daniel Bevenius. All rights reserved.
//

import UIKit
import AeroGearSync
import AeroGearSyncClient

class ViewController: UIViewController, UITextFieldDelegate {

    let backgroundQueue = NSOperationQueue()

    @IBOutlet var nameLabel: UILabel!
    @IBOutlet var profession: UITextField!
    @IBOutlet var hobby1: UITextField!
    @IBOutlet var hobby2: UITextField!
    @IBOutlet var hobby3: UITextField!
    @IBOutlet var hobby4: UITextField!
    @IBOutlet var connection: UIButton!
    var dirty = false

    let clientId = NSUUID().UUIDString
    let documentId = "12345"
    var content = Info(name: "Luke Skywalker",
        profession: "Jedi",
        hobbies: [
            Info.Hobby(desc: "Fighting the Dark Side"),
            Info.Hobby(desc: "Going into Tosche Station to pick up some power converters"),
            Info.Hobby(desc: "Kissing his sister"),
            Info.Hobby(desc: "Bulls eyeing Womprats on his T-16")
        ])

    private var syncClient: SyncClient<JsonPatchSynchronizer, InMemoryDataStore<JsonNode, JsonPatchEdit>>!

    override func viewDidLoad() {
        super.viewDidLoad()
        profession.delegate = self
        hobby1.delegate = self
        hobby2.delegate = self
        hobby3.delegate = self
        hobby4.delegate = self
        updateFields(content)

        let syncServerHost = NSBundle.mainBundle().objectForInfoDictionaryKey("SyncServerHost")! as String
        let syncServerPort = NSBundle.mainBundle().objectForInfoDictionaryKey("SyncServerPort")! as Int
        let engine = ClientSyncEngine(synchronizer: JsonPatchSynchronizer(), dataStore: InMemoryDataStore())
        syncClient = SyncClient(url: "ws://\(syncServerHost):\(syncServerPort)", syncEngine: engine)
        connect()
        println("ClientId=\(clientId)")
    }

    private func syncCallback(doc: ClientDocument<JsonNode>) {
        updateFieldsMainQueue(Info(dict:doc.content))
    }

    @IBAction func connection(button: UIButton) {
        let text = button.titleLabel!.text!
        if text == "Disconnect" {
            disconnect()
            connection.setTitle("Connect", forState:UIControlState.Normal)
        } else {
            connect()
            connection.setTitle("Disconnect", forState:UIControlState.Normal)
        }
    }

    override func viewWillDisappear(animated: Bool) {
        disconnect()
    }

    private func connect() {
        syncClient.connect()
        syncClient.addDocument(ClientDocument<JsonNode>(id: documentId, clientId: clientId, content: fieldsAsJson()), callback: syncCallback)
    }

    private func disconnect() {
        syncClient.disconnect()
    }

    private func updateFieldsMainQueue(content: Info) {
        NSOperationQueue.mainQueue().addOperationWithBlock() {
            self.updateFields(content)
            self.content = content;
        }
    }

    private func updateFields(content: Info) {
        self.nameLabel.text = content.name
        self.profession.text = content.profession
        self.hobby1.text = content.hobbies[0].desc
        self.hobby2.text = content.hobbies[1].desc
        self.hobby3.text = content.hobbies[2].desc
        self.hobby4.text = content.hobbies[3].desc
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    /**
    Should the textField in question give up focus.

    :param: textField the UITextField that is in focus
    :returns: Bool true so that the current field gives up focus
    */
    func textFieldShouldEndEditing(textField: UITextField!) -> Bool {
        return true
    }

    /**
    Hides the keyboard after return button has been pressed.
    This function will also perform a sync if the field in question
    was updated.

    :param: textField the UITextField that is in focus
    :returns: Bool true so that the keyboard is removed.
    */
    func textFieldShouldReturn(textField: UITextField!) -> Bool {
        sync(textField)
        return true
    }

    /**
    Called when focus moves from one textfield to another.
    This function will also perform a sync if the field in question
    was updated.

    :param: textField the UITextField that is in focus
    */
    @IBAction func editEnd(textField: UITextField) {
        sync(textField)
    }

    /**
    Detects when a field is being updated and takes note of this fact.
    This is later used to determine if a sync should be done or not.
    
    :param: textField the UITextField that is in focus
    */
    @IBAction func updates(sender: UITextField) {
        if !dirty {
            dirty = true
        }
    }

    private func sync(field: UITextField) {
        println("syncing...\(field.text)")
        let doc = ClientDocument<JsonNode>(id: documentId, clientId: clientId, content: fieldsAsJson())
        if dirty {
            backgroundQueue.addOperationWithBlock() {
                self.dirty = false
                self.syncClient.diffAndSend(doc)
            }
        }
    }

    private func fieldsAsJson() -> JsonNode {
        var info = JsonNode()
        
        info["name"] = nameLabel.text!
        info["profession"] = profession.text!
        
        var hobbies = Array<Dictionary<String, String>>()
        
        hobbies.append(["description" : hobby1.text!])
        hobbies.append(["description" : hobby2.text!])
        hobbies.append(["description" : hobby3.text!])
        hobbies.append(["description" : hobby4.text!])
        
        info["hobbies"] = hobbies
        
        return info
    }
}

