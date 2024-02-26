//
//  GiphyResponse.swift
//  CollectionViewPractice
//
//  Created by Macbook on 2/24/24.
//

import Foundation

enum MyError: Error {
    case notAllowedURL
    case noData
    case unAuthorized(_ err: GiphyResponse?)
    case unKnownErr(_ err: Error?)
    case decodingErr
    
    var info: String {
        switch self {
        case .notAllowedURL:
            return "유효하지 않은 URL입니다."
        case .noData:
            return "데이터가 없습니다."
        case .unAuthorized(let err):
            return "인증되지 않은 사용자 : \(err?.meta?.msg ?? "")"
        case .unKnownErr(let err):
            let nsErr = err as? NSError
            return "알 수 없는 에러발생 : \(nsErr?.code ?? 000)"
        case .decodingErr:
            return "디코딩 에러"
        }
    }
}

// MARK: - Welcome
struct GiphyResponse: Codable {
    let data: [Giphy]?
    let meta: Meta?
    let pagination: Pagination?
}

// MARK: - Datum
struct Giphy: Codable {
    let id: String?
    let images: Images?

    enum CodingKeys: String, CodingKey {
        case id
        case images
    }
    
    func getUrl() -> URL? {
        let urlString = self.images?.downsized?.url ?? ""
        
        return URL(string: urlString)
    }
}

// MARK: - Images
struct Images: Codable {
    let downsized: DownSized?

    enum CodingKeys: String, CodingKey {
        case downsized
    }
}

// MARK: - The480_WStill
struct DownSized: Codable {
    let height, width, size: String?
    let url: String?
}

// MARK: - Meta
struct Meta: Codable {
    let status: Int?
    let msg, responseID: String?

    enum CodingKeys: String, CodingKey {
        case status, msg
        case responseID = "response_id"
    }
}

// MARK: - Pagination
struct Pagination: Codable {
    let totalCount, count, offset: Int?

    enum CodingKeys: String, CodingKey {
        case totalCount = "total_count"
        case count, offset
    }
    
    func checkEnd() -> Bool {
        
        guard let totalCount = totalCount,
              let count = count,
              let offset = offset else { return true }
        
        return (totalCount <= count + offset)
    }
}
