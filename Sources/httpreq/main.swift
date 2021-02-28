import Foundation
import HTTPRequesting
import ArgumentParser
import Network

struct Args: ParsableCommand {
    enum Error: Swift.Error {
        case requiresURL
    }
    @Option(name: [.long, .short]) var timeout: Double = 10.0
    @Option(name: [.long, .short]) var requiredInterface: String?
    @Flag(name: [.long, .short]) var insecured: Bool = false
    @Argument var urlString: String
    
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
        try request.call(
            insecured: insecured,
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

Args.main()
