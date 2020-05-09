import KsApi
import Prelude
import ReactiveExtensions
import ReactiveSwift

public enum ManagePledgeAlertAction: CaseIterable {
  case updatePledge
  case changePaymentMethod
  case chooseAnotherReward
  case contactCreator
  case cancelPledge
  case viewRewards
}

public protocol ManagePledgeViewModelInputs {
  func beginRefresh()
  func configureWith(_ project: Project)
  func cancelPledgeDidFinish(with message: String)
  func fixButtonTapped()
  func menuButtonTapped()
  func menuOptionSelected(with action: ManagePledgeAlertAction)
  func pledgeViewControllerDidUpdatePledgeWithMessage(_ message: String)
  func viewDidLoad()
}

public protocol ManagePledgeViewModelOutputs {
  var configurePaymentMethodView: Signal<ManagePledgePaymentMethodViewData, Never> { get }
  var configurePledgeSummaryView: Signal<ManagePledgeSummaryViewData, Never> { get }
  var configureRewardReceivedWithProject: Signal<Project, Never> { get }
  var configureRewardSummaryView: Signal<(Project, Either<Reward, Backing>), Never> { get }
  var endRefreshing: Signal<Void, Never> { get }
  var goToCancelPledge: Signal<CancelPledgeViewData, Never> { get }
  var goToChangePaymentMethod: Signal<(Project, Reward), Never> { get }
  var goToContactCreator: Signal<(MessageSubject, Koala.MessageDialogContext), Never> { get }
  var goToFixPaymentMethod: Signal<(Project, Reward), Never> { get }
  var goToRewards: Signal<Project, Never> { get }
  var goToUpdatePledge: Signal<(Project, Reward), Never> { get }
  var notifyDelegateManagePledgeViewControllerFinishedWithMessage: Signal<String?, Never> { get }
  var rewardReceivedViewControllerViewIsHidden: Signal<Bool, Never> { get }
  var showActionSheetMenuWithOptions: Signal<[ManagePledgeAlertAction], Never> { get }
  var showErrorBannerWithMessage: Signal<String, Never> { get }
  var showSuccessBannerWithMessage: Signal<String, Never> { get }
  var title: Signal<String, Never> { get }
}

public protocol ManagePledgeViewModelType {
  var inputs: ManagePledgeViewModelInputs { get }
  var outputs: ManagePledgeViewModelOutputs { get }
}

public final class ManagePledgeViewModel:
  ManagePledgeViewModelType, ManagePledgeViewModelInputs, ManagePledgeViewModelOutputs {
  public init() {
    let initialProject = Signal.combineLatest(self.configureWithProjectSignal, self.viewDidLoadSignal)
      .map(first)

    let shouldBeginRefresh = Signal.merge(
      self.pledgeViewControllerDidUpdatePledgeWithMessageSignal.ignoreValues(),
      self.beginRefreshSignal
    )

    let refreshProjectEvent = initialProject
      .takeWhen(shouldBeginRefresh)
      .switchMap { project in
        AppEnvironment.current.apiService.fetchProject(param: Param.id(project.id))
          .ksr_delay(AppEnvironment.current.apiDelayInterval, on: AppEnvironment.current.scheduler)
          .materialize()
      }

    let shouldFetchGraphBackingWithProject = Signal.merge(
      initialProject,
      initialProject.takeWhen(shouldBeginRefresh)
    )

    let graphBackingEvent = shouldFetchGraphBackingWithProject
      .switchMap { project in
        AppEnvironment.current.apiService
          .fetchManagePledgeViewBacking(query: projectBackingQuery(withSlug: project.slug))
          .ksr_delay(AppEnvironment.current.apiDelayInterval, on: AppEnvironment.current.scheduler)
          .materialize()
      }

    let graphBackingProject = graphBackingEvent.values()
      .map { $0.project }

    let graphBackingEnvelope = graphBackingEvent.values()

    let backing = graphBackingEnvelope
      .map { $0.backing }

    self.endRefreshing = refreshProjectEvent
      .filter { $0.isTerminating }
      .ignoreValues()

    let project = Signal.merge(initialProject, refreshProjectEvent.values())

    let projectAndReward = project
      .filterMap { project in
        guard let backing = project.personalization.backing else {
          return nil
        }

        return (project, backing)
      }
      .map { project, backing in (project, reward(from: backing, inProject: project)) }

    self.title = graphBackingProject.map(navigationBarTitle(with:))

    self.configurePaymentMethodView = backing.map(managePledgePaymentMethodViewData)

    self.configurePledgeSummaryView = Signal.combineLatest(project, graphBackingEnvelope)
      .map(managePledgeSummaryViewData(with:envelope:))
      .skipNil()

    self.configureRewardReceivedWithProject = project

    self.configureRewardSummaryView = projectAndReward
      .map { project, reward in (project, .left(reward)) }

    self.showActionSheetMenuWithOptions = project
      .takeWhen(self.menuButtonTappedSignal)
      .map(actionSheetMenuOptionsFor(project:))

    self.goToUpdatePledge = projectAndReward
      .takeWhen(self.menuOptionSelectedSignal.filter { $0 == .updatePledge })

    self.goToRewards = project
      .takeWhen(self.menuOptionSelectedSignal.filter { $0 == .chooseAnotherReward || $0 == .viewRewards })

    let cancelPledgeSelected = self.menuOptionSelectedSignal
      .filter { $0 == .cancelPledge }
      .ignoreValues()

    self.goToCancelPledge = Signal.combineLatest(project, backing)
      .takeWhen(cancelPledgeSelected)
      .filter { _, backing in backing.cancelable }
      .map(cancelPledgeViewData(with:backing:))

    self.goToContactCreator = project
      .takeWhen(self.menuOptionSelectedSignal.filter { $0 == .contactCreator })
      .map { project in (MessageSubject.project(project), .backerModal) }

    let goToChangePaymentMethod = self.menuOptionSelectedSignal
      .filter { $0 == .changePaymentMethod }
      .ignoreValues()

    self.goToChangePaymentMethod = projectAndReward
      .takeWhen(goToChangePaymentMethod)

    self.goToFixPaymentMethod = projectAndReward
      .takeWhen(self.fixButtonTappedSignal)

    self.notifyDelegateManagePledgeViewControllerFinishedWithMessage = Signal.merge(
      self.cancelPledgeDidFinishWithMessageProperty.signal,
      refreshProjectEvent.mapConst(nil)
    )

    self.rewardReceivedViewControllerViewIsHidden = projectAndReward
      .map { project, reward in reward.isNoReward || project.personalization.backing?.status != .collected }

    self.showSuccessBannerWithMessage = self.pledgeViewControllerDidUpdatePledgeWithMessageSignal

    let cancelBackingDisallowed = backing
      .map { $0.cancelable }
      .filter(isFalse)

    self.showErrorBannerWithMessage = cancelBackingDisallowed
      .takeWhen(cancelPledgeSelected)
      .map { _ in
        // swiftformat:disable wrap
        Strings.We_dont_allow_cancelations_that_will_cause_a_project_to_fall_short_of_its_goal_within_the_last_24_hours()
        // swiftformat:enable wrap
      }

    let managePledgeMenuType: Signal<Koala.ManagePledgeMenuCTAType, Never> = self.menuOptionSelectedSignal
      .map(managePledgeMenuCTAType(for:))

    // Tracking
    project
      .takePairWhen(managePledgeMenuType)
      .observeValues {
        AppEnvironment.current.koala.trackManagePledgeOptionClicked(project: $0, managePledgeMenuCTA: $1)
      }

    project
      .takePairWhen(self.fixButtonTappedSignal)
      .observeValues {
        AppEnvironment.current.koala.trackFixPledgeButtonClicked(project: $0.0)
      }
  }

  private let (beginRefreshSignal, beginRefreshObserver) = Signal<Void, Never>.pipe()
  public func beginRefresh() {
    self.beginRefreshObserver.send(value: ())
  }

  private let (configureWithProjectSignal, configureWithProjectObserver) = Signal<Project, Never>.pipe()
  public func configureWith(_ project: Project) {
    self.configureWithProjectObserver.send(value: project)
  }

  private let cancelPledgeDidFinishWithMessageProperty = MutableProperty<String?>(nil)
  public func cancelPledgeDidFinish(with message: String) {
    self.cancelPledgeDidFinishWithMessageProperty.value = message
  }

  private let (fixButtonTappedSignal, fixButtonTappedObserver) = Signal<Void, Never>.pipe()
  public func fixButtonTapped() {
    self.fixButtonTappedObserver.send(value: ())
  }

  private let (menuButtonTappedSignal, menuButtonTappedObserver) = Signal<Void, Never>.pipe()
  public func menuButtonTapped() {
    self.menuButtonTappedObserver.send(value: ())
  }

  private let (menuOptionSelectedSignal, menuOptionSelectedObserver) = Signal<ManagePledgeAlertAction, Never>
    .pipe()
  public func menuOptionSelected(with action: ManagePledgeAlertAction) {
    self.menuOptionSelectedObserver.send(value: action)
  }

  private let (
    pledgeViewControllerDidUpdatePledgeWithMessageSignal,
    pledgeViewControllerDidUpdatePledgeWithMessageObserver
  ) = Signal<String, Never>.pipe()
  public func pledgeViewControllerDidUpdatePledgeWithMessage(_ message: String) {
    self.pledgeViewControllerDidUpdatePledgeWithMessageObserver.send(value: message)
  }

  private let (viewDidLoadSignal, viewDidLoadObserver) = Signal<(), Never>.pipe()
  public func viewDidLoad() {
    self.viewDidLoadObserver.send(value: ())
  }

  public let configurePaymentMethodView: Signal<ManagePledgePaymentMethodViewData, Never>
  public let configurePledgeSummaryView: Signal<ManagePledgeSummaryViewData, Never>
  public let configureRewardReceivedWithProject: Signal<Project, Never>
  public let configureRewardSummaryView: Signal<(Project, Either<Reward, Backing>), Never>
  public let endRefreshing: Signal<Void, Never>
  public let goToCancelPledge: Signal<CancelPledgeViewData, Never>
  public let goToChangePaymentMethod: Signal<(Project, Reward), Never>
  public let goToContactCreator: Signal<(MessageSubject, Koala.MessageDialogContext), Never>
  public let goToFixPaymentMethod: Signal<(Project, Reward), Never>
  public let goToRewards: Signal<Project, Never>
  public let goToUpdatePledge: Signal<(Project, Reward), Never>
  public let notifyDelegateManagePledgeViewControllerFinishedWithMessage: Signal<String?, Never>
  public let rewardReceivedViewControllerViewIsHidden: Signal<Bool, Never>
  public let showActionSheetMenuWithOptions: Signal<[ManagePledgeAlertAction], Never>
  public let showSuccessBannerWithMessage: Signal<String, Never>
  public let showErrorBannerWithMessage: Signal<String, Never>
  public let title: Signal<String, Never>

  public var inputs: ManagePledgeViewModelInputs { return self }
  public var outputs: ManagePledgeViewModelOutputs { return self }
}

// MARK: - Functions

private func actionSheetMenuOptionsFor(project: Project) -> [ManagePledgeAlertAction] {
  guard project.state == .live else {
    return [.viewRewards, .contactCreator]
  }

  if project.personalization.backing?.status == .preauth {
    return [.contactCreator]
  }

  return ManagePledgeAlertAction.allCases.filter { $0 != .viewRewards }
}

private func navigationBarTitle(with project: ManagePledgeViewBackingEnvelope.Project) -> String {
  return project.state == .live ? Strings.Manage_your_pledge() : Strings.Your_pledge()
}

private func managePledgeMenuCTAType(for managePledgeAlertAction: ManagePledgeAlertAction)
  -> Koala.ManagePledgeMenuCTAType {
  switch managePledgeAlertAction {
  case .cancelPledge: return .cancelPledge
  case .changePaymentMethod: return .changePaymentMethod
  case .chooseAnotherReward: return .chooseAnotherReward
  case .contactCreator: return .contactCreator
  case .updatePledge: return .updatePledge
  case .viewRewards: return .viewRewards
  }
}

private func cancelPledgeViewData(
  with project: Project,
  backing: ManagePledgeViewBackingEnvelope.Backing
) -> CancelPledgeViewData {
  return (
    project: project,
    projectCountry: project.country,
    projectName: project.name,
    omitUSCurrencyCode: project.stats.omitUSCurrencyCode,
    backingId: backing.id,
    pledgeAmount: backing.amount.doubleValue
  )
}

private func managePledgePaymentMethodViewData(
  with backing: ManagePledgeViewBackingEnvelope.Backing
) -> ManagePledgePaymentMethodViewData {
  (
    backingState: backing.status,
    expirationDate: backing.creditCard?.expirationDate,
    lastFour: backing.creditCard?.lastFour,
    creditCardType: backing.creditCard?.type,
    paymentType: backing.creditCard?.paymentType
  )
}

private func managePledgeSummaryViewData(
  with project: Project,
  envelope: ManagePledgeViewBackingEnvelope
) -> ManagePledgeSummaryViewData? {
  return .init(
    pledgeAmount: envelope.backing.amount.doubleValue,
    pledgedOn: envelope.backing.pledgedOn,
    projectCountry: project.country,
    omitUSCurrencyCode: project.stats.omitUSCurrencyCode,
    backerId: envelope.backing.backer.uid,
    backerName: envelope.backing.backer.name,
    backerSequence: envelope.backing.sequence,
    shippingAmount: envelope.backing.shippingAmount?.doubleValue,
    locationName: envelope.backing.location?.name,
    currentUserIsCreatorOfProject: currentUserIsCreator(of: project),
    needsConversion: project.stats.needsConversion,
    projectDeadline: project.dates.deadline,
    projectState: envelope.project.state,
    backingState: envelope.backing.status
  )
}

private func projectBackingQuery(withSlug slug: String) -> NonEmptySet<Query> {
  return Query.project(
    slug: slug,
    .pid +| [
      .state,
      .name,
      .backing(
        .status +| [
          .id,
          .amount(
            .amount +| [
              .currency,
              .symbol
            ]
          ),
          .sequence,
          .cancelable,
          .backer(
            .uid +| [
              .name
            ]
          ),
          .creditCard(
            .id +| [
              .expirationDate,
              .lastFour,
              .paymentType,
              .type
            ]
          ),
          .errorReason,
          .pledgedOn,
          .reward(
            .name +| [
              .amount(
                .amount +| [
                  .currency,
                  .symbol
                ]
              ),
              .backersCount,
              .description,
              .estimatedDeliveryOn,
              .items([], NonEmptySet(.nodes(.id +| [.name])))
            ]
          )
        ]
      )
    ]
  ) +| []
}
