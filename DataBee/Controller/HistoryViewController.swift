//
//  HistoryViewController.swift
//  DataBee
//

import UIKit

/// Full-screen chat history with a back button and local (offline) search.
class HistoryViewController: UIViewController {

    /// Called after the screen pops, with the chat the user picked.
    var onSelect: ((ChatInfo) -> Void)?

    /// Always reads the locally cached history; updated in the background.
    private var chats: [ChatInfo] { ChatHistoryStore.shared.chats }

    private var filteredChats: [ChatInfo] = []
    private let tableView = UITableView()
    private let emptyLabel = UILabel()
    private var searchTextField: UITextField!

    override func viewDidLoad() {
        super.viewDidLoad()
        buildLayout()
        refreshList()

        // Reload live when the background refresh overwrites the cache.
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(historyDidUpdate),
                                               name: ChatHistoryStore.didUpdate,
                                               object: nil)
        ChatHistoryStore.shared.refresh()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    // MARK: - Layout

    private func buildLayout() {
        let background = GradientView()
        background.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(background)

        // Header: back button + centered title.
        let headerView = UIView()
        headerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(headerView)

        let backButton = UIButton(type: .system)
        backButton.setImage(UIImage(systemName: "chevron.left",
                                    withConfiguration: UIImage.SymbolConfiguration(pointSize: 20, weight: .semibold)),
                            for: .normal)
        backButton.tintColor = Theme.teal
        backButton.addTarget(self, action: #selector(tapOnBack), for: .touchUpInside)
        backButton.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(backButton)

        let titleLabel = UILabel()
        titleLabel.text = "History"
        titleLabel.font = Theme.bold(24)
        titleLabel.textColor = Theme.teal
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(titleLabel)

        // Local search — filters the list as you type, no API call.
        let searchField = ThemeFactory.iconTextField(placeholder: "Search history...", systemImage: "magnifyingglass")
        searchTextField = searchField.textField
        searchTextField.returnKeyType = .done
        searchTextField.delegate = self
        searchTextField.addTarget(self, action: #selector(searchTextChanged), for: .editingChanged)
        searchField.container.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(searchField.container)

        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.keyboardDismissMode = .onDrag
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(HistoryCell.self, forCellReuseIdentifier: HistoryCell.reuseId)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)

        emptyLabel.font = Theme.medium(16)
        emptyLabel.textColor = Theme.teal.withAlphaComponent(0.6)
        emptyLabel.textAlignment = .center
        emptyLabel.numberOfLines = 0
        emptyLabel.isHidden = true
        emptyLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(emptyLabel)

        NSLayoutConstraint.activate([
            background.topAnchor.constraint(equalTo: view.topAnchor),
            background.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            background.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            background.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            headerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            headerView.heightAnchor.constraint(equalToConstant: 56),

            backButton.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 12),
            backButton.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            backButton.widthAnchor.constraint(equalToConstant: 44),
            backButton.heightAnchor.constraint(equalToConstant: 44),

            titleLabel.centerXAnchor.constraint(equalTo: headerView.centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),

            searchField.container.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 8),
            searchField.container.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            searchField.container.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            tableView.topAnchor.constraint(equalTo: searchField.container.bottomAnchor, constant: 12),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.keyboardLayoutGuide.topAnchor),

            emptyLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyLabel.topAnchor.constraint(equalTo: searchField.container.bottomAnchor, constant: 60),
            emptyLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            emptyLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40)
        ])
    }

    // MARK: - Actions

    @objc private func tapOnBack() {
        navigationController?.popViewController(animated: true)
    }

    @objc private func historyDidUpdate() {
        refreshList()
    }

    @objc private func searchTextChanged() {
        refreshList()
    }

    /// Applies the current search text to the cached chats and reloads.
    private func refreshList() {
        let query = (searchTextField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        if query.isEmpty {
            filteredChats = chats
        } else {
            filteredChats = chats.filter { chat in
                chat.title.localizedCaseInsensitiveContains(query)
                    || chat.messages.contains { $0.content.localizedCaseInsensitiveContains(query) }
            }
        }
        emptyLabel.text = chats.isEmpty ? "Loading history..." : "No matching chats found."
        emptyLabel.isHidden = !filteredChats.isEmpty
        tableView.reloadData()
    }
}

// MARK: - Table DataSource / Delegate

extension HistoryViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        filteredChats.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: HistoryCell.reuseId, for: indexPath) as! HistoryCell
        cell.configure(title: filteredChats[indexPath.row].title)
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let chat = filteredChats[indexPath.row]
        navigationController?.popViewController(animated: true)
        onSelect?(chat)
    }
}

extension HistoryViewController: UITextFieldDelegate {

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}

// MARK: - Cell

/// Rounded pill row showing a chat title.
private final class HistoryCell: UITableViewCell {

    static let reuseId = "HistoryCell"

    private let pillView = UIView()
    private let titleLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear
        selectionStyle = .none

        pillView.backgroundColor = .white
        pillView.layer.cornerRadius = 12
        pillView.layer.borderWidth = 1
        pillView.layer.borderColor = Theme.fieldBorder.cgColor
        pillView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(pillView)

        titleLabel.font = Theme.medium(15)
        titleLabel.textColor = .darkText
        titleLabel.numberOfLines = 1
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        pillView.addSubview(titleLabel)

        NSLayoutConstraint.activate([
            pillView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 5),
            pillView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -5),
            pillView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            pillView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),

            titleLabel.topAnchor.constraint(equalTo: pillView.topAnchor, constant: 13),
            titleLabel.bottomAnchor.constraint(equalTo: pillView.bottomAnchor, constant: -13),
            titleLabel.leadingAnchor.constraint(equalTo: pillView.leadingAnchor, constant: 14),
            titleLabel.trailingAnchor.constraint(equalTo: pillView.trailingAnchor, constant: -14)
        ])
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure(title: String) {
        titleLabel.text = title
    }
}
