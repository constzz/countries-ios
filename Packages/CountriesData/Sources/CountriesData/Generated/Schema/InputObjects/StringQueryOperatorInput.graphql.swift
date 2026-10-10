// @generated
// This file was automatically generated and should not be edited.

@_spi(Internal) @_spi(Unsafe) import ApolloAPI

extension CountriesAPI {
  nonisolated struct StringQueryOperatorInput: InputObject {
    private(set) var __data: InputDict

    init(_ data: InputDict) {
      __data = data
    }

    init(
      eq: GraphQLNullable<String> = nil,
      `in`: GraphQLNullable<[String]> = nil,
      ne: GraphQLNullable<String> = nil,
      nin: GraphQLNullable<[String]> = nil,
      regex: GraphQLNullable<String> = nil
    ) {
      __data = InputDict([
        "eq": eq,
        "in": `in`,
        "ne": ne,
        "nin": nin,
        "regex": regex
      ])
    }

    var eq: GraphQLNullable<String> {
      get { __data["eq"] }
      set { __data["eq"] = newValue }
    }

    var `in`: GraphQLNullable<[String]> {
      get { __data["in"] }
      set { __data["in"] = newValue }
    }

    var ne: GraphQLNullable<String> {
      get { __data["ne"] }
      set { __data["ne"] = newValue }
    }

    var nin: GraphQLNullable<[String]> {
      get { __data["nin"] }
      set { __data["nin"] = newValue }
    }

    var regex: GraphQLNullable<String> {
      get { __data["regex"] }
      set { __data["regex"] = newValue }
    }
  }

}