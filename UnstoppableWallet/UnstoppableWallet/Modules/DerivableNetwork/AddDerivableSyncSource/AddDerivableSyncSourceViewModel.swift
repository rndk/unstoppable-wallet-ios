import RxSwift
import RxRelay
import RxCocoa

class AddDerivableSyncSourceViewModel {
  private let service: AddDerivableSyncSourceService
  private let disposeBag = DisposeBag()
  
  private let urlCautionRelay = BehaviorRelay<Caution?>(value: nil)
  private let finishRelay = PublishRelay<Void>()
  
  init(service: AddDerivableSyncSourceService) {
    self.service = service
  }
  
}

extension AddDerivableSyncSourceViewModel {
  
  var urlCautionDriver: Driver<Caution?> {
    urlCautionRelay.asDriver()
  }
  
  var finishSignal: Signal<Void> {
    finishRelay.asSignal()
  }
  
  func onChange(url: String?) {
    service.set(urlString: url ?? "")
    urlCautionRelay.accept(nil)
  }
  
  func onChange(name: String?) {
    service.set(sourceName: name ?? "")
  }
  
  func onTapAdd() {
    do {
      try service.save()
      finishRelay.accept(())
    } catch AddEvmSyncSourceService.UrlError.alreadyExists {
      urlCautionRelay.accept(Caution(text: "add_evm_sync_source.warning.url_exists".localized, type: .warning))
    } catch AddEvmSyncSourceService.UrlError.invalid {
      urlCautionRelay.accept(Caution(text: "add_evm_sync_source.error.invalid_url".localized, type: .error))
    } catch {
    }
  }
  
}
