//
//  RNIpSecVpnBridge.m
//  RNIpSecVpn
//
//  Copyright © 2019 Sijav. All rights reserved.
//

#import <React/RCTBridgeModule.h>
#import <React/RCTEventEmitter.h>

@interface RCT_EXTERN_MODULE(RNIpSecVpn, RCTEventEmitter)

RCT_EXTERN_METHOD(prepare:(RCTPromiseResolveBlock)findEventsWithResolver rejecter:(RCTPromiseRejectBlock)rejecter)
RCT_EXTERN_METHOD(connect:(NSString *)name address:(NSString *)address username:(NSString *)username password:(NSString *)password vpnType:(NSString *)vpnType secret:(NSString *)secret disconnectOnSleep:(BOOL)disconnectOnSleep mtu:(NSNumber *_Nonnull)mtu b64CaCert:(NSString *)b64CaCert b64UserCert:(NSString *)b64UserCert userCertPassword:(NSString *)userCertPassword certAlias:(NSString *)certAlias findEventsWithResolver:(RCTPromiseResolveBlock)findEventsWithResolver rejecter:(RCTPromiseRejectBlock)rejecter)
RCT_EXTERN_METHOD(disconnect:(RCTPromiseResolveBlock)findEventsWithResolver rejecter:(RCTPromiseRejectBlock)rejecter)
RCT_EXTERN_METHOD(getCurrentState:(RCTPromiseResolveBlock)findEventsWithResolver rejecter:(RCTPromiseRejectBlock)rejecter)
RCT_EXTERN_METHOD(getCharonErrorState:(RCTPromiseResolveBlock)findEventsWithResolver rejecter:(RCTPromiseRejectBlock)rejecter)
RCT_EXTERN_METHOD(createVPNProfile:(RCTPromiseResolveBlock)findEventsWithResolver rejecter:(RCTPromiseRejectBlock)rejecter)
RCT_EXTERN_METHOD(connectToVPN:(NSString *)name address:(NSString *)address username:(NSString *)username password:(NSString *)password vpnType:(NSString *)vpnType secret:(NSString *)secret disconnectOnSleep:(BOOL)disconnectOnSleep mtu:(NSNumber *_Nonnull)mtu b64CaCert:(NSString *)b64CaCert b64UserCert:(NSString *)b64UserCert userCertPassword:(NSString *)userCertPassword certAlias:(NSString *)certAlias findEventsWithResolver:(RCTPromiseResolveBlock)findEventsWithResolver rejecter:(RCTPromiseRejectBlock)rejecter)
RCT_EXTERN_METHOD(disconnectFromVPN:(RCTPromiseResolveBlock)findEventsWithResolver rejecter:(RCTPromiseRejectBlock)rejecter)
RCT_EXTERN_METHOD(getShadowServerString:(RCTPromiseResolveBlock)findEventsWithResolver rejecter:(RCTPromiseRejectBlock)rejecter)
RCT_EXTERN_METHOD(saveShadowServerString:(NSString *)text resolver:(RCTPromiseResolveBlock)resolver rejecter:(RCTPromiseRejectBlock)rejecter)
//RCT_EXTERN_METHOD(saveShadowType:(NSInteger *)type findEventsWithResolver:(RCTPromiseResolveBlock)findEventsWithResolver rejecter:(RCTPromiseRejectBlock)rejecter)
RCT_EXTERN_METHOD(saveShadowType:(NSInteger)type resolver:(RCTPromiseResolveBlock)resolver rejecter:(RCTPromiseRejectBlock)rejecter)
RCT_EXTERN_METHOD(getShadowType:(RCTPromiseResolveBlock)findEventsWithResolver rejecter:(RCTPromiseRejectBlock)rejecter)
RCT_EXTERN_METHOD(saveTest:(NSString *)name resolver:(RCTPromiseResolveBlock)resolver rejecter:(RCTPromiseRejectBlock)rejecter)
RCT_EXTERN_METHOD(isVpnConnected:(RCTPromiseResolveBlock)resolver rejecter:(RCTPromiseRejectBlock)rejecter)

@end
