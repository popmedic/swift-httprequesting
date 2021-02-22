import Foundation
import Network

public enum HTTPRequestError: Error {
	case badURL(URL)
	case connection(NWError)
	case negitiveTimeout
	case timeoutOutOfBounds
	case receive(NWError?)
	case send(NWError)
	case wait(NWError)
	case unknown(Error)
}
