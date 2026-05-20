import 'package:bloc_clean_architecture/src/data/datasource/ai_teacher_remote_data_source.dart';
import 'package:bloc_clean_architecture/src/data/datasource/authentication_remote_data_source.dart';
import 'package:bloc_clean_architecture/src/data/datasource/chat_history_local_data_source.dart';
import 'package:bloc_clean_architecture/src/data/repository/ai_teacher_repository_impl.dart';
import 'package:bloc_clean_architecture/src/data/repository/authentication_repository_impl.dart';
import 'package:bloc_clean_architecture/src/domain/repositories/ai_teacher_repository.dart';
import 'package:bloc_clean_architecture/src/domain/repositories/autentication_repository.dart';
import 'package:bloc_clean_architecture/src/domain/usecase/login.dart';
import 'package:bloc_clean_architecture/src/presentation/bloc/ai_teacher/ai_teacher_bloc.dart';
import 'package:bloc_clean_architecture/src/presentation/bloc/authenticator_watcher/authenticator_watcher_bloc.dart';
import 'package:bloc_clean_architecture/src/presentation/bloc/sign_in_form/sign_in_form_bloc.dart';
import 'package:bloc_clean_architecture/src/presentation/cubit/theme/theme_cubit.dart';
import 'package:bloc_clean_architecture/src/utilities/tts_service.dart';
import 'package:get_it/get_it.dart';

final locator = GetIt.instance;

void init() {
  // ─── Auth ────────────────────────────────────────────────────────
  final authRemoteDataSource = AuthenticationRemoteDataSourceImpl();
  locator.registerLazySingleton<AuthenticationRemoteDataSource>(
    () => authRemoteDataSource,
  );

  final authRepository = AuthenticationRepositoryImpl(locator());
  locator.registerLazySingleton<AuthenticationRepository>(
    () => authRepository,
  );

  final signIn = SignIn(locator());
  locator.registerLazySingleton<SignIn>(() => signIn);

  // ─── App-level BLoCs / Cubits ────────────────────────────────────
  final authenticatorWatcherBloc = AuthenticatorWatcherBloc();
  locator.registerLazySingleton<AuthenticatorWatcherBloc>(
    () => authenticatorWatcherBloc,
  );

  final signInFormBloc = SignInFormBloc(locator());
  locator.registerLazySingleton<SignInFormBloc>(() => signInFormBloc);

  final themeCubit = ThemeCubit();
  locator
    ..registerLazySingleton<ThemeCubit>(() => themeCubit)

    // ─── AI Teacher (Gemini — free tier) ─────────────────────────────
    // Đổi sang `GeminiTeacherRemoteDataSource()` ↔ `OpenAiTeacherRemoteDataSource()`
    // nếu muốn chuyển provider.
    // Chạy app với:
    //   flutter run --dart-define=GEMINI_API_KEY=AIza...
    // (lấy key miễn phí tại https://aistudio.google.com/apikey)
    ..registerLazySingleton<AiTeacherRemoteDataSource>(
      () => GeminiTeacherRemoteDataSource(),
    )
    ..registerLazySingleton<ChatHistoryLocalDataSource>(
      () => ChatHistoryLocalDataSourceImpl(),
    )
    ..registerLazySingleton<TtsService>(() => TtsService())
    ..registerLazySingleton<AiTeacherRepository>(
      () => AiTeacherRepositoryImpl(
        locator<AiTeacherRemoteDataSource>(),
        locator<ChatHistoryLocalDataSource>(),
      ),
    )
    ..registerFactory<AiTeacherBloc>(
      () => AiTeacherBloc(
        locator<AiTeacherRepository>(),
        locator<TtsService>(),
      ),
    );
}
