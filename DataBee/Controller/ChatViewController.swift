//
//  ChatViewController.swift
//  DataBee
//

import UIKit

/// The main chat screen shown after login: a DataBee header with a side menu
/// (New Chat / History / Logout), the conversation area, and the ask bar.
class ChatViewController: UIViewController {

    // MARK: - Chat display model

    private enum Bubble {
        case user(String)
        case bot(String)
        case table(columns: [String], rows: [[String]])
        /// Spinner bubble shown while the AI is answering.
        case loading
    }

    private var bubbles: [Bubble] = []
    /// The chat the conversation belongs to; nil until the first question of a new chat.
    private var currentChatId: Int?
    private var isAsking = false

    // MARK: - Views

    private let tableView = UITableView()
    private let emptyStateLabel = UILabel()
    private var inputTextField: UITextField!

    private let dimView = UIView()
    private let menuView = UIView()
    private var menuLeadingConstraint: NSLayoutConstraint!
    private var isMenuOpen = false
    private let menuWidth: CGFloat = 300

    override func viewDidLoad() {
        super.viewDidLoad()
        buildLayout()
        buildSideMenu()
        showEmptyStateIfNeeded()
        // Refresh the locally cached chat history in the background.
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

        // Header: hamburger + centered title.
        let headerView = UIView()
        headerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(headerView)

        let menuButton = UIButton(type: .system)
        menuButton.setImage(UIImage(systemName: "line.3.horizontal",
                                    withConfiguration: UIImage.SymbolConfiguration(pointSize: 22, weight: .semibold)),
                            for: .normal)
        menuButton.tintColor = Theme.teal
        menuButton.addTarget(self, action: #selector(tapOnMenu), for: .touchUpInside)
        menuButton.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(menuButton)

        let titleLabel = UILabel()
        titleLabel.text = "DataBee"
        titleLabel.font = Theme.bold(28)
        titleLabel.textColor = Theme.teal
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(titleLabel)

        // Ask bar pinned above the keyboard.
        let inputBar = UIView()
        inputBar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(inputBar)

        let field = ThemeFactory.iconTextField(placeholder: "Ask a question about your data...",
                                               systemImage: "text.bubble")
        inputTextField = field.textField
        inputTextField.returnKeyType = .send
        inputTextField.delegate = self
        field.container.translatesAutoresizingMaskIntoConstraints = false
        inputBar.addSubview(field.container)

        let sendButton = UIButton(type: .system)
        sendButton.setImage(UIImage(systemName: "paperplane.fill",
                                    withConfiguration: UIImage.SymbolConfiguration(pointSize: 20, weight: .medium)),
                            for: .normal)
        sendButton.tintColor = .white
        sendButton.backgroundColor = Theme.teal
        sendButton.layer.cornerRadius = 14
        sendButton.addTarget(self, action: #selector(tapOnSend), for: .touchUpInside)
        sendButton.translatesAutoresizingMaskIntoConstraints = false
        inputBar.addSubview(sendButton)

        // Conversation area.
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.allowsSelection = false
        tableView.keyboardDismissMode = .interactive
        tableView.dataSource = self
        tableView.register(BubbleCell.self, forCellReuseIdentifier: BubbleCell.reuseId)
        tableView.register(TableCardCell.self, forCellReuseIdentifier: TableCardCell.reuseId)
        tableView.register(LoadingBubbleCell.self, forCellReuseIdentifier: LoadingBubbleCell.reuseId)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)

        emptyStateLabel.font = Theme.medium(17)
        emptyStateLabel.textColor = Theme.teal.withAlphaComponent(0.6)
        emptyStateLabel.textAlignment = .center
        emptyStateLabel.numberOfLines = 0
        emptyStateLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(emptyStateLabel)

        NSLayoutConstraint.activate([
            background.topAnchor.constraint(equalTo: view.topAnchor),
            background.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            background.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            background.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            headerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            headerView.heightAnchor.constraint(equalToConstant: 56),

            menuButton.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 16),
            menuButton.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            menuButton.widthAnchor.constraint(equalToConstant: 44),
            menuButton.heightAnchor.constraint(equalToConstant: 44),

            titleLabel.centerXAnchor.constraint(equalTo: headerView.centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),

            tableView.topAnchor.constraint(equalTo: headerView.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: inputBar.topAnchor),

            emptyStateLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyStateLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            emptyStateLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            emptyStateLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),

            inputBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            inputBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            inputBar.bottomAnchor.constraint(equalTo: view.keyboardLayoutGuide.topAnchor),

            field.container.topAnchor.constraint(equalTo: inputBar.topAnchor, constant: 10),
            field.container.leadingAnchor.constraint(equalTo: inputBar.leadingAnchor, constant: 16),
            field.container.bottomAnchor.constraint(equalTo: inputBar.bottomAnchor, constant: -10),

            sendButton.leadingAnchor.constraint(equalTo: field.container.trailingAnchor, constant: 10),
            sendButton.trailingAnchor.constraint(equalTo: inputBar.trailingAnchor, constant: -16),
            sendButton.centerYAnchor.constraint(equalTo: field.container.centerYAnchor),
            sendButton.widthAnchor.constraint(equalToConstant: 58),
            sendButton.heightAnchor.constraint(equalToConstant: 58)
        ])
    }

    // MARK: - Side Menu

    private func buildSideMenu() {
        dimView.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        dimView.alpha = 0
        dimView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(dimView)
        dimView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(closeMenu)))

        menuView.backgroundColor = .white
        menuView.layer.shadowColor = UIColor.black.cgColor
        menuView.layer.shadowOpacity = 0.15
        menuView.layer.shadowRadius = 10
        menuView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(menuView)

        let loggedInLabel = UILabel()
        let userName = Session.shared.currentUser?.name ?? ""
        let loggedInText = NSMutableAttributedString(
            string: "Logged in as: ",
            attributes: [.font: Theme.regular(15), .foregroundColor: UIColor.darkGray])
        loggedInText.append(NSAttributedString(
            string: userName,
            attributes: [.font: Theme.semiBold(15), .foregroundColor: Theme.teal]))
        loggedInLabel.attributedText = loggedInText
        loggedInLabel.numberOfLines = 0
        loggedInLabel.translatesAutoresizingMaskIntoConstraints = false
        menuView.addSubview(loggedInLabel)

        let separator = UIView()
        separator.backgroundColor = Theme.fieldBorder
        separator.translatesAutoresizingMaskIntoConstraints = false
        menuView.addSubview(separator)

        // Menu options: icon rows.
        let newChatRow = menuRow(icon: "square.and.pencil", title: "New Chat", action: #selector(tapOnNewChat))
        let historyRow = menuRow(icon: "clock.arrow.circlepath", title: "History", showsChevron: true, action: #selector(tapOnHistory))
        let logoutRow = menuRow(icon: "rectangle.portrait.and.arrow.right", title: "Logout",
                                tint: Theme.orange, action: #selector(tapOnLogout))

        let menuStack = UIStackView(arrangedSubviews: [newChatRow, hairline(), historyRow, hairline(), logoutRow, hairline()])
        menuStack.axis = .vertical
        menuStack.translatesAutoresizingMaskIntoConstraints = false
        menuView.addSubview(menuStack)

        menuLeadingConstraint = menuView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: -menuWidth)

        NSLayoutConstraint.activate([
            dimView.topAnchor.constraint(equalTo: view.topAnchor),
            dimView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            dimView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            dimView.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            menuLeadingConstraint,
            menuView.topAnchor.constraint(equalTo: view.topAnchor),
            menuView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            menuView.widthAnchor.constraint(equalToConstant: menuWidth),

            loggedInLabel.topAnchor.constraint(equalTo: menuView.safeAreaLayoutGuide.topAnchor, constant: 20),
            loggedInLabel.leadingAnchor.constraint(equalTo: menuView.leadingAnchor, constant: 20),
            loggedInLabel.trailingAnchor.constraint(equalTo: menuView.trailingAnchor, constant: -20),

            separator.topAnchor.constraint(equalTo: loggedInLabel.bottomAnchor, constant: 16),
            separator.leadingAnchor.constraint(equalTo: menuView.leadingAnchor),
            separator.trailingAnchor.constraint(equalTo: menuView.trailingAnchor),
            separator.heightAnchor.constraint(equalToConstant: 1),

            menuStack.topAnchor.constraint(equalTo: separator.bottomAnchor, constant: 8),
            menuStack.leadingAnchor.constraint(equalTo: menuView.leadingAnchor),
            menuStack.trailingAnchor.constraint(equalTo: menuView.trailingAnchor)
        ])
    }

    private func hairline() -> UIView {
        let line = UIView()
        line.backgroundColor = Theme.fieldBorder.withAlphaComponent(0.6)
        line.heightAnchor.constraint(equalToConstant: 1 / UIScreen.main.scale).isActive = true
        return line
    }

    /// A side-menu option row: leading icon, title and an optional chevron.
    private func menuRow(icon: String, title: String, tint: UIColor = Theme.teal,
                         showsChevron: Bool = false, action: Selector) -> UIControl {
        let row = UIControl()
        row.heightAnchor.constraint(equalToConstant: 56).isActive = true
        row.addTarget(self, action: action, for: .touchUpInside)

        let iconView = UIImageView(image: UIImage(systemName: icon,
                                                  withConfiguration: UIImage.SymbolConfiguration(pointSize: 19, weight: .medium)))
        iconView.tintColor = tint
        iconView.contentMode = .scaleAspectFit
        iconView.isUserInteractionEnabled = false
        iconView.translatesAutoresizingMaskIntoConstraints = false
        row.addSubview(iconView)

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = Theme.semiBold(17)
        titleLabel.textColor = tint == Theme.orange ? Theme.orange : .darkText
        titleLabel.isUserInteractionEnabled = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        row.addSubview(titleLabel)

        NSLayoutConstraint.activate([
            iconView.leadingAnchor.constraint(equalTo: row.leadingAnchor, constant: 20),
            iconView.centerYAnchor.constraint(equalTo: row.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 26),
            iconView.heightAnchor.constraint(equalToConstant: 26),

            titleLabel.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 16),
            titleLabel.centerYAnchor.constraint(equalTo: row.centerYAnchor)
        ])

        if showsChevron {
            let chevron = UIImageView(image: UIImage(systemName: "chevron.right",
                                                     withConfiguration: UIImage.SymbolConfiguration(pointSize: 14, weight: .semibold)))
            chevron.tintColor = Theme.fieldIcon
            chevron.isUserInteractionEnabled = false
            chevron.translatesAutoresizingMaskIntoConstraints = false
            row.addSubview(chevron)
            NSLayoutConstraint.activate([
                chevron.trailingAnchor.constraint(equalTo: row.trailingAnchor, constant: -20),
                chevron.centerYAnchor.constraint(equalTo: row.centerYAnchor)
            ])
        }
        return row
    }

    @objc private func tapOnMenu() {
        view.endEditing(true)
        setMenu(open: !isMenuOpen)
    }

    @objc private func closeMenu() {
        setMenu(open: false)
    }

    private func setMenu(open: Bool) {
        isMenuOpen = open
        menuLeadingConstraint.constant = open ? 0 : -menuWidth
        UIView.animate(withDuration: 0.28, delay: 0, options: .curveEaseInOut) {
            self.dimView.alpha = open ? 1 : 0
            self.view.layoutIfNeeded()
        }
    }

    // MARK: - Data

    private func showChat(_ chat: ChatInfo) {
        currentChatId = chat.chatId
        bubbles = []
        for message in chat.messages {
            let content = message.content.trimmingCharacters(in: .whitespacesAndNewlines)
            if !content.isEmpty {
                bubbles.append(.user(content))
            }
            bubbles.append(contentsOf: Self.botBubbles(fromAttributes: message.attributes))
        }
        tableView.reloadData()
        showEmptyStateIfNeeded()
        scrollToBottom(animated: false)

        // Like the web app: opening a history chat automatically re-asks
        // the chat's question so the answer is fresh.
        sendQuestion(chat.title)
    }

    /// The full ask pipeline, same as the web app:
    /// query API → render reply → save both messages → refresh history.
    private func sendQuestion(_ question: String) {
        let text = question.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, !isAsking else { return }
        isAsking = true

        // New chats get the next id after the newest existing chat.
        let chatId = currentChatId ?? ((ChatHistoryStore.shared.chats.map(\.chatId).max() ?? 0) + 1)
        currentChatId = chatId

        bubbles.append(.user(text))
        bubbles.append(.loading)
        let placeholderIndex = bubbles.count - 1
        tableView.reloadData()
        showEmptyStateIfNeeded()
        scrollToBottom(animated: true)

        let userId = Session.shared.currentUser?.contactID ?? "1"
        let dbName = Session.shared.dbName
        Task {
            defer { isAsking = false }
            do {
                let raw = try await APIClient.shared.query(question: text,
                                                           userId: userId,
                                                           chatId: chatId,
                                                           dbName: dbName)
                let replies = Self.botBubbles(fromAttributes: raw)
                bubbles.remove(at: placeholderIndex)
                bubbles.insert(contentsOf: replies.isEmpty ? [.bot("No result.")] : replies, at: placeholderIndex)
                tableView.reloadData()
                scrollToBottom(animated: true)

                // Persist the question and the reply (two saveChatMessageInfo
                // calls, like the web), then refresh the local history.
                let json = (try? JSONSerialization.jsonObject(with: Data(raw.utf8))) as? [String: Any]
                let userAttributes = (json?["sql_query_columns"] as? String) ?? ""
                let botText = (json?["text"] as? String) ?? (json?["messageContent"] as? String) ?? ""

                // The web stores the reply JSON compact, not pretty-printed.
                var botAttributes = raw
                if let json,
                   let compact = try? JSONSerialization.data(withJSONObject: json),
                   let compactString = String(data: compact, encoding: .utf8) {
                    botAttributes = compactString
                }

                try? await APIClient.shared.saveChatMessage(chatId: chatId, userId: userId,
                                                            messageContent: text, attributes: userAttributes)
                try? await APIClient.shared.saveChatMessage(chatId: chatId, userId: userId,
                                                            messageContent: botText, attributes: botAttributes)
                ChatHistoryStore.shared.refresh()
            } catch {
                if placeholderIndex < bubbles.count {
                    bubbles[placeholderIndex] = .bot(error.localizedDescription)
                    tableView.reloadData()
                }
            }
        }
    }

    /// The `Attributes` field carries the bot's reply as JSON:
    /// a `text`/`messageContent` sentence and optionally a `table` of rows
    /// (with `columns` keys and display names in `sql_query_columns`).
    private static func botBubbles(fromAttributes attributes: String) -> [Bubble] {
        let trimmed = attributes.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }
        guard let data = trimmed.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            // Some legacy replies are plain text instead of JSON.
            return [.bot(trimmed)]
        }

        var result: [Bubble] = []

        let text = (json["text"] as? String) ?? (json["messageContent"] as? String) ?? ""
        if !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            result.append(.bot(text))
        }

        if let table = json["table"] as? [[String: Any]], !table.isEmpty {
            let keys = (json["columns"] as? [String]) ?? Array(table[0].keys.sorted())
            // Prefer the human-readable column names when they line up.
            var headers = keys
            if let displayNames = json["sql_query_columns"] as? String {
                let parts = displayNames.components(separatedBy: ",")
                    .map { $0.trimmingCharacters(in: .whitespaces) }
                    .filter { !$0.isEmpty }
                if parts.count == keys.count { headers = parts }
            }
            let rows = table.map { row in keys.map { Self.cellText(row[$0]) } }
            result.append(.table(columns: headers, rows: rows))
        }
        return result
    }

    private static func cellText(_ value: Any?) -> String {
        switch value {
        case nil, is NSNull: return "N/A"
        case let string as String:
            let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed.isEmpty ? "N/A" : string
        case let number as NSNumber: return number.stringValue
        default: return "\(value!)"
        }
    }

    private func showEmptyStateIfNeeded() {
        let name = Session.shared.currentUser?.name ?? ""
        emptyStateLabel.text = name.isEmpty
            ? "Ask a question about your data to get started."
            : "Hi \(name), ask a question about your data to get started."
        emptyStateLabel.isHidden = !bubbles.isEmpty
    }

    private func scrollToBottom(animated: Bool) {
        guard !bubbles.isEmpty else { return }
        tableView.scrollToRow(at: IndexPath(row: bubbles.count - 1, section: 0), at: .bottom, animated: animated)
    }

    // MARK: - Actions

    @objc private func tapOnNewChat() {
        currentChatId = nil
        bubbles = []
        tableView.reloadData()
        showEmptyStateIfNeeded()
        closeMenu()
    }

    @objc private func tapOnHistory() {
        closeMenu()
        let historyViewController = HistoryViewController()
        historyViewController.onSelect = { [weak self] chat in
            self?.showChat(chat)
        }
        navigationController?.pushViewController(historyViewController, animated: true)
    }

    @objc private func tapOnSend() {
        let text = (inputTextField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, !isAsking else { return }
        inputTextField.text = ""
        sendQuestion(text)
    }

    @objc private func tapOnLogout() {
        let alert = UIAlertController(title: "DataBee",
                                      message: "Are you sure you want to logout?",
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Logout", style: .destructive) { [weak self] _ in
            self?.logout()
        })
        present(alert, animated: true)
    }

    private func logout() {
        Session.shared.logout()
        ChatHistoryStore.shared.clear()
        guard let window = view.window else { return }
        // Back to Login (pre-filled), keeping Company Auth beneath for back navigation.
        let navigationController = UINavigationController(rootViewController: CompanyAuthViewController())
        navigationController.viewControllers = [CompanyAuthViewController(), LoginViewController()]
        navigationController.setNavigationBarHidden(true, animated: false)
        window.rootViewController = navigationController
        UIView.transition(with: window, duration: 0.35, options: .transitionCrossDissolve, animations: nil)
    }
}

// MARK: - Table DataSource

extension ChatViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        bubbles.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch bubbles[indexPath.row] {
        case .user(let text):
            let cell = tableView.dequeueReusableCell(withIdentifier: BubbleCell.reuseId, for: indexPath) as! BubbleCell
            cell.configure(text: text, isUser: true)
            return cell
        case .bot(let text):
            let cell = tableView.dequeueReusableCell(withIdentifier: BubbleCell.reuseId, for: indexPath) as! BubbleCell
            cell.configure(text: text, isUser: false)
            return cell
        case .table(let columns, let rows):
            let cell = tableView.dequeueReusableCell(withIdentifier: TableCardCell.reuseId, for: indexPath) as! TableCardCell
            cell.configure(columns: columns, rows: rows)
            return cell
        case .loading:
            let cell = tableView.dequeueReusableCell(withIdentifier: LoadingBubbleCell.reuseId, for: indexPath) as! LoadingBubbleCell
            cell.startSpinner()
            return cell
        }
    }
}

extension ChatViewController: UITextFieldDelegate {

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        tapOnSend()
        return true
    }
}

// MARK: - Cells

/// Left-aligned bubble with a spinner and the "please hold on" text,
/// shown while the AI query is running — same as the web app.
private final class LoadingBubbleCell: UITableViewCell {

    static let reuseId = "LoadingBubbleCell"

    private let spinner = UIActivityIndicatorView(style: .medium)

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear
        selectionStyle = .none

        let bubbleView = UIView()
        bubbleView.backgroundColor = .white
        bubbleView.layer.cornerRadius = 16
        bubbleView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(bubbleView)

        spinner.color = Theme.teal
        spinner.translatesAutoresizingMaskIntoConstraints = false
        bubbleView.addSubview(spinner)

        let messageLabel = UILabel()
        messageLabel.text = "Please hold on while I look up the data for you..."
        messageLabel.font = Theme.medium(15)
        messageLabel.textColor = Theme.teal
        messageLabel.numberOfLines = 0
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        bubbleView.addSubview(messageLabel)

        NSLayoutConstraint.activate([
            bubbleView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6),
            bubbleView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -6),
            bubbleView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            bubbleView.widthAnchor.constraint(lessThanOrEqualTo: contentView.widthAnchor, multiplier: 0.85),

            spinner.leadingAnchor.constraint(equalTo: bubbleView.leadingAnchor, constant: 14),
            spinner.centerYAnchor.constraint(equalTo: bubbleView.centerYAnchor),

            messageLabel.leadingAnchor.constraint(equalTo: spinner.trailingAnchor, constant: 10),
            messageLabel.trailingAnchor.constraint(equalTo: bubbleView.trailingAnchor, constant: -14),
            messageLabel.topAnchor.constraint(equalTo: bubbleView.topAnchor, constant: 10),
            messageLabel.bottomAnchor.constraint(equalTo: bubbleView.bottomAnchor, constant: -10)
        ])
        spinner.hidesWhenStopped = false
        spinner.startAnimating()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    /// UIKit stops the animation whenever the cell leaves the window or is
    /// reused, which left an empty gap next to the text — restart everywhere.
    func startSpinner() {
        spinner.startAnimating()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        spinner.startAnimating()
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        if window != nil { spinner.startAnimating() }
    }
}

/// A white "Data" card with a teal header row and a grid of values,
/// horizontally scrollable when the table is wider than the screen —
/// matches the table cards on the DataBee web chat.
private final class TableCardCell: UITableViewCell {

    static let reuseId = "TableCardCell"
    private static let maxRows = 100

    private let cardView = UIView()
    private let titleLabel = UILabel()
    private let scrollView = UIScrollView()
    private let gridStack = UIStackView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear
        selectionStyle = .none

        cardView.backgroundColor = .white
        cardView.layer.cornerRadius = 14
        cardView.layer.borderWidth = 1
        cardView.layer.borderColor = Theme.fieldBorder.cgColor
        cardView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(cardView)

        titleLabel.text = "Data"
        titleLabel.font = Theme.semiBold(16)
        titleLabel.textColor = Theme.teal
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(titleLabel)

        scrollView.showsHorizontalScrollIndicator = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(scrollView)

        gridStack.axis = .vertical
        gridStack.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(gridStack)

        NSLayoutConstraint.activate([
            cardView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6),
            cardView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -6),
            cardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            cardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),

            titleLabel.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 12),
            titleLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 14),

            scrollView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 10),
            scrollView.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 14),
            scrollView.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -14),
            scrollView.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -12),
            scrollView.heightAnchor.constraint(equalTo: gridStack.heightAnchor),

            gridStack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            gridStack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            gridStack.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            gridStack.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor)
        ])
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure(columns: [String], rows: [[String]]) {
        gridStack.arrangedSubviews.forEach { $0.removeFromSuperview() }

        let shownRows = Array(rows.prefix(Self.maxRows))

        // Size each column to its longest text (within limits).
        var characterCounts = columns.map { $0.count }
        for row in shownRows.prefix(30) {
            for (index, value) in row.enumerated() where index < characterCounts.count {
                characterCounts[index] = max(characterCounts[index], min(value.count, 40))
            }
        }
        let columnWidths = characterCounts.map { min(max(CGFloat($0) * 7.5 + 24, 80), 280) }

        gridStack.addArrangedSubview(rowView(values: columns, widths: columnWidths, isHeader: true))
        for row in shownRows {
            gridStack.addArrangedSubview(hairline())
            gridStack.addArrangedSubview(rowView(values: row, widths: columnWidths, isHeader: false))
        }

        if rows.count > Self.maxRows {
            let footer = UILabel()
            footer.text = "+ \(rows.count - Self.maxRows) more rows"
            footer.font = Theme.medium(12)
            footer.textColor = Theme.fieldIcon
            let container = UIView()
            container.translatesAutoresizingMaskIntoConstraints = false
            footer.translatesAutoresizingMaskIntoConstraints = false
            container.addSubview(footer)
            NSLayoutConstraint.activate([
                footer.topAnchor.constraint(equalTo: container.topAnchor, constant: 8),
                footer.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -4),
                footer.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 8)
            ])
            gridStack.addArrangedSubview(container)
        }
    }

    private func hairline() -> UIView {
        let line = UIView()
        line.backgroundColor = Theme.fieldBorder.withAlphaComponent(0.6)
        line.heightAnchor.constraint(equalToConstant: 1 / UIScreen.main.scale).isActive = true
        return line
    }

    private func rowView(values: [String], widths: [CGFloat], isHeader: Bool) -> UIView {
        let rowStack = UIStackView()
        rowStack.axis = .horizontal
        rowStack.spacing = 0
        for (index, value) in values.enumerated() {
            let container = UIView()
            container.backgroundColor = isHeader ? Theme.teal : .clear
            container.translatesAutoresizingMaskIntoConstraints = false

            let label = UILabel()
            label.text = value
            label.font = isHeader ? Theme.semiBold(13) : Theme.regular(13)
            label.textColor = isHeader ? .white : .darkText
            label.numberOfLines = 1
            label.translatesAutoresizingMaskIntoConstraints = false
            container.addSubview(label)

            let width = index < widths.count ? widths[index] : 120
            NSLayoutConstraint.activate([
                container.widthAnchor.constraint(equalToConstant: width),
                label.topAnchor.constraint(equalTo: container.topAnchor, constant: 8),
                label.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -8),
                label.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 8),
                label.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -8)
            ])
            rowStack.addArrangedSubview(container)
        }
        return rowStack
    }
}

/// Chat bubble: user messages on the right in teal, replies on the left in white.
private final class BubbleCell: UITableViewCell {

    static let reuseId = "BubbleCell"

    private let bubbleView = UIView()
    private let messageLabel = UILabel()
    private var leadingConstraint: NSLayoutConstraint!
    private var trailingConstraint: NSLayoutConstraint!

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear
        selectionStyle = .none

        bubbleView.layer.cornerRadius = 16
        bubbleView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(bubbleView)

        messageLabel.font = Theme.medium(15)
        messageLabel.numberOfLines = 0
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        bubbleView.addSubview(messageLabel)

        leadingConstraint = bubbleView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16)
        trailingConstraint = bubbleView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16)

        NSLayoutConstraint.activate([
            bubbleView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6),
            bubbleView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -6),
            bubbleView.widthAnchor.constraint(lessThanOrEqualTo: contentView.widthAnchor, multiplier: 0.78),

            messageLabel.topAnchor.constraint(equalTo: bubbleView.topAnchor, constant: 10),
            messageLabel.bottomAnchor.constraint(equalTo: bubbleView.bottomAnchor, constant: -10),
            messageLabel.leadingAnchor.constraint(equalTo: bubbleView.leadingAnchor, constant: 14),
            messageLabel.trailingAnchor.constraint(equalTo: bubbleView.trailingAnchor, constant: -14)
        ])
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure(text: String, isUser: Bool) {
        messageLabel.text = text
        if isUser {
            bubbleView.backgroundColor = Theme.teal
            messageLabel.textColor = .white
            leadingConstraint.isActive = false
            trailingConstraint.isActive = true
        } else {
            bubbleView.backgroundColor = .white
            messageLabel.textColor = .darkText
            trailingConstraint.isActive = false
            leadingConstraint.isActive = true
        }
    }
}
