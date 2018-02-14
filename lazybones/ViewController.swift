//
//  ViewController.swift
//  lazybones
//
//  Created by Brian Slack on 07/02/2018.
//  Copyright © 2018 Depicus Limited. All rights reserved.
//

import UIKit
import wakeonlan

class ViewController: UIViewController {
    
    let command = Commands()
    var broadcastConnection: UDPBroadcastConnection!
    var pskcode = "0000"
    var ipaddress = "192.168.0.1"
    
    @IBOutlet var frmMain: UIView!
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view, typically from a nib.
        if let ip = UserDefaults.standard.value(forKey: "ipaddress") as? String!
        {
            // we have an ip so no need to search
            print("we got ipaddress \(ip)")
            self.ipaddress = ip
            print("we got ipaddress \(ipaddress)")
        } else {
            broadcastConnection = UDPBroadcastConnection(port: 1900) { [unowned self] (ipAddress: String, port: Int, response: String?) -> Void in
                print("Received from \(ipAddress):\(port):\n\n\(String(describing: response))")
                UserDefaults.standard.setValue(ipAddress, forKey: "ipaddress")
                self.ipaddress = ipAddress
            }
            let buf = "M-SEARCH * HTTP/1.1\r\n" +
                "MAN: \"ssdp:discover\"\r\n" +
                "HOST: 239.255.255.250:1900\r\n" +
                "ST: urn:schemas-sony-com:service:X_Telepathy:1\r\n" +
            "MX: 3\r\n\r\n"
            broadcastConnection.sendBroadcast(buf)
        }
        
        // set user defaults
        
        if let psk = UserDefaults.standard.value(forKey: "pskcode") as? String
        {
            self.pskcode = psk
            print("we got psk code \(pskcode)")
        } else {
            self.pskcode = "0000"
            UserDefaults.standard.setValue("0000", forKey: "pskcode")
        }
        
        // loop buttons and round the endges
        for case let button as UIButton in self.view.subviews {
            button.layer.cornerRadius = 8
            button.layer.masksToBounds = true
        }
        
        let wol = wakeup()
        if (wol.wakeonlan(mac: "AC:9B:0A:F6:7A:1D")) {
            print("hello we are true")
        }

    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func btnPower(_ sender: UIButton) {
        sendCommand(command: "AAAAAQAAAAEAAAAVAw==")
    }
    
    @IBAction func btnMute(_ sender: UIButton) {
        sendCommand(command: "AAAAAQAAAAEAAAAUAw==")
    }
    @IBAction func btnVolumeUp(_ sender: UIButton) {
        sendCommand(command: "AAAAAQAAAAEAAAASAw==")
    }
    @IBAction func btnVolumeDown(_ sender: UIButton) {
        sendCommand(command: "AAAAAQAAAAEAAAATAw==")
    }
    @IBAction func btnTV(_ sender: UIButton) {
        sendCommand(command: "AAAAAQAAAAEAAAAkAw==")
    }
    
    @IBAction func btnAction(_ sender: UIButton) {
        print(sender.tag)
        var arrayofcommands = [command.zero, command.one, command.two, command.three, command.four, command.five, command.six, command.seven, command.eight, command.nine]
        let channel = String(sender.tag)
        let numberarray = channel.flatMap{Int(String($0))}
        for item in numberarray {
            print("Found \(item) arrayofcommands would be \(arrayofcommands[item])")
            sendCommand(command: arrayofcommands[item])
            usleep(80000) //will sleep for .08 seconds
        }
    }
    
    func sendCommand(command:String) {
        let url = URL(string: "http://\(ipaddress)/sony/IRCC")!
        print("url is set to \(url)")
        var request = URLRequest(url: url)
        request.setValue("application/xml", forHTTPHeaderField: "Content-Type")
        request.setValue(pskcode, forHTTPHeaderField: "X-Auth-PSK")
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
    
    func sendSSDP() {
        print("ssdp pressed");
        
        let buf = "M-SEARCH * HTTP/1.1\r\n" +
            "MAN: \"ssdp:discover\"\r\n" +
            "HOST: 239.255.255.250:1900\r\n" +
            "ST: ssdp:all\r\n" +
        "MX: 5\r\n\r\n"
        let INADDR_ANY = in_addr(s_addr: 0)
        let fd = socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP)
        var addr_in = sockaddr_in(sin_len: __uint8_t(MemoryLayout<sockaddr_in>.size), sin_family: sa_family_t(AF_INET), sin_port: htons(value: 1900), sin_addr: INADDR_ANY, sin_zero: (0,0,0,0, 0,0,0,0))
        inet_aton("239.255.255.250", &addr_in.sin_addr);
        
        buf.withCString { cstr -> Void in
            _ = withUnsafePointer(to: &addr_in) {
                
                let broadcastMessageLength = buf.lengthOfBytes(using: .isoLatin1)
                print("buffer size is set to \(broadcastMessageLength)")
                let p = UnsafeRawPointer($0).bindMemory(to: sockaddr.self, capacity: 1)
                var udpflag: UInt32 = 1;
                if setsockopt(fd, SOL_SOCKET, SO_BROADCAST, &udpflag, socklen_t(MemoryLayout.size(ofValue: udpflag))) == -1
                {
                    print("Failed to set socket \(strerror(errno))")
                }
                // Send the message cstr
                sendto(fd, buf.cString(using: .isoLatin1), broadcastMessageLength, 0, p, socklen_t(addr_in.sin_len))
            }
        }
    }
    
    private func htons(value: CUnsignedShort) -> CUnsignedShort {
        return (value << 8) + (value >> 8)
    }
    
}
