import Testing
@testable import is_work_mac

@Suite("MDM enrollment parsing")
struct MDMEnrollmentParsingTests {
	@Test("Reads an unenrolled Mac")
	func readsUnenrolled() {
		let output = "Enrolled via DEP: No\nMDM enrollment: No\n"
		#expect(MDMEnrollment.isEnrolled(from: output) == false)
	}

	@Test("Reads an enrolled Mac")
	func readsEnrolled() {
		let output = "Enrolled via DEP: Yes\nMDM enrollment: Yes\n"
		#expect(MDMEnrollment.isEnrolled(from: output) == true)
	}

	@Test("Reads a user-approved enrollment")
	func readsUserApproved() {
		let output = "Enrolled via DEP: No\nMDM enrollment: Yes (User Approved)\n"
		#expect(MDMEnrollment.isEnrolled(from: output) == true)
	}

	@Test("Ignores the DEP line")
	func ignoresDEPLine() {
		let output = "Enrolled via DEP: Yes\n"
		#expect(MDMEnrollment.isEnrolled(from: output) == nil)
	}

	@Test("Returns nil without an enrollment line")
	func returnsNilWithoutLine() {
		#expect(MDMEnrollment.isEnrolled(from: "") == nil)
	}
}
