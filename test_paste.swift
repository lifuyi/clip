#!/usr/bin/swift
import Cocoa

// Test pasteboard functionality
let pasteboard = NSPasteboard.general
print("Current pasteboard change count: \(pasteboard.changeCount)")

// Clear the pasteboard
pasteboard.clearContents()
print("After clearing - pasteboard change count: \(pasteboard.changeCount)")

// Set a test string
let testString = "Test content for clipboard"
let result = pasteboard.setString(testString, forType: .string)
print("Set string result: \(result)")
print("After setting string - pasteboard change count: \(pasteboard.changeCount)")

// Retrieve the string
let retrievedString = pasteboard.string(forType: .string)
print("Retrieved string: \(retrievedString ?? "nil")")

if retrievedString == testString {
    print("✓ Successfully verified pasteboard content")
} else {
    print("✗ Pasteboard content mismatch")
}