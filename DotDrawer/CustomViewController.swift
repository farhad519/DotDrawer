//
//  CustomViewController.swift
//  DotDrawer
//
//  Created by Farhad Chowdhury on 21/8/22.
//

import UIKit

class CustomView: UIView {
    private var dotInfoArr: [[DotInfo]] = [[]]
    private var divideBy: CGSize = CGSize(width: 1, height: 1)
    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    convenience init(frame: CGRect, dotInfoArr: [[DotInfo]], divideBy: CGSize) {
        self.init(frame: frame)
        self.dotInfoArr = dotInfoArr
        self.divideBy = divideBy
    }

    convenience init(dotInfoArr: [[DotInfo]], divideBy: CGSize) {
        self.init(frame: .zero)
        self.dotInfoArr = dotInfoArr
        self.divideBy = divideBy
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("This class does not support NSCoding")
    }

    override func draw(_ rect: CGRect) {
//        let maxX = dotInfoArr
//            .flatMap({ $0 })
//            .flatMap({ [$0.midPoint.x, $0.controlPoint.x] })
//            .max() ?? 1
//        let maxY = dotInfoArr
//            .flatMap({ $0 })
//            .flatMap({ [$0.midPoint.y, $0.controlPoint.y] })
//            .max() ?? 1

//        let divideBy = CGPoint(
//            x: 320,
//            y: 380
//        )

        for dotInfos in dotInfoArr {
            let path = UIBezierPath()
            var lastPoint: CGPoint = .zero
            for i in 0..<dotInfos.count {
                if i == 0 {
                    lastPoint = dotInfos[i].midPoint
                    path.move(
                        to: lastPoint.normalizeBy(
                            divideBy: divideBy,
                            mulBy: rect.size
                        )
                    )
                    continue
                }

                path.addQuadCurve(
                    to: dotInfos[i].midPoint.normalizeBy(divideBy: divideBy, mulBy: rect.size),
                    controlPoint: dotInfos[i].controlPoint.normalizeBy(divideBy: divideBy, mulBy: rect.size)
                )
                path.move(to: dotInfos[i].midPoint.normalizeBy(divideBy: divideBy, mulBy: rect.size))
                path.stroke()
                lastPoint = dotInfos[i].midPoint
            }
        }
    }
}

class CustomViewController: UIViewController {
    var dotInfoArr: [[DotInfo]] = [[]]
    var divideBy: CGSize = CGSize(width: 1, height: 1)
    static func make(dotInfoArr: [[DotInfo]], dividBy: CGSize) -> CustomViewController {
        let vc = CustomViewController()
        vc.dotInfoArr = dotInfoArr
        vc.divideBy = dividBy
        return vc
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        let view = CustomView(dotInfoArr: dotInfoArr, divideBy: divideBy)
        self.view.addSubview(view)
        view.frame = self.view.frame
        view.backgroundColor = .white
    }
}
