// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'stores.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic, no_leading_underscores_for_local_identifiers

mixin _$AuthStore on _AuthStoreBase, Store {
  Computed<bool>? _$autenticadoComputed;

  @override
  bool get autenticado => (_$autenticadoComputed ??= Computed<bool>(
    () => super.autenticado,
    name: '_AuthStoreBase.autenticado',
  )).value;

  late final _$usuarioAtom = Atom(
    name: '_AuthStoreBase.usuario',
    context: context,
  );

  @override
  Map<String, dynamic>? get usuario {
    _$usuarioAtom.reportRead();
    return super.usuario;
  }

  @override
  set usuario(Map<String, dynamic>? value) {
    _$usuarioAtom.reportWrite(value, super.usuario, () {
      super.usuario = value;
    });
  }

  late final _$carregandoAtom = Atom(
    name: '_AuthStoreBase.carregando',
    context: context,
  );

  @override
  bool get carregando {
    _$carregandoAtom.reportRead();
    return super.carregando;
  }

  @override
  set carregando(bool value) {
    _$carregandoAtom.reportWrite(value, super.carregando, () {
      super.carregando = value;
    });
  }

  late final _$erroAtom = Atom(name: '_AuthStoreBase.erro', context: context);

  @override
  String? get erro {
    _$erroAtom.reportRead();
    return super.erro;
  }

  @override
  set erro(String? value) {
    _$erroAtom.reportWrite(value, super.erro, () {
      super.erro = value;
    });
  }

  late final _$cadastrarAsyncAction = AsyncAction(
    '_AuthStoreBase.cadastrar',
    context: context,
  );

  @override
  Future<bool> cadastrar(String nome, String email, String senha) {
    return _$cadastrarAsyncAction.run(
      () => super.cadastrar(nome, email, senha),
    );
  }

  late final _$loginAsyncAction = AsyncAction(
    '_AuthStoreBase.login',
    context: context,
  );

  @override
  Future<bool> login(String email, String senha) {
    return _$loginAsyncAction.run(() => super.login(email, senha));
  }

  late final _$confirmarMatriculaAsyncAction = AsyncAction(
    '_AuthStoreBase.confirmarMatricula',
    context: context,
  );

  @override
  Future<bool> confirmarMatricula() {
    return _$confirmarMatriculaAsyncAction.run(
      () => super.confirmarMatricula(),
    );
  }

  late final _$verificarLoginAsyncAction = AsyncAction(
    '_AuthStoreBase.verificarLogin',
    context: context,
  );

  @override
  Future<void> verificarLogin() {
    return _$verificarLoginAsyncAction.run(() => super.verificarLogin());
  }

  late final _$logoutAsyncAction = AsyncAction(
    '_AuthStoreBase.logout',
    context: context,
  );

  @override
  Future<void> logout() {
    return _$logoutAsyncAction.run(() => super.logout());
  }

  @override
  String toString() {
    return '''
usuario: ${usuario},
carregando: ${carregando},
erro: ${erro},
autenticado: ${autenticado}
    ''';
  }
}
