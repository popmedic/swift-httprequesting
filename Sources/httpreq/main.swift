import Foundation
import HTTPRequesting
import Network

guard CommandLine.arguments.count >= 3 else {
	print("error: must contain url and timeout in arguments")
	print("httpreq <url> <timeout> <optional required interface>")
	exit(1)
}
guard let url = URL(string: CommandLine.arguments[1]) else {
	print("error: arqument 1 must be a url")
	print("httpreq <url> <timeout>")
	exit(1)
}
guard let timeout: TimeInterval = Double(CommandLine.arguments[2]) else {
	print("error: arqument 2 must be a timeout")
	print("httpreq <url> <timeout>")
	exit(1)
}

let requiredInterface: NWInterface.InterfaceType? =
	CommandLine.arguments.count > 3 ? .from(string: CommandLine.arguments[3]) : nil

do {
	let grp = DispatchGroup()
	grp.enter()
	let request = NWHTTPRequest(url: url,
								timeout: timeout,
								required: requiredInterface)
	try request.call(
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
} catch {
	print(error)
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
