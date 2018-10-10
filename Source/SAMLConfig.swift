//
//  SAMLConfig.swift
//  edX
//
//  Created by andrey.canon on 10/10/18.
//  Copyright © 2018 edX. All rights reserved.
//

fileprivate enum SamlKeys: String, RawStringExtractable {
    case Enabled = "ENABLED"
    case SamlIdpSlug = "SAML_IDP_SLUG"
}
class SamlProviderConfig: NSObject {
    var enabled: Bool = false
    var samlIdpSlug: String = ""
    init(dictionary: [String: AnyObject]) {
        enabled = dictionary[SamlKeys.Enabled] as? Bool ?? false
        samlIdpSlug = dictionary[SamlKeys.SamlIdpSlug] as? String ?? ""
    }
}
private let key = "SAML"
extension OEXConfig {
    var samlProviderConfig: SamlProviderConfig {
        return SamlProviderConfig(dictionary: self[key] as? [String:AnyObject] ?? [:])
    }
}
