// @generated
// This file was automatically generated and should not be edited.

@_spi(Internal) @_spi(Unsafe) import ApolloAPI

extension CountriesAPI {
  nonisolated struct CountryFilterInput: InputObject {
    private(set) var __data: InputDict

    init(_ data: InputDict) {
      __data = data
    }

    init(
      code: GraphQLNullable<StringQueryOperatorInput> = nil,
      continent: GraphQLNullable<StringQueryOperatorInput> = nil,
      currency: GraphQLNullable<StringQueryOperatorInput> = nil,
      name: GraphQLNullable<StringQueryOperatorInput> = nil
    ) {
      __data = InputDict([
        "code": code,
        "continent": continent,
        "currency": currency,
        "name": name
      ])
    }

    var code: GraphQLNullable<StringQueryOperatorInput> {
      get { __data["code"] }
      set { __data["code"] = newValue }
    }

    var continent: GraphQLNullable<StringQueryOperatorInput> {
      get { __data["continent"] }
      set { __data["continent"] = newValue }
    }

    var currency: GraphQLNullable<StringQueryOperatorInput> {
      get { __data["currency"] }
      set { __data["currency"] = newValue }
    }

    var name: GraphQLNullable<StringQueryOperatorInput> {
      get { __data["name"] }
      set { __data["name"] = newValue }
    }
  }

}