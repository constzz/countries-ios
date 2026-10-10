import Apollo
import CountriesDomain
import Foundation
import os

/// Fetches through `ApolloClient` and maps every failure to `CountriesError`, logging its cause.
struct ApolloGraphQLClient: GraphQLClient {
  let client: ApolloClient

  func fetch<Query: GraphQLQuery>(
    _ query: Query,
    cachePolicy: CachePolicy.Query.SingleResponse
  ) async throws -> Query.Data where Query.ResponseFormat == SingleResponseFormat {
    let response: GraphQLResponse<Query>
    do {
      response = try await client.fetch(query: query, cachePolicy: cachePolicy)
    } catch {
      let mapped = Self.mapped(error)
      if mapped is CountriesError {
        let cause = String(describing: error)
        Logger.network.error("\(Query.operationName, privacy: .public) failed: \(cause, privacy: .public)")
      }
      throw mapped
    }

    do {
      return try Self.data(from: response)
    } catch {
      // Server messages can echo the variables, which hold the user's search term.
      let messages = (response.errors ?? []).compactMap(\.message).joined(separator: "; ")
      Logger.network.error("\(Query.operationName, privacy: .public) returned errors: \(messages, privacy: .private)")
      throw error
    }
  }

  /// The response's data, or `.server` when it has GraphQL errors or no data.
  static func data<Operation>(from response: GraphQLResponse<Operation>) throws -> Operation.Data {
    guard response.errors?.isEmpty ?? true, let data = response.data else {
      throw CountriesError.server
    }
    return data
  }

  /// The error to throw for a failed fetch: `CancellationError` or a `CountriesError`.
  static func mapped(_ error: any Error) -> any Error {
    switch error {
    case is CountriesError, is CancellationError:
      error
    case let error as URLError:
      switch error.code {
      case .cancelled:
        CancellationError()
      case .notConnectedToInternet, .networkConnectionLost:
        CountriesError.offline
      default:
        CountriesError.network
      }
    case is ResponseCodeInterceptor.ResponseCodeError:
      CountriesError.network
    case is JSONResponseParsingError, is GraphQLExecutionError:
      CountriesError.decoding
    default:
      CountriesError.unknown
    }
  }
}
