import Foundation

typealias Time = TimeInterval
typealias Vector2 = SIMD2<Float>
typealias Vector3 = SIMD3<Float>
typealias Vector4 = SIMD4<Float>
typealias Color = SIMD4<Float>
typealias Rect = SIMD4<Float>
typealias Size = SIMD2<Float>

extension Rect {

	var width: Float {
		self.z
	}

	var height: Float {
		self.w
	}

	var size: Vector2 {
		Vector2(self.width, self.height)
	}
}

extension Color {
	
	var alpha: Float {
		get {
			self.w
		}
		set {
			self.w = newValue
		}
	}
}

extension Size {

	var width: Float {
		self.x
	}
	
	var height: Float {
		self.y
	}
}

extension Rect {

	var maxX: Float {
		self.x + self.width
	}

	var midX: Float {
		self.x + self.width / 2
	}

	var maxY: Float {
		self.y + self.height
	}
}

struct Quad {

	static let ndcValues =
	[
		Vertex(x: -0.5, y: 0.5, textureCoords: simd_float2(0, 0)),
		Vertex(x: 0.5, y: 0.5, textureCoords: simd_float2(0, 0)),
		Vertex(x: -0.5, y: -0.5, textureCoords: simd_float2(0, 0)),
		Vertex(x: 0.5, y: -0.5, textureCoords: simd_float2(0, 0))
	]

	static func quadValuesFromRect(_ rect: Rect) -> [Vertex] {
		[
			Vertex(x: rect.x, y: rect.y, textureCoords: simd_float2(0, 0)),
			Vertex(x: rect.x + rect.width, y: rect.y, textureCoords: simd_float2(1, 0)),
			Vertex(x: rect.x, y: rect.y + rect.height, textureCoords: simd_float2(0, 1)),
			Vertex(x: rect.x + rect.width, y: rect.y + rect.height, textureCoords: simd_float2(1, 1))
		]
	}
}

extension Vertex {

	init(x: Float, y: Float, textureCoords: simd_float2) {
		self.init(position: simd_float4(x, y, 0, 1), textureCoords: textureCoords)
	}
}
