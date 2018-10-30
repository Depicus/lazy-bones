//
//  wakeup.swift
//  wakeonlan
//
//  Created by Brian Slack on 07/02/2018.
//  Copyright © 2018 Depicus Limited. All rights reserved.
//

import UIKit

public class wakeup: NSObject {

    public func wakeonlan(mac:String) -> Bool {
        print("wake up button pressed");
        var macaddress = mac
        macaddress = macaddress.replacingOccurrences(of: "-", with: "")
        macaddress = macaddress.replacingOccurrences(of: " ", with: "")
        macaddress = macaddress.replacingOccurrences(of: ":", with: "")
        macaddress = macaddress.replacingOccurrences(of: ".", with: "")
        print("Mac address is \(macaddress) after stripping and \(String(describing: macaddress.count)) long")
        if macaddress.count != 12 {
            return false
        }
        var buf = ""
        for x in 0..<6 {
            var dec = UInt32()
            let hexString = "FF"
            let scan = Scanner(string: hexString)
            if scan.scanHexInt32(&dec) {
                buf += String(format: "%C", dec)
            }
            else {
                print("No value at %i", x)
            }
        }
        //print("Swift Buffer is set to \(buf) and MAC is \(macaddress)")
        for _ in 0..<16 {
            for x in stride(from: 0, through: 10, by: 2) {
                var dec = uint()
                let hexString = macaddress as NSString
                let parthexString = hexString.substring(with: NSRange(location: x, length: 2))
                let scan = Scanner(string: parthexString as String)
                if scan.scanHexInt32(&dec) {
                    buf += String(format: "%C", dec)
                    //print("HexString is \(hexString) and the buffer is \(buf) \r\n")
                }
                else {
                    print("No dec value is scanned.")
                }
            }
        }
        //print("Finally buffer is set to \(buf)")
        //print("Buffer size is \(buf.lengthOfBytes(using: .isoLatin1))")
        
        let INADDR_ANY = in_addr(s_addr: 0)
        let fd = socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP)
        var addr_in = sockaddr_in(sin_len: __uint8_t(MemoryLayout<sockaddr_in>.size), sin_family: sa_family_t(AF_INET), sin_port: htons(value: 4343), sin_addr: INADDR_ANY, sin_zero: (0,0,0,0, 0,0,0,0))
        inet_aton("255.255.255.255", &addr_in.sin_addr);
        
        /*
         withUnsafeMutablePointer(to: &nc) {
         dgetrf_($0, $0, &matrix, $0, &ipiv, &info)
         }
 */
        /*buf.withCString { cstr -> Void in
            _ = withUnsafePointer(to: &addr_in) {
                
                let broadcastMessageLength = buf.lengthOfBytes(using: .isoLatin1) //    Int(strlen(buf) + 1) //Int(strlen(cstr) + 1)
                print("buffer size is set to \(broadcastMessageLength)")
                let p = UnsafeRawPointer($0).bindMemory(to: sockaddr.self, capacity: 1)                
                var udpflag: UInt32 = 1;
                if setsockopt(fd, SOL_SOCKET, SO_BROADCAST, &udpflag, socklen_t(MemoryLayout.size(ofValue: udpflag))) == -1
                {
                    print("Failed to set socket \(String(describing: strerror(errno)))")
                }
                // Send the message cstr
                sendto(fd, buf.cString(using: .isoLatin1), broadcastMessageLength, 0, p, socklen_t(addr_in.sin_len))
            }
        }*/
        return true
    }
    
    private func htons(value: CUnsignedShort) -> CUnsignedShort {
        return (value << 8) + (value >> 8)
    }

    
}
