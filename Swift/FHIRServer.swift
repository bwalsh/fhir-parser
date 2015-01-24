//
//  FHIRReference.swift
//  SMART-on-FHIR
//
//  Created by Pascal Pfiffner on 01/24/15.
//  2015, SMART Platforms.
//

import Foundation


/// Callback from server methods
public typealias FHIRServerJSONCallback = ((response: FHIRServerJSONResponse?, error: NSError?) -> Void)

/// The FHIR server error domain
public let FHIRServerErrorDomain = "FHIRServerError"


/**
	Encapsulates a server response.
 */
public class FHIRServerResponse
{
	/// The HTTP status code
	public let status: Int = 0
	
	/// Response headers
	public let headers: [String: String]
	
	/// An NSError, generated from status code unless it was explicitly assigned.
	public var error: NSError?
	
	public required init(status: Int, headers: [String: String]) {
		self.status = status
		self.headers = headers
		
		if status >= 400 {
			let errstr = NSHTTPURLResponse.localizedStringForStatusCode(status)
			error = NSError(domain: FHIRServerErrorDomain, code: status, userInfo: [NSLocalizedDescriptionKey: errstr])
		}
	}
	
	
	/** Instantiate a FHIRServerJSONResponse from an NS(HTTP)URLResponse. */
	public class func from(# response: NSURLResponse) -> Self {
		var status = 0
		var headers = [String: String]()
		
		if let http = response as? NSHTTPURLResponse {
			status = http.statusCode
			for (key, val) in http.allHeaderFields {
				if let keystr = key as? String {
					if let valstr = val as? String {
						headers[keystr] = valstr
					}
					else {
						println("DEBUG: Not a string in location headers: \(val) (for \(keystr))")
					}
				}
			}
		}
		
		return self(status: status, headers: headers)
	}
}


/**
	Encapsulates a server response with JSON response body, if any.
 */
public class FHIRServerJSONResponse: FHIRServerResponse
{
	/// The response body, decoded into a JSONDictionary
	public var body: JSONDictionary?
	
	public required init(status: Int, headers: [String: String]) {
		super.init(status: status, headers: headers)
	}

	/** Instantiate a FHIRServerJSONResponse from an NS(HTTP)URLResponse and NSData. */
	public class func from(# response: NSURLResponse, data inData: NSData?) -> Self {
		let sup = super.from(response: response)
		let res = self(status: sup.status, headers: sup.headers)		// TODO: figure out how to make super work with "Self"
		
		if let data = inData {
			var error: NSError? = nil
			if let json = NSJSONSerialization.JSONObjectWithData(data, options: nil, error: &error) as? JSONDictionary {
				res.body = json
			}
			else {
				let errstr = "Failed to deserialize JSON into a dictionary: \(error?.localizedDescription)\n"
				             "\(NSString(data: data, encoding: NSUTF8StringEncoding))"
				res.error = NSError(domain: FHIRServerErrorDomain, code: res.status, userInfo: [NSLocalizedDescriptionKey: errstr])
			}
		}
		
		return res
	}
}


/**
	Protocol for server objects to be used by `FHIRResource` and subclasses.
 */
public protocol FHIRServer
{
	/** A server object must always have a base URL. */
	var baseURL: NSURL { get }
	
	/**
		Instance method that takes a path, which is relative to `baseURL`, executes a GET request from that URL and
		returns a decoded JSONDictionary - or an error - in the callback.
	
		:param: path The REST path to request, relative to the server's base URL
		:param: callback The callback to call when the request ends (success or failure)
	 */
	func getJSON(path: String, callback: FHIRServerJSONCallback)
	
	/**
		Instance method that takes a path, which is relative to `baseURL`, executes a PUT request at that URL and
		returns a decoded JSONDictionary - or an error - in the callback.
	
		:param: path The REST path to request, relative to the server's base URL
		:param: body The request body data as JSONDictionary
		:param: callback The callback to call when the request ends (success or failure)
	*/
	func putJSON(path: String, body: JSONDictionary, callback: FHIRServerJSONCallback)
	
	func postJSON(path: String, body: JSONDictionary, callback: FHIRServerJSONCallback)
}

