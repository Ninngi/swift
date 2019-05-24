// SWIFT_ENABLE_TENSORFLOW

// RUN: %empty-directory(%t)
// RUN: %target-swift-frontend %s -emit-module -parse-as-library -o %t
// RUN: llvm-bcanalyzer %t/differentiable_attr.swiftmodule | %FileCheck %s -check-prefix=BCANALYZER
// RUN: %target-sil-opt -disable-sil-linking -enable-sil-verify-all %t/differentiable_attr.swiftmodule -o - | %FileCheck %s

// BCANALYZER-NOT: UnknownCode

// CHECK: @differentiable(wrt: x, jvp: jvpSimple, vjp: vjpSimple)
// CHECK-NEXT: func simple(x: Float) -> Float
@differentiable(jvp: jvpSimple, vjp: vjpSimple)
func simple(x: Float) -> Float {
  return x
}

func jvpSimple(x: Float) -> (Float, (Float) -> Float) {
  return (x, { v in v })
}

func vjpSimple(x: Float) -> (Float, (Float) -> Float) {
  return (x, { v in v })
}

// CHECK: @differentiable(wrt: x)
// CHECK-NEXT: func testWrtClause(x: Float, y: Float) -> Float
@differentiable(wrt: x)
func testWrtClause(x: Float, y: Float) -> Float {
  return x + y
}

struct InstanceMethod : Differentiable {
  // CHECK: @differentiable(wrt: (self, y))
  // CHECK-NEXT: func testWrtClause(x: Float, y: Float) -> Float
  @differentiable(wrt: (self, y))
  func testWrtClause(x: Float, y: Float) -> Float {
    return x + y
  }
}

// CHECK: @differentiable(wrt: x where T : Differentiable)
// CHECK-NEXT: func testOnlyWhereClause<T>(x: T) -> T where T : Numeric
@differentiable(where T : Differentiable)
func testOnlyWhereClause<T : Numeric>(x: T) -> T {
  return x
}

// CHECK: @differentiable(wrt: x, vjp: vjpTestWhereClause where T : Differentiable)
// CHECK-NEXT: func testWhereClause<T>(x: T) -> T where T : Numeric
@differentiable(vjp: vjpTestWhereClause where T : Differentiable)
func testWhereClause<T : Numeric>(x: T) -> T {
  return x
}
func vjpTestWhereClause<T>(x: T) -> (T, (T.TangentVector) -> T.TangentVector)
  where T : Numeric, T : Differentiable
{
  return (x, { v in v })
}

protocol P {}
extension P {
  // CHECK: @differentiable(wrt: self, vjp: vjpTestWhereClauseMethod where Self : Differentiable)
  // CHECK-NEXT: func testWhereClauseMethod() -> Self
  @differentiable(wrt: self, vjp: vjpTestWhereClauseMethod where Self : Differentiable)
  func testWhereClauseMethod() -> Self {
    return self
  }
}
extension P where Self : Differentiable {
  func vjpTestWhereClauseMethod() -> (Self, (Self.TangentVector) -> Self.TangentVector) {
    return (self, { v in v })
  }
}

// CHECK: @differentiable(wrt: x, vjp: vjpTestWhereClauseMethodTypeConstraint where T : Differentiable, T == T.TangentVector)
// CHECK-NEXT: func testWhereClauseMethodTypeConstraint<T>(x: T) -> T where T : Numeric
@differentiable(vjp: vjpTestWhereClauseMethodTypeConstraint where T : Differentiable, T == T.TangentVector)
func testWhereClauseMethodTypeConstraint<T : Numeric>(x: T) -> T {
  return x
}
func vjpTestWhereClauseMethodTypeConstraint<T>(x: T) -> (T, (T) -> T)
  where T : Numeric, T : Differentiable, T == T.TangentVector
{
  return (x, { v in v })
}

extension P {
  // CHECK: @differentiable(wrt: self, vjp: vjpTestWhereClauseMethodTypeConstraint where Self : Differentiable, Self == Self.TangentVector)
  // CHECK-NEXT: func testWhereClauseMethodTypeConstraint() -> Self
  @differentiable(wrt: self, vjp: vjpTestWhereClauseMethodTypeConstraint where Self.TangentVector == Self, Self : Differentiable)
  func testWhereClauseMethodTypeConstraint() -> Self {
    return self
  }
}
extension P where Self : Differentiable, Self == Self.TangentVector {
  func vjpTestWhereClauseMethodTypeConstraint() -> (Self, (Self.TangentVector) -> Self.TangentVector) {
    return (self, { v in v })
  }
}