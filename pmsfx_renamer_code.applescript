-- PMSFX UCS Renamer - Applescript + Python3
-- Created by Phil Michalski @ PMSFX

on run {input, parameters}
	-- Get the selected files
	set theFiles to input
	
	if (count of theFiles) is 0 then
		display dialog "No files selected. Please select audio files in Finder." buttons {"OK"} default button 1 with icon stop
		return input
	end if
	
	-- UCS Categories Data Structure
	-- We'll load this from JSON file
	set homeFolder to POSIX path of (path to home folder)
	set ucsDataPath to homeFolder & "PMSFX_Renamer/ucs_categories.json"
	set configPath to homeFolder & ".pmsfx_renamer_config.json"
	
	-- Check if UCS data file exists
	try
		do shell script "test -f " & quoted form of ucsDataPath
	on error
		display dialog "Could not find ucs_categories.json in ~/PMSFX_Renamer/" buttons {"OK"} default button 1 with icon stop
		return input
	end try
	
	-- Load UCS categories using shell
	set categoriesJSON to do shell script "cat " & quoted form of ucsDataPath
	
	-- Get list of main categories
	set categoryList to do shell script "cat " & quoted form of ucsDataPath & " | python3 -c 'import json, sys; data=json.load(sys.stdin); print(\"\\n\".join(sorted(data.keys())))'"
	set categoryChoices to paragraphs of categoryList
	
	-- Dialog 1: Choose Category
	set selectedCategory to choose from list categoryChoices with prompt "Choose a Category:" default items {item 1 of categoryChoices} with title "PMSFX UCS Renamer" OK button name "Next" cancel button name "Cancel"
	
	if selectedCategory is false then
		return input -- User canceled
	end if
	set selectedCategory to item 1 of selectedCategory
	
	-- Get subcategories
	set subcategoryList to do shell script "cat " & quoted form of ucsDataPath & " | python3 -c 'import json, sys; data=json.load(sys.stdin); print(\"\\n\".join(sorted(data[\"" & selectedCategory & "\"].keys())))'"
	set subcategoryChoices to paragraphs of subcategoryList
	
	-- Dialog 2: Choose SubCategory
	set selectedSubCategory to choose from list subcategoryChoices with prompt "Choose a SubCategory for " & selectedCategory & ":" default items {item 1 of subcategoryChoices} with title "PMSFX UCS Renamer" OK button name "Next" cancel button name "Cancel"
	
	if selectedSubCategory is false then
		return input
	end if
	set selectedSubCategory to item 1 of selectedSubCategory
	
	-- Get CatID
	set catID to do shell script "cat " & quoted form of ucsDataPath & " | python3 -c 'import json, sys; data=json.load(sys.stdin); print(data[\"" & selectedCategory & "\"][\"" & selectedSubCategory & "\"])'"
	
	-- Load last used values
	set lastAuthor to "PMSFX"
	set lastLibrary to ""
	
	try
		do shell script "test -f " & quoted form of configPath
		set lastAuthor to do shell script "cat " & quoted form of configPath & " | python3 -c 'import json, sys; print(json.load(sys.stdin).get(\"last_author\", \"PMSFX\"))'"
		set lastLibrary to do shell script "cat " & quoted form of configPath & " | python3 -c 'import json, sys; print(json.load(sys.stdin).get(\"last_library\", \"\"))'"
	end try
	
	-- Show CatID and get SFX Name
	set dialogText to "Category: " & selectedCategory & return & "SubCategory: " & selectedSubCategory & return & "CatID: " & catID & return & return & "Enter SFX Name (spaces OK, no underscores):"
	
	set sfxName to text returned of (display dialog dialogText default answer "" with title "PMSFX UCS Renamer" buttons {"Cancel", "Next"} default button 2)
	
	if sfxName is "" then
		display dialog "SFX Name is required!" buttons {"OK"} default button 1 with icon stop
		return input
	end if
	
	-- Validate SFX name - only check for underscores
	if sfxName contains "_" then
		display dialog "SFX Name cannot contain underscores." & return & return & "Spaces are fine! Example: Thunder Crack" buttons {"OK"} default button 1 with icon stop
		return input
	end if
	
	-- Ask if user wants to keep spaces
	set spaceChoice to button returned of (display dialog "How should spaces in '" & sfxName & "' be handled?" & return & return & "Remove spaces: ThunderCrack" & return & "Keep spaces: Thunder Crack" buttons {"Cancel", "Remove Spaces", "Keep Spaces"} default button 2 with title "Space Handling")
	
	if spaceChoice is "Cancel" then
		return input
	end if
	
	-- Process SFX name based on choice
	if spaceChoice is "Remove Spaces" then
		set sfxNameClean to my replaceText(sfxName, " ", "")
	else
		set sfxNameClean to sfxName
	end if
	
	-- Get Author
	set authorName to text returned of (display dialog "Enter Author:" default answer lastAuthor with title "PMSFX UCS Renamer" buttons {"Cancel", "Next"} default button 2)
	
	if authorName is "" then
		display dialog "Author is required!" buttons {"OK"} default button 1 with icon stop
		return input
	end if
	
	-- Get Library
	set libraryName to text returned of (display dialog "Enter Library (short name):" default answer lastLibrary with title "PMSFX UCS Renamer" buttons {"Cancel", "Next"} default button 2)
	
	if libraryName is "" then
		display dialog "Library is required!" buttons {"OK"} default button 1 with icon stop
		return input
	end if
	
	-- Detect starting number from folder
	set firstFile to POSIX path of (item 1 of theFiles)
	set folderPath to do shell script "dirname " & quoted form of firstFile
	
	-- Look for existing numbered files
	set suggestedNumber to 1
	try
		set existingMax to do shell script "cd " & quoted form of folderPath & " && ls *.wav *.aif *.aiff *.mp3 *.flac *.ogg 2>/dev/null | grep -o '_[0-9]\\{3\\}_' | grep -o '[0-9]\\{3\\}' | sort -n | tail -1"
		if existingMax is not "" then
			set suggestedNumber to (existingMax as integer) + 1
		end if
	end try
	
	-- Get Starting Number
	set startNumber to text returned of (display dialog "Enter starting number:" & return & "(Detected from folder: " & suggestedNumber & ")" default answer (suggestedNumber as text) with title "PMSFX UCS Renamer" buttons {"Cancel", "Rename"} default button 2)
	
	-- Validate number
	try
		set startNumber to startNumber as integer
	on error
		display dialog "Starting number must be a valid number!" buttons {"OK"} default button 1 with icon stop
		return input
	end try
	
	-- Calculate required padding based on total files
	set totalFiles to count of theFiles
	set maxNumber to startNumber + totalFiles - 1
	set requiredDigits to length of (maxNumber as text)
	
	-- Minimum 3 digits, but expand if needed
	if requiredDigits < 3 then
		set requiredDigits to 3
	end if
	
	-- Preview & Confirm
	set previewText to "Ready to rename " & totalFiles & " files:" & return & return
	set previewText to previewText & "Format: " & catID & "_" & sfxNameClean & "###_" & authorName & "_" & libraryName & return
	set previewText to previewText & "Number padding: " & requiredDigits & " digits" & return & return
	set previewText to previewText & "Example: " & catID & "_" & sfxNameClean & my padNumber(startNumber, requiredDigits) & "_" & authorName & "_" & libraryName & ".wav" & return & return
	set previewText to previewText & "Continue?"
	
	set confirmRename to button returned of (display dialog previewText buttons {"Cancel", "Rename"} default button 2 with title "Confirm Rename")
	
	if confirmRename is "Cancel" then
		return input
	end if
	
	-- Do the renaming
	set renamedCount to 0
	set skippedCount to 0
	set errorList to {}
	
	repeat with i from 1 to count of theFiles
		set currentFile to item i of theFiles
		set filePath to POSIX path of currentFile
		
		-- Get file extension
		set fileName to do shell script "basename " & quoted form of filePath
		set fileExt to ""
		if fileName contains "." then
			set fileExt to do shell script "echo " & quoted form of fileName & " | sed 's/.*\\.//'"
			set fileExt to "." & fileExt
		end if
		
		-- Build new filename
		set currentNumber to startNumber + i - 1
		set newFileName to catID & "_" & sfxNameClean & my padNumber(currentNumber, requiredDigits) & "_" & authorName & "_" & libraryName & fileExt
		set newFilePath to do shell script "dirname " & quoted form of filePath
		set newFilePath to newFilePath & "/" & newFileName
		
		-- Check if target exists
		try
			do shell script "test -f " & quoted form of newFilePath
			set skippedCount to skippedCount + 1
		on error
			-- File doesn't exist, safe to rename
			try
				do shell script "mv " & quoted form of filePath & " " & quoted form of newFilePath
				set renamedCount to renamedCount + 1
			on error errMsg
				set end of errorList to errMsg
			end try
		end try
	end repeat
	
	-- Save config
	set configData to "{\"last_author\": \"" & authorName & "\", \"last_library\": \"" & libraryName & "\"}"
	do shell script "echo " & quoted form of configData & " > " & quoted form of configPath
	
	-- Show results
	set resultText to "✓ Successfully renamed " & renamedCount & " file(s)"
	if skippedCount > 0 then
		set resultText to resultText & return & "⚠️  Skipped " & skippedCount & " file(s) (already exist)"
	end if
	if (count of errorList) > 0 then
		set resultText to resultText & return & return & "Errors: " & return & (errorList as text)
	end if
	
	display dialog resultText buttons {"OK"} default button 1 with title "Rename Complete"
	
	return input
end run

-- Helper function to pad numbers with leading zeros (dynamic padding)
on padNumber(num, digits)
	set numText to num as text
	set padding to ""
	repeat (digits - (length of numText)) times
		set padding to padding & "0"
	end repeat
	return padding & numText
end padNumber

-- Helper function to replace text
on replaceText(theText, searchString, replacementString)
	set AppleScript's text item delimiters to searchString
	set theTextItems to every text item of theText
	set AppleScript's text item delimiters to replacementString
	set theText to theTextItems as string
	set AppleScript's text item delimiters to ""
	return theText
end replaceText
