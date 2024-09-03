// Mocks generated by Mockito 5.4.4 from annotations
// in simple_webdav_client/test/unit_test/std_test/parser_test/response_parser_test.dart.
// Do not manually edit this file.

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'dart:async' as _i7;
import 'dart:convert' as _i2;

import 'package:mockito/mockito.dart' as _i1;
import 'package:mockito/src/dummies.dart' as _i4;
import 'package:simple_webdav_client/src/_std/error.dart' as _i8;
import 'package:simple_webdav_client/src/_std/parser.dart' as _i5;
import 'package:simple_webdav_client/src/_std/resource.dart' as _i3;
import 'package:xml/xml.dart' as _i6;

// ignore_for_file: type=lint
// ignore_for_file: avoid_redundant_argument_values
// ignore_for_file: avoid_setters_without_getters
// ignore_for_file: comment_references
// ignore_for_file: deprecated_member_use
// ignore_for_file: deprecated_member_use_from_same_package
// ignore_for_file: implementation_imports
// ignore_for_file: invalid_use_of_visible_for_testing_member
// ignore_for_file: prefer_const_constructors
// ignore_for_file: unnecessary_parenthesis
// ignore_for_file: camel_case_types
// ignore_for_file: subtype_of_sealed_class

class _FakeUri_0 extends _i1.SmartFake implements Uri {
  _FakeUri_0(
    Object parent,
    Invocation parentInvocation,
  ) : super(
          parent,
          parentInvocation,
        );
}

class _FakeConverter_1<S, T> extends _i1.SmartFake
    implements _i2.Converter<S, T> {
  _FakeConverter_1(
    Object parent,
    Invocation parentInvocation,
  ) : super(
          parent,
          parentInvocation,
        );
}

class _FakeSink_2<T> extends _i1.SmartFake implements Sink<T> {
  _FakeSink_2(
    Object parent,
    Invocation parentInvocation,
  ) : super(
          parent,
          parentInvocation,
        );
}

/// A class which mocks [WebDavStdResource].
///
/// See the documentation for Mockito's code generation for more information.
class MockWebDavStdResource extends _i1.Mock implements _i3.WebDavStdResource {
  MockWebDavStdResource() {
    _i1.throwOnMissingStub(this);
  }

  @override
  Uri get path => (super.noSuchMethod(
        Invocation.getter(#path),
        returnValue: _FakeUri_0(
          this,
          Invocation.getter(#path),
        ),
      ) as Uri);

  @override
  int get status => (super.noSuchMethod(
        Invocation.getter(#status),
        returnValue: 0,
      ) as int);

  @override
  bool get isEmpty => (super.noSuchMethod(
        Invocation.getter(#isEmpty),
        returnValue: false,
      ) as bool);

  @override
  bool get isNotEmpty => (super.noSuchMethod(
        Invocation.getter(#isNotEmpty),
        returnValue: false,
      ) as bool);

  @override
  int get length => (super.noSuchMethod(
        Invocation.getter(#length),
        returnValue: 0,
      ) as int);

  @override
  Iterable<_i3.WebDavStdResourceProp<dynamic>> get props => (super.noSuchMethod(
        Invocation.getter(#props),
        returnValue: <_i3.WebDavStdResourceProp<dynamic>>[],
      ) as Iterable<_i3.WebDavStdResourceProp<dynamic>>);

  @override
  String toDebugString() => (super.noSuchMethod(
        Invocation.method(
          #toDebugString,
          [],
        ),
        returnValue: _i4.dummyValue<String>(
          this,
          Invocation.method(
            #toDebugString,
            [],
          ),
        ),
      ) as String);
}

/// A class which mocks [HrefElementParser].
///
/// See the documentation for Mockito's code generation for more information.
class MockHrefElementParser extends _i1.Mock implements _i5.HrefElementParser {
  MockHrefElementParser() {
    _i1.throwOnMissingStub(this);
  }

  @override
  Uri? convert(_i6.XmlElement? input) => (super.noSuchMethod(Invocation.method(
        #convert,
        [input],
      )) as Uri?);

  @override
  _i2.Converter<_i6.XmlElement, TT> fuse<TT>(_i2.Converter<Uri?, TT>? other) =>
      (super.noSuchMethod(
        Invocation.method(
          #fuse,
          [other],
        ),
        returnValue: _FakeConverter_1<_i6.XmlElement, TT>(
          this,
          Invocation.method(
            #fuse,
            [other],
          ),
        ),
      ) as _i2.Converter<_i6.XmlElement, TT>);

  @override
  Sink<_i6.XmlElement> startChunkedConversion(Sink<Uri?>? sink) =>
      (super.noSuchMethod(
        Invocation.method(
          #startChunkedConversion,
          [sink],
        ),
        returnValue: _FakeSink_2<_i6.XmlElement>(
          this,
          Invocation.method(
            #startChunkedConversion,
            [sink],
          ),
        ),
      ) as Sink<_i6.XmlElement>);

  @override
  _i7.Stream<Uri?> bind(_i7.Stream<_i6.XmlElement>? stream) =>
      (super.noSuchMethod(
        Invocation.method(
          #bind,
          [stream],
        ),
        returnValue: _i7.Stream<Uri?>.empty(),
      ) as _i7.Stream<Uri?>);

  @override
  _i2.Converter<RS, RT> cast<RS, RT>() => (super.noSuchMethod(
        Invocation.method(
          #cast,
          [],
        ),
        returnValue: _FakeConverter_1<RS, RT>(
          this,
          Invocation.method(
            #cast,
            [],
          ),
        ),
      ) as _i2.Converter<RS, RT>);
}

/// A class which mocks [HttpStatusElementParser].
///
/// See the documentation for Mockito's code generation for more information.
class MockHttpStatusElementParser extends _i1.Mock
    implements _i5.HttpStatusElementParser {
  MockHttpStatusElementParser() {
    _i1.throwOnMissingStub(this);
  }

  @override
  int? convert(_i6.XmlElement? input) => (super.noSuchMethod(Invocation.method(
        #convert,
        [input],
      )) as int?);

  @override
  _i2.Converter<_i6.XmlElement, TT> fuse<TT>(_i2.Converter<int?, TT>? other) =>
      (super.noSuchMethod(
        Invocation.method(
          #fuse,
          [other],
        ),
        returnValue: _FakeConverter_1<_i6.XmlElement, TT>(
          this,
          Invocation.method(
            #fuse,
            [other],
          ),
        ),
      ) as _i2.Converter<_i6.XmlElement, TT>);

  @override
  Sink<_i6.XmlElement> startChunkedConversion(Sink<int?>? sink) =>
      (super.noSuchMethod(
        Invocation.method(
          #startChunkedConversion,
          [sink],
        ),
        returnValue: _FakeSink_2<_i6.XmlElement>(
          this,
          Invocation.method(
            #startChunkedConversion,
            [sink],
          ),
        ),
      ) as Sink<_i6.XmlElement>);

  @override
  _i7.Stream<int?> bind(_i7.Stream<_i6.XmlElement>? stream) =>
      (super.noSuchMethod(
        Invocation.method(
          #bind,
          [stream],
        ),
        returnValue: _i7.Stream<int?>.empty(),
      ) as _i7.Stream<int?>);

  @override
  _i2.Converter<RS, RT> cast<RS, RT>() => (super.noSuchMethod(
        Invocation.method(
          #cast,
          [],
        ),
        returnValue: _FakeConverter_1<RS, RT>(
          this,
          Invocation.method(
            #cast,
            [],
          ),
        ),
      ) as _i2.Converter<RS, RT>);
}

/// A class which mocks [PropstatElementParser].
///
/// See the documentation for Mockito's code generation for more information.
class MockPropstatElementParser extends _i1.Mock
    implements _i5.PropstatElementParser {
  MockPropstatElementParser() {
    _i1.throwOnMissingStub(this);
  }

  @override
  Iterable<_i3.WebDavStdResourceProp<dynamic>> convert(
          ({_i6.XmlElement node, _i3.WebDavStdResource resource})? input) =>
      (super.noSuchMethod(
        Invocation.method(
          #convert,
          [input],
        ),
        returnValue: <_i3.WebDavStdResourceProp<dynamic>>[],
      ) as Iterable<_i3.WebDavStdResourceProp<dynamic>>);

  @override
  _i2.Converter<({_i6.XmlElement node, _i3.WebDavStdResource resource}), TT>
      fuse<TT>(
              _i2.Converter<Iterable<_i3.WebDavStdResourceProp<dynamic>>, TT>?
                  other) =>
          (super.noSuchMethod(
            Invocation.method(
              #fuse,
              [other],
            ),
            returnValue: _FakeConverter_1<
                ({_i6.XmlElement node, _i3.WebDavStdResource resource}), TT>(
              this,
              Invocation.method(
                #fuse,
                [other],
              ),
            ),
          ) as _i2.Converter<
              ({_i6.XmlElement node, _i3.WebDavStdResource resource}), TT>);

  @override
  Sink<({_i6.XmlElement node, _i3.WebDavStdResource resource})>
      startChunkedConversion(
              Sink<Iterable<_i3.WebDavStdResourceProp<dynamic>>>? sink) =>
          (super.noSuchMethod(
            Invocation.method(
              #startChunkedConversion,
              [sink],
            ),
            returnValue: _FakeSink_2<
                ({_i6.XmlElement node, _i3.WebDavStdResource resource})>(
              this,
              Invocation.method(
                #startChunkedConversion,
                [sink],
              ),
            ),
          ) as Sink<({_i6.XmlElement node, _i3.WebDavStdResource resource})>);

  @override
  _i7.Stream<Iterable<_i3.WebDavStdResourceProp<dynamic>>> bind(
          _i7.Stream<({_i6.XmlElement node, _i3.WebDavStdResource resource})>?
              stream) =>
      (super.noSuchMethod(
        Invocation.method(
          #bind,
          [stream],
        ),
        returnValue:
            _i7.Stream<Iterable<_i3.WebDavStdResourceProp<dynamic>>>.empty(),
      ) as _i7.Stream<Iterable<_i3.WebDavStdResourceProp<dynamic>>>);

  @override
  _i2.Converter<RS, RT> cast<RS, RT>() => (super.noSuchMethod(
        Invocation.method(
          #cast,
          [],
        ),
        returnValue: _FakeConverter_1<RS, RT>(
          this,
          Invocation.method(
            #cast,
            [],
          ),
        ),
      ) as _i2.Converter<RS, RT>);
}

/// A class which mocks [ErrorElementParser].
///
/// See the documentation for Mockito's code generation for more information.
class MockErrorElementParser extends _i1.Mock
    implements _i5.ErrorElementParser {
  MockErrorElementParser() {
    _i1.throwOnMissingStub(this);
  }

  @override
  _i8.WebDavStdResError? convert(_i6.XmlElement? input) =>
      (super.noSuchMethod(Invocation.method(
        #convert,
        [input],
      )) as _i8.WebDavStdResError?);

  @override
  _i2.Converter<_i6.XmlElement, TT> fuse<TT>(
          _i2.Converter<_i8.WebDavStdResError?, TT>? other) =>
      (super.noSuchMethod(
        Invocation.method(
          #fuse,
          [other],
        ),
        returnValue: _FakeConverter_1<_i6.XmlElement, TT>(
          this,
          Invocation.method(
            #fuse,
            [other],
          ),
        ),
      ) as _i2.Converter<_i6.XmlElement, TT>);

  @override
  Sink<_i6.XmlElement> startChunkedConversion(
          Sink<_i8.WebDavStdResError?>? sink) =>
      (super.noSuchMethod(
        Invocation.method(
          #startChunkedConversion,
          [sink],
        ),
        returnValue: _FakeSink_2<_i6.XmlElement>(
          this,
          Invocation.method(
            #startChunkedConversion,
            [sink],
          ),
        ),
      ) as Sink<_i6.XmlElement>);

  @override
  _i7.Stream<_i8.WebDavStdResError?> bind(_i7.Stream<_i6.XmlElement>? stream) =>
      (super.noSuchMethod(
        Invocation.method(
          #bind,
          [stream],
        ),
        returnValue: _i7.Stream<_i8.WebDavStdResError?>.empty(),
      ) as _i7.Stream<_i8.WebDavStdResError?>);

  @override
  _i2.Converter<RS, RT> cast<RS, RT>() => (super.noSuchMethod(
        Invocation.method(
          #cast,
          [],
        ),
        returnValue: _FakeConverter_1<RS, RT>(
          this,
          Invocation.method(
            #cast,
            [],
          ),
        ),
      ) as _i2.Converter<RS, RT>);
}