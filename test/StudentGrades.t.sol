// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {StudentGrades} from "../src/StudentGrades.sol";

contract StudentGradesTest is Test {
    // Copies of the contract's events, so tests can check them with vm.expectEmit.
    event StudentAdded(address indexed student);
    event ScoreUpdated(address indexed student);
    event AdminTransferStarted(address indexed currentAdmin, address indexed pending);
    event AdminTransferred(address indexed previousAdmin, address indexed newAdmin);

    StudentGrades internal grades;

    address internal admin = makeAddr("admin");
    address internal student1 = makeAddr("student1");
    address internal student2 = makeAddr("student2");
    address internal stranger = makeAddr("stranger");
    address internal nominee = makeAddr("nominee");

    function setUp() public {
        vm.prank(admin);
        grades = new StudentGrades();
    }

    function _addStudent(address student, string memory name, uint256 score) internal {
        vm.prank(admin);
        grades.addStudent(student, name, score);
    }

    function _readAsAdmin(address student) internal returns (string memory name, uint256 score) {
        vm.prank(admin);
        return grades.getStudent(student);
    }

    // ---------------------------------------------------------------------
    // Deployment
    // ---------------------------------------------------------------------

    function test_Constructor_SetsDeployerAsAdmin() public view {
        assertEq(grades.admin(), admin);
        assertEq(grades.pendingAdmin(), address(0));
    }

    function test_Constructor_EmitsAdminTransferred() public {
        vm.expectEmit(true, true, false, false);
        emit AdminTransferred(address(0), admin);
        vm.prank(admin);
        new StudentGrades();
    }

    // ---------------------------------------------------------------------
    // addStudent: registration
    // ---------------------------------------------------------------------

    function test_AddStudent_StoresRecord() public {
        _addStudent(student1, "Student A", 75);

        (string memory name, uint256 score) = _readAsAdmin(student1);
        assertEq(name, "Student A");
        assertEq(score, 75);
    }

    function test_AddStudent_EmitsEvent() public {
        vm.expectEmit(true, false, false, true, address(grades));
        emit StudentAdded(student1);
        _addStudent(student1, "Student A", 75);
    }

    function test_AddStudent_AcceptsBoundaryScores() public {
        _addStudent(student1, "Zero", 0);
        _addStudent(student2, "Max", grades.MAX_SCORE());

        (, uint256 low) = _readAsAdmin(student1);
        (, uint256 high) = _readAsAdmin(student2);
        assertEq(low, 0);
        assertEq(high, 100);
    }

    function test_AddStudent_AcceptsMaxLengthName() public {
        string memory name = new string(grades.MAX_NAME_LENGTH());
        _addStudent(student1, name, 50);

        (string memory stored,) = _readAsAdmin(student1);
        assertEq(bytes(stored).length, 64);
    }

    function test_AddStudent_AdminCanRegisterThemselves() public {
        _addStudent(admin, "Admin", 10);

        vm.prank(admin);
        (, uint256 score) = grades.viewMyGrade();
        assertEq(score, 10);
    }

    // ---------------------------------------------------------------------
    // addStudent: access control
    // ---------------------------------------------------------------------

    function test_AddStudent_RevertsForNonAdmin() public {
        vm.prank(stranger);
        vm.expectRevert(StudentGrades.NotAdmin.selector);
        grades.addStudent(student1, "Student B", 80);
    }

    function test_AddStudent_StudentCannotRegisterOthers() public {
        _addStudent(student1, "Student A", 75);

        vm.prank(student1);
        vm.expectRevert(StudentGrades.NotAdmin.selector);
        grades.addStudent(student2, "Student B", 80);
    }

    function testFuzz_AddStudent_RevertsForAnyNonAdmin(address caller) public {
        vm.assume(caller != admin);

        vm.prank(caller);
        vm.expectRevert(StudentGrades.NotAdmin.selector);
        grades.addStudent(student1, "Student A", 75);
    }

    // ---------------------------------------------------------------------
    // addStudent: input validation
    // ---------------------------------------------------------------------

    function test_AddStudent_RevertsOnScoreAboveMax() public {
        vm.prank(admin);
        vm.expectRevert(abi.encodeWithSelector(StudentGrades.InvalidScore.selector, 101));
        grades.addStudent(student1, "Student A", 101);
    }

    function test_AddStudent_RevertsOnMaxUintScore() public {
        uint256 score = type(uint256).max;
        vm.prank(admin);
        vm.expectRevert(abi.encodeWithSelector(StudentGrades.InvalidScore.selector, score));
        grades.addStudent(student1, "Student A", score);
    }

    function testFuzz_AddStudent_ValidatesScore(uint256 score) public {
        vm.prank(admin);
        if (score > 100) {
            vm.expectRevert(abi.encodeWithSelector(StudentGrades.InvalidScore.selector, score));
            grades.addStudent(student1, "Student A", score);
        } else {
            grades.addStudent(student1, "Student A", score);
            (, uint256 stored) = _readAsAdmin(student1);
            assertEq(stored, score);
        }
    }

    function test_AddStudent_RevertsOnZeroAddress() public {
        vm.prank(admin);
        vm.expectRevert(StudentGrades.ZeroAddress.selector);
        grades.addStudent(address(0), "Nobody", 50);
    }

    function test_AddStudent_RevertsOnEmptyName() public {
        vm.prank(admin);
        vm.expectRevert(StudentGrades.InvalidName.selector);
        grades.addStudent(student1, "", 50);
    }

    function test_AddStudent_RevertsOnTooLongName() public {
        string memory name = new string(grades.MAX_NAME_LENGTH() + 1);
        vm.prank(admin);
        vm.expectRevert(StudentGrades.InvalidName.selector);
        grades.addStudent(student1, name, 50);
    }

    // ---------------------------------------------------------------------
    // addStudent: duplicates
    // ---------------------------------------------------------------------

    function test_AddStudent_RevertsOnDuplicate() public {
        _addStudent(student1, "Student A", 75);

        vm.prank(admin);
        vm.expectRevert(abi.encodeWithSelector(StudentGrades.StudentAlreadyExists.selector, student1));
        grades.addStudent(student1, "Imposter", 100);
    }

    function test_AddStudent_DuplicateDoesNotOverwrite() public {
        _addStudent(student1, "Student A", 75);

        vm.prank(admin);
        vm.expectRevert(abi.encodeWithSelector(StudentGrades.StudentAlreadyExists.selector, student1));
        grades.addStudent(student1, "Imposter", 100);

        (string memory name, uint256 score) = _readAsAdmin(student1);
        assertEq(name, "Student A");
        assertEq(score, 75);
    }

    function test_AddStudent_DuplicateCheckRunsBeforeValidation() public {
        _addStudent(student1, "Student A", 75);

        // Even with an invalid score, the duplicate error is reported first.
        vm.prank(admin);
        vm.expectRevert(abi.encodeWithSelector(StudentGrades.StudentAlreadyExists.selector, student1));
        grades.addStudent(student1, "Student A", 500);
    }

    // ---------------------------------------------------------------------
    // updateScore
    // ---------------------------------------------------------------------

    function test_UpdateScore_ChangesScoreOnly() public {
        _addStudent(student1, "Student A", 75);

        vm.prank(admin);
        grades.updateScore(student1, 88);

        (string memory name, uint256 score) = _readAsAdmin(student1);
        assertEq(name, "Student A");
        assertEq(score, 88);
    }

    function test_UpdateScore_EmitsEvent() public {
        _addStudent(student1, "Student A", 75);

        vm.expectEmit(true, false, false, true, address(grades));
        emit ScoreUpdated(student1);
        vm.prank(admin);
        grades.updateScore(student1, 88);
    }

    function test_UpdateScore_AcceptsBoundaryScores() public {
        _addStudent(student1, "Student A", 75);

        vm.prank(admin);
        grades.updateScore(student1, 0);
        (, uint256 low) = _readAsAdmin(student1);
        assertEq(low, 0);

        vm.prank(admin);
        grades.updateScore(student1, 100);
        (, uint256 high) = _readAsAdmin(student1);
        assertEq(high, 100);
    }

    function test_UpdateScore_DoesNotAffectOtherStudents() public {
        _addStudent(student1, "Student A", 75);
        _addStudent(student2, "Student B", 60);

        vm.prank(admin);
        grades.updateScore(student1, 99);

        (, uint256 score2) = _readAsAdmin(student2);
        assertEq(score2, 60);
    }

    function test_UpdateScore_RevertsForNonAdmin() public {
        _addStudent(student1, "Student A", 75);

        vm.prank(stranger);
        vm.expectRevert(StudentGrades.NotAdmin.selector);
        grades.updateScore(student1, 100);
    }

    function test_UpdateScore_StudentCannotChangeOwnScore() public {
        _addStudent(student1, "Student A", 75);

        vm.prank(student1);
        vm.expectRevert(StudentGrades.NotAdmin.selector);
        grades.updateScore(student1, 100);

        (, uint256 score) = _readAsAdmin(student1);
        assertEq(score, 75);
    }

    function testFuzz_UpdateScore_RevertsForAnyNonAdmin(address caller, uint256 newScore) public {
        vm.assume(caller != admin);
        _addStudent(student1, "Student A", 75);

        vm.prank(caller);
        vm.expectRevert(StudentGrades.NotAdmin.selector);
        grades.updateScore(student1, newScore);
    }

    function test_UpdateScore_RevertsForMissingStudent() public {
        vm.prank(admin);
        vm.expectRevert(abi.encodeWithSelector(StudentGrades.StudentNotFound.selector, student1));
        grades.updateScore(student1, 50);
    }

    function test_UpdateScore_RevertsOnScoreAboveMax() public {
        _addStudent(student1, "Student A", 75);

        vm.prank(admin);
        vm.expectRevert(abi.encodeWithSelector(StudentGrades.InvalidScore.selector, 101));
        grades.updateScore(student1, 101);

        (, uint256 score) = _readAsAdmin(student1);
        assertEq(score, 75);
    }

    function testFuzz_UpdateScore_RejectsOutOfRange(uint256 newScore) public {
        newScore = bound(newScore, 101, type(uint256).max);
        _addStudent(student1, "Student A", 75);

        vm.prank(admin);
        vm.expectRevert(abi.encodeWithSelector(StudentGrades.InvalidScore.selector, newScore));
        grades.updateScore(student1, newScore);
    }

    // ---------------------------------------------------------------------
    // getStudent
    // ---------------------------------------------------------------------

    function test_GetStudent_StudentCanReadOwnRecord() public {
        _addStudent(student1, "Student A", 75);

        vm.prank(student1);
        (string memory name, uint256 score) = grades.getStudent(student1);
        assertEq(name, "Student A");
        assertEq(score, 75);
    }

    function test_GetStudent_RevertsForOtherStudent() public {
        _addStudent(student1, "Student A", 75);
        _addStudent(student2, "Student B", 60);

        vm.prank(student2);
        vm.expectRevert(StudentGrades.NotAuthorized.selector);
        grades.getStudent(student1);
    }

    function test_GetStudent_RevertsForStranger() public {
        _addStudent(student1, "Student A", 75);

        vm.prank(stranger);
        vm.expectRevert(StudentGrades.NotAuthorized.selector);
        grades.getStudent(student1);
    }

    function test_GetStudent_StrangerCannotProbeMissingRecord() public {
        // Unauthorized callers get NotAuthorized, not StudentNotFound,
        // so the API does not reveal whether an address is registered.
        vm.prank(stranger);
        vm.expectRevert(StudentGrades.NotAuthorized.selector);
        grades.getStudent(student1);
    }

    function test_GetStudent_RevertsForMissingStudentAsAdmin() public {
        vm.prank(admin);
        vm.expectRevert(abi.encodeWithSelector(StudentGrades.StudentNotFound.selector, student1));
        grades.getStudent(student1);
    }

    function test_GetStudent_RevertsForMissingStudentAsSelf() public {
        vm.prank(student1);
        vm.expectRevert(abi.encodeWithSelector(StudentGrades.StudentNotFound.selector, student1));
        grades.getStudent(student1);
    }

    // ---------------------------------------------------------------------
    // viewMyGrade
    // ---------------------------------------------------------------------

    function test_ViewMyGrade_ReturnsOwnRecord() public {
        _addStudent(student1, "Student C", 90);

        vm.prank(student1);
        (string memory name, uint256 score) = grades.viewMyGrade();
        assertEq(name, "Student C");
        assertEq(score, 90);
    }

    function test_ViewMyGrade_ReflectsUpdate() public {
        _addStudent(student1, "Student C", 90);
        vm.prank(admin);
        grades.updateScore(student1, 40);

        vm.prank(student1);
        (, uint256 score) = grades.viewMyGrade();
        assertEq(score, 40);
    }

    function test_ViewMyGrade_RevertsForUnregistered() public {
        vm.prank(student2);
        vm.expectRevert(StudentGrades.NotRegistered.selector);
        grades.viewMyGrade();
    }

    function test_ViewMyGrade_RevertsForAdminWhoIsNotAStudent() public {
        vm.prank(admin);
        vm.expectRevert(StudentGrades.NotRegistered.selector);
        grades.viewMyGrade();
    }

    // ---------------------------------------------------------------------
    // Admin transfer
    // ---------------------------------------------------------------------

    function test_TransferAdmin_TwoStepHandover() public {
        vm.expectEmit(true, true, false, false, address(grades));
        emit AdminTransferStarted(admin, nominee);
        vm.prank(admin);
        grades.transferAdmin(nominee);

        assertEq(grades.admin(), admin, "admin changes only after accept");
        assertEq(grades.pendingAdmin(), nominee);

        vm.expectEmit(true, true, false, false, address(grades));
        emit AdminTransferred(admin, nominee);
        vm.prank(nominee);
        grades.acceptAdmin();

        assertEq(grades.admin(), nominee);
        assertEq(grades.pendingAdmin(), address(0));
    }

    function test_TransferAdmin_NewAdminGainsAndOldAdminLosesRights() public {
        vm.prank(admin);
        grades.transferAdmin(nominee);
        vm.prank(nominee);
        grades.acceptAdmin();

        vm.prank(admin);
        vm.expectRevert(StudentGrades.NotAdmin.selector);
        grades.addStudent(student1, "Student A", 75);

        vm.prank(nominee);
        grades.addStudent(student1, "Student A", 75);

        vm.prank(nominee);
        (, uint256 score) = grades.getStudent(student1);
        assertEq(score, 75);
    }

    function test_TransferAdmin_PendingAdminHasNoRightsBeforeAccept() public {
        vm.prank(admin);
        grades.transferAdmin(nominee);

        vm.prank(nominee);
        vm.expectRevert(StudentGrades.NotAdmin.selector);
        grades.addStudent(student1, "Student A", 75);
    }

    function test_TransferAdmin_RevertsForNonAdmin() public {
        vm.prank(stranger);
        vm.expectRevert(StudentGrades.NotAdmin.selector);
        grades.transferAdmin(stranger);
    }

    function test_TransferAdmin_RevertsOnZeroAddress() public {
        vm.prank(admin);
        vm.expectRevert(StudentGrades.ZeroAddress.selector);
        grades.transferAdmin(address(0));
    }

    function test_TransferAdmin_CanReplaceNominee() public {
        vm.startPrank(admin);
        grades.transferAdmin(nominee);
        grades.transferAdmin(stranger);
        vm.stopPrank();

        vm.prank(nominee);
        vm.expectRevert(StudentGrades.NotPendingAdmin.selector);
        grades.acceptAdmin();

        vm.prank(stranger);
        grades.acceptAdmin();
        assertEq(grades.admin(), stranger);
    }

    function test_AcceptAdmin_RevertsWithoutPendingTransfer() public {
        vm.prank(stranger);
        vm.expectRevert(StudentGrades.NotPendingAdmin.selector);
        grades.acceptAdmin();
    }

    function test_AcceptAdmin_RevertsForWrongCaller() public {
        vm.prank(admin);
        grades.transferAdmin(nominee);

        vm.prank(stranger);
        vm.expectRevert(StudentGrades.NotPendingAdmin.selector);
        grades.acceptAdmin();
    }

    // ---------------------------------------------------------------------
    // Privacy: documents a limitation, not a feature
    // ---------------------------------------------------------------------

    /// Shows that the read restrictions on getStudent do not make data private:
    /// anyone can read contract storage directly. If the storage layout changes
    /// (admin = slot 0, pendingAdmin = slot 1, students = slot 2), update the slot here.
    function test_Privacy_ScoreIsReadableFromRawStorage() public {
        _addStudent(student1, "Student A", 75);

        uint256 studentsSlot = 2;
        bytes32 recordSlot = keccak256(abi.encode(student1, studentsSlot));
        bytes32 scoreSlot = bytes32(uint256(recordSlot) + 1);

        uint256 rawScore = uint256(vm.load(address(grades), scoreSlot));
        assertEq(rawScore, 75);
    }
}
