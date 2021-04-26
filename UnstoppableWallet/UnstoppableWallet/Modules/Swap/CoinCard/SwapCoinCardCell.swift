import UIKit
import ThemeKit
import RxSwift
import CoinKit
import ComponentKit

class SwapCoinCardCell: UITableViewCell {
    let cellHeight: CGFloat = 170 + 2 * .margin12

    private let disposeBag = DisposeBag()

    private let viewModel: SwapCoinCardViewModel
    weak var presentDelegate: IPresentDelegate?

    private let cardView = CardView(insets: .zero)

    private let titleLabel = UILabel()
    private let badgeView = BadgeView()
    private let paddingView = UIView()
    private let tokenSelectButton = UIButton()

    private let amountInputWrapper = UIView()
    private let formAmountInput: FormAmountInputView

    private let balanceView = AdditionalDataView()

    init(viewModel: SwapCoinCardViewModel, amountInputViewModel: AmountInputViewModel, title: String) {
        self.viewModel = viewModel

        formAmountInput = FormAmountInputView(viewModel: amountInputViewModel)

        super.init(style: .default, reuseIdentifier: nil)

        backgroundColor = .clear
        selectionStyle = .none

        contentView.addSubview(cardView)
        cardView.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin16)
            maker.top.bottom.equalToSuperview().inset(CGFloat.margin12)
        }

        cardView.contentView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { maker in
            maker.top.equalToSuperview().offset(CGFloat.margin12)
            maker.leading.equalToSuperview().inset(CGFloat.margin16)
        }

        titleLabel.setContentHuggingPriority(.required, for: .horizontal)
        titleLabel.font = .body
        titleLabel.textColor = .themeOz
        titleLabel.text = title

        cardView.contentView.addSubview(badgeView)
        badgeView.snp.makeConstraints { maker in
            maker.centerY.equalTo(titleLabel)
            maker.leading.equalTo(titleLabel.snp.trailing).offset(CGFloat.margin8)
        }

        badgeView.compressionResistance = .defaultLow
        badgeView.text = "swap.estimated".localized.uppercased()
        badgeView.isHidden = true

        cardView.contentView.addSubview(paddingView)
        paddingView.snp.makeConstraints { maker in
            maker.centerY.equalTo(badgeView)
            maker.leading.equalTo(badgeView.snp.trailing).offset(CGFloat.margin8)
            maker.height.equalTo(10)
        }

        paddingView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        cardView.contentView.addSubview(tokenSelectButton)
        tokenSelectButton.snp.makeConstraints { maker in
            maker.top.equalToSuperview()
            maker.height.equalTo(CGFloat.heightSingleLineCell)
            maker.trailing.equalToSuperview()
            maker.leading.equalTo(paddingView.snp.trailing)
        }

        tokenSelectButton.setContentHuggingPriority(.required, for: .horizontal)
        tokenSelectButton.setContentCompressionResistancePriority(.required, for: .horizontal)

        tokenSelectButton.semanticContentAttribute = .forceRightToLeft
        tokenSelectButton.setImage(UIImage(named: "arrow_small_down_20"), for: .normal)
        tokenSelectButton.setTitleColor(.themeLeah, for: .normal)
        tokenSelectButton.titleLabel?.font = UIFont.subhead1
        tokenSelectButton.addTarget(self, action: #selector(onTapTokenSelect), for: .touchUpInside)
        tokenSelectButton.contentEdgeInsets = UIEdgeInsets(top: 0, left: .margin8, bottom: 0, right: .margin16)
        tokenSelectButton.titleEdgeInsets = UIEdgeInsets(top: 0, left: -.margin8, bottom: 0, right: .margin8)

        cardView.contentView.addSubview(amountInputWrapper)
        amountInputWrapper.snp.makeConstraints { maker in
            maker.top.equalTo(tokenSelectButton.snp.bottom)
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin8)
            maker.height.equalTo(formAmountInput.viewHeight)
        }

        amountInputWrapper.layer.cornerRadius = .cornerRadius2x
        amountInputWrapper.layer.borderWidth = CGFloat.heightOnePixel
        amountInputWrapper.layer.borderColor = UIColor.themeSteel20.cgColor

        amountInputWrapper.addSubview(formAmountInput)
        formAmountInput.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        cardView.contentView.addSubview(balanceView)
        balanceView.snp.makeConstraints { maker in
            maker.top.equalTo(amountInputWrapper.snp.bottom).offset(CGFloat.margin12)
            maker.leading.trailing.equalToSuperview()
        }

        subscribeToViewModel()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func subscribeToViewModel() {
        subscribe(disposeBag, viewModel.isEstimated) { [weak self] in self?.setBadge(hidden: !$0) }
        subscribe(disposeBag, viewModel.tokenCodeDriver) { [weak self] in self?.set(tokenCode: $0) }
        subscribe(disposeBag, viewModel.balanceDriver) { [weak self] in self?.set(balance: $0) }
        subscribe(disposeBag, viewModel.balanceErrorDriver) { [weak self] in self?.set(balanceError: $0) }
    }

    @objc private func onTapTokenSelect() {
        let viewController = CoinSelectModule.viewController(dex: viewModel.dex, delegate: self)
        presentDelegate?.show(viewController: ThemeNavigationController(rootViewController: viewController))
    }

}

extension SwapCoinCardCell {

    private func setBadge(hidden: Bool) {
        badgeView.isHidden = hidden
    }

    private func set(tokenCode: String?) {
        if let tokenCode = tokenCode {
            tokenSelectButton.setTitle(tokenCode, for: .normal)
            tokenSelectButton.setTitleColor(.themeLeah, for: .normal)
        } else {
            tokenSelectButton.setTitle("swap.token".localized, for: .normal)
            tokenSelectButton.setTitleColor(.themeYellowD, for: .normal)
        }
    }

    private func set(balance: String?) {
        balanceView.bind(title: "swap.balance".localized, value: balance)
    }

    private func set(balanceError: Bool) {
        let color: UIColor = balanceError ? .themeLucian : .themeGray
        balanceView.setTitle(color: color)
        balanceView.setValue(color: color)
    }

}

extension SwapCoinCardCell: ICoinSelectDelegate {

    func didSelect(coin: Coin) {
        viewModel.onSelect(coin: coin)
    }

}
