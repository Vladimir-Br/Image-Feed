

import Foundation

extension Array {
    func withReplaced(itemAt index: Int, newValue: Element) -> [Element] {
        var array = self
        array[index] = newValue
        return array
    }
}
