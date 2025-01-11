//
//  RNIpSecVpn.swift
//  RNIpSecVpn
//
//  Created by Sina Javaheri on 25/02/1399.
//  Copyright © 1399 AP Sijav. All rights reserved.
//

import Foundation
import NetworkExtension
import Security



// Identifiers
let serviceIdentifier = "MySerivice"
let userAccount = "authenticatedUser"
let accessGroup = "MySerivice"

// Arguments for the keychain queries
var kSecAttrAccessGroupSwift = NSString(format: kSecClass)

let kSecClassValue = kSecClass as CFString
let kSecAttrAccountValue = kSecAttrAccount as CFString
let kSecValueDataValue = kSecValueData as CFString
let kSecClassGenericPasswordValue = kSecClassGenericPassword as CFString
let kSecAttrServiceValue = kSecAttrService as CFString
let kSecMatchLimitValue = kSecMatchLimit as CFString
let kSecReturnDataValue = kSecReturnData as CFString
let kSecMatchLimitOneValue = kSecMatchLimitOne as CFString
let kSecAttrGenericValue = kSecAttrGeneric as CFString
let kSecAttrAccessibleValue = kSecAttrAccessible as CFString

class KeychainService: NSObject {
    func save(key: String, value: String) {
        let keyData: Data = key.data(using: String.Encoding(rawValue: String.Encoding.utf8.rawValue), allowLossyConversion: false)!
        let valueData: Data = value.data(using: String.Encoding(rawValue: String.Encoding.utf8.rawValue), allowLossyConversion: false)!

        let keychainQuery = NSMutableDictionary()
        keychainQuery[kSecClassValue as! NSCopying] = kSecClassGenericPasswordValue
        keychainQuery[kSecAttrGenericValue as! NSCopying] = keyData
        keychainQuery[kSecAttrAccountValue as! NSCopying] = keyData
        keychainQuery[kSecAttrServiceValue as! NSCopying] = "VPN"
        keychainQuery[kSecAttrAccessibleValue as! NSCopying] = kSecAttrAccessibleAlwaysThisDeviceOnly
        keychainQuery[kSecValueData as! NSCopying] = valueData
        // Delete any existing items
        SecItemDelete(keychainQuery as CFDictionary)
        SecItemAdd(keychainQuery as CFDictionary, nil)
    }

    func load(key: String) -> Data {
        let keyData: Data = key.data(using: String.Encoding(rawValue: String.Encoding.utf8.rawValue), allowLossyConversion: false)!
        let keychainQuery = NSMutableDictionary()
        keychainQuery[kSecClassValue as! NSCopying] = kSecClassGenericPasswordValue
        keychainQuery[kSecAttrGenericValue as! NSCopying] = keyData
        keychainQuery[kSecAttrAccountValue as! NSCopying] = keyData
        keychainQuery[kSecAttrServiceValue as! NSCopying] = "VPN"
        keychainQuery[kSecAttrAccessibleValue as! NSCopying] = kSecAttrAccessibleAlwaysThisDeviceOnly
        keychainQuery[kSecMatchLimit] = kSecMatchLimitOne
        keychainQuery[kSecReturnPersistentRef] = kCFBooleanTrue

        var result: AnyObject?
        let status = withUnsafeMutablePointer(to: &result) { SecItemCopyMatching(keychainQuery, UnsafeMutablePointer($0)) }

        if status == errSecSuccess {
            if let data = result as! NSData? {
                if NSString(data: data as Data, encoding: String.Encoding.utf8.rawValue) != nil {}
                return data as Data
            }
        }
        return "".data(using: .utf8)!
    }

}

@objc(RNIpSecVpn)
class RNIpSecVpn: RCTEventEmitter {
    
    @objc override static func requiresMainQueueSetup() -> Bool {
        return true
    }

    override func supportedEvents() -> [String]! {
        return [ "stateChanged" ]
    }
    
    @objc
    func prepare(_ findEventsWithResolver: RCTPromiseResolveBlock, rejecter: RCTPromiseRejectBlock) -> Void {

        // Register to be notified of changes in the status. These notifications only work when app is in foreground.
        NotificationCenter.default.addObserver(forName: NSNotification.Name.NEVPNStatusDidChange, object : nil , queue: nil) {
            notification in let nevpnconn = notification.object as! NEVPNConnection
            self.sendEvent(withName: "stateChanged", body: [ "state" : checkNEStatus(status: nevpnconn.status) ])
        }
        findEventsWithResolver(nil)
    }
    
    @objc
    func connect(_ name: NSString, address: NSString, username: NSString, password: NSString, vpnType: NSString, secret: NSString, disconnectOnSleep: Bool, mtu: NSNumber, b64CaCert: NSString, b64UserCert: NSString, userCertPassword: NSString, certAlias: NSString, findEventsWithResolver: @escaping RCTPromiseResolveBlock, rejecter: @escaping RCTPromiseRejectBlock) -> Void {

        let vpnManager = NEVPNManager.shared()
        let kcs = KeychainService()

        vpnManager.loadFromPreferences { (error) -> Void in

            if error != nil {
                print("VPN Preferences error: 1")
            } else {

                //vpnType == 'IKEv2' || vpnType == 'IPSec'
                if(vpnType == "IPSec") {
                    
                    let p = NEVPNProtocolIPSec()
                    p.username = username as String
                    p.serverAddress = address as String
                    p.authenticationMethod = NEVPNIKEAuthenticationMethod.sharedSecret
                    
                    kcs.save(key: "secret", value: secret as String)
                    kcs.save(key: "password", value: password as String)
                    
                    p.sharedSecretReference = kcs.load(key: "secret")
                    p.passwordReference = kcs.load(key: "password")
                    
                    p.useExtendedAuthentication = true
                    p.disconnectOnSleep = disconnectOnSleep
                    
                    vpnManager.protocolConfiguration = p
                    
                } else {

                    let p = NEVPNProtocolIKEv2()

                    p.username = username as String
                    p.remoteIdentifier = address as String
                    p.serverAddress = address as String
                    //p.localIdentifier = "vpnclient"

                    p.childSecurityAssociationParameters.diffieHellmanGroup = NEVPNIKEv2DiffieHellmanGroup.group14
                    p.childSecurityAssociationParameters.encryptionAlgorithm = NEVPNIKEv2EncryptionAlgorithm.algorithmAES128GCM
                    p.childSecurityAssociationParameters.lifetimeMinutes = 1410
                    p.ikeSecurityAssociationParameters.diffieHellmanGroup = NEVPNIKEv2DiffieHellmanGroup.group14
                    p.ikeSecurityAssociationParameters.integrityAlgorithm = NEVPNIKEv2IntegrityAlgorithm.SHA256
                    p.ikeSecurityAssociationParameters.encryptionAlgorithm = NEVPNIKEv2EncryptionAlgorithm.algorithmAES256
                    p.ikeSecurityAssociationParameters.lifetimeMinutes = 1410

                    //p.disableMOBIKE = false
                    //p.disableRedirect = false
                    //p.enableRevocationCheck = false
                    //p.enablePFS = false
                    //p.useConfigurationAttributeInternalIPSubnet = false

                    //p.serverCertificateIssuerCommonName = "TEST SubCA"
                    //p.serverCertificateCommonName = "TEST SubCA"

                    p.authenticationMethod = NEVPNIKEAuthenticationMethod.certificate

                    //kcs.save(key: "secret", value: secret as String)
                    kcs.save(key: "password", value: password as String)
                    //kcs.save(key: "b64CaCert", value: b64CaCert as String)

                    //p.sharedSecretReference = kcs.load(key: "secret")
                    p.passwordReference = kcs.load(key: "password")
                    //p.certificateType = NEVPNIKEv2CertificateType.RSA

                    //let pkcs12Cert = ""

                    //let nnn = b64UserCert.replacingOccurrences(of: "\r\n", with: "")
                    //let certificateData = Data(base64Encoded: pkcs12Cert)
                    //, options: Data.Base64DecodingOptions(rawValue: 0)
                    //print("certificateData")
                    //print(certificateData ?? "nothing!")
                    //p.identityData = certificateData
                    //05c41851-5ea9-4166-b38a-a122ca3dc0c8
                    //p.identityDataPassword = secret as String

                    // On ios we put our pkcs12cert in b64UserCert
                    // password & PKCS12 from .mobileconfig
                    p.identityData = Data(base64Encoded: b64UserCert as String)
                    //p.identityDataPassword = "GztrFW9pcGExwHPAGh"
                    p.identityDataPassword = userCertPassword as String

                    print("ohoho")
                    print(p)

                    //p.useExtendedAuthentication = true
                    p.disconnectOnSleep = disconnectOnSleep

                    vpnManager.protocolConfiguration = p
                }
                

                vpnManager.isEnabled = true
                
                let defaultErr = NSError()

                vpnManager.saveToPreferences(completionHandler: { (error) -> Void in
                    if error != nil {
                        print("VPN Preferences error: 2")
                        rejecter("VPN_ERR", "VPN Preferences error: 2", defaultErr)
                    } else {
                        vpnManager.loadFromPreferences(completionHandler: { error in

                            if error != nil {
                                print("VPN Preferences error: 2")
                                rejecter("VPN_ERR", "VPN Preferences error: 2", defaultErr)
                            } else {
                                var startError: NSError?

                                do {
                                    try vpnManager.connection.startVPNTunnel()
                                } catch let error as NSError {
                                    startError = error
                                    print(startError ?? "VPN Manager cannot start tunnel")
                                    rejecter("VPN_ERR", "VPN Manager cannot start tunnel", startError)
                                } catch {
                                    print("Fatal Error")
                                    rejecter("VPN_ERR", "Fatal Error", NSError(domain: "", code: 200, userInfo: nil))
                                    fatalError()
                                }
                                if startError != nil {
                                    print("VPN Preferences error: 3")
                                    print(startError ?? "Start Error")
                                    //rejecter("VPN_ERR", "VPN Preferences error: 3", startError)
                                } else {
                                    print("VPN started successfully..")
                                    findEventsWithResolver(nil)
                                }
                            }
                        })
                    }
                })
            }
        } 
    }
    
    @objc
    func disconnect(_ findEventsWithResolver: RCTPromiseResolveBlock, rejecter: RCTPromiseRejectBlock) -> Void {
        let vpnManager = NEVPNManager.shared()
        vpnManager.connection.stopVPNTunnel()
        findEventsWithResolver(nil)
    }
    
    @objc
    func getCurrentState(_ findEventsWithResolver:RCTPromiseResolveBlock, rejecter:RCTPromiseRejectBlock) -> Void {
        let vpnManager = NEVPNManager.shared()
        let status = checkNEStatus(status: vpnManager.connection.status)
        if(status.intValue < 5){
            findEventsWithResolver(status)
        } else {
            rejecter("VPN_ERR", "Unknown state", NSError())
            fatalError()
        }
    }
    
    @objc
    func getCharonErrorState(_ findEventsWithResolver: RCTPromiseResolveBlock, rejecter: RCTPromiseRejectBlock) -> Void {
        findEventsWithResolver(nil)
    }

    @objc
    func createVPNProfile(_ resolver: @escaping RCTPromiseResolveBlock, rejecter: @escaping RCTPromiseRejectBlock) {
        NETunnelProviderManager.loadAllFromPreferences() { managers, error in
            guard let managers = managers, error == nil else {
                rejecter("VPN_ERR", "CANT SELECT VPN MANAGER", error)
                return
            }
            if managers.count == 0 {
                let tunnelProtocol = NETunnelProviderProtocol()
                tunnelProtocol.serverAddress = "darkpass"
                //tunnelProtocol.enforceRoutes = false
                if #available(iOS 14.2, *) {
                    tunnelProtocol.enforceRoutes = false
                }
                tunnelProtocol.providerBundleIdentifier = "com.sarzhevsky.darkpass.proxy" // bundle id of the network extension target
                tunnelProtocol.disconnectOnSleep = false

                let manager = NETunnelProviderManager()
                manager.localizedDescription = "sarzhevsky darkpass"
                manager.protocolConfiguration = tunnelProtocol
                manager.isEnabled = true

                manager.saveToPreferences { error in
                    if let error = error {
                        rejecter("VPN_ERR", "CANT SAVE TO PREFERENCES", error)
                    } else {
                        resolver(nil)
                    }
                }
            } else {
                resolver(nil)
            }
        }
    }

    @objc
    func connectToVPN(_ name: NSString, address: NSString, username: NSString, password: NSString, vpnType: NSString, secret: NSString, disconnectOnSleep: Bool, mtu: NSNumber, b64CaCert: NSString, b64UserCert: NSString, userCertPassword: NSString, certAlias: NSString, findEventsWithResolver: @escaping RCTPromiseResolveBlock, rejecter: @escaping RCTPromiseRejectBlock) -> Void {

        if(vpnType == "SS"){
            NETunnelProviderManager.loadAllFromPreferences { managers, error in
                guard let manager = managers?.first, error == nil else {
                    rejecter("VPN_ERR", "CONNECT VPN MANAGER NOT FOUND", error)
                    return
                }

                let tunnelProtocol = NETunnelProviderProtocol()
                tunnelProtocol.serverAddress = "darkpass"
                //tunnelProtocol.enforceRoutes = false
                if #available(iOS 14.2, *) {
                    tunnelProtocol.enforceRoutes = false
                }
                tunnelProtocol.providerBundleIdentifier = "com.sarzhevsky.darkpass.proxy" // bundle id of the network extension target
                tunnelProtocol.disconnectOnSleep = false

                manager.protocolConfiguration = tunnelProtocol
                manager.isEnabled = true
                manager.saveToPreferences { error in
                    guard error == nil else {
                        rejecter("VPN_ERR", "CANT CONNECT SS 1", error)
                        return
                    }
                    manager.loadFromPreferences { error in
                        guard error == nil else {
                            rejecter("VPN_ERR", "CANT CONNECT SS 2", error)
                            return
                        }

                        do {
                            try manager.connection.startVPNTunnel()
                            findEventsWithResolver(nil)
                        } catch {
                            rejecter("VPN_ERR", "CANT CONNECT VPN", error)
                        }
                        
                    }
                }

            }
        } else {

            let vpnManager = NEVPNManager.shared()
            let kcs = KeychainService()

            vpnManager.loadFromPreferences { (error) -> Void in
                if error != nil {
                    print("VPN Preferences error: 1", error)
                    rejecter("VPN_ERR", "VPN Preferences error: 1", error)
                } else {

                    if(vpnType == "IPSec") {
                        
                        let p = NEVPNProtocolIPSec()
                        p.username = username as String
                        p.serverAddress = address as String
                        p.authenticationMethod = NEVPNIKEAuthenticationMethod.sharedSecret
                        
                        kcs.save(key: "secret", value: secret as String)
                        kcs.save(key: "password", value: password as String)
                        
                        p.sharedSecretReference = kcs.load(key: "secret")
                        p.passwordReference = kcs.load(key: "password")
                        
                        p.useExtendedAuthentication = true
                        p.disconnectOnSleep = disconnectOnSleep
                        
                        vpnManager.protocolConfiguration = p
                        
                    } else {

                        let p = NEVPNProtocolIKEv2()

                        p.username = username as String
                        p.remoteIdentifier = address as String
                        p.serverAddress = address as String

                        p.childSecurityAssociationParameters.diffieHellmanGroup = NEVPNIKEv2DiffieHellmanGroup.group14
                        p.childSecurityAssociationParameters.encryptionAlgorithm = NEVPNIKEv2EncryptionAlgorithm.algorithmAES128GCM
                        p.childSecurityAssociationParameters.lifetimeMinutes = 1440
                        p.ikeSecurityAssociationParameters.diffieHellmanGroup = NEVPNIKEv2DiffieHellmanGroup.group14
                        p.ikeSecurityAssociationParameters.integrityAlgorithm = NEVPNIKEv2IntegrityAlgorithm.SHA256
                        p.ikeSecurityAssociationParameters.encryptionAlgorithm = NEVPNIKEv2EncryptionAlgorithm.algorithmAES256
                        p.ikeSecurityAssociationParameters.lifetimeMinutes = 1440

                        p.authenticationMethod = NEVPNIKEAuthenticationMethod.sharedSecret
                        
                        kcs.save(key: "secret", value: secret as String)
                        kcs.save(key: "password", value: password as String)
                        
                        p.sharedSecretReference = kcs.load(key: "secret")
                        p.passwordReference = kcs.load(key: "password")
                        
                        p.useExtendedAuthentication = true

                        //p.authenticationMethod = NEVPNIKEAuthenticationMethod.certificate
                        //kcs.save(key: "password", value: password as String)
                        //p.passwordReference = kcs.load(key: "password")
                        //p.identityData = Data(base64Encoded: b64UserCert as String)
                        //p.identityDataPassword = userCertPassword as String
                        p.disconnectOnSleep = disconnectOnSleep

                        vpnManager.protocolConfiguration = p
                    }
                    

                    vpnManager.isEnabled = true
                    
         
                    vpnManager.saveToPreferences { error in
                        guard error == nil else {
                            rejecter("VPN_ERR", "CANT SAVE TO PREFERENCES", error)
                            return
                        }
                        vpnManager.loadFromPreferences { error in
                            guard error == nil else {
                                rejecter("VPN_ERR", "CANT LOAD FROM PREFERENCES", error)
                                return
                            }

                            do {
                                try vpnManager.connection.startVPNTunnel()
                                findEventsWithResolver(nil)
                            } catch {
                                rejecter("VPN_ERR", "CANT START VPN TUNNEL", error)
                            }
                            
                        }
                    }

                    
                }
            }
        }
    }

    @objc
    func disconnectFromVPN(_ resolver: @escaping RCTPromiseResolveBlock, rejecter: @escaping RCTPromiseRejectBlock) {
        NETunnelProviderManager.loadAllFromPreferences { managers, error in
            guard let manager = managers?.first, error == nil else {
                rejecter("VPN_ERR", "Unable to use VPN manager", error)
                return
            }

            manager.connection.stopVPNTunnel()
            resolver(nil)
        }
    }

    @objc
    func saveShadowServerString(_ text: String, resolver: @escaping RCTPromiseResolveBlock, rejecter: @escaping RCTPromiseRejectBlock) {
        let ud = UserDefaults(suiteName: "group.com.sarzhevsky.darkpass")
        ud?.set(text, forKey: "shadowserver")
        resolver(nil)
    }

    @objc
    func getShadowServerString(_ resolver: @escaping RCTPromiseResolveBlock, rejecter: @escaping RCTPromiseRejectBlock) {
        let ud = UserDefaults(suiteName: "group.com.sarzhevsky.darkpass")
        let val = ud?.string(forKey: "shadowserver") ?? ""
        resolver(val)
    }

    @objc
    func getShadowType(_ resolver: @escaping RCTPromiseResolveBlock, rejecter: @escaping RCTPromiseRejectBlock) {
        let ud = UserDefaults(suiteName: "group.com.sarzhevsky.darkpass")
        let val = ud?.integer(forKey: "type") ?? 0
        resolver(val)
    }

    @objc
    func saveShadowType(_ type: Int, resolver: @escaping RCTPromiseResolveBlock, rejecter: @escaping RCTPromiseRejectBlock) {
        guard type >= 0 else {
            rejecter("INVALID_TYPE", "The type must be 0 or greater", nil)
            return
        }
        let ud = UserDefaults(suiteName: "group.com.sarzhevsky.darkpass")
        ud?.set(type, forKey: "type")
        resolver(nil)
    }

    @objc
    func saveTest(_ name: String, resolver: @escaping RCTPromiseResolveBlock, rejecter: @escaping RCTPromiseRejectBlock) {
        print("saveTest called with name: \(name)")
        guard !name.isEmpty else {
            rejecter("ERROR_CODE", "Name cannot be empty", nil)
            return
        }
        print("saveTest called with name: \(name)")
        resolver("Name saved successfully: \(name)")
    }

    @objc
    func isVpnConnected(_ resolver: @escaping RCTPromiseResolveBlock, rejecter: @escaping RCTPromiseRejectBlock) {
        let vpnManager = NEVPNManager.shared()
        let status = vpnManager.connection.status

        switch status {
        case .connected:
            resolver(true)
        case .connecting, .disconnecting, .disconnected, .invalid, .reasserting:
            resolver(false)
        @unknown default:
            resolver(false)
        }
    }



}


func checkNEStatus( status:NEVPNStatus ) -> NSNumber {
    switch status {
    case .connecting:
        return 1
    case .connected:
        return 2
    case .disconnecting:
        return 3
    case .disconnected:
        return 0
    case .invalid:
        return 0
    case .reasserting:
        return 4
    @unknown default:
        return 5
    }
}
