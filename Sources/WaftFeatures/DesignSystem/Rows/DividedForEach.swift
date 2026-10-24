import SwiftUI

struct DividedForEach<Data: RandomAccessCollection, ID: Hashable, Content: View>: View {
    private let data: Data
    private let id: KeyPath<Data.Element, ID>
    private let content: (Data.Element) -> Content

    init(_ data: Data, id: KeyPath<Data.Element, ID>, @ViewBuilder content: @escaping (Data.Element) -> Content) {
        self.data = data
        self.id = id
        self.content = content
    }

    var body: some View {
        let firstID = data.first?[keyPath: id]

        ForEach(data, id: id) { element in
            if element[keyPath: id] != firstID {
                RowDivider()
            }

            content(element)
        }
    }
}
