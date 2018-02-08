//
//  ViewController.swift
//  lazybones
//
//  Created by Brian Slack on 07/02/2018.
//  Copyright © 2018 Depicus Limited. All rights reserved.
//

import UIKit
import wakeonlan
//import Commands

class ViewController: UIViewController {
    
    let command = Commands()

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        let wol = wakeup()
        if (wol.wakeonlan(mac: "AC:9B:0A:F6:7A:1D")) {
            NSLog("hello we are true")
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func btnE4(_ sender: Any) {
        NSLog("tuning to E4")
        sendCommand(command: command.two)
        sendCommand(command: command.five)
    }
    
    @IBAction func btnFilm4(_ sender: Any) {
        sendCommand(command: command.two)
        sendCommand(command: command.nine)
    }
    
    @IBAction func btnAction(_ sender: UIButton) {
        print(sender.tag)
        var arrayofcommands = [command.zero, command.one, command.two, command.three, command.four, command.five, command.six, command.seven, command.eight, command.nine]

        let channel = String(sender.tag)
        let numberarray = channel.flatMap{Int(String($0))}
        for item in numberarray {
            print("Found \(item) arrayofcommands would be \(arrayofcommands[item])")
            sendCommand(command: arrayofcommands[item])
        }
    }
    
    func sendCommand(command:String) {
        let url = URL(string: "http://192.168.43.201/sony/IRCC")!
        var request = URLRequest(url: url)
        request.setValue("application/xml", forHTTPHeaderField: "Content-Type")
        request.setValue("0000", forHTTPHeaderField: "X-Auth-PSK")
        request.setValue("\"urn:schemas-sony-com:service:IRCC:1#X_SendIRCC\"", forHTTPHeaderField: "SOAPACTION")
        request.setValue("TVSideview/2.0.1 CFNetwork/672.0.8Darwin/14.0.0", forHTTPHeaderField: "User-Agent")
        request.httpMethod = "POST"
        
        var xml = "<?xml version=\"1.0\"?>"
        xml += "<s:Envelope xmlns:s=\"http://schemas.xmlsoap.org/soap/envelope/\" s:encodingStyle=\"http://schemas.xmlsoap.org/soap/encoding/\">"
        xml += "<s:Body>"
        xml += "<u:X_SendIRCC xmlns:u=\"urn:schemas-sony-com:service:IRCC:1\">"
        xml += "<IRCCCode>\(command)</IRCCCode>"
        xml += "</u:X_SendIRCC>"
        xml += "</s:Body>"
        xml += "</s:Envelope>"

        request.httpBody = xml.data(using: .utf8)
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                print("error= \(String(describing: error))")
                return
            }
            if let httpStatus = response as? HTTPURLResponse, httpStatus.statusCode != 200 {
                print("statusCode should be 200, but is \(httpStatus.statusCode)")
                print("response = \(String(describing: response))")
            }
            let responseString = String(data: data, encoding: .utf8)
            print("responseString = \(String(describing: responseString))")
        }
        task.resume()
    }
    
}

