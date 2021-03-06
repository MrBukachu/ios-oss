import Foundation
import KsApi
import Library
import Prelude
import UIKit

final class PledgeDescriptionViewController: UIViewController {
  // MARK: - Properties

  private lazy var dateLabel: UILabel = { UILabel(frame: .zero) }()
  private lazy var estimatedDeliveryLabel: UILabel = { UILabel(frame: .zero) }()
  private lazy var estimatedDeliveryStackView: UIStackView = { UIStackView(frame: .zero) }()
  private lazy var rewardInfoStackView: UIStackView = { UIStackView(frame: .zero) }()
  private lazy var rewardInfoBackgroundView: UIView = { UIView(frame: .zero) }()
  private lazy var rewardTitleLabel: UILabel = { UILabel(frame: .zero) }()
  private lazy var rootStackView: UIStackView = {
    UIStackView(frame: .zero)
      |> \.translatesAutoresizingMaskIntoConstraints .~ false
  }()

  private let viewModel: PledgeDescriptionViewModelType = PledgeDescriptionViewModel()

  // MARK: - Lifecycle

  override func viewDidLoad() {
    super.viewDidLoad()

    self.configureSubviews()
    self.setupConstraints()
  }

  // MARK: - Styles

  override func bindStyles() {
    super.bindStyles()

    _ = self.dateLabel
      |> dateLabelStyle

    _ = self.estimatedDeliveryLabel
      |> estimatedDeliveryLabelStyle

    let isAccessibilityCategory = self.traitCollection.preferredContentSizeCategory.isAccessibilityCategory

    _ = self.estimatedDeliveryStackView
      |> estimatedDeliveryStackViewStyle(isAccessibilityCategory)

    _ = self.rewardInfoBackgroundView
      |> rewardInfoBackgroundViewStyle

    _ = self.rewardInfoStackView
      |> rewardInfoStackViewStyle

    _ = self.rewardTitleLabel
      |> rewardTitleLabelStyle

    _ = self.rootStackView
      |> rootStackViewStyle

    _ = self.view
      |> checkoutBackgroundStyle
  }

  private func configureSubviews() {
    _ = (self.rootStackView, self.view)
      |> ksr_addSubviewToParent()
      |> ksr_constrainViewToEdgesInParent()

    _ = ([self.estimatedDeliveryLabel, self.dateLabel, UIView()], self.estimatedDeliveryStackView)
      |> ksr_addArrangedSubviewsToStackView()

    _ = ([self.estimatedDeliveryStackView, self.rewardTitleLabel], self.rewardInfoStackView)
      |> ksr_addArrangedSubviewsToStackView()

    _ = (self.rewardInfoStackView, self.rewardInfoBackgroundView)
      |> ksr_addSubviewToParent()
      |> ksr_constrainViewToEdgesInParent()

    _ = ([self.rewardInfoBackgroundView], self.rootStackView)
      |> ksr_addArrangedSubviewsToStackView()
  }

  private func setupConstraints() {
    NSLayoutConstraint.activate([
      self.rewardInfoBackgroundView.widthAnchor.constraint(equalTo: self.rootStackView.widthAnchor)
    ])
  }

  // MARK: - Actions

  @objc private func rewardCardTapped() {
    self.viewModel.inputs.rewardCardTapped()
  }

  // MARK: - View model

  internal override func bindViewModel() {
    super.bindViewModel()

    self.dateLabel.rac.text = self.viewModel.outputs.estimatedDeliveryText
    self.estimatedDeliveryStackView.rac.hidden = self.viewModel.outputs.estimatedDeliveryStackViewIsHidden

    self.viewModel.outputs.rewardTitle
      .observeForUI()
      .observeValues { [weak self] title in
        _ = self?.rewardTitleLabel
          ?|> \.text .~ title
      }

    self.viewModel.outputs.popViewController
      .observeForUI()
      .observeValues { [weak self] in
        guard let self = self else { return }
        self.navigationController?.popViewController(animated: true)
      }
  }

  // MARK: - Configuration

  internal func configureWith(value: (project: Project, reward: Reward)) {
    self.viewModel.inputs.configureWith(data: value)
  }
}

// MARK: Styles

private let dateLabelStyle: LabelStyle = { (label: UILabel) in
  label
    |> \.textColor .~ UIColor.ksr_soft_black
    |> \.font .~ UIFont.ksr_caption1()
    |> \.adjustsFontForContentSizeCategory .~ true
    |> \.minimumScaleFactor .~ 0.5
}

private let estimatedDeliveryLabelStyle: LabelStyle = { (label: UILabel) in
  label
    |> \.text %~ { _ in Strings.Estimated_delivery() }
    |> \.textColor .~ UIColor.ksr_text_dark_grey_500
    |> \.font .~ UIFont.ksr_caption1()
    |> \.adjustsFontForContentSizeCategory .~ true
    |> \.minimumScaleFactor .~ 0.5
}

private func estimatedDeliveryStackViewStyle(_ isAccessibilityCategory: Bool) -> (StackViewStyle) {
  return { (stackView: UIStackView) in
    stackView
      |> checkoutAdaptableStackViewStyle(isAccessibilityCategory)
      |> \.isLayoutMarginsRelativeArrangement .~ true
      |> \.spacing .~ Styles.grid(1)
      |> \.distribution .~ .fill
      |> \.alignment .~ .leading
  }
}

private let rewardInfoBackgroundViewStyle: ViewStyle = { (view: UIView) in
  view
    |> roundedStyle(cornerRadius: Styles.grid(2))
    |> \.backgroundColor .~ .white
}

private let rewardInfoStackViewStyle: StackViewStyle = { (stackView: UIStackView) in

  stackView
    |> verticalStackViewStyle
    |> \.isLayoutMarginsRelativeArrangement .~ true
    |> \.layoutMargins .~ UIEdgeInsets.init(topBottom: Styles.grid(3), leftRight: Styles.grid(3))
    |> \.spacing .~ Styles.grid(1)
}

private let rewardTitleLabelStyle: LabelStyle = { (label: UILabel) in
  label
    |> \.numberOfLines .~ 2
    |> \.textColor .~ UIColor.ksr_soft_black
    |> \.font .~ UIFont.ksr_headline().bolded
    |> \.adjustsFontForContentSizeCategory .~ true
}

private let rootStackViewStyle: StackViewStyle = { (stackView: UIStackView) in
  stackView
    |> checkoutSubStackViewStyle
    |> verticalStackViewStyle
    |> \.alignment .~ UIStackView.Alignment.top
}
