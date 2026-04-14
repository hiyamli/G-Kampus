import 'app_repository.dart';
import 'mock_app_repository.dart';

AppRepository appRepository = const MockAppRepository();

void configureAppRepository(AppRepository repository) {
  appRepository = repository;
}
