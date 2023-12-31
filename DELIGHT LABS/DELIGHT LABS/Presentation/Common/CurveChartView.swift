//
//  CurveChartView.swift
//  DELIGHT LABS
//
//  Created by 표건욱 on 2023/11/18.
//


import UIKit
import SnapKit
import Then


class CurveChartView: UIView {
    
    let data: [TransactionsModel]
    let isDay: Bool
    let isPositive: Bool
    
    init(data: [TransactionsModel], isDay: Bool, isPositive: Bool) {
        self.data = data
        self.isDay = isDay
        self.isPositive = isPositive
        super.init(frame: .zero)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func draw(_ rect: CGRect) {
        let incomeValues = data
            .filter {
                let calendar = Calendar.current
                let components = calendar.dateComponents([.hour, .minute], from: $0.time)
                
                switch isDay {
                case true:
                    return ((components.minute ?? 0) % 30) == 0
                case false:
                    return ((components.hour ?? 0) % 12) == 0 && components.minute == 0
                }
            }
            .map {
                switch isPositive {
                case true:
                    return $0.amount
                case false:
                    return $0.amount * -1
                }
            }
        
//        let maximum = (incomeValues.max() ?? 0) * 1.5
        let maximum = (incomeValues.max() ?? 0)
        let pointSpace = self.frame.width / Double(incomeValues.count - 1)
        var points = incomeValues
            .enumerated()
            .map { index, value in
                
                let rate = value / maximum
                let pointY = self.frame.height * rate
                
                return CGPoint(
                    x: pointSpace * Double(index),
                    y: self.frame.height - pointY
                )
        }
        
        points.insert(CGPoint(x: 0, y: frame.maxY), at: 0)
        points.append(CGPoint(x: frame.maxX, y: frame.maxY))
        
        let path = createCurve(from: points, withSmoothness: 0.5)
        
        let strokeColor: UIColor = isPositive ? .purple : .green
        let shapeLayer = CAShapeLayer()
        
        shapeLayer.fillColor =  UIColor.clear.cgColor
        shapeLayer.strokeColor = strokeColor.cgColor
        shapeLayer.lineWidth = 2
        shapeLayer.lineJoin = CAShapeLayerLineJoin.round
        shapeLayer.lineCap = CAShapeLayerLineCap.round
        shapeLayer.strokeStart = 0
        shapeLayer.path = path.cgPath
        
        self.layer.addSublayer(shapeLayer)
        
        let strokeAnimation = CABasicAnimation(keyPath: "strokeEnd")
        strokeAnimation.fromValue = 0
        strokeAnimation.toValue = 1
        strokeAnimation.duration = 2
        strokeAnimation.fillMode = .forwards
        
        shapeLayer.add(strokeAnimation, forKey: "strokeAnimation")
        
        let gradientLayer = CAGradientLayer()
        let startColor = strokeColor.cgColor
        let endColor = UIColor.white.cgColor
        let colors = isPositive ? [startColor, endColor] : [startColor, endColor, endColor, endColor]
        
        gradientLayer.colors = colors
        gradientLayer.frame = path.bounds
        
        let maskLayer = CAShapeLayer()
        maskLayer.path = path.cgPath
        gradientLayer.mask = maskLayer
        
        self.layer.addSublayer(gradientLayer)
        
//        let fillAnimation = CABasicAnimation(keyPath: "fillColor")
        let fillAnimation = CABasicAnimation(keyPath: "opacity")
        fillAnimation.duration = 3
        fillAnimation.fromValue = 0  // 이전 값 사용하지 않음
        fillAnimation.toValue = 1
        fillAnimation.fillMode = .forwards
        fillAnimation.isRemovedOnCompletion = false
        
        gradientLayer.add(fillAnimation, forKey: "fillAnimation")
    }
    
    private func createCurve(from points: [CGPoint], withSmoothness smoothness: CGFloat, addZeros: Bool = false) -> UIBezierPath {
        
        let path = UIBezierPath()
        
        guard points.count > 0 else { return path }
        
        var prevPoint: CGPoint = points.first!
        let interval = getXLineInterval()
        
        if addZeros {
            path.move(to: CGPoint(x: interval.origin.x, y: interval.origin.y))
            path.addLine(to: points[0])
        } else {
            path.move(to: points[0])
        }
        
        for i in 1 ..< points.count {
            let cp = controlPoints(p1: prevPoint, p2: points[i], smoothness: smoothness)
            path.addCurve(to: points[i], controlPoint1: cp.0, controlPoint2: cp.1)
            
            prevPoint = points[i]
        }
        
        if addZeros {
            path.addLine(to: CGPoint(x: prevPoint.x, y: interval.origin.y))
        }
        
        return path
    }
    
    private func controlPoints(p1: CGPoint, p2: CGPoint, smoothness: CGFloat) -> (CGPoint, CGPoint) {
        let cp1: CGPoint!
        let cp2: CGPoint!
        let percent = min(1, max(0, smoothness))
        
        do {
            var cp = p2
            let x0 = max(p1.x, p2.x)
            let x1 = min(p1.x, p2.x)
            let x = x0 + (x1 - x0) * percent
            
            cp.x = x
            cp2 = cp
        }
        
        do {
            var cp = p1
            let x0 = min(p1.x, p2.x)
            let x1 = max(p1.x, p2.x)
            let x = x0 + (x1 - x0) * percent
            
            cp.x = x
            cp1 = cp
        }
        
        return (cp1, cp2)
    }
    
    internal func getXLineInterval() -> CGRect {
        return CGRect.zero
    }
}
