import Foundation
import Alamofire

// MARK: - 网络错误类型
enum NetworkError: Error {
    case invalidURL
    case decodingFailed
    case serverError(Int)           // HTTP 状态码非 2xx
    case bizError(Int, String)      // 业务错误码（code != 0）
    case unknown(Error)
}

// MARK: - 网络服务基类
/// 所有具体 NetworkService 的基类，封装 Alamofire 调用细节
/// 使用时继承此类，或参考此类直接用 Alamofire 发请求
class NetworkService {

    static let shared = NetworkService()

    // MARK: - 通用 GET 请求
    /// - Parameters:
    ///   - url: 完整 URL 字符串
    ///   - params: Query 参数
    ///   - completion: 回调，Result<T, NetworkError>
    func get<T: Decodable>(
        _ url: String,
        params: Parameters? = nil,
        completion: @escaping (Result<T>) -> Void
    ) {
        Alamofire.request(url, method: .get, parameters: params)
            .validate()
            .responseData { response in
                switch response.result {
                case .success(let data):
                    do {
                        let model = try JSONDecoder().decode(T.self, from: data)
                        completion(.success(model))
                    } catch {
                        completion(.failure(NetworkError.decodingFailed))
                    }
                case .failure(let error):
                    if let statusCode = response.response?.statusCode {
                        completion(.failure(NetworkError.serverError(statusCode)))
                    } else {
                        completion(.failure(NetworkError.unknown(error)))
                    }
                }
            }
    }

    // MARK: - 通用 POST 请求
    func post<T: Decodable>(
        _ url: String,
        body: Parameters? = nil,
        completion: @escaping (Result<T>) -> Void
    ) {
        Alamofire.request(url, method: .post, parameters: body, encoding: JSONEncoding.default)
            .validate()
            .responseData { response in
                switch response.result {
                case .success(let data):
                    do {
                        let model = try JSONDecoder().decode(T.self, from: data)
                        completion(.success(model))
                    } catch {
                        completion(.failure(NetworkError.decodingFailed))
                    }
                case .failure(let error):
                    if let statusCode = response.response?.statusCode {
                        completion(.failure(NetworkError.serverError(statusCode)))
                    } else {
                        completion(.failure(NetworkError.unknown(error)))
                    }
                }
            }
    }
}

// MARK: - 使用示例（真实接入服务端时参考）
/*

 // 1. 定义响应模型（遵守 Decodable）
 struct NoteListResponse: Decodable {
     let code: Int
     let msg: String
     let data: NoteListData?
 }

 struct NoteListData: Decodable {
     let notes: [Note]
     let hasMore: Bool
     let nextCursor: String?
 }

 // 2. 发起请求
 NetworkService.shared.get(
     "https://api.example.com/api/sns/v1/notes",
     params: ["page": 1, "size": 20]
 ) { (result: Result<NoteListResponse>) in
     switch result {
     case .success(let response):
         if response.code == 0 {
             let notes = response.data?.notes ?? []
         } else {
             print("业务错误：\(response.msg)")
         }
     case .failure(let error):
         print("网络错误：\(error)")
     }
 }

*/
