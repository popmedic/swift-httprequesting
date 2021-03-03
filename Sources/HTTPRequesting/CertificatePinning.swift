import Foundation
import CommonCrypto

public enum CertificatePinning {
    case
        adhoc(sec_protocol_verify_t),
        insecure,
        normal,
        certificate(String)
}

public enum CertificatePinningError: Error {
    case cannotRetainTrust, secError(CFError)
}
extension CertificatePinning {
    func handle(metadata: sec_protocol_metadata_t,
                trust: sec_trust_t,
                complete: @escaping sec_protocol_verify_complete_t) {
        switch self {
        case .adhoc(let verifier):
            verifier(metadata, trust, complete)
        case .insecure:
            debugPrint("it is prefered that you use a pinned certificate.")
            debugPrint("for this server you could pin:")
            debugPrint(getBase64EncodedCertificateSHA256(from: trust).joined(separator: "\n"))
            complete(true)
        case .normal:
            let trust = sec_trust_copy_ref(trust).takeRetainedValue()
            var error: CFError?
            complete(SecTrustEvaluateWithError(trust, &error))
        case .certificate(let pinned):
            let base64certs = getBase64EncodedCertificateSHA256(from: trust)
            for cert in base64certs {
                if cert == pinned {
                    complete(true)
                    break
                }
            }
            complete(false)
        }
    }
}

private func sha256(data : Data) -> Data {
    var hash = [UInt8](repeating: 0,  count: Int(CC_SHA256_DIGEST_LENGTH))
    data.withUnsafeBytes {
        _ = CC_SHA256($0.baseAddress, CC_LONG(data.count), &hash)
    }
    return Data(hash)
}

private func getBase64EncodedCertificateSHA256(from trust: sec_trust_t) -> [String] {
    let trust = sec_trust_copy_ref(trust).takeRetainedValue()
    let count = SecTrustGetCertificateCount(trust)
    var result = [String]()
    for index in 0..<count {
        guard let cert = SecTrustGetCertificateAtIndex(trust, index) else {
            continue
        }
        result.append(
            sha256(
                data: SecCertificateCopyData(cert) as Data
            )
            .base64EncodedString()
        )
    }
    return result
}
