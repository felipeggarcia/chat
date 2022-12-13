import 'package:chat/data/http/http.dart';
import 'package:chat/domain/helpers/helpers.dart';
import 'package:chat/domain/usecases/usecases.dart';
import 'package:faker/faker.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

class RemoteAuthentication {
  final String url;
  final HttpClient httpClient;
  RemoteAuthentication({required this.url, required this.httpClient});
  Future<void> auth(AuthenticationParams params) async {
    try {
      final body = RemoteAuthenticationParams.fromDomain(params).toJson();
      await httpClient.request(url: url, method: 'post', body: body);
    } on HttpError {
      throw DomainError.unexpected;
    }
  }
}

class RemoteAuthenticationParams {
  final String email;
  final String password;

  RemoteAuthenticationParams({required this.email, required this.password});

  factory RemoteAuthenticationParams.fromDomain(AuthenticationParams params) =>
      RemoteAuthenticationParams(
          email: params.email, password: params.password);

  Map toJson() => {'email': email, 'password': password};
}

abstract class HttpClient {
  Future<dynamic>? request(
      {required String? url, required String? method, Map? body});
}

class HttpClientSpy extends Mock implements HttpClient {}

void main() {
  var httpClient = HttpClientSpy();
  var url = faker.internet.httpUrl();
  var sut = RemoteAuthentication(httpClient: httpClient, url: url);
  var params = AuthenticationParams(
      email: faker.internet.email(), password: faker.internet.password());

  PostExpectation mockRequest() => when(httpClient.request(
      url: anyNamed('url'),
      method: anyNamed('method'),
      body: anyNamed('body')));

  void mockHttpError(HttpError error) {
    mockRequest().thenThrow(error);
  }

  setUp(() {
    httpClient = HttpClientSpy();
    url = faker.internet.httpUrl();
    sut = RemoteAuthentication(httpClient: httpClient, url: url);
    params = AuthenticationParams(
        email: faker.internet.email(), password: faker.internet.password());
  });
  test('Should call HttpClient with correct values', () async {
    await sut.auth(params);
    verify(httpClient.request(
        url: url,
        method: 'post',
        body: {'email': params.email, 'password': params.password}));
  });
  test('Should throw UnexpectedError if HttpClient returns 400', () async {
    mockHttpError(HttpError.badRequest);

    final future = sut.auth(params);

    expect(future, throwsA(DomainError.unexpected));
  });
}
