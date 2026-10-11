// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
@_spi(Execution) @_spi(Unsafe) import ApolloAPI

extension CountriesAPI {
  nonisolated struct CountryQuery: GraphQLQuery {
    static let operationName: String = "Country"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"query Country($code: ID!) { country(code: $code) { __typename ...CountryBasics capital currencies languages { __typename code name } } }"#,
        fragments: [CountryBasics.self]
      ))

    public var code: ID

    public init(code: ID) {
      self.code = code
    }

    @_spi(Unsafe) public var __variables: Variables? { ["code": code] }

    nonisolated struct Data: CountriesAPI.SelectionSet {
      let __data: DataDict
      init(_dataDict: DataDict) { __data = _dataDict }

      static var __parentType: any ApolloAPI.ParentType { CountriesAPI.Objects.Query }
      static var __selections: [ApolloAPI.Selection] { [
        .field("country", Country?.self, arguments: ["code": .variable("code")]),
      ] }
      static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        CountryQuery.Data.self
      ] }

      var country: Country? { __data["country"] }

      /// Country
      ///
      /// Parent Type: `Country`
      nonisolated struct Country: CountriesAPI.SelectionSet {
        let __data: DataDict
        init(_dataDict: DataDict) { __data = _dataDict }

        static var __parentType: any ApolloAPI.ParentType { CountriesAPI.Objects.Country }
        static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("capital", String?.self),
          .field("currencies", [String].self),
          .field("languages", [Language].self),
          .fragment(CountryBasics.self),
        ] }
        static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          CountryQuery.Data.Country.self,
          CountryBasics.self
        ] }

        var capital: String? { __data["capital"] }
        var currencies: [String] { __data["currencies"] }
        var languages: [Language] { __data["languages"] }
        var code: CountriesAPI.ID { __data["code"] }
        var name: String { __data["name"] }
        var emoji: String { __data["emoji"] }
        var continent: Continent { __data["continent"] }

        struct Fragments: FragmentContainer {
          let __data: DataDict
          init(_dataDict: DataDict) { __data = _dataDict }

          var countryBasics: CountryBasics { _toFragment() }
        }

        /// Country.Language
        ///
        /// Parent Type: `Language`
        nonisolated struct Language: CountriesAPI.SelectionSet {
          let __data: DataDict
          init(_dataDict: DataDict) { __data = _dataDict }

          static var __parentType: any ApolloAPI.ParentType { CountriesAPI.Objects.Language }
          static var __selections: [ApolloAPI.Selection] { [
            .field("__typename", String.self),
            .field("code", CountriesAPI.ID.self),
            .field("name", String.self),
          ] }
          static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            CountryQuery.Data.Country.Language.self
          ] }

          var code: CountriesAPI.ID { __data["code"] }
          var name: String { __data["name"] }
        }

        typealias Continent = CountryBasics.Continent
      }
    }
  }

}