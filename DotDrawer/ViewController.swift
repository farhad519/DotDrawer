//
//  ViewController.swift
//  DotDrawer
//
//  Created by Farhad Chowdhury on 21/8/22.
//

import UIKit
import SpriteKit
import GameplayKit

class PaddedLabel: UILabel {
    override func drawText(in rect: CGRect) {
        let insets = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
        super.drawText(in: rect.inset(by: insets))
    }
}

class PaddedTextField: UITextField {
    let padding = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)

    override open func textRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.inset(by: padding)
    }

    override open func placeholderRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.inset(by: padding)
    }

    override open func editingRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.inset(by: padding)
    }
}

struct LabelViewInfo {
    var labelText: String
    var textFieldText: String // Works as default initial value
    let label: PaddedLabel = PaddedLabel()
    let textField: PaddedTextField = PaddedTextField()

    var textFieldValueAsFloat: CGFloat {
        let value = NumberFormatter().number(from: textField.text ?? textFieldText)
        return (value as? CGFloat) ?? 0.0
    }
}

class ViewController: UIViewController {
    private let labelTextFieldContainerView = UIView()
    private let labelTextFieldInfo: [LabelViewInfo] = [
        LabelViewInfo(labelText: "Inter space", textFieldText: "0.2"),
        LabelViewInfo(labelText: "Dot view size", textFieldText: "3")
    ]

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.navigationBar.isHidden = true
        self.view.backgroundColor = .white

        labelTextFieldContainerView.frame = CGRect(
            x: 0,
            y: 150,
            width: self.view.frame.width,
            height: 100
        )
        labelTextFieldContainerView.backgroundColor = .white
        self.view.addSubview(labelTextFieldContainerView)

        setupSubViews()
        DispatchQueue.global(qos: .background).async {
            var cnt = 0
            Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
                print("timer timer tiimer.................")
                cnt += 1
                if cnt == 3 {
                    timer.invalidate()
                }
            }
        }
    }

    @objc private func generateButtonAction(sender: UIButton!) {
        let vc = DotsViewController.makeViewController(
            dotViewInterSpace: labelTextFieldInfo[0].textFieldValueAsFloat,
            dotViewSize: labelTextFieldInfo[1].textFieldValueAsFloat
        )
        navigationController?.pushViewController(vc, animated: true)
    }

    @objc private func defaultButtonAction(sender: UIButton!) {
        for item in labelTextFieldInfo {
            item.textField.text = item.textFieldText
        }
    }

    private func setupSubViews() {
        let insetX: CGFloat = 2.0
        let insetY: CGFloat = 2.0
        let interSpaceRow: CGFloat = 2.0
        let interSpaceCol: CGFloat = 2.0

        let itemPerRow = 2
        let itemPerCol = labelTextFieldInfo.count

        let totalWidth = labelTextFieldContainerView.frame.width
        let totalHeight = labelTextFieldContainerView.frame.height
        let availableWidth = totalWidth - (2 * insetX) - (CGFloat(itemPerRow - 1) * interSpaceRow)
        let availableHeight = totalHeight - (2 * insetY) - (CGFloat(itemPerCol - 1) * interSpaceCol)
        let itemWidth = availableWidth / CGFloat(itemPerRow)
        let itemHeight = availableHeight / CGFloat(itemPerCol)

        var x = insetX
        var y = insetY
        for item in labelTextFieldInfo {
            // Label setup
            item.label.frame = CGRect(
                x: x,
                y: y,
                width: itemWidth,
                height: itemHeight
            )
            item.label.backgroundColor = .white
            item.label.layer.cornerRadius = itemHeight / 4
            item.label.layer.borderWidth = 1
            item.label.text = item.labelText
            labelTextFieldContainerView.addSubview(item.label)

            // Text field setup
            x = x + interSpaceRow + itemWidth
            item.textField.frame = CGRect(
                x: x,
                y: y,
                width: itemWidth,
                height: itemHeight
            )
            item.textField.backgroundColor = .white
            item.textField.layer.cornerRadius = itemHeight / 4
            item.textField.layer.borderWidth = 1
            item.textField.delegate = self
            item.textField.text = item.textFieldText
            item.textField.keyboardType = .numbersAndPunctuation
            labelTextFieldContainerView.addSubview(item.textField)

            x = insetX
            y = y + interSpaceCol + itemHeight
        }

        let generateButton = UIButton(
            frame: CGRect(
                x: x,
                y: y,
                width: itemWidth,
                height: itemHeight
            )
        )
        generateButton.backgroundColor = .blue
        generateButton.setTitleColor(.white, for: .normal)
        generateButton.setTitle("Generate", for: .normal)
        generateButton.titleLabel?.adjustsFontSizeToFitWidth = true
        generateButton.addTarget(self, action: #selector(generateButtonAction), for: .touchUpInside)
        //generateButton.layer.borderWidth = 1
        generateButton.layer.cornerRadius = itemHeight / 4
        self.view.addSubview(generateButton)

        x = x + interSpaceRow + itemWidth

        let defaultButton = UIButton(
            frame: CGRect(
                x: x,
                y: y,
                width: itemWidth,
                height: itemHeight
            )
        )
        defaultButton.backgroundColor = .blue
        defaultButton.setTitleColor(.white, for: .normal)
        defaultButton.setTitle("Default", for: .normal)
        defaultButton.titleLabel?.adjustsFontSizeToFitWidth = true
        defaultButton.addTarget(self, action: #selector(defaultButtonAction), for: .touchUpInside)
        //defaultButton.layer.borderWidth = 1
        defaultButton.layer.cornerRadius = itemHeight / 4
        self.view.addSubview(defaultButton)
    }
}

extension ViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        //textField.endEditing(true)
    }
}
