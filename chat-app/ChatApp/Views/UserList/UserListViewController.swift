//
//  UserListViewController.swift
//  ChatApp
//
//  Created by William Rena on 8/26/24.
//

import UIKit
import SuperEasyLayout

class UserListViewController: BaseViewController {
    private lazy var searchBarView = {
        let view = SearchBarView()
        view.backgroundColor = .clear
        return view
    }()

    private lazy var layout: UICollectionViewCompositionalLayout = {
        UICollectionViewCompositionalLayout { [weak self] index, _ in
            guard let self, let sections = dataSource?.snapshot().sectionIdentifiers else { fatalError() }

            switch sections[index] {
            case .list: return getUsersSectionLayout()
            case .whole: return getWholeSectionLayout()
            }
        }
    }()

    private lazy var collectionView: UICollectionView = {
        let view = UICollectionView(frame: .zero, collectionViewLayout: layout)
        view.backgroundView = nil
        view.backgroundColor = .white

        NoDataCollectionViewCell.registerCell(to: view)
        UserCollectionViewCell.registerCell(to: view)
        return view
    }()

    private var navigationBar: ChatRoomListNavigationBar? {
        navigationController?.navigationBar as? ChatRoomListNavigationBar
    }
    
    private typealias Section = UserListViewModel.Section
    private typealias Item = UserListViewModel.Item
    private typealias ItemInfo = UserListViewModel.ItemInfo
    private typealias DataSource = UICollectionViewDiffableDataSource<Section, Item>
    private typealias Snapshot = NSDiffableDataSourceSnapshot<Section, Item>
    private var dataSource: DataSource?

    let viewModel = UserListViewModel()

    // MARK: - View Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        Task {
            await IndicatorController.shared.show()
            await viewModel.load()
            await IndicatorController.shared.dismiss()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationBar?.showCloseButtonOnly = true
    }
    
    // MARK: - Setups

    override func setupNavigation() {
        setNavigationBarDefaultStyle()
        navigationBar?.title = "Invite Users"
    }

    override func setupLayout() {
        view.backgroundColor = .main

        addSubviews([
            searchBarView,
            collectionView
        ])
    }

    override func setupConstraints() {
        searchBarView.left == view.left
        searchBarView.right == view.right
        searchBarView.top == view.topMargin + 10

        collectionView.left == view.left
        collectionView.right == view.right
        collectionView.top == searchBarView.bottom + 8
        collectionView.bottom == view.bottom
    }

    override func setupBindings() {
        viewModel.$items
            .receive(on: DispatchQueue.main)
            .sink { [weak self] items in
                self?.apply(items)
            }
            .store(in: &cancellables)

        searchBarView.textPublisher
            .sink { [weak self] text in
                guard let text else { return }
                self?.viewModel.filterByName(searchKey: text)
            }
            .store(in: &cancellables)
    }

    override func setupActions() {
        navigationBar?.closeTapHandler = { [weak self] _ in
            self?.dismiss(animated: true)
        }
    }
}

// MARK: - Navigation

extension UserListViewController {
    static func show(on parentViewController: UIViewController, roomId: Int) {
        let viewController = UserListViewController()
        viewController.viewModel.roomId = roomId

        let navigationController = UINavigationController(navigationBarClass: ChatRoomListNavigationBar.self,
                                                          toolbarClass: nil)
        navigationController.modalPresentationStyle = .overFullScreen
        navigationController.transitioningDelegate = viewController.fadeInAnimator
        navigationController.viewControllers = [viewController]

        parentViewController.present(navigationController, animated: true)
    }
}

// MARK: - Collection Layout

extension UserListViewController {
    private func getUsersSectionLayout() -> NSCollectionLayoutSection {
        let unitSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .estimated(70))
        let item = NSCollectionLayoutItem(layoutSize: unitSize)
        let group = NSCollectionLayoutGroup.vertical(layoutSize: unitSize, subitems: [item])
        return NSCollectionLayoutSection(group: group)
    }

    private func getWholeSectionLayout() -> NSCollectionLayoutSection {
        let unitSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1), heightDimension: .fractionalHeight(1)
        )
        let item = NSCollectionLayoutItem(layoutSize: unitSize)
        let group = NSCollectionLayoutGroup.vertical(layoutSize: unitSize, subitems: [item])
        let section = NSCollectionLayoutSection(group: group)
        return section
    }
}

// MARK: - Set View Based on Data

extension UserListViewController {
    private func apply(_ items: [Section: [Item]]) {
        guard !items.isEmpty else { return }

        var snapshot = Snapshot()
        snapshot.appendSections(items.keys.sorted())

        for (section, subitems) in items {
            snapshot.appendItems(subitems, toSection: section)
        }

        if let dataSource {
            dataSource.apply(snapshot, animatingDifferences: true)
        } else {
            dataSource = DataSource(
                collectionView: collectionView,
                cellProvider: { [weak self] collectionView, indexPath, itemIdentifier in
                    switch itemIdentifier {
                    case .user(let info): self?.getUserCell(at: indexPath, item: info)
                    case .noData: self?.getNoDataCell(at: indexPath)
                    }
                })
            if #available(iOS 15.0, *) {
                dataSource?.applySnapshotUsingReloadData(snapshot)
            } else {
                dataSource?.apply(snapshot)
            }
        }
    }

    private func getUserCell(at indexPath: IndexPath, item: ItemInfo) -> UserCollectionViewCell {
        let cell = UserCollectionViewCell.dequeueCell(from: collectionView, for: indexPath)
        cell.name = item.name
        cell.isInvited = item.isInvited
        cell.inviteHandlerAsync = { [weak self] _ in
            guard let self, !(cell.isInvited ?? false) else { return }

            do {
                await IndicatorController.shared.show()
                try await viewModel.inviteUser(deviceId: item.deviceId)
                await IndicatorController.shared.dismiss()
            } catch {
                print("[UserListViewController] Error! \(error as! NetworkError)")
                await IndicatorController.shared.dismiss()
            }

        }
        return cell
    }

    private func getNoDataCell(at indexPath: IndexPath) -> NoDataCollectionViewCell {
        NoDataCollectionViewCell.dequeueCell(from: collectionView, for: indexPath)
    }
}
