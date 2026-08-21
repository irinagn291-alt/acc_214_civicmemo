import SwiftUI

struct CivicBlotter: View {
  var body: some View {
    CivicPalette.ice
      .ignoresSafeArea()
      .overlay {
        Image("TextureBlotter")
          .resizable(resizingMode: .tile)
          .opacity(0.45)
          .allowsHitTesting(false)
      }
  }
}

struct CivicCard<Content: View>: View {
  @ViewBuilder var content: Content

  var body: some View {
    content
      .padding(16)
      .frame(maxWidth: .infinity, alignment: .leading)
      .background(Color.white)
      .overlay(
        RoundedRectangle(cornerRadius: 10)
          .stroke(CivicPalette.fog, lineWidth: 1)
      )
      .clipShape(RoundedRectangle(cornerRadius: 10))
  }
}

struct CivicPrimaryButton: View {
  var title: String
  var action: () -> Void

  var body: some View {
    Button(action: action) {
      Text(title)
        .font(CivicType.semibold(16))
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(CivicPalette.blue)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
    .buttonStyle(.plain)
  }
}

struct CivicChip: View {
  var title: String
  var selected: Bool

  var body: some View {
    Text(title)
      .font(CivicType.medium(13))
      .foregroundStyle(selected ? .white : CivicPalette.navy)
      .padding(.horizontal, 12)
      .padding(.vertical, 8)
      .background(selected ? CivicPalette.navy : CivicPalette.fog)
      .clipShape(Capsule())
  }
}

struct QuotaMeter: View {
  var title: String
  var value: Double
  var cap: Double
  var unit: String

  var body: some View {
    VStack(alignment: .leading, spacing: 6) {
      HStack {
        Text(title)
          .font(CivicType.medium(12))
          .foregroundStyle(CivicPalette.slate)
        Spacer()
        Text("\(Int(value.rounded())) / \(Int(cap.rounded())) \(unit)")
          .font(CivicType.semibold(12))
          .foregroundStyle(CivicPalette.ink)
      }
      GeometryReader { geo in
        let ratio = cap > 0 ? min(value / cap, 1) : 0
        ZStack(alignment: .leading) {
          Capsule().fill(CivicPalette.fog)
          Capsule()
            .fill(CivicPalette.blue)
            .frame(width: geo.size.width * ratio)
        }
      }
      .frame(height: 8)
    }
  }
}

struct CivicEmptyBoard: View {
  var image: String
  var title: String
  var note: String

  var body: some View {
    VStack(spacing: 12) {
      Image(image)
        .resizable()
        .scaledToFit()
        .frame(width: 168, height: 168)
      Text(title)
        .font(CivicType.semibold(16))
        .foregroundStyle(CivicPalette.navy)
      Text(note)
        .font(CivicType.regular(13))
        .foregroundStyle(CivicPalette.slate)
        .multilineTextAlignment(.center)
    }
    .frame(maxWidth: .infinity)
    .padding(.vertical, 24)
  }
}
