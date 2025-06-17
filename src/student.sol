// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;


contract StudentGrades {
    address public admin;

    struct Student {
        string name;
        uint score;
        bool exists;
    }

    mapping(address => Student) public students;

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can perform this action");
        _;
    }

    modifier onlyStudent() {
        require(students[msg.sender].exists, "Only registered students can perform this action");
        _;
    }

    constructor() {
        admin = msg.sender;
    }

    function addStudent(address studentAddress, string calldata name, uint score) external onlyAdmin {
        require(!students[studentAddress].exists, "Student already exists");
        require(score <= 100, "Score must be between 0 and 100");

        students[studentAddress] = Student({
            name: name,
            score: score,
            exists: true
        });
    }

    function getStudent(address studentAddress) external view returns (string memory name, uint score) {
        require(students[studentAddress].exists, "Student does not exist");
        Student storage student = students[studentAddress];
        return (student.name, student.score);
    }

    function viewMyGrade() external view onlyStudent returns (string memory name, uint score) {
        Student storage student = students[msg.sender];
        return (student.name, student.score);
    }
}
