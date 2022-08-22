//
//  HelperView.swift
//  DotDrawer
//
//  Created by Farhad Chowdhury on 21/8/22.
//

import UIKit

class MiniMap: UIView {
    enum NotificationName: String {
        case updateMiniMap
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("This class does not support NSCoding")
    }

    static func updateMiniMap() {
        NotificationCenter.default.post(
            name: Notification.Name(MiniMap.NotificationName.updateMiniMap.rawValue),
            object: nil
        )
    }

    private var lineLayerView: CustomView?
    private var smallView: UIView?
    private var scrollView: UIScrollView?

    convenience init(frame: CGRect, scrollView: UIScrollView) {
        self.init(frame: frame)
        self.scrollView = scrollView
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(self.methodOfReceivedNotification(notification:)),
            name: Notification.Name(NotificationName.updateMiniMap.rawValue),
            object: nil
        )
        let tapgesture = UITapGestureRecognizer(target: self, action: #selector(tappedOnMiniMap(_ :)))
        self.addGestureRecognizer(tapgesture)
        drawSmallView()
    }

    @objc func methodOfReceivedNotification(notification: Notification) {
        drawSmallView()
    }

    // For tapping of small view in miniMap
    @objc private func tappedOnMiniMap(_ gesture: UITapGestureRecognizer) {
        print("tappedMiniMap")
        guard
            let miniMap = gesture.view as? MiniMap,
            let unwrappedScrollView = scrollView
            else { return }

        let tappedPoint = gesture.location(in: miniMap)
        miniMap.updateSmallViewForTapped(point: tappedPoint)

        // To avoid problem like contentSize beeing zero
        var contentSize = unwrappedScrollView.contentSize
        if contentSize.width == 0.0 || contentSize.height == 0.0 {
            contentSize = unwrappedScrollView.frame.size
        }

        let cW = contentSize.width / miniMap.frame.width
        let cH = contentSize.height / miniMap.frame.height
        let scrollViewPoint = CGPoint(
            x: cW * tappedPoint.x,
            y: cH * tappedPoint.y
        )

        // Let not go beyond frame
        let transformedMidPoint = ViewHelper.fixEdgePoint(
            midPoint: scrollViewPoint,
            bounds: unwrappedScrollView.frame.size,
            parentsBounds: contentSize
        )
        let transformedOriginPoint = CGPoint(
            x: transformedMidPoint.x - unwrappedScrollView.frame.width / 2,
            y: transformedMidPoint.y - unwrappedScrollView.frame.height / 2
        )

        unwrappedScrollView.bounds.origin = transformedOriginPoint
    }

    // For drag and drop of small view in miniMap
    @objc func handlePanGesture(recognizer: UIPanGestureRecognizer) {
        let translation = recognizer.translation(in: self)
        if let view = recognizer.view, let wrappedScrollView = scrollView {
            let viewCenterPoint = CGPoint(
                x: view.center.x + translation.x,
                y: view.center.y + translation.y
            )
            view.center = ViewHelper.fixEdgePoint(
                midPoint: viewCenterPoint,
                bounds: view.frame.size,
                parentsBounds: self.frame.size
            )
            let cW = wrappedScrollView.contentSize.width / self.frame.width
            let cH = wrappedScrollView.contentSize.height / self.frame.height
            let scrollViewPoint = CGPoint(
                x: cW * view.center.x - (wrappedScrollView.frame.width / 2),
                y: cH * view.center.y - (wrappedScrollView.frame.height / 2)
            )

            wrappedScrollView.bounds.origin = scrollViewPoint
        }
        recognizer.setTranslation(CGPoint.zero, in: self)
    }
    
    func drawSmallView() {
        smallView?.removeFromSuperview()
        guard
            var contentSize = scrollView?.contentSize,
            let scrollFrame = scrollView?.frame,
            let offSet = scrollView?.contentOffset
            else { return }

        // To avoid divide by zero
        if contentSize.width == 0.0 || contentSize.height == 0.0 {
            contentSize = scrollFrame.size
        }

        let cW = scrollFrame.width / contentSize.width
        let cH = scrollFrame.height / contentSize.height
        let cOffSetW = offSet.x / contentSize.width
        let cOffSetH = offSet.y / contentSize.height

        smallView = UIView(
            frame: CGRect(
                x: self.frame.width * cOffSetW,
                y: self.frame.height * cOffSetH,
                width: self.frame.width * cW,
                height: self.frame.height * cH
            )
        )

        smallView?.backgroundColor = .clear
        smallView?.layer.borderWidth = 2
        smallView?.layer.borderColor = UIColor.blue.cgColor
        self.backgroundColor = .white
        self.layer.borderWidth = 0.5
        self.addSubview(smallView ?? UIView())

        let pan = UIPanGestureRecognizer.init(target: self, action: #selector(handlePanGesture(recognizer:)))
        smallView?.addGestureRecognizer(pan)
    }

    func updateSmallViewForTapped(point: CGPoint) {
        guard
            let smallViewFrame = smallView?.frame
            else { return }
        smallView?.frame.origin = ViewHelper.fixEdgePoint(
            originPoint: CGPoint(
                x: point.x - smallViewFrame.width / 2,
                y: point.y - smallViewFrame.height / 2
            ),
            bounds: smallViewFrame.size,
            parentsBounds: self.frame.size
        )
    }

    func updateMiniMapLineLayerView(dotInfoArr: [[DotInfo]]) {
        lineLayerView?.removeFromSuperview()
        lineLayerView = CustomView(
            dotInfoArr: dotInfoArr,
            divideBy: scrollView?.frame.size ?? CGSize(width: 1, height: 1)
        )
        lineLayerView?.frame = CGRect(
            origin: .zero,
            size: self.frame.size
        )
        lineLayerView?.backgroundColor = .white
        self.addSubview(lineLayerView ?? UIView())
        if let smallView = smallView {
            self.bringSubviewToFront(smallView)
        }
    }
}

class ViewHelper {
    static func getMiddlePoint(frame: CGRect) -> CGPoint {
        CGPoint(
            x: frame.minX + (frame.width / 2),
            y: frame.minY + (frame.height / 2)
        )
    }

    static func calculateDistance(p1: CGPoint, p2: CGPoint) -> CGFloat {
        let x = (p1.x - p2.x) * (p1.x - p2.x)
        let y = (p1.y - p2.y) * (p1.y - p2.y)
        let z = sqrt(Double(x + y))
        return CGFloat(z)
    }

    static func calculateAngle(p1: CGPoint, p2: CGPoint) -> CGFloat {
        let v1 = CGVector(dx: p1.x - p2.x, dy: p1.y - p2.y)
        let angle = atan2(v1.dy, v1.dx)
        var deg = angle * CGFloat(180.0 / Double.pi)
        if deg < 0 { deg += 360.0 }
        return deg
    }

    static func fixEdgePoint(midPoint: CGPoint, bounds: CGSize, parentsBounds: CGSize) -> CGPoint {
        var newPoint = midPoint
        if midPoint.x - bounds.width / 2 < 0 {
            newPoint.x = bounds.width / 2
        } else if midPoint.x + bounds.width / 2 > parentsBounds.width {
            newPoint.x = parentsBounds.width - bounds.width / 2
        }

        if midPoint.y - bounds.height / 2 < 0 {
            newPoint.y = bounds.height / 2
        } else if midPoint.y + bounds.height / 2 > parentsBounds.height {
            newPoint.y = parentsBounds.height - bounds.height / 2
        }

        return newPoint
    }

    static func fixEdgePoint(originPoint: CGPoint, bounds: CGSize, parentsBounds: CGSize) -> CGPoint {
        let midPoint = CGPoint(
            x: originPoint.x + bounds.width / 2 ,
            y: originPoint.y + bounds.height / 2
        )
        var newPoint = midPoint
        if midPoint.x - bounds.width / 2 < 0 {
            newPoint.x = bounds.width / 2
        } else if midPoint.x + bounds.width / 2 > parentsBounds.width {
            newPoint.x = parentsBounds.width - bounds.width / 2
        }

        if midPoint.y - bounds.height / 2 < 0 {
            newPoint.y = bounds.height / 2
        } else if midPoint.y + bounds.height / 2 > parentsBounds.height {
            newPoint.y = parentsBounds.height - bounds.height / 2
        }

        return CGPoint(
            x: newPoint.x - bounds.width / 2 ,
            y: newPoint.y - bounds.height / 2
        )
    }
}

extension UIView {
    func rotate(angle: CGFloat) {
        let radians = angle / 180.0 * CGFloat.pi
        let rotation = self.transform.rotated(by: radians)
        self.transform = rotation
    }

    func setAnchorPoint(_ point: CGPoint) {
        var newPoint = CGPoint(x: bounds.size.width * point.x, y: bounds.size.height * point.y)
        var oldPoint = CGPoint(x: bounds.size.width * layer.anchorPoint.x, y: bounds.size.height * layer.anchorPoint.y);

        newPoint = newPoint.applying(transform)
        oldPoint = oldPoint.applying(transform)

        var position = layer.position

        position.x -= oldPoint.x
        position.x += newPoint.x

        position.y -= oldPoint.y
        position.y += newPoint.y

        layer.position = position
        layer.anchorPoint = point
    }
}

extension CGPoint {
    func normalizeBy(divideBy: CGSize, mulBy: CGSize) -> CGPoint {
        var newDivideBy = CGSize(width: 1, height: 1)
        if divideBy.width != 0 {
            newDivideBy.width = divideBy.width
        }
        if divideBy.height != 0 {
            newDivideBy.height = divideBy.height
        }

        return CGPoint(
            x: (self.x / divideBy.width) * mulBy.width,
            y: (self.y / divideBy.height) * mulBy.height
        )
    }
}
