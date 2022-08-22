//
//  DotsViewController.swift
//  DotDrawer
//
//  Created by Farhad Chowdhury on 21/8/22.
//

import UIKit
import SpriteKit
import GameplayKit

class HighlightedButton: UIButton {
    override var isHighlighted: Bool {
        didSet {
            backgroundColor = isHighlighted ? .gray : .white
        }
    }
}

enum ButtonType {
    case undo
    case startNew
    case draw
    case curve
    case leftCurve
    case rightCurve
    case save
    case na
}

class DotInfo: Equatable {
    static func == (lhs: DotInfo, rhs: DotInfo) -> Bool {
        if lhs.view == rhs.view {
            return true
        } else {
            return false
        }
    }

    var view: UIView
    var midPoint: CGPoint
    var controlPoint: CGPoint = .zero
    var controlPointCurveCount: CGFloat = 0.0

    init(view: UIView) {
        self.view = view
        self.midPoint = ViewHelper.getMiddlePoint(frame: view.frame)
    }
}

struct ButtonInfo {
    var type: ButtonType
    var title: String
    var button: HighlightedButton
    var action: () -> ()
}

class DotsViewController: UIViewController {
    private var scrollViewContainer = UIView()
    private var scrollView = UIScrollView()
    private var dotViewContainer = UIView()
    private var buttonViewContainer = UIView()
    private var lineViewLayer: UIView = UIView()
    private var miniMap: MiniMap?

    private let maxScale: CGFloat = 8.0
    private let miniMapHeight: CGFloat = 100
    private let miniMapWidth: CGFloat = 80
    private var dotViewWidth: CGFloat = 3.0
    private var dotViewsInterSpace: CGFloat = 0.2

    private var controlPointCurveCount: CGFloat = 0.0
    private var controlPointCurveMulti: CGFloat = 10.0

    private var curveButtonState = false
    private var buttonActionDic: [UIButton: ButtonType] = [:]
    private var buttonInfoList: [ButtonInfo] = []
    private var dotInfoArr2d: [[DotInfo]] = [[]]
    private var dotInfoArr: [DotInfo] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.navigationBar.isHidden = true
        mainViewLayoutSetup()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        scrollView.setZoomScale(1.001, animated: false)
        scrollView.setZoomScale(1, animated: false)
    }

    static func makeViewController(dotViewInterSpace: CGFloat, dotViewSize: CGFloat) -> DotsViewController {
        let vc = DotsViewController()
        vc.dotViewsInterSpace = dotViewInterSpace
        vc.dotViewWidth = dotViewSize
        return vc
    }
}

extension DotsViewController: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        //print("viewForZooming")
        MiniMap.updateMiniMap()
        return self.dotViewContainer
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        //print("scrollViewDidScroll")
        scrollView.bounds.origin = ViewHelper.fixEdgePoint(
            originPoint: scrollView.contentOffset,
            bounds: scrollView.frame.size,
            parentsBounds: scrollView.contentSize
        )

        MiniMap.updateMiniMap()
    }

//    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
//        print("scrollViewWillBeginDragging")
//    }
//
//    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
//        print("scrollViewWillEndDragging")
//    }
//
//    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
//        print("scrollViewDidEndDragging")
//    }
//
//    func scrollViewWillBeginDecelerating(_ scrollView: UIScrollView) {
//        print("scrollViewWillBeginDecelerating")
//    }
//
//    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
//        print("scrollViewDidEndDecelerating")
//    }

}

//extension GameViewController: UIGestureRecognizerDelegate {
//    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
//        true
//    }
//}

// MARK: -  Main view's subview setup
extension DotsViewController {
    private func mainViewLayoutSetup() {
        setupButtonViews()
        setupScrollView()
        setupDotViews()
        setupMiniMap()
    }

    private func setupScrollView() {
        let frame = self.view.frame
        scrollViewContainer.frame = CGRect(
            x: frame.minX,
            y: frame.minY + miniMapHeight,
            width: frame.width,
            height: frame.height - miniMapHeight
        )
        scrollViewContainer.backgroundColor = .blue
        scrollViewContainer.addSubview(scrollView)

        self.view.addSubview(scrollViewContainer)

        // the below 2 line makes all 4 constraint value to zero with respect to superview scrollViewContainer
        scrollView.frame.size = scrollViewContainer.frame.size
        scrollView.frame.origin = .zero
        scrollView.delegate = self
        scrollView.maximumZoomScale = maxScale
        scrollView.backgroundColor = .white
    }
}

// MARK: -  Upper layer view for showing the shape
extension DotsViewController {
    private func updateLineLayerView() {
        updateControlPointForLastDot()
        dotInfoArr2d.append(dotInfoArr)
        lineViewLayer.removeFromSuperview()
        lineViewLayer = getLineLayerView(
            frame: CGRect(
                origin: .zero,
                size: dotViewContainer.frame.size
            )
        )
        dotViewContainer.addSubview(lineViewLayer)
        miniMap?.updateMiniMapLineLayerView(dotInfoArr: dotInfoArr2d)
        let _ = dotInfoArr2d.popLast()
    }

    private func getLineLayerView(frame: CGRect = CGRect(origin: .zero, size: .zero)) -> UIView {
        let view = CustomView(
            frame: frame,
            dotInfoArr: dotInfoArr2d,
            divideBy: scrollView.contentSize
        )
        view.backgroundColor = .clear
        return view
    }
}

// MARK: -  Curve line helper function
extension DotsViewController {
    private func updateControlPointForLastDot() {
        guard dotInfoArr.count >= 2 else {
            return
        }

        let lastPoint = dotInfoArr[dotInfoArr.count - 1].midPoint
        let lastPoint2nd = dotInfoArr[dotInfoArr.count - 2].midPoint
        dotInfoArr[dotInfoArr.count - 1].controlPoint = getCurveViewControlPoint(
            p1: lastPoint2nd,
            p2: lastPoint
        )
        print(dotInfoArr[dotInfoArr.count - 1].controlPoint)
    }

    private func getCurveViewControlPoint(p1: CGPoint, p2: CGPoint) -> CGPoint {
        let anyHeight: CGFloat = abs(2 * (controlPointCurveCount * controlPointCurveMulti))
        let dis = ViewHelper.calculateDistance(p1: p1, p2: p2)
        let angle = ViewHelper.calculateAngle(p1: p1, p2: p2)
        let view = UIView(
            frame: CGRect(
                x: p1.x - dis,
                y: (p1.y - (anyHeight / 2)),
                width: dis,
                height: anyHeight
            )
        )

        //view.backgroundColor = .green
        dotViewContainer.addSubview(view)

        var points: [CGPoint] = []
        points.append(view.frame.origin)
        points.append(CGPoint(x: view.frame.minX + view.frame.width, y: view.frame.minY))
        points.append(CGPoint(x: view.frame.minX + view.frame.width, y: view.frame.minY + view.frame.height))
        points.append(CGPoint(x: view.frame.minX, y: view.frame.minY + view.frame.height))

        let firstMidPoint = CGPoint(
            x: view.frame.minX + view.frame.width / 2,
            y: controlPointCurveCount < 0 ? (view.frame.minY + view.frame.height) : view.frame.minY
        )
        print(firstMidPoint)

        view.setAnchorPoint(CGPoint(x: 1.0, y: 0.5))
        view.rotate(angle: angle)

        let resultTrans = view.transform

        var xx: CGFloat = (firstMidPoint.x * resultTrans.a) + (firstMidPoint.y * resultTrans.c) + resultTrans.tx
        var yy: CGFloat = (firstMidPoint.x * resultTrans.b) + (firstMidPoint.y * resultTrans.d) + resultTrans.ty
        let translatedPoint = calculateTranslation(
            rotatedView: view,
            resultTrans: resultTrans,
            points: points,
            angle: angle
        )
        xx = xx + translatedPoint.x
        yy = yy + translatedPoint.y

        view.removeFromSuperview()

        return CGPoint(x: xx, y: yy)
    }

    private func calculateTranslation(
        rotatedView: UIView,
        resultTrans: CGAffineTransform,
        points: [CGPoint],
        angle: CGFloat
    ) -> CGPoint {
        var transPoints: [CGPoint] = []
        for point in points {
            let xxx: CGFloat = (point.x * resultTrans.a) + (point.y * resultTrans.c) + resultTrans.tx
            let yyy: CGFloat = (point.x * resultTrans.b) + (point.y * resultTrans.d) + resultTrans.ty
            transPoints.append(CGPoint(x: xxx, y: yyy))
        }

        let idx = getIndexByAngle(gAngle: angle)
        let xx = rotatedView.frame.minX - transPoints[idx.0].x
        let yy = rotatedView.frame.minY - transPoints[idx.1].y

        return CGPoint(x: xx, y: yy)
    }

    private func getIndexByAngle(gAngle: CGFloat) -> (Int, Int) {
        switch gAngle {
        case 0...90:
            return (3, 0)
        case 90...180:
            return (2, 3)
        case 180...270:
            return (1, 2)
        case 270...360:
            return (0, 1)
        default:
            return (0, 0)
        }
    }
}

// MARK: -  Dot view setup
extension DotsViewController {
    @objc private func tappedOnLabel(_ gesture: UITapGestureRecognizer) {
        guard self.curveButtonState == false else {
            return
        }
        controlPointCurveCount = 0
        guard
            let subView = getTappedDotView(gesture),
            subView.frame.width == dotViewWidth
            else {
            return
        }
        subView.backgroundColor = .black

        dotInfoArr.append(DotInfo(view: subView))
        updateLineLayerView()
    }

    private func getTappedDotView(_ gesture: UITapGestureRecognizer) -> UIView? {
        let tappedPoint = gesture.location(in: dotViewContainer)
        for subView in dotViewContainer.subviews {
            if subView.frame.contains(tappedPoint) {
                return subView
            }
        }
        return nil
    }

    private func setupDotViews() {
        dotViewContainer.frame.origin = .zero
        dotViewContainer.frame.size = scrollView.frame.size
        dotViewContainer.backgroundColor = .white
        scrollView.addSubview(dotViewContainer)

        let tapgesture = UITapGestureRecognizer(target: self, action: #selector(tappedOnLabel(_ :)))
        //tapgesture.delegate = self
        //view.isUserInteractionEnabled = true
        dotViewContainer.addGestureRecognizer(tapgesture)

        putDotViews()
    }

    private func putDotViews() {
        let viewSize = dotViewWidth
        let totalWidth = self.view.frame.width
        let totalHeight = self.view.frame.height

        var x: CGFloat = dotViewsInterSpace
        var y: CGFloat = dotViewsInterSpace

        while true {
            x = dotViewsInterSpace
            while true {
                let view = UIView()
                //view.layer.borderWidth = 0.2
                view.layer.cornerRadius = viewSize / 2
                view.backgroundColor = .cyan
                view.frame = CGRect(x: x, y: y, width: viewSize, height: viewSize)
                dotViewContainer.addSubview(view)
                x = x + dotViewsInterSpace + viewSize
                if x >= totalWidth { break }
            }
            y = y + dotViewsInterSpace + viewSize
            if y >= totalHeight {
                break
            }
        }
    }
}

// MARK: -  Minimap setup
extension DotsViewController {
    private func setupMiniMap() {
        miniMap = MiniMap(
            frame: CGRect(
                origin: CGPoint(
                    x: self.view.frame.width - miniMapWidth,
                    y: 0
                ),
                size: CGSize(
                    width: miniMapWidth,
                    height: miniMapHeight
                )
            ),
            scrollView: scrollView
        )
        self.view.addSubview(miniMap ?? UIView())
    }
}

// MARK: -  Top buttons setup
extension DotsViewController {
    @objc private func buttonAction(sender: UIButton!) {
        guard
            let type = buttonActionDic[sender],
            let buttonInfo = buttonInfoList.first(where: { $0.type == type })
            else { return }

        buttonInfo.action()
    }

    private func setupButtonViews() {
        buttonViewContainer.frame = CGRect(
            x: 0,
            y: 0,
            width: self.view.frame.width - miniMapWidth,
            height: miniMapHeight
        )
        buttonViewContainer.backgroundColor = .yellow
        self.view.addSubview(buttonViewContainer)

        putButtonViews()
        // After button setting few button needs to be disabled.
        enableAllButtonExceptCurve()
    }

    private func putButtonViews() {
        setupButtonInfo()

        let buttonViewsInterSpace: CGFloat = 2
        let numberOfButtonPerRow = 4
        let numberOfButtonPerCol = 2
        let totalWidth = buttonViewContainer.frame.width
        let totalHeight = buttonViewContainer.frame.height
        let availableWidth = totalWidth - (CGFloat(numberOfButtonPerRow + 1) * buttonViewsInterSpace)
        let availableHeight = totalHeight - (CGFloat(numberOfButtonPerCol + 1) * buttonViewsInterSpace)
        let buttonWidth = availableWidth / CGFloat(numberOfButtonPerRow)
        let buttonHeight = availableHeight / CGFloat(numberOfButtonPerCol)


        var x = buttonViewsInterSpace
        var y = buttonViewsInterSpace
        for i in stride(from: 0, to: numberOfButtonPerCol, by: 1) {
            for j in stride(from: 0, to: numberOfButtonPerRow, by: 1) {
                let idx = j + (i * numberOfButtonPerRow)
                var button = UIButton()
                var buttonText = ""
                if idx < buttonInfoList.count {
                    buttonText = buttonInfoList[idx].title
                    button = buttonInfoList[idx].button
                }
                else {
                    buttonText = "NA"
                }
                button.frame = CGRect(
                    x: x,
                    y: y,
                    width: buttonWidth,
                    height: buttonHeight
                )
                button.backgroundColor = .white
                button.setTitleColor(.black, for: .normal)
                button.setTitle(buttonText, for: .normal)
                button.titleLabel?.adjustsFontSizeToFitWidth = true
                button.addTarget(self, action: #selector(buttonAction), for: .touchUpInside)
                button.layer.cornerRadius = buttonWidth / 8
                button.layer.borderWidth = 1
                buttonViewContainer.addSubview(button)
                x = x + (buttonViewsInterSpace + buttonWidth)
                if idx < buttonInfoList.count {
                    buttonActionDic[button] = buttonInfoList[idx].type
                } else {
                    buttonActionDic[button] = .na
                    button.isEnabled = false
                    button.backgroundColor = UIColor.black.withAlphaComponent(0.75)
                }
            }
            x = buttonViewsInterSpace
            y = y + (buttonViewsInterSpace + buttonHeight)
        }
    }

    private func disableAllButtonExceptCurve() {
        for item in buttonInfoList {
            if item.type != .leftCurve && item.type != .rightCurve && item.type != .curve {
                item.button.isEnabled = false
                item.button.backgroundColor = UIColor.black.withAlphaComponent(0.5)
            } else {
                item.button.isEnabled = true
                item.button.backgroundColor = .white
            }
        }
    }

    private func enableAllButtonExceptCurve() {
        for item in buttonInfoList {
            if item.type != .leftCurve && item.type != .rightCurve {
                item.button.isEnabled = true
                item.button.backgroundColor = .white
            } else {
                item.button.isEnabled = false
                item.button.backgroundColor = UIColor.black.withAlphaComponent(0.5)
            }
        }
    }

    private func setupButtonInfo() {
        buttonInfoList.append(
            ButtonInfo(
                type: .undo,
                title: "U",
                button: HighlightedButton(),
                action: {
                    switch (self.dotInfoArr.isEmpty, self.dotInfoArr2d.isEmpty) {
                    case (true, true):
                        return
                    case (true, false):
                        self.dotInfoArr = self.dotInfoArr2d.popLast() ?? []
                    default:
                        break
                    }

                    guard let lastDotInfo = self.dotInfoArr.popLast() else {
                        return
                    }

                    var doContain = false
                    for item in self.dotInfoArr2d {
                        if item.contains(lastDotInfo) {
                            doContain = true
                            break
                        }
                    }
                    if self.dotInfoArr.contains(lastDotInfo) {
                        doContain = true
                    }

                    if doContain == false {
                        lastDotInfo.view.backgroundColor = .cyan
                    }

                    // If the line just before undo is curve
                    if self.dotInfoArr.isEmpty == false {
                        self.controlPointCurveCount = self.dotInfoArr[
                            self.dotInfoArr.count - 1
                        ].controlPointCurveCount
                    }

                    self.updateLineLayerView()
                }
            )
        )

        buttonInfoList.append(
            ButtonInfo(
                type: .startNew,
                title: "S",
                button: HighlightedButton(),
                action: {
                    guard self.dotInfoArr.isEmpty == false else {
                        return
                    }
                    self.dotInfoArr2d.append(self.dotInfoArr)
                    self.dotInfoArr = []
                }
            )
        )

        buttonInfoList.append(
            ButtonInfo(
                type: .draw,
                title: "D",
                button: HighlightedButton(),
                action: {
                    if self.dotInfoArr.isEmpty == false {
                        self.dotInfoArr2d.append(self.dotInfoArr)
                        self.dotInfoArr = []
                    }
                    let vc = CustomViewController.make(
                        dotInfoArr: self.dotInfoArr2d,
                        dividBy: self.scrollView.frame.size
                    )
                    self.present(vc, animated: true)
                }
            )
        )

        buttonInfoList.append(
            ButtonInfo(
                type: .curve,
                title: "C",
                button: HighlightedButton(),
                action: {
                    if self.curveButtonState {
                        self.curveButtonState = false
                        self.enableAllButtonExceptCurve()
                        if self.dotInfoArr.isEmpty == false {
                            self.dotInfoArr[self.dotInfoArr.count - 1].controlPointCurveCount = self.controlPointCurveCount
                        }
                    } else {
                        self.curveButtonState = true
                        self.disableAllButtonExceptCurve()
                        if self.dotInfoArr.isEmpty == false {
                            self.controlPointCurveCount = self.dotInfoArr[
                                self.dotInfoArr.count - 1
                            ].controlPointCurveCount
                        } else {
                            self.controlPointCurveCount = 0.0
                        }
                    }
                }
            )
        )

        buttonInfoList.append(
            ButtonInfo(
                type: .leftCurve,
                title: "<",
                button: HighlightedButton(),
                action: {
                    self.controlPointCurveCount += 1
                    self.updateLineLayerView()
                }
            )
        )

        buttonInfoList.append(
            ButtonInfo(
                type: .rightCurve,
                title: ">",
                button: HighlightedButton(),
                action: {
                    self.controlPointCurveCount -= 1
                    self.updateLineLayerView()
                }
            )
        )

        buttonInfoList.append(
            ButtonInfo(
                type: .save,
                title: "SV",
                button: HighlightedButton(),
                action: {
                    struct PointInfo: Encodable {
                        var p, c: CGPoint
                    }

                    if self.dotInfoArr.isEmpty == false {
                        self.dotInfoArr2d.append(self.dotInfoArr)
                        self.dotInfoArr = []
                    }

                    var pointsArr: [PointInfo] = []
                    for itemArr in self.dotInfoArr2d {
                        for item in itemArr {
                            pointsArr.append(
                                PointInfo(
                                    p: item.midPoint,
                                    c: item.controlPoint
                                )
                            )
                        }
                    }

                    do {
                        let file = "Coordinate.txt"
                        let jsonData = try JSONEncoder().encode(pointsArr)
                        guard
                            let jsonString = String(data: jsonData, encoding: .utf8),
                            let dir = FileManager.default.urls(
                                for: .documentDirectory,
                                in: .userDomainMask
                            ).first
                            else { return }
                        let finalUrl = dir.appendingPathComponent(file)
                        try jsonString.write(to: finalUrl, atomically: false, encoding: .utf8)
                    } catch {
                        print(error)
                    }
                }
            )
        )
    }
}
