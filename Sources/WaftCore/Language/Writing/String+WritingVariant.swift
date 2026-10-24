extension String {
    package func written(in variant: WritingVariant?, keeping terms: [String]) -> String {
        guard let variant else { return self }

        return variant.converting(self, keeping: terms)
    }
}
