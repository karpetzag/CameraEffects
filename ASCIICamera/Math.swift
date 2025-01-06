//
//  Math.swift
//  NextFloor
//
//  Created by Andrey Karpets on 02.09.2024.
//

import Foundation

extension float2x2 {

	static func makeScaleMatrix(scale: Vector2) -> Self {
		float2x2(diagonal: scale)
	}
}

extension float4x4 {

	static let identity = matrix_identity_float4x4

	static func makeZRotationMatrix(angle: Float) -> Self {
		let ca = cosf(angle)
		let sa = sinf(angle)
		let column1 = SIMD4<Float>(ca, sa, 0.0, 0.0)
		let column2 = SIMD4<Float>(-sa, ca, 0.0, 0.0)
		let column3 = SIMD4<Float>(0.0, 0.0, 1.0, 0)
		let column4 = SIMD4<Float>(0.0, 0.0, 0.0, 1.0)
		let result = matrix_float4x4([column1, column2, column3, column4])
		
		return result
	}

	static func makeScaleMatrix(scale: Float) -> Self {
		float4x4(diagonal: SIMD4<Float>(scale, scale, scale, 1))
	}

	static func makeScaleMatrix(scale: Vector2) -> Self {
		float4x4(diagonal: SIMD4<Float>(scale.x, scale.y, 1, 1))
	}

	static func makeTranslationMatrix(x: Float, y: Float) -> Self {
		let column1 = SIMD4<Float>(1.0, 0.0, 0.0, 0.0)
		let column2 = SIMD4<Float>(0.0, 1.0, 0.0, 0.0)
		let column3 = SIMD4<Float>(0.0, 0.0, 1.0, 0.0)
		let column4 = SIMD4<Float>(x, y, 0.0, 1.0)
		let result = matrix_float4x4(column1, column2, column3, column4)
		return result
	}

	static func makeOrhtoProjectionMatrix(
		left: Float,
		right: Float,
		top: Float,
		bottom: Float,
		near: Float,
		far: Float
	) -> Self {
		let column1 = SIMD4<Float>(2.0 / (right - left), 0, 0, 0)
		let column2 = SIMD4<Float>(0.0, 2 / (top - bottom), 0, 0)
		let column3 = SIMD4<Float>(0.0, 0.0, 1.0 / (far - near), 0)
		let column4 = SIMD4<Float>((left + right) / (left - right), (top + bottom) / (bottom - top), near / (near - far), 1.0)
		let result = matrix_float4x4([column1, column2, column3, column4])
		return result
	}
}

extension Vector2 {

	func normalized() -> Vector2 {
		simd.normalize(self)
	}

	func toAngle() -> Float {
		atan2(self.y, self.x) + .pi * 2 + .pi / 2
	}

	func lenght() -> Float {
		length(self)
	}

	func lenghtSquared() -> Float {
		length_squared(self)
	}
}

extension Vector2 {

	static func from(angle: Float, radius: Float = 1) -> Vector2 {
		return radius * Vector2(cosf(angle), sinf(angle))
	}
}
