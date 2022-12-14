import Foundation

func / (lhs: CGSize, rhs: CGFloat) -> CGSize {
  return CGSize(width: lhs.width / rhs, height: lhs.height / rhs)
}
