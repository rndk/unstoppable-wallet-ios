import UIKit
import ThemeKit
import SnapKit
import SectionsTableView
import RxSwift
import RxCocoa
import ComponentKit

class SendXFeeSettingsViewController: ThemeViewController {
    let disposeBag = DisposeBag()

    private let viewModel: SendXFeeSettingsViewModel

    private let tableView = SectionsTableView(style: .grouped)
    let bottomWrapper = BottomGradientHolder()

    private let feeSliderViewModel: SendXFeeSliderViewModel
    private let feeCautionViewModel: SendXFeeWarningViewModel
    private let amountCautionViewModel: SendFeeSettingsAmountCautionViewModel

    private let feeCell: FeeCell
    private let feePriorityCell: SendXFeePriorityCell
    private let feeRateCell = BaseThemeCell()
    private let feeSliderCell: FeeSliderCell
    private let feeWarningCell = TitledHighlightedDescriptionCell()
    private let feeAmountErrorCell = TitledHighlightedDescriptionCell()

    private let doneButton = ThemeButton()

    private var loaded = false

    init(viewModel: SendXFeeSettingsViewModel, feeViewModel: SendXFeeViewModel, feeSliderViewModel: SendXFeeSliderViewModel, feePriorityViewModel: SendXFeePriorityViewModel, feeCautionViewModel: SendXFeeWarningViewModel, amountCautionViewModel: SendFeeSettingsAmountCautionViewModel) {
        self.viewModel = viewModel
        self.feeSliderViewModel = feeSliderViewModel
        self.feeCautionViewModel = feeCautionViewModel
        self.amountCautionViewModel = amountCautionViewModel

        feeCell = FeeCell(viewModel: feeViewModel)
        feePriorityCell = SendXFeePriorityCell(viewModel: feePriorityViewModel)
        feeSliderCell = FeeSliderCell(sliderDriver: feeSliderViewModel.sliderDriver)

        super.init()

        feePriorityCell.sourceViewController = self
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "fee_settings".localized
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "button.done".localized, style: .done, target: self, action: #selector(onTapDone))
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "button.reset".localized, style: .plain, target: self, action: #selector(onTapReset))

        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.leading.top.trailing.equalToSuperview()
        }

        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.delaysContentTouches = false

        tableView.registerCell(forClass: TitledHighlightedDescriptionCell.self)
        tableView.sectionDataSource = self

        feeRateCell.set(backgroundStyle: .lawrence, isFirst: true, isLast: false)
        CellBuilder.build(cell: feeRateCell, elements: [.text, .text])
        feeRateCell.bind(index: 0, block: { (component: TextComponent) in
            component.set(style: .d1)
            component.text = "fee_settings.fee_rate".localized
        })
        feeRateCell.bind(index: 1, block: { (component: TextComponent) in
            component.set(style: .c2)
        })

        feePriorityCell.set(backgroundStyle: .lawrence, isFirst: true, isLast: true)
        feeSliderCell.set(backgroundStyle: .lawrence, isFirst: false, isLast: true)

        view.addSubview(bottomWrapper)
        bottomWrapper.snp.makeConstraints { maker in
            maker.top.equalTo(tableView.snp.bottom).offset(-CGFloat.margin16)
            maker.leading.trailing.equalToSuperview()
            maker.bottom.equalTo(view.safeAreaLayoutGuide)
        }

        bottomWrapper.addSubview(doneButton)
        doneButton.snp.makeConstraints { maker in
            maker.top.equalToSuperview().inset(CGFloat.margin32)
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin24)
            maker.bottom.equalToSuperview().inset(CGFloat.margin16)
            maker.height.equalTo(CGFloat.heightButton)
        }

        doneButton.apply(style: .primaryYellow)
        doneButton.setTitle("button.done".localized, for: .normal)
        doneButton.addTarget(self, action: #selector(onTapDone), for: .touchUpInside)

        subscribe(disposeBag, feeSliderViewModel.sliderDriver) { [weak self] in
            self?.sync(feeSliderViewItem: $0)
        }
        feeSliderViewModel.subscribeTracking(cell: feeSliderCell)

        subscribe(disposeBag, feeCautionViewModel.cautionDriver) { [weak self] in
            self?.handle(cell: self?.feeWarningCell, caution: $0)
        }
        subscribe(disposeBag, amountCautionViewModel.amountCautionDriver) { [weak self] in
            self?.handle(cell: self?.feeAmountErrorCell, caution: $0)
        }

        subscribe(disposeBag, viewModel.resetButtonActiveDriver) { [weak self] active in
            self?.navigationItem.leftBarButtonItem?.isEnabled = active
        }

        tableView.buildSections()

        loaded = true
    }

    @objc private func onTapDone() {
        dismiss(animated: true)
    }

    @objc private func onTapReset() {
        viewModel.reset()
    }

    private func handle(cell: TitledHighlightedDescriptionCell?, caution: TitledCaution?) {
        guard let cell = cell else {
            return
        }
        cell.isVisible = caution != nil

        if let caution = caution {
            cell.bind(caution: caution)
        }

        if loaded {
            UIView.animate(withDuration: 0.15) {
                self.tableView.beginUpdates()
                self.tableView.endUpdates()
            }
        }
    }

    private func sync(feeSliderViewItem: FeeSliderViewItem?) {
        feeRateCell.bind(index: 1, block: { (component: TextComponent) in
            component.text = feeSliderViewItem.map {
                "\($0.initialValue) \($0.description ?? "")"
            }
        })
    }

    private func openInfo(title: String, description: String) {
        let viewController = EvmGasDataInfoViewController(title: title, description: description)
        present(viewController.toBottomSheet, animated: true)
    }

    private func reloadTable() {
        if loaded {
            UIView.animate(withDuration: 0.15) {
                self.tableView.beginUpdates()
                self.tableView.endUpdates()
            }
        }
    }

}

extension SendXFeeSettingsViewController: SectionsDataSource {

    func buildSections() -> [SectionProtocol] {
        let feeSections: [SectionProtocol] = [
            Section(
                    id: "fee",
                    headerState: .margin(height: .margin12),
                    rows: [
                        StaticRow(
                                cell: feeCell,
                                id: "fee",
                                height: .heightCell48,
                                autoDeselect: true,
                                action: { [weak self] in
                                    self?.openInfo(title: "fee_settings.fee".localized, description: "fee_settings.fee.info".localized)
                                }
                        )
                    ]
            ),
            Section(
                    id: "fee-speed",
                    headerState: .margin(height: .margin8),
                    rows: [
                        StaticRow(
                                cell: feePriorityCell,
                                id: "fee-priority",
                                height: .heightCell48,
                                autoDeselect: true,
                                action: { [weak self] in
                                    self?.present(InfoModule.feeInfo, animated: true)
                                }
                        )
                    ]
            )
        ]

        var feeSliderSection = [SectionProtocol]()
        feeSliderSection.append(
                Section(
                        id: "fee-slider",
                        headerState: .margin(height: .margin8),
                        rows: [
                            StaticRow(
                                    cell: feeRateCell,
                                    id: "fee-rate",
                                    height: .heightCell48
                            ),
                            StaticRow(
                                    cell: feeSliderCell,
                                    id: "fee-slider",
                                    height: .heightCell48
                            )
                        ]
                )
        )


        let cautionsSections: [SectionProtocol] = [
            Section(
                    id: "cautions",
                    headerState: .margin(height: .margin12),
                    rows: [
                        StaticRow(
                                cell: feeWarningCell,
                                id: "fee-caution",
                                dynamicHeight: { [weak self] containerWidth in
                                    self?.feeWarningCell.cellHeight(containerWidth: containerWidth) ?? 0
                                }
                        ),
                        StaticRow(
                                cell: feeAmountErrorCell,
                                id: "amount-error",
                                dynamicHeight: { [weak self] containerWidth in
                                    self?.feeAmountErrorCell.cellHeight(containerWidth: containerWidth) ?? 0
                                }
                        )
                    ]
            )
        ]

        return feeSections + feeSliderSection + cautionsSections
    }

}