import Apollo
import AtlasDomain
import Foundation
import Testing
@testable import AtlasData

@Suite("Apollo error mapping")
struct ErrorMappingTests {
  @Test(
    "AC-1.6 not connected maps to offline",
    arguments: [URLError.Code.notConnectedToInternet, .networkConnectionLost]
  )
  func notConnectedMapsToOffline(code: URLError.Code) {
    #expect(ApolloGraphQLClient.mapped(URLError(code)) as? RequestError == .offline)
  }

  @Test(
    "AC-1.6 other transport failures map to network",
    arguments: [URLError.Code.timedOut, .cannotFindHost, .badServerResponse]
  )
  func transportFailuresMapToNetwork(code: URLError.Code) {
    #expect(ApolloGraphQLClient.mapped(URLError(code)) as? RequestError == .network)
  }

  @Test("AC-1.11 cancellation stays cancellation")
  func cancellationStaysCancellation() {
    #expect(ApolloGraphQLClient.mapped(CancellationError()) is CancellationError)
    #expect(ApolloGraphQLClient.mapped(URLError(.cancelled)) is CancellationError)
  }

  @Test("AC-1.6 a body that isn't JSON maps to decoding")
  func unparsableBodyMapsToDecoding() {
    let error = JSONResponseParsingError.couldNotParseToJSON(data: Data("<html>".utf8))
    #expect(ApolloGraphQLClient.mapped(error) as? RequestError == .decoding)
  }

  @Test(
    "AC-1.6 a value that doesn't fit its field maps to decoding",
    arguments: [JSONDecodingError.missingValue, .nullValue, .wrongType]
  )
  func undecodableValueMapsToDecoding(error: JSONDecodingError) {
    #expect(ApolloGraphQLClient.mapped(error) as? RequestError == .decoding)
  }

  @Test("AC-1.6 anything else maps to unknown, and a RequestError passes through")
  func otherErrorsMapToUnknown() {
    #expect(ApolloGraphQLClient.mapped(ApolloClient.Error.noResults) as? RequestError == .unknown)
    #expect(ApolloGraphQLClient.mapped(CocoaError(.fileNoSuchFile)) as? RequestError == .unknown)
    #expect(ApolloGraphQLClient.mapped(RequestError.server) as? RequestError == .server)
  }

  @Test("AC-1.6 a response with GraphQL errors maps to server")
  func graphQLErrorsMapToServer() async throws {
    let error = GraphQLError(["message": "Unexpected error."])
    let withoutData = response(data: nil, errors: [error])
    let withData = try await response(data: countriesData(), errors: [error])

    #expect(throws: RequestError.server) { try ApolloGraphQLClient.data(from: withoutData) }
    #expect(throws: RequestError.server) { try ApolloGraphQLClient.data(from: withData) }
  }

  @Test("AC-1.6 a response without data maps to server")
  func missingDataMapsToServer() {
    #expect(throws: RequestError.server) { try ApolloGraphQLClient.data(from: response(data: nil, errors: nil)) }
  }

  @Test("AC-1.1 a response with data and no errors returns the data")
  func dataIsReturned() async throws {
    let data = try await countriesData()
    #expect(try ApolloGraphQLClient.data(from: response(data: data, errors: [])) == data)
  }

  // MARK: Helpers

  private func countriesData() async throws -> CountriesAPI.CountriesQuery.Data {
    try await CountriesAPI.CountriesQuery.Data(data: JSONFixture.object(#"{ "countries": [] }"#))
  }

  private func response(
    data: CountriesAPI.CountriesQuery.Data?,
    errors: [GraphQLError]?
  ) -> GraphQLResponse<CountriesAPI.CountriesQuery> {
    GraphQLResponse(data: data, extensions: nil, errors: errors, source: .server, dependentKeys: nil)
  }
}
