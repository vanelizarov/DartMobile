//
//  ViewController.swift
//  DartMobile
//
//  Created by vanya elizarov on 23/02/2019.
//  Copyright © 2019 vanya elizarov. All rights reserved.
//

import UIKit
import JavaScriptCore

let kToolbarHeight: CGFloat = 44.0

class ViewController: UIViewController {
    
    private lazy var codeArea: UITextView = createCodeArea()
    private lazy var resultArea: UITextView = createResultArea()
    private lazy var compileButton: UIBarButtonItem = createCompileButton()
    
    private lazy var window: UIWindow = {
        return UIApplication.shared.keyWindow!
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.navigationBar.isTranslucent = false
        navigationItem.setRightBarButton(compileButton, animated: true)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        view.addSubview(codeArea)
        view.addSubview(resultArea)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillShow),
            name: .UIKeyboardWillShow,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillHide),
            name: .UIKeyboardWillHide,
            object: nil
        )
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        NotificationCenter.default.removeObserver(
            self,
            name: .UIKeyboardWillShow,
            object: nil
        )
        NotificationCenter.default.removeObserver(
            self,
            name: .UIKeyboardWillHide,
            object: nil
        )
    }

    private func createCodeArea() -> UITextView {
        let textView = UITextView(frame: CGRect(x: 0.0,
                                                y: 0.0,
                                                width: view.frame.size.width,
                                                height: (view.frame.size.height - view.safeAreaInsets.bottom) / 2));
        
        textView.font = UIFont(name: "Menlo-Regular", size: 12.0)
        textView.keyboardType = .default
        textView.autocorrectionType = .no
        textView.autocapitalizationType = .none
        
        let toolbar = UIToolbar(frame: CGRect(x: 0.0,
                                                    y: 0.0,
                                                    width: view.frame.size.width,
                                                    height: kToolbarHeight))
        toolbar.barStyle = .default
        toolbar.items = [
            UIBarButtonItem(barButtonSystemItem: .flexibleSpace,
                            target: self,
                            action: nil),
            UIBarButtonItem(title: "Done",
                            style: .done,
                            target: self,
                            action: #selector(hideKeyboard))
        ]
        
        textView.inputAccessoryView = toolbar
        
        return textView
    }
    
    private func createResultArea() -> UITextView {
        let textView = UITextView(frame: CGRect(x: 0.0,
                                                y: (view.frame.size.height - view.safeAreaInsets.bottom) / 2,
                                                width: view.frame.size.width,
                                                height: (view.frame.size.height - view.safeAreaInsets.bottom) / 2))
        textView.font = UIFont(name: "Menlo-Regular", size: 12.0)
        textView.backgroundColor = UIColor(red: 0.97,
                                           green: 0.97,
                                           blue: 0.97,
                                           alpha: 1.0)
        textView.isEditable = false
        
        return textView
    }
    
    private func createCompileButton() -> UIBarButtonItem {
        return UIBarButtonItem(barButtonSystemItem: .play,
                               target: self,
                               action: #selector(compile))
    }
    
    @objc
    private func compile() {
        resultArea.text = ""
        hideKeyboard()
        compileButton.isEnabled = false
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        
        Api.compile(source: codeArea.text!) { (res) in
            guard let js = res?.js else {
                print("failed")
                return
            }

            let ctx = JSContext()
            ctx?.evaluateScript("var console = { log: function(message) { _consoleLog(message) } }")
            let consoleLog: @convention(block) (String) -> Void = { message in
                self.resultArea.text = "\(self.resultArea.text ?? "")\(message)\n"
            }
            ctx?.setObject(unsafeBitCast(consoleLog, to: AnyObject.self), forKeyedSubscript: "_consoleLog" as (NSCopying & NSObjectProtocol)!)
            ctx?.evaluateScript(js)
            
            self.compileButton.isEnabled = true
            UIApplication.shared.isNetworkActivityIndicatorVisible = false
        }
        
    }
    
    @objc
    func keyboardWillShow(_ notification: Notification) {
        if let keyboardSize = (notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            let keyboardHeight = keyboardSize.height
            
            UIView.animate(withDuration: 0.3) {
                self.codeArea.frame.size.height = self.view.frame.size.height - keyboardHeight
                self.resultArea.frame.origin.y = self.view.frame.size.height - keyboardHeight
                self.resultArea.frame.size.height = keyboardHeight
            }
        }
    }
    
    @objc
    func keyboardWillHide(_ notification: Notification) {
        UIView.animate(withDuration: 0.3) {
            self.codeArea.frame.size.height = (self.view.frame.size.height - self.view.safeAreaInsets.bottom) / 2
            self.resultArea.frame.origin.y = (self.view.frame.size.height - self.view.safeAreaInsets.bottom) / 2
            self.resultArea.frame.size.height = (self.view.frame.size.height - self.view.safeAreaInsets.bottom) / 2
        }
    }
    
    @objc
    func hideKeyboard() {
        codeArea.resignFirstResponder()
    }
}

