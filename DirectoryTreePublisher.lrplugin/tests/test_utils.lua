--[[
  Unit tests for utils module
  Run with: lua test_utils.lua
]]

-- Add parent directory to package path so we can require utils
package.path = package.path .. ";../?.lua"

-- Import the shared utilities
local utils = require 'utils'

-- ============================================================================
-- Test framework
-- ============================================================================

local tests_passed = 0
local tests_failed = 0

local function assertEquals(expected, actual, test_name)
  if expected == actual then
    tests_passed = tests_passed + 1
    print("[PASS] " .. test_name)
  else
    tests_failed = tests_failed + 1
    print("[FAIL] " .. test_name)
    print("    Expected: '" .. tostring(expected) .. "'")
    print("    Actual:   '" .. tostring(actual) .. "'")
  end
end

-- ============================================================================
-- Test cases
-- ============================================================================

print("\n=== Testing longestCommonRoot ===\n")

-- Test 1: Empty input
assertEquals("", utils.longestCommonRoot(nil), "nil input returns empty string")
assertEquals("", utils.longestCommonRoot({}), "empty array returns empty string")

-- Test 2: Single directory
assertEquals(
  "D:/Photos/2023/January",
  utils.longestCommonRoot({ "D:/Photos/2023/January" }),
  "single directory returns itself"
)

-- Test 3: Two directories with common root
assertEquals(
  "D:/Photos/2023",
  utils.longestCommonRoot({
    "D:/Photos/2023/January",
    "D:/Photos/2023/February"
  }),
  "two directories with common parent"
)

-- Test 4: Multiple directories with deeper common root
assertEquals(
  "D:/Photos",
  utils.longestCommonRoot({
    "D:/Photos/2023/January",
    "D:/Photos/2023/February",
    "D:/Photos/2024/March"
  }),
  "three directories with common grandparent"
)

-- Test 5: No common root (different drives)
assertEquals(
  "",
  utils.longestCommonRoot({
    "C:/Photos/2023",
    "D:/Photos/2023"
  }),
  "different drives have no common root"
)

-- Test 6: Windows backslash paths (should normalize)
assertEquals(
  "D:/Photos/2023",
  utils.longestCommonRoot({
    "D:\\Photos\\2023\\January",
    "D:\\Photos\\2023\\February"
  }),
  "Windows backslash paths are normalized"
)

-- Test 7: Mixed path separators
assertEquals(
  "D:/Photos/2023",
  utils.longestCommonRoot({
    "D:/Photos/2023/January",
    "D:\\Photos\\2023\\February"
  }),
  "mixed path separators work correctly"
)

-- Test 8: Common root is the drive only
assertEquals(
  "D:",
  utils.longestCommonRoot({
    "D:/Photos/2023",
    "D:/Videos/2023"
  }),
  "common root can be just the drive"
)

-- Test 9: Identical paths
assertEquals(
  "D:/Photos/2023/January",
  utils.longestCommonRoot({
    "D:/Photos/2023/January",
    "D:/Photos/2023/January"
  }),
  "identical paths return the full path"
)

-- Test 10: One path is prefix of another
assertEquals(
  "D:/Photos",
  utils.longestCommonRoot({
    "D:/Photos",
    "D:/Photos/2023/January"
  }),
  "shorter path is common root when it's a prefix"
)

-- Test 11: Unix-style paths
assertEquals(
  "/home/user/photos",
  utils.longestCommonRoot({
    "/home/user/photos/2023",
    "/home/user/photos/2024"
  }),
  "Unix-style paths work correctly"
)

-- Test 12: Case sensitivity (Lua string comparison is case-sensitive)
assertEquals(
  "D:",
  utils.longestCommonRoot({
    "D:/Photos/2023",
    "D:/photos/2023"
  }),
  "paths are case-sensitive (Photos != photos)"
)

-- ============================================================================
-- Summary
-- ============================================================================

print("\n=== Test Summary ===")
print("Passed: " .. tests_passed)
print("Failed: " .. tests_failed)
print("Total:  " .. (tests_passed + tests_failed))

if tests_failed > 0 then
  os.exit(1)
else
  print("\nAll tests passed!")
  os.exit(0)
end
