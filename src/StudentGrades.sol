// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @title StudentGrades
/// @notice A minimal registry where a single admin records and updates student scores (0-100).
/// @dev PRIVACY WARNING: everything this contract stores, every event it emits and the calldata of
///      every transaction sent to it is publicly readable on-chain (for example with
///      `eth_getStorageAt` or a block explorer). The access checks on the view functions only limit
///      what this contract's own API returns; they do NOT make the data private. Do not store real
///      student names or real grades on a public network. See SECURITY.md.
contract StudentGrades {
    /// @notice Highest score that can be recorded.
    uint256 public constant MAX_SCORE = 100;

    /// @notice Longest name (in bytes) that can be recorded.
    uint256 public constant MAX_NAME_LENGTH = 64;

    struct Student {
        string name;
        uint256 score;
        bool exists;
    }

    /// @notice Account allowed to register students and change scores.
    address public admin;

    /// @notice Account nominated to become admin. It must call `acceptAdmin` to take over.
    address public pendingAdmin;

    /// @dev Private only hides the getter. The data is still public on-chain (see contract docs).
    mapping(address => Student) private students;

    /// @dev Events deliberately leave out names and scores to avoid making them easier to index.
    event StudentAdded(address indexed student);
    event ScoreUpdated(address indexed student);
    event AdminTransferStarted(address indexed currentAdmin, address indexed nominee);
    event AdminTransferred(address indexed previousAdmin, address indexed newAdmin);

    error NotAdmin();
    error NotPendingAdmin();
    error NotAuthorized();
    error NotRegistered();
    error ZeroAddress();
    error InvalidName();
    error InvalidScore(uint256 score);
    error StudentAlreadyExists(address student);
    error StudentNotFound(address student);

    modifier onlyAdmin() {
        if (msg.sender != admin) {
            revert NotAdmin();
        }
        _;
    }

    constructor() {
        admin = msg.sender;
        emit AdminTransferred(address(0), msg.sender);
    }

    /// @notice Register a new student with an initial score.
    /// @param studentAddress The student's account. Must not be the zero address or already registered.
    /// @param name Display name, 1 to `MAX_NAME_LENGTH` bytes. Avoid real personal data on public networks.
    /// @param score Initial score, 0 to `MAX_SCORE`.
    function addStudent(address studentAddress, string calldata name, uint256 score) external onlyAdmin {
        if (studentAddress == address(0)) {
            revert ZeroAddress();
        }
        if (students[studentAddress].exists) {
            revert StudentAlreadyExists(studentAddress);
        }
        uint256 nameLength = bytes(name).length;
        if (nameLength == 0 || nameLength > MAX_NAME_LENGTH) {
            revert InvalidName();
        }
        if (score > MAX_SCORE) {
            revert InvalidScore(score);
        }

        students[studentAddress] = Student({name: name, score: score, exists: true});
        emit StudentAdded(studentAddress);
    }

    /// @notice Change the score of a registered student.
    /// @param studentAddress The student's account. Must be registered.
    /// @param newScore New score, 0 to `MAX_SCORE`.
    function updateScore(address studentAddress, uint256 newScore) external onlyAdmin {
        if (!students[studentAddress].exists) {
            revert StudentNotFound(studentAddress);
        }
        if (newScore > MAX_SCORE) {
            revert InvalidScore(newScore);
        }

        students[studentAddress].score = newScore;
        emit ScoreUpdated(studentAddress);
    }

    /// @notice Read a student's record. Only the admin or the student themselves may call this.
    function getStudent(address studentAddress) external view returns (string memory name, uint256 score) {
        if (msg.sender != admin && msg.sender != studentAddress) {
            revert NotAuthorized();
        }
        Student storage student = students[studentAddress];
        if (!student.exists) {
            revert StudentNotFound(studentAddress);
        }
        return (student.name, student.score);
    }

    /// @notice Read the caller's own record.
    function viewMyGrade() external view returns (string memory name, uint256 score) {
        Student storage student = students[msg.sender];
        if (!student.exists) {
            revert NotRegistered();
        }
        return (student.name, student.score);
    }

    /// @notice Start handing admin rights to `newAdmin`. Calling again replaces the pending nominee.
    function transferAdmin(address newAdmin) external onlyAdmin {
        if (newAdmin == address(0)) {
            revert ZeroAddress();
        }
        pendingAdmin = newAdmin;
        emit AdminTransferStarted(msg.sender, newAdmin);
    }

    /// @notice Finish an admin handover. Must be called by the pending admin.
    function acceptAdmin() external {
        if (msg.sender != pendingAdmin) {
            revert NotPendingAdmin();
        }
        address previousAdmin = admin;
        admin = msg.sender;
        pendingAdmin = address(0);
        emit AdminTransferred(previousAdmin, msg.sender);
    }
}
