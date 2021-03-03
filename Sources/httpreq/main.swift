import Foundation
import HTTPRequesting
import ArgumentParser
import Network

struct httpreq: ParsableCommand {
    enum Error: Swift.Error {
        case requiresURL
    }
    @Option(
        name: [.long, .short],
        help: "time to live for request"
    ) var timeout: Double = 10.0
    @Option(
        name: [.long, .short],
        help: "interface to force request on; wifi, cell, wired, loop"
    ) var requiredInterface: String?
    @Option(
        name: [.long, .short],
        help: "pin the certificate base64 of the SHA256"
    ) var pinned: String?
    @Flag(
        name: [.long, .short],
        help: "allow self signed certificates on tls"
    ) var insecured: Bool = false
    @Argument(
        help: "url to request; Eg. https://github.com/popmedic/swift-httprequesting"
    ) var urlString: String
    
    mutating func run() throws {
        guard let url = URL(string: urlString) else {
            throw Error.requiresURL
        }
        let required: NWInterface.InterfaceType =
            requiredInterface != nil ? .from(string: requiredInterface!) : .other
        print(
            """
            using:
                url: \(url)
                timeout: \(timeout)
                required interface: \(required)
                insecure allowed: \(insecured)
            """
        )
        let grp = DispatchGroup()
        grp.enter()
        let request = NWHTTPRequest(url: url,
                                    timeout: timeout,
                                    required: required)
        let validation: CertificatePinning
        if insecured { validation = .insecure }
        else if let pinned = pinned { validation = .certificate(pinned) }
        else { validation = .normal }
        try request.call(
            certificate: validation,
            handle: { (error, data) in
                if let error = error { return print(error) }
                if let data = data {
                    let result = String(data: data, encoding: .ascii) ??
                        "data could not be string encoded"
                    return print(result)
               }
               print("no error, no result")
           },
           complete: {
               grp.leave()
           }
        )
        grp.wait()
    }
}

extension NWInterface.InterfaceType {
	static func from(string: String) -> Self {
		let uppercased = string.uppercased()
		switch uppercased {
		case "WIFI": return .wifi
		case "CELL", "CELLULAR": return .cellular
		case "LOOPBACK", "LOOP": return .loopback
		case "WIRED", "WIREDETHERNET", "ETHERNET": return .wiredEthernet
		default: return .other
		}
	}
}

httpreq.main()
