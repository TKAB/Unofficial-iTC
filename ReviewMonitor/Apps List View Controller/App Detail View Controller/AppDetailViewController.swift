//
//  AppDetailViewController.swift
//  ReviewMonitor
//
//  Created by Tayal, Rishabh on 9/26/17.
//  Copyright © 2017 Tayal, Rishabh. All rights reserved.
//

import UIKit

import Presentr

class AppDetailViewController: UIViewController {

    let presenter: Presentr = {
        let presenter = Presentr(presentationType: .dynamic(center: .bottomCenter))
        presenter.transitionType = TransitionType.coverVertical
        presenter.dismissOnSwipe = true
        presenter.blurBackground = true
        return presenter
    }()

    enum SectionType: Int {
        case appStore
        case testflight

        static var numberOfSections = 2
    }

    struct Rows {
        static var appstore = ["Reviews"]
        static var testflight = ["Testers"]
    }

    @IBOutlet var tableView: UITableView!
    @IBOutlet var appImageView: UIImageView!
    @IBOutlet var appNameLabel: UILabel!
    @IBOutlet var platformLabel: UILabel!
    @IBOutlet var lastModifiedLabel: UILabel!

    var app: App!
    var processingBuildCount = 0

    override func viewDidLoad() {
        super.viewDidLoad()
        title = app.name

        appImageView.addBorder(1 / UIScreen.main.scale, color: UIColor.lightGray)
        appImageView.cornerRadius(8)
        if let imageUrl = app.previewUrl {
            appImageView.sd_setImage(with: URL(string: imageUrl)!, completed: nil)
        } else {
            appImageView.image = UIImage(named: "empty_app_icon")
        }
        appNameLabel.text = app.name
        platformLabel.text = app.platforms.joined(separator: ", ")
        let date = Date(timeIntervalSince1970: app.lastModified.doubleValue / 1000)
        lastModifiedLabel.text = "Last modified: \(date.formatDate(format: .MMMddyyy))"

        tableView.dataSource = self
        tableView.delegate = self
        tableView.tableFooterView = UIView()
        view.addSubview(tableView)

        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "View in App Store", style: .plain, target: self, action: #selector(viewInAppStoreTapped))
        // getProcessingBuilds()
        getMetaData()
    }

    @IBOutlet weak var availableLabel: UILabel!
    @IBOutlet weak var versionLabel: UILabel!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var bundleLabel: UILabel!
    @IBOutlet weak var langLabel: UILabel!
    @IBOutlet weak var aw: UILabel!
    @IBOutlet weak var moreButton: UIButton!

    var metadata = AppMetadata()
    var langs = Array<Any>()

    func getMetaData() {
        ServiceCaller.getAppMetadata(bundleId: app.bundleId) { result, error in
            if let r = result as? Dictionary<String, Any> {
                DispatchQueue.main.async {
                    self.metadata = AppMetadata(name: self.app.name, bundleId: self.app.bundleId, dict: r)
                    self.availableLabel.text = self.metadata.available
                    self.versionLabel.text = self.metadata.version
                    self.statusLabel.text = self.metadata.status
                    self.bundleLabel.text = self.app.bundleId
                    self.langLabel.text = self.metadata.languages
                    self.aw.text = self.metadata.watchos

                    self.moreButton.addTarget(self, action: #selector(self.viewAllMetadata), for: .touchUpInside)
                    let swipeUp = UISwipeGestureRecognizer(target: self, action: #selector(self.viewAllMetadata))
                    swipeUp.direction = .up
                    self.view.addGestureRecognizer(swipeUp)
                }
            }
        }
    }

    @objc func viewAllMetadata() {
        let metaVC = AppMetadataViewController(nibName: "AppMetadataViewController", bundle: nil)
        metaVC.metadata = metadata
        let navC = UINavigationController(rootViewController: metaVC)
        customPresentViewController(presenter, viewController: navC, animated: true, completion: nil)
    }

    @objc func viewInAppStoreTapped() {
        let url = URL(string: "https://itunes.apple.com/us/app/app/id" + app.appId)!
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }

    //    func getProcessingBuilds() {
    //        ServiceCaller.getProcessingBuilds(bundleId: app.bundleId) { result, e in
    //            DispatchQueue.main.async {
    //                if let r = result as? [[String: Any]] {
    //                    self.processingBuildCount = r.count
    //                    self.tableView.reloadData()
    //                }
    //            }
    //        }
    //    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if let indexPath = tableView.indexPathForSelectedRow {
            tableView.deselectRow(at: indexPath, animated: true)
        }
    }
}

extension AppDetailViewController: UITableViewDataSource, UITableViewDelegate {

    func numberOfSections(in tableView: UITableView) -> Int {
        return SectionType.numberOfSections
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == SectionType.appStore.rawValue {
            return Rows.appstore.count
        }
        return Rows.testflight.count
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == SectionType.appStore.rawValue {
            return "App Store"
        }
        return "TestFlight"
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell: UITableViewCell? = tableView.dequeueReusableCell(withIdentifier: "cell")
        if cell == nil {
            cell = UITableViewCell(style: .default, reuseIdentifier: "cell")
            cell?.accessoryType = .disclosureIndicator
        }
        if indexPath.section == SectionType.appStore.rawValue {
            cell?.textLabel?.text = Rows.appstore[indexPath.row]
        } else if indexPath.section == SectionType.testflight.rawValue {
            cell?.textLabel?.text = Rows.testflight[indexPath.row]
        } else {
        }

        return cell!
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == SectionType.appStore.rawValue {
            let reviewVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "ReviewsViewController") as! ReviewsViewController
            reviewVC.app = app
            navigationController?.pushViewController(reviewVC, animated: true)
        } else if indexPath.section == SectionType.testflight.rawValue {
            let testersVC = TestersViewController()
            testersVC.app = app
            navigationController?.pushViewController(testersVC, animated: true)
        } else {
            tableView.deselectRow(at: indexPath, animated: true)
        }
    }
}
