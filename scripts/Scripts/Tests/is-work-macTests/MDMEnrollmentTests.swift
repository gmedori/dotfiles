import Testing
@testable import is_work_mac

struct `MDM enrollment parsing` {
	@Test
	func `Reads an unenrolled Mac`() {
		let output = "Enrolled via DEP: No\nMDM enrollment: No\n"
		#expect(MDMEnrollment.isEnrolled(from: output) == false)
	}

	@Test
	func `Reads an enrolled Mac`() {
		let output = "Enrolled via DEP: Yes\nMDM enrollment: Yes\n"
		#expect(MDMEnrollment.isEnrolled(from: output) == true)
	}

	@Test
	func `Reads a user-approved enrollment`() {
		let output = "Enrolled via DEP: No\nMDM enrollment: Yes (User Approved)\n"
		#expect(MDMEnrollment.isEnrolled(from: output) == true)
	}

	@Test
	func `Ignores the DEP line`() {
		let output = "Enrolled via DEP: Yes\n"
		#expect(MDMEnrollment.isEnrolled(from: output) == nil)
	}

	@Test
	func `Returns nil without an enrollment line`() {
		#expect(MDMEnrollment.isEnrolled(from: "") == nil)
	}
}
