// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
@_spi(Execution) @_spi(Unsafe) import ApolloAPI

extension CountriesAPI {
  nonisolated struct CountriesQuery: GraphQLQuery {
    static let operationName: String = "Countries"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"query Countries($filter: CountryFilterInput) { countries(filter: $filter) { __typename ...CountryBasics } }"#,
        fragments: [CountryBasics.self]
      ))

    public var filter: GraphQLNullable<CountryFilterInput>

    public init(filter: GraphQLNullable<CountryFilterInput>) {
      self.filter = filter
    }

    @_spi(Unsafe) public var __variables: Variables? { ["filter": filter] }

    nonisolated struct Data: CountriesAPI.SelectionSet {
      let __data: DataDict
      init(_dataDict: DataDict) { __data = _dataDict }

      static var __parentType: any ApolloAPI.ParentType { CountriesAPI.Objects.Query }
      static var __selections: [ApolloAPI.Selection] { [
        .field("countries", [Country].self, arguments: ["filter": .variable("filter")]),
      ] }
      static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        CountriesQuery.Data.self
      ] }

      var countries: [Country] { __data["countries"] }

      /// Country
      ///
      /// Parent Type: `Country`
      nonisolated struct Country: CountriesAPI.SelectionSet {
        let __data: DataDict
        init(_dataDict: DataDict) { __data = _dataDict }

        static var __parentType: any ApolloAPI.ParentType { CountriesAPI.Objects.Country }
        static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .fragment(CountryBasics.self),
        ] }
        static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          CountriesQuery.Data.Country.self,
          CountryBasics.self
        ] }

        var code: CountriesAPI.ID { __data["code"] }
        var name: String { __data["name"] }
        var emoji: String { __data["emoji"] }
        var continent: Continent { __data["continent"] }

        struct Fragments: FragmentContainer {
          let __data: DataDict
          init(_dataDict: DataDict) { __data = _dataDict }

          var countryBasics: CountryBasics { _toFragment() }
        }

        typealias Continent = CountryBasics.Continent
      }
    }
  }

}