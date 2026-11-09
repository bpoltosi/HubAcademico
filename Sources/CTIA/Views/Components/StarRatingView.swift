import SwiftUI

// MARK: - Estrelas de Avaliação em Âmbar #FFC107
public struct StarRatingView: View {
    public let rating: Double
    public var maxRating: Int = 5
    public var starSize: CGFloat = 13
    public var isInteractive: Bool = false
    public var onRate: ((Int) -> Void)? = nil
    
    public init(
        rating: Double,
        maxRating: Int = 5,
        starSize: CGFloat = 13,
        isInteractive: Bool = false,
        onRate: ((Int) -> Void)? = nil
    ) {
        self.rating = rating
        self.maxRating = maxRating
        self.starSize = starSize
        self.isInteractive = isInteractive
        self.onRate = onRate
    }
    
    public var body: some View {
        HStack(spacing: 3) {
            ForEach(1...maxRating, id: \.self) { index in
                Image(systemName: Double(index) <= rating ? "star.fill" : (Double(index) - 0.5 <= rating ? "star.leadinghalf.filled" : "star"))
                    .font(.system(size: starSize))
                    .foregroundColor(Double(index) <= rating || Double(index) - 0.5 <= rating ? Color.ambarUFSM : Color.bordaUFSM)
                    .onTapGesture {
                        if isInteractive {
                            onRate?(index)
                        }
                    }
            }
        }
    }
}
