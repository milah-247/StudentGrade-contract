// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

//import
import {Test} from "forge-std/Test.sol";
import {StudentGrades} from "../src/student.sol";


contract StudentGradeTest is Test {
    StudentGrades studentGrades;
    address admin = address(1);
    address student1 = address(2);
    address student2 = address(3);

    function setUp() public {
        vm.prank(admin);
        studentGrades = new StudentGrades();
    }

    function testAdminAddsStudent() public {
        vm.startPrank(admin);
        studentGrades.addStudent(student1, "Student A", 75);
        (string memory name, uint score) = studentGrades.getStudent(student1);
        assertEq(name, "Student A");
        assertEq(score, 75);
        vm.stopPrank();
    }

    function testOnlyAdminCanAddStudent() public {
        vm.startPrank(student1);
        vm.expectRevert("Only admin can perform this action");
        studentGrades.addStudent(student1, "Student B", 80);
        vm.stopPrank();
    }

    function testStudentViewOwnGrade() public {
        vm.startPrank(admin);
        studentGrades.addStudent(student1, "Student C", 90);
        vm.stopPrank();

        vm.startPrank(student1);
        (string memory name, uint score) = studentGrades.viewMyGrade();
        assertEq(name, "Student C");
        assertEq(score, 90);
        vm.stopPrank();
    }

    function testUnregisteredCannotViewGrade() public {
        vm.startPrank(student2);
        vm.expectRevert("Only registered students can perform this action");
        studentGrades.viewMyGrade();
        vm.stopPrank();
    }
}

