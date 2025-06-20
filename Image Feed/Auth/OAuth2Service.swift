import Foundation

enum OAuth2Error: Error {
    case invalidRequest
    
}

final class OAuth2Service {
    static let shared = OAuth2Service()
    private init() {}
    
    private var currentTask: URLSessionTask?
    
    func makeOAuthTokenRequest(code: String) -> URLRequest? {
        guard var urlComponents = URLComponents(string: "https://unsplash.com/oauth/token") else {
            print("[OAuth2Service] Failed to create URLComponents")
            return nil
        }
        
        urlComponents.queryItems = [
            URLQueryItem(name: "client_id", value: Constants.accessKey),
            URLQueryItem(name: "client_secret", value: Constants.secretKey),
            URLQueryItem(name: "redirect_uri", value: Constants.redirectURI),
            URLQueryItem(name: "code", value: code),
            URLQueryItem(name: "grant_type", value: "authorization_code")
        ]
        
        guard let url = urlComponents.url else {
            print("[OAuth2Service] Failed to create URL from URLComponents")
            return nil
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        return request
    }
    
    func fetchOAuthToken(code: String, completion: @escaping (Result<String, Error>) -> Void) {
        currentTask?.cancel()
        currentTask = nil
        
        guard let request = makeOAuthTokenRequest(code: code) else {
            print("[OAuth2Service] Failed to create URLRequest")
            completion(.failure(OAuth2Error.invalidRequest))
            return
        }
        
        currentTask = URLSession.shared.data(for: request) { result in
            switch result {
            case .success(let data):
                do {
                    let decoder = JSONDecoder()
                    let response = try decoder.decode(OAuthTokenResponseBody.self, from: data)
                    completion(.success(response.accessToken))
                } catch {
                    print("[OAuth2Service] JSON Decoding Error: \(error.localizedDescription)")
                    completion(.failure(error))
                }
            case .failure(let error):
                if let networkError = error as? NetworkError {
                    switch networkError {
                    case .httpStatusCode(let statusCode):
                        print("[OAuth2Service] HTTP Error: Status code \(statusCode)")
                    case .urlRequestError(let urlError):
                        print("[OAuth2Service] Network Error: \(urlError.localizedDescription)")
                    case .urlSessionError:
                        print("[OAuth2Service] URLSession Error")
                    }
                } else {
                    print("[OAuth2Service] Unknown Error: \(error.localizedDescription)")
                }
                completion(.failure(error))
            }
        }
        currentTask?.resume()
    }
}

struct OAuthTokenResponseBody: Decodable {
    let accessToken: String
    let tokenType: String
    let scope: String
    
    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case tokenType = "token_type"
        case scope
    }
}
