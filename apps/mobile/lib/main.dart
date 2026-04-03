import 'app/app.dart';
import 'bootstrap.dart';

Future<void> main() async {
  await bootstrap((state) => BabyDayLogApp(bootstrapState: state));
}
